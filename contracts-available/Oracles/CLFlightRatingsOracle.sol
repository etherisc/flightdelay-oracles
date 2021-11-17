/**
 * @title FlightRatingsOracle is a contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 *
 * Deployed on rinkeby at 0xcd2cbac4f5e4d4f5d6d0f7b1fda0910b7f0c9c56
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
        req.add("extPath", carrierFlightNumber.toSliceB32().toString());
        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);
        requests[chainlinkRequestId] = _gifRequestId;

        emit Request(chainlinkRequestId, _gifRequestId, carrierFlightNumber);
    }

    function fulfill(bytes32 _chainlinkRequestId, bytes32 _data)
    public
    recordChainlinkFulfillment(_chainlinkRequestId)
    {
        // expected result

        strings.slice memory slResult = _data.toSliceB32();

        require(slResult.len() != 0, "ERROR:CFR-001:EMPTY_RESULT");
        require(slResult.count(",".toSlice()) == 5, "ERROR:CFR-002:INVALID_RESULT");

        uint256[6] memory statistics;
        for (uint i = 0; i < 5; i++) {
            statistics[i] = slResult.split(",".toSlice()).toString().parseInt();
        }
        statistics[5] = slResult.toString().parseInt();

        _respond(requests[_chainlinkRequestId], abi.encode(statistics));
        delete requests[_chainlinkRequestId];

        updatedHeight = block.number;

        emit Fulfill(statistics);
    }
}
