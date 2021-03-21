// SPDX-License-Identifier: MIT
// FIO Protocol ERC721 and Oracle Contract
// Adam Androulidakis 3/2021
// Prototype: Do not use in production

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FIONFT is ERC721, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint8 constant MAXENT = 7;
    address owner;

    struct custodian {
      mapping ( address => bool) registered;
      int activation_count;
      bool active;
    }

    struct oracle {
      mapping ( address => bool) registered;
      int activation_count;
      bool active;
    }

    struct pending {
      mapping (address => bool) approver;
      int approvers;
      address recipient;
      uint256 amount;
      bool wrap;
    }

    mapping ( address => oracle) oracles;
    mapping ( address => custodian) custodians;
    mapping ( uint256 => pending) approvals; // uint256 hash can be any obtid

    constructor() public ERC721("FIO Protocol NFT", "FIO") {
      owner = msg.sender;
    }

    modifier ownerAndCustodian {
      require(
        ((msg.sender == owner) ||
         (custodians[msg.sender].active == true)),
          "Only contract owner or custodians may call this function."
      );
      _;
    }
    /*
    modifier allPrincipals {
      require(
        ((msg.sender == owner) ||
         (custodians[msg.sender].active == true) ||
         (oracles[msg.sender].active == true )),
          "Only contract owner, custodians or oracles may call this function."
      );
      _;
    }
    */
    modifier oracleOnly {
      require(oracles[msg.sender].active == true,
         "Only a wFIO oracle may call this function."
      );
      _;
    }

    modifier custodianOnly {
      require(custodians[msg.sender].active == true,
         "Only a wFIO custodian may call this function."
      );
      _;
    }


    modifier ownerOnly {
      require( msg.sender == owner,
          "Only contract owner can call this function."
      );
      _;
    }

    function wrap(address ethaddress, string memory tokenURI, uint256 obtid) public ownerOnly returns (uint256)
    {

      require(ethaddress != address(0), "Invalid account");
      require(obtid != uint256(0), "Invalid obtid");

        uint256 tokenId = 0;
        {
          _tokenIds.increment();
           tokenId = _tokenIds.current();
          _mint(ethaddress, tokenId);
          _setTokenURI(tokenId, tokenURI);

        }
        return tokenId;
    }

    function unwrap(address ethaddress, uint256 tokenId) public ownerOnly {
        require(ownerOf(tokenId) == ethaddress);
        _burn(tokenId);
      }


      function getCustodian(address ethaddress) public view returns (int, bool) {
        require(ethaddress != address(0), "Invalid address");
        return (custodians[ethaddress].activation_count, custodians[ethaddress].active);
      }

      function getOracle(address ethaddress) public view returns (int, bool) {
        require(ethaddress != address(0), "Invalid address");
        return (oracles[ethaddress].activation_count, oracles[ethaddress].active);
      }

      function getApprovals(uint256 obtid) public view returns (int, address, uint256) {
        require(obtid != uint256(0), "Invalid obtid");
        return (approvals[obtid].approvers, approvals[obtid].recipient, approvals[obtid].amount);
      }

      function regoracle(address ethaddress) public custodianOnly {
        require(ethaddress != address(0), "Invalid address");
        require(ethaddress != msg.sender, "Cannot register self");
        require(oracles[ethaddress].active == false, "Oracle is already registered");
        require(oracles[ethaddress].registered[msg.sender] == false, "msg.sender has already registered this oracle");
        if (oracles[ethaddress].activation_count < MAXENT) {
          oracles[ethaddress].activation_count++;
          oracles[ethaddress].registered[msg.sender] = true;
        }
        if (oracles[ethaddress].activation_count == MAXENT){
          oracles[ethaddress].active=true;
        }
      }

      function unregoracle(address ethaddress) public ownerAndCustodian {
        require(ethaddress != address(0), "Invalid address");
        require(ethaddress != msg.sender, "Cannot unregister self");
        require(oracles[ethaddress].active == true, "Oracle is not registered");
        require(oracles[ethaddress].registered[msg.sender] == true, "msg.sender has not registered this oracle");
        if (oracles[ethaddress].activation_count > 0) {
          oracles[ethaddress].activation_count--;
          delete oracles[ethaddress].registered[msg.sender];
        }
        if (oracles[ethaddress].activation_count == 0) {
            delete oracles[ethaddress];
        }

      } // unregoracle


      function regcust(address ethaddress) public custodianOnly {
        require(ethaddress != address(0), "Invalid address");
        require(ethaddress != msg.sender, "Cannot register self");
        require(custodians[ethaddress].active == false, "Custodian is already registered");
        require(custodians[ethaddress].registered[msg.sender] == false,  "msg.sender has already registered this custodian");
        if (custodians[ethaddress].activation_count < MAXENT) {
          custodians[ethaddress].activation_count++;
          custodians[ethaddress].registered[msg.sender] = true;
        }
        if (custodians[ethaddress].activation_count == MAXENT) {
          custodians[ethaddress].active = true;
        }
      }

      function unregcust(address ethaddress) public ownerAndCustodian() {
        require(ethaddress != address(0), "Invalid address");
        require(ethaddress != msg.sender, "Cannot unregister self");
        require(custodians[ethaddress].active == true, "Custodian is not registered");
        require(custodians[ethaddress].registered[msg.sender] == true, "msg.sender has not registered this custodian");
        if (custodians[ethaddress].activation_count > 0) {
          custodians[ethaddress].activation_count--;
          delete custodians[ethaddress].registered[msg.sender];
        }
        if (custodians[ethaddress].activation_count == 0) {
            delete custodians[ethaddress];
        }
      } //unregcustodian

      // ------------------------------------------------------------------------
      // Don't accept ETH
      // ------------------------------------------------------------------------
      receive () external payable {
          revert();
      }
}
