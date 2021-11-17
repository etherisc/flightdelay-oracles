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

contract MockFlightRatingsOracle is Ownable, Oracle {

    event Request(uint256 _requestId, bytes32 carrierFlightNumber);
    event Fulfill(uint256[6] statistics);

    bytes32 public constant NAME = "MockFlightRatings";
    bytes32 public constant ORACLETYPE = "FlightRatings";

    constructor(address _oracleService, address _oracleOwnerService)
    public
    Oracle(_oracleService, _oracleOwnerService, ORACLETYPE, NAME)
    {}

    function request(uint256 _requestId, bytes calldata _input)
    external override
    onlyQuery
    {
        (bytes32 carrierFlightNumber) = abi.decode(_input, (bytes32));
        uint256[6] memory statistics;

        if (carrierFlightNumber == "XX001") {
            statistics = [uint256(0),0,0,0,0,0];
        } else if (carrierFlightNumber == "XX002") {
            statistics = [uint256(10),0,0,0,0,0];
        } else if (carrierFlightNumber == "XX003") {
            statistics = [uint256(10),0,0,0,0,0];
        } else if (carrierFlightNumber == "XX004") {
            statistics = [uint256(10),0,0,0,0,0];
        } else if (carrierFlightNumber == "XX005") {
            statistics = [uint256(10),0,0,0,0,0];
        }
        _respond(_requestId, abi.encode(statistics));

        emit Request(_requestId, carrierFlightNumber);
        emit Fulfill(statistics);
    }

}
