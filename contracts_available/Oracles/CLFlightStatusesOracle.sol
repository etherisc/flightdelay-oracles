/**
 * @title FlightStatusesOracle is a contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 *
 * Deployed on rinkeby at 0xFbAbbC5c0Be7a2eE474FEE6F1bBD77D97ae45850
 *
 */

pragma solidity 0.6.11;
// SPDX-License-Identifier: Apache-2.0


import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "../Utilities/strings.sol";
import "./ChainlinkOracle.sol";

contract CLFlightStatusesOracle is ChainlinkOracle {
    using strings for *;

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

    function fulfill(bytes32 _chainlinkRequestId, bytes32 _data)
    public
    recordChainlinkFulfillment(_chainlinkRequestId)
    {
        strings.slice memory slResult = _data.toSliceB32();
        require(slResult.len() > 0, "ERROR:CFS-001:EMPTY_RESULT");
        require(slResult.count(",".toSlice()) == 2, "ERROR:CFS-002:INVALID_RESULT");

        bytes1 status = bytes(slResult.split(",".toSlice()).toString())[0];
        bool arrived;
        uint256 arrivalGateDelayMinutes;

        if (status == "C") {
            // Flight cancelled
            _respond(requests[_chainlinkRequestId], abi.encode(status, -1));
        } else if (status == "D") {
            // Flight diverted
            _respond(requests[_chainlinkRequestId], abi.encode(status, -1));
        } else if (status != "L" && status != "A" && status != "C" && status != "D") {
            // Unprocessable status
            _respond(requests[_chainlinkRequestId], abi.encode(status, -1));
        } else {
            strings.slice memory slArrivalGateDelayMinutes = slResult.split(",".toSlice());
            arrived = slResult.split(",".toSlice()).compare("true".toSlice()) == 0;

            if (status == "A" || (status == "L" && !arrived)) {
                // Flight still active or not at gate
                _respond(requests[_chainlinkRequestId], abi.encode(bytes1("A"), -1));
            } else if (status == "L" && arrived) {
                arrivalGateDelayMinutes = slArrivalGateDelayMinutes.len() == 0 ? 0 : slArrivalGateDelayMinutes.toString().parseInt();
                _respond(requests[_chainlinkRequestId], abi.encode(status, arrivalGateDelayMinutes));
            } else {
                // No delay info
                _respond(requests[_chainlinkRequestId], abi.encode(status, -1));
            }
        }

        delete requests[_chainlinkRequestId];

        updatedHeight = block.number;

        emit Fulfill(status, arrived, arrivalGateDelayMinutes);
    }

}
