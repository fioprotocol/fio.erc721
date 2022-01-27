// SPDX-License-Identifier: MIT
// FIO Protocol ERC721 and Oracle Contract
// Adam Androulidakis 3/2021
// Prototype: Do not use in production

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FIONFT is ERC721Upgradeable, AccessControlUpgradeable, PausableUpgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    struct pending {
      mapping (address => bool) approved;
      uint32 approvals;
      bool complete;
    }

    uint32 custodian_count;
    uint32 oracle_count;

    int private uoracmapv;
    int private roracmapv;
    int private rcustmapv;
    int private ucustmapv;

    string _baseURIextended;

    event unwrapped(string fioaddress, string domain);
    event wrapped(address account, string domain, string obtid);
    event domainburned(address account, uint256 tokenId, string obtid);
    event custodian_unregistered(address account, bytes32 eid);
    event custodian_registered(address account, bytes32 eid);
    event oracle_unregistered(address account, bytes32 eid);
    event oracle_registered(address account, bytes32 eid);

    address[] oraclelist;
    mapping ( uint256 => string ) attribute;
    mapping ( bytes32 => pending ) approvals; // uint256 hash can be any obtid

    function initialize( address[] memory newcustodians) initializer public {
      __ERC721_init("FIO Protocol NFT","FIO");
      __AccessControl_init();
      __Pausable_init();
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(PAUSER_ROLE, msg.sender);
      _grantRole(MINTER_ROLE, msg.sender);
      _grantRole(OWNER_ROLE, msg.sender);

      require(newcustodians.length == 10, "Cannot deploy");

      for (uint8 i = 0; i < 10; i++ ) {
        require(!hasRole(CUSTODIAN_ROLE, newcustodians[i]), "Custodian already registered");
        require(!hasRole(OWNER_ROLE, newcustodians[i]), "Owner role cannot be custodian");
        _grantRole(CUSTODIAN_ROLE, newcustodians[i]);
      }
      _baseURIextended = "https://metadata.fioprotocol.io/domainnft/";
      custodian_count = 10;
      oracle_count = 0;
    }

    function pause() external onlyRole(CUSTODIAN_ROLE) onlyRole(PAUSER_ROLE) whenNotPaused{
        _pause();
    }

    function unpause() external onlyRole(CUSTODIAN_ROLE) onlyRole(PAUSER_ROLE) whenPaused{
        _unpause();
    }

    function setBaseURI(string memory baseURI_) external onlyRole(CUSTODIAN_ROLE)  {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory){
      require(_exists(_tokenId), "No token");
      return string(abi.encodePacked(_baseURI(), attribute[_tokenId], ".json"));
    }

    function getConsensus(bytes32 hash, uint8 t) internal returns (bool){
      require(!approvals[hash].approved[msg.sender], "Approval already complete");
      uint32 APPROVALS_NEEDED;
      if (t == 0) {
        APPROVALS_NEEDED = custodian_count * 2 / 3 + 1;
      } else {
        APPROVALS_NEEDED = oracle_count;
      }

      if (approvals[hash].approvals < APPROVALS_NEEDED) {
        require(!approvals[hash].approved[msg.sender], "oracle has already approved this hash");
        approvals[hash].approved[msg.sender] = true;
        approvals[hash].approvals++;
        if (approvals[hash].approvals == APPROVALS_NEEDED) {
          require(approvals[hash].approved[msg.sender], "An approving oracle must execute");
          approvals[hash].complete = true;
        }
      }
      return approvals[hash].complete;
    }

    function wrapnft(address account, string memory domain, string memory obtid) external onlyRole(ORACLE_ROLE) whenNotPaused returns (uint256){
      require(account != address(0), "Invalid account");
      require(bytes(domain).length > 1 && bytes(domain).length < 64, "Invalid domain");
      require(bytes(obtid).length > 0, "Invalid obtid");
      require(oracle_count >= 3, "Oracles must be 3 or greater");
      uint256 tokenId = 0;
      bytes32 obthash = keccak256(bytes(abi.encodePacked(account, domain, obtid)));
      if (getConsensus(obthash, 1)) {
         _tokenIds.increment();
          tokenId = _tokenIds.current();
         _mint(account, tokenId);
         attribute[_tokenIds.current()] = domain;
         emit wrapped(account, domain, obtid);
      }

        return tokenId;
    }

    function unwrapnft(string memory fioaddress, uint256 tokenId) external whenNotPaused {
      require(bytes(fioaddress).length > 3 && bytes(fioaddress).length <= 64, "Invalid FIO Address");
      require(ownerOf(tokenId) == msg.sender);
      _burn(tokenId);
      emit unwrapped(fioaddress, attribute[tokenId]);
      attribute[tokenId] = "";
    }

    function burnnft(uint256 tokenId, string memory obtid) external onlyRole(ORACLE_ROLE) whenNotPaused returns (uint256){

      require(_exists(tokenId), "Invalid tokenId");
      require(bytes(obtid).length > 0, "Invalid obtid");
      require(oracle_count >= 3, "Oracles must be 3 or greater");
      bytes32 obthash = keccak256(bytes(abi.encodePacked(tokenId, obtid)));
      if (getConsensus(obthash, 1)) {
         _burn(tokenId);
         attribute[tokenId] = "";
         emit domainburned(msg.sender, tokenId, obtid);
      }

        return tokenId;

    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function getCustodian(address account) external view returns (bool, uint32) {
      require(account != address(0), "Invalid address");
      return (hasRole(CUSTODIAN_ROLE, account), custodian_count);
    }

    function getOracle(address account) external view returns (bool, uint32) {
      require(account != address(0), "Invalid address");
      return (hasRole(ORACLE_ROLE, account), uint32(oraclelist.length));
    }

    function getApproval(string memory obtid) external view returns (uint32, bool) {
      require(bytes(obtid).length > 0, "Invalid obtid");
      bytes32 obthash = keccak256(bytes(abi.encode(obtid)));
      return (approvals[obthash].approvals, approvals[obthash].complete);
    }

    function getOracles() external view returns(address[] memory) {
      return oraclelist;
    }

    function regoracle(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid address");
      require(account != msg.sender, "Cannot register self");
      require(!hasRole(ORACLE_ROLE, account), "Oracle already registered");
      bytes32 id = keccak256(bytes(abi.encode("ro",account, roracmapv )));
      if (getConsensus(id, 0)){
        _grantRole(ORACLE_ROLE, account);
        oracle_count++;
        oraclelist.push(account);
        roracmapv++;
        emit oracle_registered(account, id);
      }
    }

    function unregoracle(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid address");
      require(oracle_count > 0, "No oracles remaining");
      bytes32 id = keccak256(bytes(abi.encode("uo",account, uoracmapv)));
      require(hasRole(ORACLE_ROLE, account), "Oracle not registered");
      if ( getConsensus(id, 0)) {
          _revokeRole(ORACLE_ROLE, account);
          oracle_count--;
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

    function regcust(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid address");
      require(account != msg.sender, "Cannot register self");
      bytes32 id = keccak256(bytes(abi.encode("rc",account, rcustmapv)));
      require(!hasRole(CUSTODIAN_ROLE, account), "Already registered");
      if (getConsensus(id, 0)) {
        _grantRole(CUSTODIAN_ROLE, account);
        custodian_count++;
        rcustmapv++;
        emit custodian_registered(account, id);
      }
    }

    function unregcust(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid address");
      require(hasRole(CUSTODIAN_ROLE, account), "Custodian not registered");
      require(custodian_count > 7, "Must contain 7 custodians");
      bytes32 id = keccak256(bytes(abi.encode("uc",account, ucustmapv)));
      require(hasRole(CUSTODIAN_ROLE, account), "Already unregistered");
      if (getConsensus(id, 0)) {
          _revokeRole(CUSTODIAN_ROLE, account);
          custodian_count--;
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
