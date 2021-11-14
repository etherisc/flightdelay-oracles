pragma solidity ^0.8.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

// Deployed to Sokol at 0x0a26A5EE6eB55C637dDE1A885B329EB2303Ab831

contract ChainlinkTestToken is ERC20, Ownable {
    constructor() ERC20("Chainlink Test Token", "LINKTST") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
