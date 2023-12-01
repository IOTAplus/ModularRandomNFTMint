// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface ISCEntropy {
    function getEntropy() external returns (bytes32);
}

contract RandomMintNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct NFTType {
        uint256 currentSupply;
        uint256 maxSupply;
        string name;
        string uri;
    }

    uint256[] private mintables;

    mapping(uint256 => NFTType) public nftTypes;
    mapping(uint256 => uint256) private _totalMintableSupply;
    mapping(uint256 => uint256) private _tokenTypeIndexes;

    mapping(uint256 => bool) private _tokenExists;
    mapping(string => bool) private _nftTypeNameExists;

    address public paymentReceiver;
    address constant ISC = 0x1074000000000000000000000000000000000000;

    uint256 public totalNFTsSold;
    uint256 public totalNFTTypes;

    uint256 public mintPrice = 10000 * 10**18; // 10000 Sphericals

    IERC20 public constant SPHE = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138); // ChangeMe

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        paymentReceiver = msg.sender; // Initially set the payment receiver to the contract owner
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setPaymentReceiver(address newReceiver) external onlyOwner {
        if (newReceiver == address(0)) revert("Invalid address");
        paymentReceiver = newReceiver;
    }

    // Function to update the URI of an NFT type
    function setNFTTypeURI(uint256 typeId, string memory newUri) external onlyOwner {
        if (keccak256(bytes(nftTypes[typeId].name)) == 0) revert("typeId dosent exist");
        nftTypes[typeId].uri = newUri;
    }

    function viewAllMintables() external view returns (uint256[] memory) {
        return mintables;
    }

    function totalMintables() external view returns (uint256) {
        return mintables.length;
    }

    function addNFTType(string memory _name, uint256 maxSupply, string memory uri) external onlyOwner {
        if (_nftTypeNameExists[_name]) revert("NFTType already exists");
        if (maxSupply == 0) revert("Invalid maxSupply");
        
        nftTypes[totalNFTTypes] = NFTType(
            0, 
            maxSupply, 
            _name, 
            uri
        );

        _nftTypeNameExists[_name] = true;
        mintables.push(totalNFTTypes);
        totalNFTTypes++;
    }

    function unlistNFTType(uint256 typeId) external onlyOwner {
        if (keccak256(bytes(nftTypes[typeId].name)) == 0) revert("typeId dosent exist");

        delete nftTypes[typeId];
        totalNFTTypes--;

        string memory _name = nftTypes[typeId].name;
        _nftTypeNameExists[_name] = false;

        mintables[typeId] = mintables[mintables.length - 1];
        mintables.pop();
    }

    function mint() external nonReentrant {
        uint256 len = mintables.length;

        if (len == 0) revert("No NFTTypes available to mint");

        // SPHE.safeTransferFrom(msg.sender, paymentReceiver, mintPrice);

        // eth
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % len;
        // shimmer
        // uint256 randomIndex = uint256(keccak256(abi.encodePacked(ISCEntropy(ISC).getEntropy()))) % len;

        uint256 typeId = mintables[randomIndex];

        _tokenTypeIndexes[totalNFTsSold] = typeId;
        _tokenExists[totalNFTsSold] = true;

        _mint(msg.sender, totalNFTsSold);

        unchecked {
            nftTypes[typeId].currentSupply++;
            totalNFTsSold++;
        }

        if (nftTypes[typeId].currentSupply == nftTypes[typeId].maxSupply) {
            mintables[randomIndex] = mintables[mintables.length - 1];
            mintables.pop();
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_tokenExists[tokenId], "ERC721Metadata: URI query for nonexistent token");
        uint256 nftTypeId = _tokenTypeIndexes[tokenId];
        return nftTypes[nftTypeId].uri;
    }

    function getTotalMintableSupply() public view returns (uint256) {
        uint256 totalMintableSupply;

        for (uint256 i = 0; i < totalNFTTypes; i++) {
            totalMintableSupply += nftTypes[i].maxSupply - nftTypes[i].currentSupply;
        }
        return totalMintableSupply;
    }

    function getMintableSupply(uint256 typeId) external view returns (uint256) {
        if (keccak256(bytes(nftTypes[typeId].name)) == 0) revert("typeId dosent exist");
        return nftTypes[typeId].maxSupply - nftTypes[typeId].currentSupply;
    }

    // this ouput is a bad idea
    function nFTsOfOwner(address _owner) external view returns (string memory) {
        string memory json = '[';
        uint256 tokenCount = balanceOf(_owner);
        uint256 tokenId;
        uint256 typeId;

        unchecked {
            for (uint256 i; i < tokenCount; i++) {
                tokenId = tokenOfOwnerByIndex(_owner, i);
                typeId = _tokenTypeIndexes[tokenId];

                json = string(abi.encodePacked(json, 
                    '{',
                    '"tokenId":', uint2str(tokenId), ',',
                    '"uri":"', nftTypes[typeId].uri, '",',
                    '"nftType":"', nftTypes[typeId].name, '"',
                    '}',
                    (i < tokenCount - 1) ? ',' : ''
                ));
            }
        }
        return string(abi.encodePacked(json, ']'));
    }

    // this ouput is a bad idea
    function getNFTTypes() public view returns (string memory) {
        string memory json = '[';
        uint256 remainingSupply;
        uint256 ratio;

        for (uint256 i; i < totalNFTTypes; i++) {
            remainingSupply = nftTypes[i].maxSupply - nftTypes[i].currentSupply;
            ratio = (getTotalMintableSupply() > 0) ? (remainingSupply * 10000) / getTotalMintableSupply() : 0;

            json = string(abi.encodePacked(json,
                '{',
                '"name":"', nftTypes[i].name, '",',
                '"maxSupply":', uint2str(nftTypes[i].maxSupply), ',',
                '"remainingSupply":', uint2str(remainingSupply), ',',
                '"ratioLeft":', uint2str(ratio), ',',
                '"uri":"', nftTypes[i].uri, '"',  // Include the URI here
                '}', 
                (i < totalNFTTypes - 1) ? ',' : '')
            );
        }
        return string(abi.encodePacked(json, ']'));
    }

    // Helper function to convert uint to string when abi.encode does not work
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
}