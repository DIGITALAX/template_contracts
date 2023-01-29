// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChildTemplates is ERC1155, Ownable {
    string public name;
    string public symbol;
    uint256 public tokenIdPointer;

    struct ChildTemplate {
        string _name;
        string _tokenId;
        string _imageURI;
    }

    mapping(uint256 => string) public tokenIdToURI;
    mapping(uint256 => ChildTemplate) public tokenIdToTemplate;
    mapping(uint256 => address) public tokenIdToOwner;

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
        ++tokenIdPointer;
        _mint(_to, tokenIdPointer, _amount, "");
        string memory imageURI = _templateDataFromSvg(_svg);
        tokenIdToURI[tokenIdPointer] = _formatURI(
            imageURI,
            _name,
            tokenIdPointer
        );
        tokenIdToTemplate[tokenIdPointer] = ChildTemplate({
            _name: _name,
            _tokenId: Strings.toString(tokenIdPointer),
            _imageURI: imageURI
        });
        _setURI(tokenIdPointer, tokenIdToURI[tokenIdPointer]);
        tokenIdToOwner[tokenIdPointer] = msg.sender;
        emit ChildTemplateCreated(tokenIdPointer, tokenIdToURI[tokenIdPointer]);
    }

    function mintBatch(
        address _to,
        uint256[] memory _amounts,
        string[] memory _svgs,
        string[] memory _names
    ) external onlyOwner {
        require(
            _names.length == _svgs.length &&
                _names.length == _amounts.length &&
                _svgs.length == _amounts.length,
            "All arrays must be the same length"
        );
        uint256[] memory _ids = new uint[](_names.length);
        for (uint i = 0; i < _names.length; i++) {
            _ids[i] = ++tokenIdPointer;
        }
        _mintBatch(_to, _ids, _amounts, "");
        for (uint i = 0; i < _ids.length; i++) {
            string memory imageURI = _templateDataFromSvg(_svgs[i]);
            tokenIdToURI[tokenIdPointer] = _formatURI(
                imageURI,
                _names[i],
                _ids[i]
            );
            tokenIdToTemplate[tokenIdPointer] = ChildTemplate({
                _name: _names[i],
                _tokenId: Strings.toString(_ids[i]),
                _imageURI: imageURI
            });
            _setURI(_ids[i], tokenIdToURI[tokenIdPointer]);
            tokenIdToOwner[_ids[i]] = msg.sender;
        }
    }

    function burn(uint256 _id, uint256 _amount) external onlyOwner {
        delete tokenIdToTemplate[_id];
        delete tokenIdToURI[_id];
        tokenIdToOwner[_id] = address(0);
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external {
        for (uint256 i = 0; i < _ids.length; i++) {
            delete tokenIdToTemplate[_ids[i]];
            delete tokenIdToURI[_ids[i]];
            tokenIdToOwner[_ids[i]] = address(0);
        }
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        for (uint256 i = 0; i < _burnIds.length; i++) {
            delete tokenIdToTemplate[_burnIds[i]];
            delete tokenIdToURI[_burnIds[i]];
            tokenIdToOwner[_burnIds[i]] = address(0);
        }
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
                                Strings.toString(_tokenId),
                                '", "svgData": "',
                                _imageURI,
                                '" }'
                            )
                        )
                    )
                )
            );
    }

    function tokenExists(
        uint256[] calldata _childTokenIds
    ) external view returns (bool success) {
        for (uint256 i = 0; i < _childTokenIds.length; i++) {
            require(
                _childTokenIds[i] <= tokenIdPointer && _childTokenIds[i] != 0,
                "Token Id has not yet been minted"
            );
        }

        return true;
    }

    function getTokenOwner(uint256 _tokenId) external view returns (address) {
        return tokenIdToOwner[_tokenId];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override {
        require(
            _from == msg.sender && tokenIdToOwner[_id] == _from,
            "ERC1155: caller is not token owner or approved"
        );
        tokenIdToOwner[_id] = _to;
        _safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override {
        require(_from == msg.sender, "ERC1155: caller is not token owner");
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                tokenIdToOwner[_ids[i]] == _from,
                "ERC1155: caller is not token owner"
            );
            tokenIdToOwner[_ids[i]] = _to;
        }
        _safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }
}
