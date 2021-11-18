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

contract TestCLFlightStatusesOracle is ChainlinkOracle {
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

    function request(uint256 _requestId, bytes calldata _input)
    external
    override
    {

    }

    function request2(bytes32 jobId)
    external
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        req.add("carrier", "LH/117");
        req.add("flightNumber", "117");
        req.addUint("year", 2021);
        req.addUint("month", 11);
        req.addUint("day", 15);
        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);

        emit Request(chainlinkRequestId, 0 /* _gifRequestId */, 0 /* checkAtTime */, "/LH/117", "2021/11/15");
    }

    function fulfill(bytes32 _chainlinkRequestId, bytes1 status, bool arrived, uint256 delay)
    public
    recordChainlinkFulfillment(_chainlinkRequestId)
    {
        emit Fulfill(status, true, delay);
    }
}
