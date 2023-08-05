// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "IStardust.sol";

contract StardustPilot is ERC721Enumerable, Ownable {
 
    constructor() ERC721("Pilot", "PILOT") {}

    address STARDUST;

    // 1: Optimism    2: AVAX    3: Polygon
    uint256 internal tokenId = 1000000000000000000000000000000000;

    function getId() external view returns (uint256) {
        return tokenId;
    }

    function setControl(address _owner) public onlyOwner {
        STARDUST = _owner;
    }


    function mint(address to) external onlyOwner {
        _safeMint(to, tokenId);
        unchecked {
            tokenId++;
        }
    }

    function instantiate(address to, uint id) external onlyOwner {
        _safeMint(to, id);
        unchecked {
            tokenId++;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to
    ) internal virtual {
        super._beforeTokenTransfer(from, to, tokenId, 1);
        require(IStardust(STARDUST).checkAvailable(tokenId) == true);
        IStardust(STARDUST).updateEmployer(tokenId, to);
    }


}
