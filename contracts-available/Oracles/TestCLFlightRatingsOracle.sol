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

contract TestCLFlightRatingsOracle is ChainlinkOracle {
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

    function request(uint256 _requestId, bytes calldata _input)
    external
    override
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        // (bytes32 carrierFlightNumber) = abi.decode(_input, (bytes32));
        // req.add("cfn", carrierFlightNumber.toSliceB32().toString());
        req.add("cfn", "/LH/117");
        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);

        emit Request(chainlinkRequestId, 0 /* _gifRequestId */, "/LH/117");
    }

    function request2(bytes32 jobId)
    external
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        req.add("carrier", "LH");
        req.add("flightNumber", "117");
        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);

        emit Request(chainlinkRequestId, 0 /* _gifRequestId */, "/LH/117");
    }

    function fulfill(bytes32 _chainlinkRequestId, uint256 observations, uint256 late15, uint256 late30, uint256 late45, uint256 cancelled, uint256 diverted)
    public
    recordChainlinkFulfillment(_chainlinkRequestId)
    {
        emit Fulfill([observations, late15, late30, late45, cancelled, diverted]);
    }
}
