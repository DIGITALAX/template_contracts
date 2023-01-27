// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract ChildTemplates is ERC1155, Ownable {
    string public name;
    string public symbol;
    uint256 public tokenIdPointer;

    struct ChildTemplate {
        string _name;
        uint256 _tokenId;
        string _imageURI;
    }

    mapping(uint256 => string) public tokenIdToURI;
    mapping(uint256 => ChildTemplate) public tokenIdToTemplate;
    mapping()

    event ChildTemplateCreated(uint256 indexed tokenId, string tokenURI);

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
        tokenIdPointer = 0;
    }

    function mint(
        address _to,
        uint256 _amount,
        string memory _svg,
        string memory _name
    ) external onlyOwner {
        _mint(_to, tokenIdPointer, _amount, "");
        string memory imageURI = _templateDataFromSvg(_svg);
        tokenIdToURI[tokenIdPointer] = _formatURI(
            imageURI,
            _name,
            tokenIdPointer
        );
        tokenIdToTemplate[tokenIdPointer] = ChildTemplate({
            _name: _name,
            _tokenId: tokenIdPointer,
            _imageURI: tokenIdToURI[tokenIdPointer]
        });
        _setURI(tokenIdPointer, tokenIdToURI[tokenIdPointer]);
        emit ChildTemplateCreated(tokenIdPointer, tokenIdToURI[tokenIdPointer]);
        tokenIdPointer++;
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function burn(uint256 _id, uint256 _amount) external onlyOwner {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function _setURI(uint256 _id, string memory _uri) internal onlyOwner {
        tokenIdToURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenIdToURI[_id];
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
                                '" }'
                            )
                        )
                    )
                )
            );
    }

    function tokenExists(uint256[] calldata _childTokenIds) public view {
        for (uint256 i = _childTokenIds[0]; i <= _childTokenIds.length; i++) {
            require(
                _childTokenIds[i] <= tokenIdPointer,
                "Token Id has not yet been minted"
            );
        }
    }
}
