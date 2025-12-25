// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DDCNFT {
    // State variables packed into the same storage slot for gas optimization
    bool private _paused;
    address private _owner;
    uint96 private _totalSupply; // Reduced uint size to fit in the storage slot
    
    // Events
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferred(address previousOwner, address newOwner);
    
    // Stores the key hash representing the current owner of each token
    mapping(uint256 => bytes32) private _tokenKeyHashes;

    // Tracks whether each token has been destroyed
    mapping(uint256 => bool) private _destroyedTokens;

    // Token name and symbol
    string private _name;
    string private _symbol;

    // Global baseURI (strongly recommended - most gas-efficient)
    string private _baseURI = "";

    // Per-token individual full URI (use only in special cases as an override mechanism)
    // Note: Using this mapping consumes an additional storage slot per set token (~20,000 gas)
    // It is strongly recommended to use the global _baseURI + tokenId approach unless
    // certain tokens require completely different metadata URLs
    mapping(uint256 => string) private _tokenURIs;

    // ERC721 Metadata
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;    
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the metadata URI for a token
     * Priority: returns the individual URI if set for this token
     * Fallback: returns _baseURI + tokenId (recommended low-gas method)
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_tokenKeyHashes[tokenId] != bytes32(0), "Token does not exist!");
        require(!_destroyedTokens[tokenId], "Token has been destroyed!");

        // Priority: use individual URI (override mechanism)
        string memory specificURI = _tokenURIs[tokenId];
        if (bytes(specificURI).length > 0) {
            return specificURI;
        }

        // Recommended low-gas method: global baseURI + tokenId
        if (bytes(_baseURI).length == 0) {
            return "";
        }
        return string(abi.encodePacked(_baseURI, tokenId));
    }

    /**
     * @dev Set the global baseURI (strongly recommended)
     * All token URIs will automatically become baseURI + tokenId
     * Writes to only one storage slot - extremely low gas cost
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    /**
     * @dev Set an individual full URI for a specific token
     * Use only when the token needs completely different metadata from others
     * Each call consumes an additional storage slot (~20,000 gas) - not recommended for bulk use
     */
    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        require(_tokenKeyHashes[tokenId] != bytes32(0), "Token does not exist!");
        require(!_destroyedTokens[tokenId], "Token has been destroyed!");
        _tokenURIs[tokenId] = uri;
    }

    // Optional: clear the individual URI for a token to fall back to global baseURI
    function clearTokenURI(uint256 tokenId) public onlyOwner {
        require(_tokenKeyHashes[tokenId] != bytes32(0), "Token does not exist!");
        delete _tokenURIs[tokenId];
    }

    function ownerOf(uint256 tokenId) public view returns (bytes32) {
        bytes32 ownerHash = _tokenKeyHashes[tokenId];
        require(ownerHash != bytes32(0), "Token does not exist!");
        return ownerHash;
    }
    
    function transfer(bytes32 toHash, uint256 tokenId, string memory key) public onlyOwner whenNotPaused {
        require(toHash != bytes32(0), "Invalid recipient hash");
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        require(_tokenKeyHashes[tokenId] == keyHash, "Not authorized");
        require(!_destroyedTokens[tokenId], "Token has been destroyed");
        _transfer(toHash, tokenId);
    }

    event Transfer(bytes32 indexed fromHash, bytes32 indexed toHash, uint256 indexed tokenId);
    event TokenDestroyed(uint256 indexed tokenId, bytes32 indexed ownerHash);

    function _transfer(bytes32 toHash, uint256 tokenId) internal {
        bytes32 fromHash = _tokenKeyHashes[tokenId];
        _tokenKeyHashes[tokenId] = toHash;
        emit Transfer(fromHash, toHash, tokenId);
    }

    function mint(uint256 tokenId, bytes32 keyHash) public onlyOwner whenNotPaused {
        require(tokenId != 0, "Invalid token ID");
        require(keyHash != bytes32(0), "Invalid key hash");
        require(_tokenKeyHashes[tokenId] == bytes32(0), "Token already minted!");
        require(!_destroyedTokens[tokenId], "Token was previously destroyed");
        
        require(_totalSupply + 1 > _totalSupply, "Total supply overflow");
        _tokenKeyHashes[tokenId] = keyHash;
        unchecked { _totalSupply++; }
        emit Transfer(bytes32(0), keyHash, tokenId);
    }

    function destroy(uint256 tokenId, string memory key) public onlyOwner whenNotPaused {
        require(tokenId != 0, "Invalid token ID");
        require(bytes(key).length > 0, "Invalid key");
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        require(_tokenKeyHashes[tokenId] == keyHash, "Incorrect key or unauthorized!");
        require(!_destroyedTokens[tokenId], "Token already destroyed");
        
        require(_totalSupply > 0, "Total supply underflow");
        _destroyedTokens[tokenId] = true;
        // Clean up individual URI to save future storage
        delete _tokenURIs[tokenId];
        unchecked { _totalSupply--; }
        emit TokenDestroyed(tokenId, keyHash);
        emit Transfer(keyHash, bytes32(0), tokenId);
    }
}