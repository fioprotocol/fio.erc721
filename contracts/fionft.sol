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
    uint8 constant MINCUST = 7;
    address owner;

    struct custodian {
      mapping ( address => bool) registered;
      int activation_count;
      bool active;
    }
    int custodian_count;

    struct oracle {
      mapping ( address => bool) registered;
      int activation_count;
      bool active;
    }
    int oracle_count;

    struct pending {
      mapping (address => bool) approver;
      int approvers;
      address account;
      bytes32 tokenURI;
    }

    event unwrapped(string fioaddress, uint256 tokenId);
    event wrapped(address ethaddress, string tokenURI, uint256 obtid);

    mapping ( address => oracle) oracles;
    mapping ( address => custodian) custodians;
    mapping ( uint256 => pending) approvals; // uint256 hash can be any obtid

    constructor( address[] memory newcustodians ) public ERC721("FIO Protocol NFT", "FIO") {
            require(newcustodians.length == 10, "wFIO cannot deploy without 10 custodians");
      owner = msg.sender;

      for (uint8 i = 0; i < 10; i++ ) {
        require(newcustodians[i] != owner, "Contract owner cannot be custodian");
        custodians[newcustodians[i]].activation_count = 0; // For clarity - activation_count is zero for these custodians so contract owner may unregister at will
        custodians[newcustodians[i]].active = true;
        custodians[newcustodians[i]].registered[msg.sender] = true;
      }
      custodian_count = 10;
      oracle_count = 0;

    }

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

    function wrap(address account, string memory tokenURI, uint256 obtid) public oracleOnly returns (uint256)
    {
      require(account != address(0), "Invalid account");
      require(obtid != uint256(0), "Invalid obtid");
      uint256 tokenId = 0;
      int reqoracles = ((oracle_count / 3) * 2 + 1);
      if (approvals[obtid].approvers < reqoracles) {
        require(approvals[obtid].approver[msg.sender] == false, "oracle has already approved this obtid");
        approvals[obtid].approvers++;
        approvals[obtid].approver[msg.sender] = true;
      }
      if (approvals[obtid].approvers == reqoracles) {
       require(approvals[obtid].approver[msg.sender] == true, "An approving oracle must execute wrap");

         _tokenIds.increment();
          tokenId = _tokenIds.current();
         _mint(account, tokenId);
         _setTokenURI(tokenId, tokenURI);
         emit wrapped(account, tokenURI, obtid);
        delete approvals[obtid];
      }
      if (approvals[obtid].approvers == 1) {
        approvals[obtid].account = account;
        approvals[obtid].tokenURI = keccak256(bytes(tokenURI));
      }
      if (approvals[obtid].approvers > 1) {
        require(approvals[obtid].account == account, "recipient account does not match prior approvals");
        require(approvals[obtid].tokenURI.length == bytes(tokenURI).length &&
          approvals[obtid].tokenURI == keccak256(bytes(tokenURI)), "tokenURI does not match prior approvals");
      }
        return tokenId;
    }

      function unwrap(string memory fioaddress, uint256 tokenId) public {
        require(bytes(fioaddress).length > 3 && bytes(fioaddress).length <= 64, "Invalid FIO Address");
        require(ownerOf(tokenId) == msg.sender);
        _burn(tokenId);
        emit unwrapped(fioaddress, tokenId);
      }


      function getCustodian(address ethaddress) public view returns (int, bool, int) {
        require(ethaddress != address(0), "Invalid address");
        return (custodians[ethaddress].activation_count, custodians[ethaddress].active, custodian_count);
      }

      function getOracle(address ethaddress) public view returns (int, bool, int) {
        require(ethaddress != address(0), "Invalid address");
        return (oracles[ethaddress].activation_count, oracles[ethaddress].active, oracle_count);
      }

      function getApprovals(uint256 obtid) public view returns (int, address, bytes32) {
        require(obtid != uint256(0), "Invalid obtid");
        return (approvals[obtid].approvers, approvals[obtid].account, approvals[obtid].tokenURI);
      }

      function regoracle(address ethaddress) public custodianOnly {
        require(ethaddress != address(0), "Invalid address");
        require(ethaddress != msg.sender, "Cannot register self");
        require(oracles[ethaddress].active == false, "Oracle is already registered");
        require(oracles[ethaddress].registered[msg.sender] == false, "msg.sender has already registered this oracle");
        if (oracles[ethaddress].activation_count < MINCUST) {
          oracles[ethaddress].activation_count++;
          oracles[ethaddress].registered[msg.sender] = true;
        }
        if (oracles[ethaddress].activation_count == MINCUST){
          oracles[ethaddress].active=true;
          oracle_count++;
        }
      }

      function unregoracle(address ethaddress) public custodianOnly {
        require(ethaddress != address(0), "Invalid address");
        require(oracle_count > 0, "No oracles remaining");
        require(oracles[ethaddress].active == true, "Oracle is not registered");
        if (oracles[ethaddress].activation_count > 0) {
          oracles[ethaddress].activation_count--;
          delete oracles[ethaddress].registered[msg.sender];
        }
        if (oracles[ethaddress].activation_count == 0) {
            delete oracles[ethaddress];
            oracle_count--;
        }

      } // unregoracle


      function regcust(address ethaddress) public custodianOnly {
        require(ethaddress != address(0), "Invalid address");
        require(ethaddress != msg.sender, "Cannot register self");
        require(custodians[ethaddress].active == false, "Custodian is already registered");
        require(custodians[ethaddress].registered[msg.sender] == false,  "msg.sender has already registered this custodian");
        if (custodians[ethaddress].activation_count < MINCUST) {
          custodians[ethaddress].activation_count++;
          custodians[ethaddress].registered[msg.sender] = true;
        }
        if (custodians[ethaddress].activation_count == MINCUST) {
          custodians[ethaddress].active = true;
          custodian_count++;
        }
      }

      function unregcust(address ethaddress) public custodianOnly {
        require(ethaddress != address(0), "Invalid address");
        require(custodians[ethaddress].active == true, "Custodian is not registered");
        require(custodian_count > MINCUST, "Must contain 7 custodians");
        if (custodians[ethaddress].activation_count > 0) {
          custodians[ethaddress].activation_count--;
          delete custodians[ethaddress].registered[msg.sender];
        }
        if (custodians[ethaddress].activation_count == 0) {
            delete custodians[ethaddress];
            custodian_count--;
        }
      } //unregcustodian

      // ------------------------------------------------------------------------
      // Don't accept ETH
      // ------------------------------------------------------------------------
      receive () external payable {
          revert();
      }
}
