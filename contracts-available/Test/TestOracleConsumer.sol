// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.11;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract ATestnetConsumer is ChainlinkClient, Ownable {
    uint256 constant private ORACLE_PAYMENT = 0 * LINK;

    address oracle = 0xa68bC2d344f69F34f5A7cbb5233f9bF1a270B2f6;

    bytes32 public ratings;


    event RequestRatingsOracleFulfilled(
        bytes32 indexed requestId,
        bytes32 ratings
    );

    constructor() public Ownable() {
        setChainlinkToken(0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2);

    }

    function requestRatingsOracle(string memory _jobId)
    public
    onlyOwner
    {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfillRatingsOracle.selector);
        req.add("extPath", "LH/117");
        sendChainlinkRequestTo(oracle, req, ORACLE_PAYMENT);
    }


    function fulfillRatingsOracle(bytes32 _requestId, bytes32 _ratings)
    public
    recordChainlinkFulfillment(_requestId)
    {
        ratings = _ratings;
        emit RequestRatingsOracleFulfilled(_requestId, _ratings);
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    )
    public
    onlyOwner
    {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly { // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

}
