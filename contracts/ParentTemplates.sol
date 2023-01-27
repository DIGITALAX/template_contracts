// SPDX-License-Identifier: UNLICENSE
// @title: Parent FGO
// @version: 1.0.0
// @author: Emma-Jane MacKinnon-Lee | DIGITALAX

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ChildTemplates.sol";

contract ParentTemplates is ERC721, Ownable {
    uint256 public totalSupply;
    address public childContract;

    struct Template {
        string _name;
        uint256 _tokenId;
        string _svgData;
        uint256[] _childTokenIds;
    }

    mapping(uint256 => uint256[]) public parentToChild;
    mapping(uint256 => string) public tokenIdToURI;
    mapping(uint256 => Template) public tokenIdToTemplate;

    event TemplateCreated(uint indexed tokenId, string tokenURI);

    modifier childTokensModifier() {
        _verifyChildTokens();
        _;
    }

    constructor(address _childContract) ERC721("ParentTemplates", "PTFGO") {
        totalSupply = 0;
        childContract = _childContract;
    }

    function createTemplate(
        string memory _svg,
        uint256[] memory _childTokenIds,
        string memory _name
    ) external onlyOwner childTokensModifier {
        _safeMint(msg.sender, totalSupply);
        string memory imageURI = _templateDataFromSvg(_svg);
        tokenIdToTemplate[totalSupply] = Template({
            _name: _name,
            _tokenId: totalSupply,
            _svgData: imageURI,
            _childTokenIds: _childTokenIds
        });
        tokenIdToURI[totalSupply] = _formatURI(
            imageURI,
            _name,
            _childTokenIds,
            totalSupply
        );
        parentToChild[totalSupply] = _childTokenIds;
        ++totalSupply;

        emit TemplateCreated(totalSupply - 1, tokenIdToURI[totalSupply]);
    }

    function updateURI(
        uint256 _tokenId,
        string memory _svg
    ) external onlyOwner {
        string memory imageURI = _templateDataFromSvg(_svg);
        tokenIdToURI[_tokenId] = _formatURI(
            imageURI,
            tokenIdToTemplate[_tokenId]._name,
            tokenIdToTemplate[_tokenId]._childTokenIds,
            _tokenId
        );
    }

    function _templateDataFromSvg(
        string memory _svg
    ) internal pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(_svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function _formatURI(
        string memory _imageURI,
        string memory _name,
        uint256[] memory _childTokenIds,
        uint256 _tokenId
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{ "name": "',
                                _name,
                                '", "tokenId": "',
                                _tokenId,
                                '", "svgData": "',
                                _imageURI,
                                '", "childTokenIds": "',
                                _childTokenIds,
                                '" }'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return tokenIdToURI[_tokenId];
    }

    function parentChildTokens(
        uint256 _tokenId
    ) public view virtual returns (uint256[] memory) {
        return parentToChild[_tokenId];
    }

    function numberOfChildTokens(
        uint256 _tokenId
    ) public view virtual returns (uint256) {
        return parentToChild[_tokenId].length;
    }

    function _verifyChildTokens(
        uint256[] calldata _childTokenIds
    ) internal returns (bool) {
        ChildTemplates(childContract).tokenExists(_childTokenIds);
    }
}