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

    struct QueuedRequest {
        uint256 executionTime;
        bytes32 carrierFlightNumber;
        bytes32 yearMonthDay;
    }

    mapping(uint256 => QueuedRequest) public queuedRequests;

    bytes32 public constant ORACLETYPE = "FlightStatuses";
    bytes32 public constant NAME = "CL FlightStatuses";

    event RequestQueued(
        uint256 gifRequestId,
        uint256 checkAtTime,
        bytes32 carrierFlightNumber,
        bytes32 departureYearMonthDay
    );
    event Request(
        bytes32 chainlinkRequestId,
        uint256 gifRequestId,
        uint256 checkAtTime,
        bytes32 carrierFlightNumber,
        bytes32 departureYearMonthDay
    );
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
        (uint256 executionTime, bytes32 carrierFlightNumber, bytes32 yearMonthDay) = abi.decode(_input, (uint256, bytes32, bytes32));
        require(executionTime > block.timestamp, 'ERROR:FSO-001:EXECUTION_TIME_IN_THE_PAST');
        QueuedRequest memory queued = QueuedRequest(executionTime, carrierFlightNumber, yearMonthDay);
        queuedRequests[_gifRequestId] = queued;
        emit RequestQueued(
            _gifRequestId,
            executionTime,
            carrierFlightNumber,
            yearMonthDay
        );
    }

    function executeQueuedRequest(uint256 _gifRequestId)
    external // anybody can call this
    {
        // TODO: Add incentive system to ensure execution
        QueuedRequest memory queued = queuedRequests[_gifRequestId];
        require(queued.executionTime > 0 && queued.executionTime <= block.timestamp, 'ERROR:FSO-002:QUEUED_REQUEST_NOT_DUE');

        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("carrierFlightNumber", queued.carrierFlightNumber.toSliceB32().toString());
        req.add("yearMonthDay", queued.yearMonthDay.toSliceB32().toString());
        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);
        requests[chainlinkRequestId] = _gifRequestId;
        delete queuedRequests[_gifRequestId];
        emit Request(
            chainlinkRequestId,
            _gifRequestId,
            queued.executionTime,
            queued.carrierFlightNumber,
            queued.yearMonthDay
        );
    }


    function fulfill(bytes32 _chainlinkRequestId, bytes1 _status, bool _arrived, uint256 _delay)
    public
    recordChainlinkFulfillment(_chainlinkRequestId)
    {
        bytes memory data;

        if (_status == "C") {
            // Flight cancelled
            //_respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
            data = abi.encode(_status, -1);
        } else if (_status == "D") {
            // Flight diverted
            //_respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
            data = abi.encode(_status, -1);
        } else if (_status != "L" && _status != "A" && _status != "C" && _status != "D") {
            // Unprocessable _status
            //_respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
            data = abi.encode(_status, -1);
        } else {
            if (_status == "A" || (_status == "L" && !_arrived)) {
                // Flight still active or not at gate
                //_respond(requests[_chainlinkRequestId], abi.encode(bytes1("A"), -1));
                data = abi.encode(bytes1("A"), -1);
            } else if (_status == "L" && _arrived) {
                //_respond(requests[_chainlinkRequestId], abi.encode(_status, _delay));
                data = abi.encode(_status, _delay);
            } else {
                // No _delay info
                //_respond(requests[_chainlinkRequestId], abi.encode(_status, -1));
                data = abi.encode(_status, -1);
            }
        }

        _respond(requests[_chainlinkRequestId], data);

        delete requests[_chainlinkRequestId];

        updatedHeight = block.number;

        emit Fulfill(_status, _arrived, _delay);
    }

}
