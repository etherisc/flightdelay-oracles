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


import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "../Utilities/strings.sol";
import "@etherisc/gif-interface/contracts/0.6/Oracle.sol";

contract MockFlightStatusesOracle is Ownable, Oracle {

    event Request(uint256 requestId, uint256 checkAtTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay);
    event Fulfill(bytes1 status, uint256 delay);

    bytes32 public constant NAME = "MockFlightStatuses";
    bytes32 public constant ORACLETYPE = "FlightStatuses";

    constructor(address _oracleService, address _oracleOwnerService)
    public
    Oracle(_oracleService, _oracleOwnerService, ORACLETYPE, NAME)
    {}

    function request(uint256 _requestId, bytes calldata _input)
    external override
    onlyQuery
    {
        (uint256 checkAtTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay) = abi.decode(_input, (uint256, bytes32, bytes32));

        bytes1 status;
        uint256 delay;

        if (carrierFlightNumber == "XX-001") { status = "A"; delay = 0; }
        else if (carrierFlightNumber == "XX-001") { status = "A"; delay = 0; }
        else if (carrierFlightNumber == "XX-001") { status = "A"; delay = 0; }
        else if (carrierFlightNumber == "XX-001") { status = "A"; delay = 0; }
        else if (carrierFlightNumber == "XX-001") { status = "A"; delay = 0; }
        else if (carrierFlightNumber == "XX-001") { status = "A"; delay = 0; }
        _respond(_requestId, abi.encode(status, delay));

        emit Request(_requestId, checkAtTime, carrierFlightNumber, departureYearMonthDay);
        emit Fulfill(status, delay);
    }

}

