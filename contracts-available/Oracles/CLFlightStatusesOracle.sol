/**
 * @title FlightStatusesOracle is a contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 *
 */

pragma solidity 0.7.6;
// SPDX-License-Identifier: Apache-2.0


import "@chainlink/contracts/src/v0.7/ChainlinkClient.sol";
import "../Utilities/strings.sol";
import "./ChainlinkOracle.sol";

contract CLFlightStatusesOracle is ChainlinkOracle {
    using strings for *;
    using Chainlink for Chainlink.Request;

    bytes32 public constant ORACLETYPE = "FlightStatuses";
    bytes32 public constant NAME = "CL FlightStatuses";

    event Request(bytes32 chainlinkRequestId, uint256 gifRequestId, uint256 checkAtTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay);
    event Fulfill(bytes1 status, bool arrived, uint256 arrivalGateDelayMinutes);

    constructor(
        address _link,
        address _chainLinkOracle,
        address _oracleService,
        address _oracleOwnerService,
        bytes32 _jobId,
        uint256 _payment
    )
    public
    ChainlinkOracle(
        _link,
        _chainLinkOracle,
        _oracleService,
        _oracleOwnerService,
        ORACLETYPE,
        NAME,
        _jobId,
        _payment
    )
    {}

    function request(uint256 _gifRequestId, bytes calldata _input)
    external override
    onlyQuery
    {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        (uint256 checkAtTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay) = abi.decode(_input, (uint256, bytes32, bytes32));
        req.add("endpoint", "e-status");
        req.add("carrierFlightNumber", carrierFlightNumber.toSliceB32().toString());
        req.add("yearMonthDay", departureYearMonthDay.toSliceB32().toString());
        req.add("checkAtTime", checkAtTime.toString());
        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);
        requests[chainlinkRequestId] = _gifRequestId;

        emit Request(chainlinkRequestId, _gifRequestId, checkAtTime, carrierFlightNumber, departureYearMonthDay);
    }

    function fulfill(bytes32 _chainlinkRequestId, bytes1 _status, bool _arrived, uint256 _delay)
    public
    recordChainlinkFulfillment(_chainlinkRequestId)
    {

        if (_status == "C") {
            // Flight cancelled
            _respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
        } else if (_status == "D") {
            // Flight diverted
            _respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
        } else if (_status != "L" && _status != "A" && _status != "C" && _status != "D") {
            // Unprocessable _status
            _respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
        } else {
            if (_status == "A" || (_status == "L" && !_arrived)) {
                // Flight still active or not at gate
                _respond(requests[_chainlinkRequestId], abi.encode(bytes1("A"), -1));
            } else if (_status == "L" && _arrived) {
                _respond(requests[_chainlinkRequestId], abi.encode(_status, _delay));
            } else {
                // No _delay info
                _respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
            }
        }

        delete requests[_chainlinkRequestId];

        updatedHeight = block.number;

        emit Fulfill(_status, _arrived, _delay);
    }

}
