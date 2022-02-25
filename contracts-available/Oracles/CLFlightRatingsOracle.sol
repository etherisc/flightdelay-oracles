/**
 * @title FlightRatingsOracle is a contract which requests data from
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

contract CLFlightRatingsOracle is ChainlinkOracle {
    using strings for *;
    using Chainlink for Chainlink.Request;

    bytes32 public constant ORACLETYPE = "FlightRatings";
    bytes32 public constant NAME = "CL FlightRatings";

    event Request(bytes32 chainlinkRequestId, uint256 gifRequestId, bytes32 carrierFlightNumber);
    event Fulfill(uint256[6] statistics);

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
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        (bytes32 carrierFlightNumber) = abi.decode(_input, (bytes32));
        req.add("carrierFlightNumber", carrierFlightNumber.toSliceB32().toString());
        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);
        requests[chainlinkRequestId] = _gifRequestId;

        emit Request(chainlinkRequestId, _gifRequestId, carrierFlightNumber);
    }

    function fulfill(
        bytes32 _chainlinkRequestId,
        uint256 _observations,
        uint256 _late15,
        uint256 _late30,
        uint256 _late45,
        uint256 _cancelled,
        uint256 _diverted)
    public
    recordChainlinkFulfillment(_chainlinkRequestId)
    {
        uint256[6] memory statistics = [_observations, _late15, _late30, _late45, _cancelled, _diverted];
        bytes memory data =  abi.encode(statistics);
        _respond(requests[_chainlinkRequestId], data);
        delete requests[_chainlinkRequestId];
        emit Fulfill(statistics);
    }
}
