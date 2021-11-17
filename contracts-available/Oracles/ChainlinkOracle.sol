/**
 * @title ChainlinkOracle is a contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 *
 */

pragma solidity 0.7.6;
// SPDX-License-Identifier: Apache-2.0


import "@chainlink/contracts/src/v0.7/ChainlinkClient.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "../Utilities/strings.sol";
import "@etherisc/gif-interface/contracts/0.7/Oracle.sol";

abstract contract ChainlinkOracle is Ownable, Oracle, ChainlinkClient {
    using strings for *;

    bytes32 public jobId;
    uint256 public payment;
    uint[6] public currentAnswer;
    uint256 public updatedHeight;

    mapping(bytes32 /* CL request ID */ => uint256 /* Etherisc request ID */) public requests;

    constructor(
        address _link,
        address _chainLinkOracle,
        address _oracleService,
        address _oracleOwnerService,
        bytes32 _oracleType,
        bytes32 _oracleName,
        bytes32 _jobId,
        uint256 _payment
    )
    Oracle(_oracleService, _oracleOwnerService, _oracleType, _oracleName)
    {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        _updateRequestDetails(_chainLinkOracle, _jobId, _payment);
    }

    function updateRequestDetails(
        address _oracle,
        bytes32 _jobId,
        uint256 _payment
    ) external onlyOwner() {
        _updateRequestDetails(_oracle, _jobId, _payment);
    }

    function _updateRequestDetails(
        address _oracle,
        bytes32 _jobId,
        uint256 _payment
    ) private {
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        payment = _payment;
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function getChainlinkOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    function withdrawLink() public onlyOwner() {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "ERROR:CFR-003:UNABLE_TO_TRANSFER");
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    )
    public
    onlyOwner()
    {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

}
