// SPDX-License-Identifier: MIT
// FIO Protocol ERC721 and Oracle Contract
// Adam Androulidakis 3/2021
// Prototype: Do not use in production

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FIONFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address owner;

    struct custodian {
      bool active;
    }

    struct oracle {
      bool active;
    }

    struct pending {
      mapping (address => bool) approved;
      int approvals;
      address account;
      bytes32 obtid;
    }

    int custodian_count;
    int oracle_count;

    int uoracmapv;
    int roracmapv;
    int rcustmapv;
    int ucustmapv;

    string _baseURIextended;

    event unwrapped(string fioaddress, string domain);
    event wrapped(address account, string domain, string obtid);
    event custodian_unregistered(address account, bytes32 eid);
    event custodian_registered(address account, bytes32 eid);
    event oracle_unregistered(address account, bytes32 eid);
    event oracle_registered(address account, bytes32 eid);

    mapping ( address => oracle) oracles;
    address[] oraclelist;
    mapping ( address => custodian ) custodians;
    mapping ( uint256 => string ) attribute;
    mapping ( bytes32 => pending ) approvals; // uint256 hash can be any obtid

    constructor( address[] memory newcustodians) ERC721("FIO Protocol NFT", "FIO") {
            require(newcustodians.length == 10, "Cannot deploy");
      owner = msg.sender;

      for (uint8 i = 0; i < 10; i++ ) {
        require(newcustodians[i] != owner, "Contract owner cannot be custodian");
        custodians[newcustodians[i]].active = true;
        _baseURIextended = "https://localhost:5443/";
      }
      custodian_count = 10;
      oracle_count = 0;
    }

    modifier oracleOnly {
      require(oracles[msg.sender].active,
         "Only wFIO oracle can call action."
      );
      _;
    }

    modifier custodianOnly {
      require(custodians[msg.sender].active,
         "Only wFIO custodian can call action."
      );
      _;
    }

    modifier ownerOnly {
      require( msg.sender == owner,
          "Only contract owner can call action."
      );
      _;
    }

    function setBaseURI(string memory baseURI_) external custodianOnly()  {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory){
      require(_exists(_tokenId), "No token");
      return string(abi.encodePacked(_baseURI(), "nfts/", attribute[_tokenId], ".json"));
    }

    function wrapnft(address account, string memory domain, string memory obtid) external oracleOnly returns (uint256){
      require(account != address(0), "Invalid account");
      require(bytes(domain).length > 1 && bytes(domain).length < 64, "Invalid domain");
      require(bytes(obtid).length > 0, "Invalid obtid");
      require(oracle_count >= 3, "Oracles must be 3 or greater");
      uint256 tokenId = 0;
      bytes32 obthash = keccak256(bytes(abi.encodePacked(obtid)));
      if (approvals[obthash].approvals < oracle_count) {
        require(!approvals[obthash].approved[msg.sender], "Already approved");
        approvals[obthash].approvals++;
        approvals[obthash].approved[msg.sender] = true;
      }
      if (approvals[obthash].approvals == 1) {
        approvals[obthash].account = account;
        approvals[obthash].obtid = keccak256(bytes(obtid));
      }
      if (approvals[obthash].approvals > 1) {
        require(approvals[obthash].account == account, "Account mismatch");
        require(approvals[obthash].obtid == keccak256(bytes(obtid)), "Obtid mismatch");
      }
      if (approvals[obthash].approvals == oracle_count) {
       require(approvals[obthash].approved[msg.sender], "Oracle must execute");

         _tokenIds.increment();
          tokenId = _tokenIds.current();
         _mint(account, tokenId);
         attribute[_tokenIds.current()] = domain;
         emit wrapped(account, domain, obtid);
        delete approvals[obthash];
      }

        return tokenId;
    }

    function unwrapnft(string memory fioaddress, uint256 tokenId) public {
      require(bytes(fioaddress).length > 3 && bytes(fioaddress).length <= 64, "Invalid FIO Address");
      require(ownerOf(tokenId) == msg.sender);
      _burn(tokenId);
      emit unwrapped(fioaddress, attribute[tokenId]);
      attribute[tokenId] = "";
    }

    function getCustodian(address account) external view returns (bool, int) {
      require(account != address(0), "Invalid address");
      return (custodians[account].active, custodian_count);
    }

    function getOracle(address account) external view returns (bool, int) {
      require(account != address(0), "Invalid address");
      return (oracles[account].active, oracle_count);
    }

    function getApproval(string memory obtid) external view returns (int, address, bytes32) {
      require(bytes(obtid).length > 0, "Invalid obtid");
      bytes32 obthash = keccak256(bytes(abi.encode(obtid)));
      return (approvals[obthash].approvals, approvals[obthash].account, approvals[obthash].obtid);
    }

    function getOracles() external view returns(address[] memory) {
      return oraclelist;
    }

    function regoracle(address account) external custodianOnly {
      require(account != address(0), "Invalid address");
      require(account != msg.sender, "Cannot register self");
      require(oracles[account].active, "Oracle already registered");
      bytes32 id = keccak256(bytes(abi.encode("ro",account, roracmapv )));
      require(!approvals[id].approved[msg.sender],  "Already approved");
      int reqcust = custodian_count * 2 / 3 + 1;
      if (approvals[id].approvals < reqcust) {
        approvals[id].approvals++;
        approvals[id].approved[msg.sender] = true;
      }
      if (approvals[id].approvals == reqcust){
        oracles[account].active=true;
        oracle_count++;
        oraclelist.push(account);
        delete approvals[id];
        roracmapv++;
        emit oracle_registered(account, id);
      }
    }

    function unregoracle(address account) external custodianOnly {
      require(account != address(0), "Invalid address");
      require(oracle_count > 0, "No oracles remaining");
      bytes32 id = keccak256(bytes(abi.encode("uo",account, uoracmapv)));
      require(oracles[account].active, "Oracle not registered");
      int reqcust = custodian_count * 2 / 3 + 1;
      if (approvals[id].approvals < reqcust) {
        approvals[id].approvals++;
        approvals[id].approved[msg.sender] = true;
      }
      if ( approvals[id].approvals == reqcust) {
          oracles[account].active = false;
          delete oracles[account];
          oracle_count--;
          delete approvals[id];
          uoracmapv++;
          for(uint16 i = 0; i <= oraclelist.length - 1; i++) {
            if(oraclelist[i] == account) {
              oraclelist[i] = oraclelist[oraclelist.length - 1];
              oraclelist.pop();
              break;
            }
          }
          emit oracle_unregistered(account, id);
      }

    } // unregoracle

    function regcust(address account) external custodianOnly {
      require(account != address(0), "Invalid address");
      require(account != msg.sender, "Cannot register self");
      bytes32 id = keccak256(bytes(abi.encode("rc",account, rcustmapv)));
      require(custodians[account].active, "Already registered");
      require(!approvals[id].approved[msg.sender],  "Already approved");
      int reqcust = custodian_count * 2 / 3 + 1;
      if (approvals[id].approvals < reqcust) {
        approvals[id].approvals++;
        approvals[id].approved[msg.sender] = true;
      }
      if (approvals[id].approvals == reqcust) {
        custodians[account].active = true;
        custodian_count++;
        delete approvals[id];
        rcustmapv++;
        emit custodian_registered(account, id);
      }
    }

    function unregcust(address account) external custodianOnly {
      require(account != address(0), "Invalid address");
      require(custodians[account].active, "Custodian not registered");
      require(custodian_count > 7, "Must contain 7 custodians");
      bytes32 id = keccak256(bytes(abi.encode("uc",account, ucustmapv)));
      require(!approvals[id].approved[msg.sender], "Already unregistered");
      int reqcust = custodian_count * 2 / 3 + 1;
      if (approvals[id].approvals < reqcust) {
        approvals[id].approvals++;
        approvals[id].approved[msg.sender] = true;
      }
      if ( approvals[id].approvals == reqcust) {
          custodians[account].active = false;
          delete custodians[account];
          custodian_count--;
          delete approvals[id];
          ucustmapv++;
          emit custodian_unregistered(account, id);
      }
    } //unregcustodian

      // ------------------------------------------------------------------------
      // Don't accept ETH
      // ------------------------------------------------------------------------
    receive () external payable {
      revert();
    }

}
