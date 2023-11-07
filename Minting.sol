// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct NFTType {
        string name;
        uint256 maxSupply;
        uint256 currentSupply;
        string uri;
    }

   struct NFTTypeInfo {
    string name;
    uint256 maxSupply;
    uint256 remainingSupply;
    uint256 ratioLeft;
}

    struct OwnedNFTInfo {
        uint256 tokenId;
        string uri;
        string nftType;
    }

    NFTType[] public nftTypes;
    EnumerableSet.UintSet private availableTypes;
    mapping(uint256 => uint256) private _tokenTypeIndexes;
    mapping(uint256 => bool) private _tokenExists;
    mapping(string => bool) private _nftTypeNameExists;

    uint256 public totalNFTsSold;
    uint256 public mintPrice = 10000 * 10**18; // 10000 Sphericals
    IERC20 public sphericalsToken = IERC20(0x70AE63bA0D88335c3CC89802AeEf253114cea30c);
    address public paymentReceiver;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        paymentReceiver = msg.sender; // Initially set the payment receiver to the contract owner
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setPaymentReceiver(address newReceiver) public onlyOwner {
        require(newReceiver != address(0), "Invalid address");
        paymentReceiver = newReceiver;
    }

    function addNFTType(string memory name, uint256 maxSupply, string memory uri) public onlyOwner {
        require(!_nftTypeNameExists[name], "NFT type name already exists");
        nftTypes.push(NFTType({
            name: name,
            maxSupply: maxSupply,
            currentSupply: 0,
            uri: uri
        }));
        availableTypes.add(nftTypes.length - 1);
        _nftTypeNameExists[name] = true;
    }

    function unlistNFTType(string memory name) public onlyOwner {
        for (uint256 i = 0; i < nftTypes.length; i++) {
            if (keccak256(bytes(nftTypes[i].name)) == keccak256(bytes(name))) {
                require(availableTypes.contains(i), "NFT type is not listed or already unlisted");
                availableTypes.remove(i);
                _nftTypeNameExists[name] = false;
                break;
            }
        }
    }

    function mint() public {
        require(availableTypes.length() > 0, "No NFT types available to mint");
        require(sphericalsToken.transferFrom(msg.sender, paymentReceiver, mintPrice), "Payment failed");

        uint256 typeId = getRandomAvailableTypeIndex();
        NFTType storage nftType = nftTypes[typeId];

        uint256 newTokenId = totalNFTsSold + 1;
        _mint(msg.sender, newTokenId);
        _tokenTypeIndexes[newTokenId] = typeId;
        _tokenExists[newTokenId] = true;
        nftType.currentSupply++;
        totalNFTsSold++;

        if (nftType.currentSupply >= nftType.maxSupply) {
            availableTypes.remove(typeId);
        }
    }

    function getRandomAvailableTypeIndex() private view returns (uint256) {
        uint256 totalMintableSupply = getTotalMintableSupply();
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % totalMintableSupply;
        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < availableTypes.length(); i++) {
            uint256 typeId = availableTypes.at(i);
            uint256 weight = nftTypes[typeId].maxSupply - nftTypes[typeId].currentSupply;
            cumulativeWeight += weight;
            if (randomIndex < cumulativeWeight) {
                return typeId;
            }
        }
        revert("Random type selection failed");
    }

    function getTotalMintableSupply() public view returns (uint256) {
        uint256 totalMintableSupply = 0;
        for (uint256 i = 0; i < nftTypes.length; i++) {
            totalMintableSupply += (nftTypes[i].maxSupply - nftTypes[i].currentSupply);
        }
        return totalMintableSupply;
    }

    function getNFTTypes() public view returns (NFTTypeInfo[] memory) {
        NFTTypeInfo[] memory typesInfo = new NFTTypeInfo[](nftTypes.length);
        uint256 totalMintableSupply = getTotalMintableSupply();
        for (uint256 i = 0; i < nftTypes.length; i++) {
            uint256 remainingSupply = nftTypes[i].maxSupply - nftTypes[i].currentSupply;
            uint256 ratio = (totalMintableSupply > 0) ? (remainingSupply * 10000) / totalMintableSupply : 0;
            typesInfo[i] = NFTTypeInfo({
                name: nftTypes[i].name,
                maxSupply: nftTypes[i].maxSupply, // Added maxSupply here
                remainingSupply: remainingSupply,
                ratioLeft: ratio
            });
        }
        return typesInfo;
    }

    function tokensOfOwner(address owner) public view returns (OwnedNFTInfo[] memory) {
        uint256 tokenCount = balanceOf(owner);
        OwnedNFTInfo[] memory ownedNFTs = new OwnedNFTInfo[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            uint256 typeId = _tokenTypeIndexes[tokenId];
            ownedNFTs[i] = OwnedNFTInfo({
                tokenId: tokenId,
                uri: nftTypes[typeId].uri,
                nftType: nftTypes[typeId].name
            });
        }
        return ownedNFTs;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_tokenExists[tokenId], "ERC721Metadata: URI query for nonexistent token");
        uint256 nftTypeId = _tokenTypeIndexes[tokenId];
        return nftTypes[nftTypeId].uri;
    }

    // ... Additional functions and logic ...
}
