pragma solidity 0.6.11;
// SPDX-License-Identifier: Apache-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract etheriscAddressResolver is Ownable {

    address public addr;

    function getAddress() public view returns (address _addr) {
        return addr;
    }

    function setAddress(address _addr) public onlyOwner {
        addr = _addr;
    }
}
