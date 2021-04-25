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
import "@etherisc/gif-interface/contracts/Oracle.sol";
import "../Utilities/strings.sol";

contract CLFlightStatusesOracle is ChainlinkClient, Oracle {
    using strings for *;

    struct Answer {
        bytes1 status;
        bool arrived;
        uint256 arrivalGateDelayMinutes;
    }

    bytes32 public jobId;
    uint256 public payment;
    Answer public currentAnswer;
    uint256 public updatedHeight;
    mapping(bytes32 /* CL request ID */ => uint256 /* Etherisc request ID */) public requests;

    event Request(uint256 erRequestId, uint256 checkAtTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay);
    event Fulfill(bytes1 status, bool arrived, uint256 arrivalGateDelayMinutes);

    /**
     * @notice Deploy the contract with a specified address for the LINK, Chainlink oracle,
     * and Etherisc oracle service contract addresses.
     * @dev Sets the storage for the specified addresses
     * @param _link The address of the LINK token contract
     * @param _clOracle The Chainlink oracle contract address to send the request to
     * @param _erOracleService The Etherisc oracle service contract address to return results to
     * @param _jobId The bytes32 JobID to be executed
     * @param _payment The payment to send to the oracle
     */
    constructor(
        address _link,
        address _clOracle,
        address _erOracleService,
        bytes32 _jobId,
        uint256 _payment
    )
    public
    payable
    Oracle(_erOracleService)
    {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        _updateRequestDetails(_clOracle, _jobId, _payment);
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
        (uint256 checkAtTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay) = abi.decode(_input, (uint256, bytes32, bytes32));
        req.add("endpoint", "e-status");
        req.add("carrierFlightNumber", carrierFlightNumber.toSliceB32().toString());
        req.add("yearMonthDay", departureYearMonthDay.toSliceB32().toString());
        req.add("checkAtTime", checkAtTime.toString());
        bytes32 clRequestId = sendChainlinkRequest(req, payment);
        requests[clRequestId] = _erRequestId;

        emit Request(_erRequestId, checkAtTime, carrierFlightNumber, departureYearMonthDay);
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
        } else if (slResult.count(",".toSlice()) != 2) {
            revert("Declined (invalid result)");
        }

        bytes1 status = bytes(slResult.split(",".toSlice()).toString())[0];
        bool arrived;
        uint256 arrivalGateDelayMinutes;

        if (status == "C") {
            // Flight cancelled
            _respond(requests[_clRequestId], abi.encode(status, -1));
        } else if (status == "D") {
            // Flight diverted
            _respond(requests[_clRequestId], abi.encode(status, -1));
        } else if (status != "L" && status != "A" && status != "C" && status != "D") {
            // Unprocessable status
            _respond(requests[_clRequestId], abi.encode(status, -1));
        } else {
            strings.slice memory slArrivalGateDelayMinutes = slResult.split(",".toSlice());
            arrived = slResult.split(",".toSlice()).compare("true".toSlice()) == 0;

            if (status == "A" || (status == "L" && !arrived)) {
                // Flight still active or not at gate
                _respond(requests[_clRequestId], abi.encode(bytes1("A"), -1));
            } else if (status == "L" && arrived) {
                arrivalGateDelayMinutes = slArrivalGateDelayMinutes.len() == 0 ? 0 : slArrivalGateDelayMinutes.toString().parseInt();
                _respond(requests[_clRequestId], abi.encode(status, arrivalGateDelayMinutes));
            } else {
                // No delay info
                _respond(requests[_clRequestId], abi.encode(status, -1));
            }
        }

        delete requests[_clRequestId];

        currentAnswer = Answer(status, arrived, arrivalGateDelayMinutes);
        updatedHeight = block.number;

        emit Fulfill(status, arrived, arrivalGateDelayMinutes);
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
