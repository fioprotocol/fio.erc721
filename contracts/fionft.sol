// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FIONFT is ERC721, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("FIO NFT", "FIO Protocol") {}

    function sendnft(address owner, string memory tokenURI)
        public
        returns (uint256)
    {

        _tokenIds.increment();

        uint256 newFioId = _tokenIds.current();
        _mint(owner, newFioId);
        _setTokenURI(newFioId, tokenURI);

        return newFioId;
    }
}
