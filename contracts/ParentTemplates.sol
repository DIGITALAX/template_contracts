// SPDX-License-Identifier: UNLICENSE
// @title: Parent FGO
// @version: 1.0.0
// @author: Emma-Jane MacKinnon-Lee | DIGITALAX

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ChildTemplates.sol";

contract ParentTemplates is ERC721, Ownable {
    uint256 public totalSupply;
    address public childContract;

    struct Template {
        string _name;
        uint256 _tokenId;
        string _imageURI;
        uint256[] _childTokenIds;
    }

    mapping(uint256 => uint256[]) public parentToChild;
    mapping(uint256 => string) public tokenIdToURI;
    mapping(uint256 => Template) public tokenIdToTemplate;
    mapping(uint256 => address) public tokenIdToOwner;

    event ParentTemplateCreated(uint indexed tokenId, string tokenURI);

    modifier childTokensModifier(uint256[] calldata _childTokenIds) {
        _verifyChildTokens(_childTokenIds);
        _;
    }

    constructor(address _childContract) ERC721("ParentTemplates", "PTFGO") {
        totalSupply = 0;
        childContract = _childContract;
    }

    function createTemplate(
        string calldata _svg,
        uint256[] calldata _childTokenIds,
        string calldata _name
    ) public onlyOwner childTokensModifier(_childTokenIds) {
        ++totalSupply;
        _safeMint(msg.sender, totalSupply);
        string memory imageURI = _templateDataFromSvg(_svg);
        tokenIdToTemplate[totalSupply] = Template({
            _name: _name,
            _tokenId: totalSupply,
            _imageURI: imageURI,
            _childTokenIds: _childTokenIds
        });
        tokenIdToURI[totalSupply] = _formatURI(
            imageURI,
            _name,
            _childTokenIds,
            totalSupply
        );
        tokenIdToOwner[totalSupply] = msg.sender;
        parentToChild[totalSupply] = _childTokenIds;
        emit ParentTemplateCreated(totalSupply, tokenIdToURI[totalSupply]);
    }

    function updateSvg(
        uint256 _tokenId,
        string calldata _svg
    ) public onlyOwner {
        string memory imageURI = _templateDataFromSvg(_svg);
        tokenIdToURI[_tokenId] = _formatURI(
            imageURI,
            tokenIdToTemplate[_tokenId]._name,
            tokenIdToTemplate[_tokenId]._childTokenIds,
            _tokenId
        );
        tokenIdToTemplate[totalSupply] = Template({
            _name: tokenIdToTemplate[_tokenId]._name,
            _tokenId: _tokenId,
            _imageURI: imageURI,
            _childTokenIds: tokenIdToTemplate[_tokenId]._childTokenIds
        });
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
        string memory _stringChildTokenIds;
        for (uint256 i = 0; i < _childTokenIds.length - 1; i++) {
            _stringChildTokenIds = string.concat(
                _stringChildTokenIds,
                " ",
                Strings.toString(_childTokenIds[i]),
                ", "
            );
        }
        _stringChildTokenIds = string(
            abi.encodePacked(
                "[",
                _stringChildTokenIds,
                Strings.toString(_childTokenIds[_childTokenIds.length - 1]),
                " ]"
            )
        );
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
                                Strings.toString(_tokenId),
                                '", "svgData": "',
                                _imageURI,
                                '", "childTokenIds": "',
                                _stringChildTokenIds,
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

    function _verifyChildTokens(uint256[] memory _childTokenIds) internal view {
        ChildTemplates(childContract).tokenExists(_childTokenIds);
    }

    function burnTemplate(
        uint256 _tokenId,
        uint256[] calldata _childTokenIds,
        uint256[] calldata _amounts
    ) public onlyOwner childTokensModifier(_childTokenIds) {
        for (uint256 i = 0; i < _childTokenIds.length; i++) {
            require(
                _amounts[i] <=
                    ChildTemplates(childContract).tokenIdToAmount(
                        _childTokenIds[i]
                    ),
                "Incorrect Child Tokens Amount"
            );
        }
        _burn(_tokenId);
        tokenIdToOwner[totalSupply] = address(0);
        ChildTemplates(childContract).burnBatch(_childTokenIds, _amounts);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
        tokenIdToOwner[totalSupply] = to;
        uint256[] memory childTokens = parentToChild[tokenId];
        uint256[] memory childAmounts = new uint[](
            parentToChild[tokenId].length
        );

        ChildTemplates(childContract).safeBatchTransferFrom(
            from,
            to,
            childTokens,
            childAmounts,
            ""
        );
    }
}
