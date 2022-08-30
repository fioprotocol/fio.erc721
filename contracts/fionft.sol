// SPDX-License-Identifier: MIT
// FIO Protocol ERC721 and Oracle Contract
// Adam Androulidakis 3/2021
// Prototype: Do not use in production

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FIONFT is ERC721, Pausable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    struct pending {
      mapping (address => bool) approved;
      bool complete;
      uint32 approvals;
    }

    uint32 custodian_count;
    uint32 oracle_count;

    enum ApprovalType {
        WrapNFT,
        BurnNFT,
        AddOracle,
        RemoveOracle,
        AddCustodian,
        RemoveCustodian
    }

    string _baseURIextended;

    event unwrapped(string fioaddress, string domain);
    event wrapped(address account, string domain, string obtid);
    event domainburned(address account, uint256 tokenId, string obtid);
    event custodian_unregistered(address account, bytes32 eid);
    event custodian_registered(address account, bytes32 eid);
    event oracle_unregistered(address account, bytes32 eid);
    event oracle_registered(address account, bytes32 eid);
    event consensus_activity(string signer, bytes32 hash);

    address[] public oraclelist;
    address[] private custodianlist;

    mapping ( uint256 => string ) attribute;
    mapping ( bytes32 => pending ) approvals; // uint256 hash can be any obtid
    mapping(uint256 => address) private _owners;

    constructor( address[] memory newcustodians)  ERC721("FIO Protocol NFT", "FIO") {

      _grantRole(PAUSER_ROLE, msg.sender);
      _grantRole(OWNER_ROLE, msg.sender);

      require(newcustodians.length == 10, "Cannot deploy");

      for (uint8 i = 0; i < 10; i++ ) {
        require(!hasRole(CUSTODIAN_ROLE, newcustodians[i]), "Custodian already registered");
        require(!hasRole(OWNER_ROLE, newcustodians[i]), "Owner role cannot be custodian");
        _grantRole(CUSTODIAN_ROLE, newcustodians[i]);
        custodianlist.push(newcustodians[i]);
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

    //Precondition: Roles must be checked in parent functions. This should only be called by authorized oracle or custodian
    function getConsensus(bytes32 hash, uint8 approvalType) internal returns (bool){
      require(!approvals[hash].complete, "Approval already complete");

      uint32 APPROVALS_NEEDED = oracle_count;
      if (approvalType == 1) {
        APPROVALS_NEEDED = custodian_count * 2 / 3 + 1;
      }
      if (approvals[hash].approvals < APPROVALS_NEEDED) {
        require(!approvals[hash].approved[msg.sender], "sender has already approved this hash");
        approvals[hash].approved[msg.sender] = true;
        approvals[hash].approvals++;
         //moving this if block after the parent if block will allow the execution to take place immediately instead of requiring a subsequent call 
        if (approvals[hash].approvals >= APPROVALS_NEEDED) {
          require(approvals[hash].approved[msg.sender], "An approver must execute");
          approvals[hash].complete = true;
          return approvals[hash].complete;
        }
      }
      return approvals[hash].complete;
    }

    function wrapnft(address account, string memory domain, string memory obtid) external onlyRole(ORACLE_ROLE) whenNotPaused returns (uint256){
      require(account != address(0), "Invalid account");
      require(account != address(this), "Cannot wrap to contract account");
      require(bytes(domain).length >= 1 && bytes(domain).length < 63, "Invalid domain");
      require(bytes(obtid).length > 0, "Invalid obtid");
      require(oracle_count >= 3, "Oracles must be 3 or greater");
      uint256 tokenId = 0;
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.WrapNFT, account, domain, obtid)));
      if (getConsensus(indexhash, 0)) {
         _tokenIds.increment();
          tokenId = _tokenIds.current();
         _mint(account, tokenId);
         attribute[_tokenIds.current()] = domain;
         emit wrapped(account, domain, obtid);
        _owners[tokenId] = account;
      }
        emit consensus_activity("oracle", indexhash);
        return tokenId;
    }

    function unwrapnft(string memory fioaddress, uint256 tokenId) external whenNotPaused {
      require(bytes(fioaddress).length >=3 && bytes(fioaddress).length <= 64, "Invalid FIO Handle");
      require(ownerOf(tokenId) == msg.sender, "Invalid token owner");
      _burn(tokenId);
      emit unwrapped(fioaddress, attribute[tokenId]);
      attribute[tokenId] = "";
      _owners[tokenId] = address(0);
    }

    function burnnft(uint256 tokenId, string memory obtid) external onlyRole(ORACLE_ROLE) whenNotPaused returns (uint256){

      require(_exists(tokenId), "Invalid tokenId");
      require(bytes(obtid).length > 0, "Invalid obtid");
      require(oracle_count >= 3, "Oracles must be 3 or greater");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.BurnNFT, tokenId, obtid)));
      if (getConsensus(indexhash, 0)) {
         _burn(tokenId);
         attribute[tokenId] = "";
         emit domainburned(msg.sender, tokenId, obtid);
        _owners[tokenId] = address(0);
      }

        emit consensus_activity("oracle", indexhash);
        return tokenId;

    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721) {
        require(to != address(this), "Cannot transfer to contract");
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function getCustodian(address account) external view returns (bool, uint32) {
      require(account != address(0), "Invalid account");
      return (hasRole(CUSTODIAN_ROLE, account), custodian_count);
    }

    function getOracle(address account) external view returns (bool, uint32) {
      require(account != address(0), "Invalid account");
      return (hasRole(ORACLE_ROLE, account), uint32(oraclelist.length));
    }

    function getApproval(bytes memory obtid) external view returns (uint32, bool) {
      require(obtid.length > 0, "Invalid obtid");
      return (approvals[bytes32(obtid)].approvals, approvals[bytes32(obtid)].complete);
    }

    function listDomainsOfOwner(address _owner) public view returns(string[] memory ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        return new string[](0);
    } else {
        string[] memory result = new string[](tokenCount);
        uint256 resultIndex = 0;
        uint256 tokenId;
        for (tokenId = 1; tokenId <= _tokenIds._value; tokenId++) {
            if (_owners[tokenId] == _owner) {
                result[resultIndex] = attribute[tokenId];
                resultIndex++;
            }
        }
            return result;
        }
    }

    function getOracles() external view returns(address[] memory) {
      return oraclelist;
    }

    function regoracle(address account) external onlyRole(CUSTODIAN_ROLE)  {
      require(account != address(0), "Invalid account");
      require(account != msg.sender, "Cannot register self");
      require(!hasRole(ORACLE_ROLE, account), "Already registered");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.AddOracle,account )));
      if (getConsensus(indexhash, 1)){
        _grantRole(ORACLE_ROLE, account);
        oracle_count++;
        oraclelist.push(account);
        emit oracle_registered(account, indexhash);
      }
      emit consensus_activity("custodian", indexhash);
    }

    function unregoracle(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid account");
      require(oracle_count > 0, "No oracles remaining");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.RemoveOracle,account)));
      require(hasRole(ORACLE_ROLE, account), "Oracle not registered");
      if ( getConsensus(indexhash, 1)) {
          _revokeRole(ORACLE_ROLE, account);
          oracle_count--;
          for(uint16 i = 0; i < oraclelist.length; i++) {
            if(oraclelist[i] == account) {
              oraclelist[i] = oraclelist[oraclelist.length - 1];
              oraclelist.pop();
              break;
            }
          }
          emit oracle_unregistered(account, indexhash);
      }
       emit consensus_activity("custodian", indexhash);

    } // unregoracle

    function regcust(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid account");
      require(account != msg.sender, "Cannot register self");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.AddCustodian,account)));
      require(!hasRole(CUSTODIAN_ROLE, account), "Already registered");
      if (getConsensus(indexhash, 1)) {
        _grantRole(CUSTODIAN_ROLE, account);
        custodian_count++;
        custodianlist.push(account);
        emit custodian_registered(account, indexhash);
      }
      emit consensus_activity("custodian", indexhash);
    }

    function unregcust(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid account");
      require(hasRole(CUSTODIAN_ROLE, account), "Custodian not registered");
      require(custodian_count > 7, "Must contain 7 custodians");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.RemoveCustodian,account)));
      if (getConsensus(indexhash, 1)) {
          _revokeRole(CUSTODIAN_ROLE, account);
          custodian_count--;
          for(uint16 i = 0; i < custodianlist.length; i++) {
            if(custodianlist[i] == account) {
              custodianlist[i] = custodianlist[custodianlist.length - 1];
              custodianlist.pop();
              break;
            }
          }
          emit custodian_unregistered(account, indexhash);
      }
      emit consensus_activity("custodian", indexhash);
    } //unregcustodian

      // ------------------------------------------------------------------------
      // Don't accept ETH
      // ------------------------------------------------------------------------


    receive () external payable {
      revert();
    }

}