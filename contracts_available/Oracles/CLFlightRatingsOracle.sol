/**
 * @title FlightRatingsOracle is a contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 *
 * Deployed on rinkeby at 0xcd2cbac4f5e4d4f5d6d0f7b1fda0910b7f0c9c56
 *
 */

pragma solidity 0.6.11;
// SPDX-License-Identifier: Apache-2.0


import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "../Utilities/strings.sol";
import "@etherisc/gif-interface/contracts/Oracle.sol";

contract CLFlightRatingsOracle is Ownable, Oracle, ChainlinkClient {
    using strings for *;

    bytes32 public jobId;
    uint256 public payment;
    uint[6] public currentAnswer;
    uint256 public updatedHeight;
    mapping(bytes32 /* CL request ID */ => uint256 /* Etherisc request ID */) public requests;

    event Request(bytes32 clRequestId, uint256 _erRequestId, bytes32 carrierFlightNumber);
    event Fulfill(uint256[6] statistics);

    /**
     * @notice Deploy the contract with a specified address for the LINK, Chainlink oracle,
     * and Etherisc oracle service contract addresses.
     * @dev Sets the storage for the specified addresses
     * @param _link The address of the LINK token contract
     * @param _chainLinkOracle The Chainlink oracle contract address to send the request to
     * @param _etheriscOracleService The Etherisc oracle service contract address to return results to
     * @param _jobId The bytes32 JobID to be executed
     * @param _payment The payment to send to the oracle
     */
    constructor(
        address _link,
        address _chainLinkOracle,
        address _etheriscOracleService,
        bytes32 _jobId,
        uint256 _payment
    )
    public
    Oracle(_etheriscOracleService)
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

    /*
     * @notice Creates a request to the stored Oracle contract address
     */
    function request(uint256 _erRequestId, bytes calldata _input)
    external override
    onlyQuery
    {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        (bytes32 carrierFlightNumber) = abi.decode(_input, (bytes32));
        req.add("endpoint", "e-ratings");
        req.add("carrierFlightNumber", carrierFlightNumber.toSliceB32().toString());
        bytes32 clRequestId = sendChainlinkRequest(req, payment);
        requests[clRequestId] = _erRequestId;

        emit Request(clRequestId, _erRequestId, carrierFlightNumber);
    }

    /**
     * @notice Calls Etherisc's _respond method with the response
     * from the oracle
     * @param _clRequestId The Chainlink ID that was generated for the request
     * @param _data The answer provided by the oracle
     */
    function fulfill(bytes32 _clRequestId, bytes32 _data)
    public
    recordChainlinkFulfillment(_clRequestId)
    {
        strings.slice memory slResult = _data.toSliceB32();

        if (slResult.len() == 0) {
            revert("Declined (empty result)");
        } else if (slResult.count(",".toSlice()) != 5) {
            revert("Declined (invalid result)");
        }

        uint256[6] memory statistics;
        for (uint i = 0; i < 5; i++) {
            statistics[i] = slResult.split(",".toSlice()).toString().parseInt();
        }
        statistics[5] = slResult.toString().parseInt();

        _respond(requests[_clRequestId], abi.encode(statistics));
        delete requests[_clRequestId];

        currentAnswer = statistics;
        updatedHeight = block.number;

        emit Fulfill(statistics);
    }

    /**
     * @notice Returns the address of the LINK token
     * @dev This is the public implementation for chainlinkTokenAddress, which is
     * an internal method of the ChainlinkClient contract
     */
    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    /**
     * @notice Returns the address of the stored oracle contract address
     */
    function getChainlinkOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    /**
     * @notice Allows the owner to withdraw any LINK balance on the contract
     */
    function withdrawLink() public onlyOwner() {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * @notice Call this method if no response is received within 5 minutes
     * @param _requestId The ID that was generated for the request to cancel
     * @param _payment The payment specified for the request to cancel
     * @param _callbackFunctionId The bytes4 callback function ID specified for
     * the request to cancel
     * @param _expiration The expiration generated for the request to cancel
     */
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
