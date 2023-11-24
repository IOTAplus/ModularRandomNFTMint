// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RandomMintNFT is ERC721Enumerable, Ownable {
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
    IERC20 public sphericalsToken = IERC20(0xa662a27EC0EC79c1c75bf9BC4ff4aA1f1A7a27AF);
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
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
            require(_tokenExists[tokenId], "ERC721Metadata: URI query for nonexistent token");
            uint256 nftTypeId = _tokenTypeIndexes[tokenId];
            return nftTypes[nftTypeId].uri;
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
   function getNFTTypes() public view returns (string memory) {
    string memory json = '[';
    for (uint256 i = 0; i < nftTypes.length; i++) {
        uint256 remainingSupply = nftTypes[i].maxSupply - nftTypes[i].currentSupply;
        uint256 ratio = (getTotalMintableSupply() > 0) ? (remainingSupply * 10000) / getTotalMintableSupply() : 0;

        json = string(abi.encodePacked(json,
            '{',
            '"name":"', nftTypes[i].name, '",',
            '"maxSupply":', uint2str(nftTypes[i].maxSupply), ',',
            '"remainingSupply":', uint2str(remainingSupply), ',',
            '"ratioLeft":', uint2str(ratio), ',',
            '"uri":"', nftTypes[i].uri, '"',  // Include the URI here
            '}', 
            (i < nftTypes.length - 1) ? ',' : ''
        ));
    }
    return string(abi.encodePacked(json, ']'));
}

    function nFTsOfOwner(address owner) public view returns (string memory) {
            string memory json = '[';
            uint256 tokenCount = balanceOf(owner);
            for (uint256 i = 0; i < tokenCount; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, i);
                uint256 typeId = _tokenTypeIndexes[tokenId];
                NFTType memory nftType = nftTypes[typeId];
                json = string(abi.encodePacked(json, 
                    '{',
                    '"tokenId":', uint2str(tokenId), ',',
                    '"uri":"', nftType.uri, '",',
                    '"nftType":"', nftType.name, '"',
                    '}',
                    (i < tokenCount - 1) ? ',' : ''
                ));
            }
            return string(abi.encodePacked(json, ']'));
        }

    // Helper function to convert uint to string
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    // Function to update the URI of an NFT type
    function setNFTTypeURI(string memory nftTypeName, string memory newUri) public onlyOwner {
        bool typeExists = false;
        uint256 typeId;

        // Search for the NFT type by name
        for (uint256 i = 0; i < nftTypes.length; i++) {
            if (keccak256(abi.encodePacked(nftTypes[i].name)) == keccak256(abi.encodePacked(nftTypeName))) {
                typeExists = true;
                typeId = i;
                break;
            }
        }

        // Ensure the NFT type exists
        require(typeExists, "NFT type does not exist");

        // Update the URI
        NFTType storage nftType = nftTypes[typeId];
        nftType.uri = newUri;
    }
}
