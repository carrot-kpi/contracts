pragma solidity 0.8.15;

import {Ownable} from "oz/access/Ownable.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";
import {IOracle} from "./interfaces/oracles/IOracle.sol";
import {IBaseTemplatesManager} from "./interfaces/IBaseTemplatesManager.sol";
import {IKPITokensFactory} from "./interfaces/IKPITokensFactory.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Templates manager
/// @dev The templates manager contract acts as a template
/// registry for oracles/kpi token implementations. Additionally,
/// templates can also only be instantiated by the manager itself,
/// exclusively by request of a KPI token being created. All
/// templates-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the templates manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
abstract contract BaseTemplatesManager is Ownable, IBaseTemplatesManager {
    address public factory;
    uint256 internal templateId;
    Template[] internal templates;
    mapping(uint256 => uint256) internal templateIdToIndex;

    error NonExistentTemplate();
    error ZeroAddressFactory();
    error Forbidden();
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error NoKeyForTemplate();
    error InvalidVersionBump();
    error InvalidIndices();
    error AutomationNotSupported();

    event AddTemplate(
        uint256 indexed id,
        address indexed template,
        string specification
    );
    event RemoveTemplate(uint256 indexed id);
    event UpgradeTemplate(
        uint256 indexed id,
        address indexed newTemplate,
        uint256 _newVersion,
        string newSpecification
    );
    event UpdateTemplateSpecification(
        uint256 indexed id,
        string newSpecification
    );

    constructor(address _factory) {
        if (_factory == address(0)) revert ZeroAddressFactory();
        factory = _factory;
    }

    /// @dev Adds a template to the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _template The template's address.
    /// @param _specification An IPFS cid pointing to a structured JSON
    /// describing the template.
    function addTemplate(address _template, string calldata _specification)
        external
        override
        onlyOwner
    {
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = ++templateId;
        templates.push(
            Template({
                id: _id,
                addrezz: _template,
                version: 1,
                specification: _specification
            })
        );
        templateIdToIndex[_id] = templates.length;
        emit AddTemplate(_id, _template, _specification);
    }

    /// @dev Removes a template from the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _id The id of the template that must be removed.
    function removeTemplate(uint256 _id) external override onlyOwner {
        uint256 _index = templateIdToIndex[_id];
        if (_index == 0) revert NonExistentTemplate();
        Template storage _lastTemplate = templates[templates.length - 1];
        if (_lastTemplate.id != _id) {
            templates[_index - 1] = _lastTemplate;
            templateIdToIndex[_lastTemplate.id] = _index;
        }
        delete templateIdToIndex[_id];
        templates.pop();
        emit RemoveTemplate(_id);
    }

    /// @dev Updates a template specification. The specification is an IPFS cid
    /// pointing to a structured JSON file containing data about the template.
    /// This function can only be called by the contract owner (governance).
    /// @param _id The template's id.
    /// @param _newSpecification the updated specification for the template with id `_id`.
    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override onlyOwner {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        storageTemplate(_id).specification = _newSpecification;
        emit UpdateTemplateSpecification(_id, _newSpecification);
    }

    /// @dev Upgrades a template. This function can only be called by the contract owner (governance).
    /// @param _id The id of the template that needs to be upgraded.
    /// @param _newTemplate The new address of the template.
    /// @param _newSpecification The updated specification for the upgraded template.
    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        string calldata _newSpecification
    ) external override onlyOwner {
        if (_newTemplate == address(0)) revert ZeroAddressTemplate();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        Template storage _templateFromStorage = storageTemplate(_id);
        if (
            keccak256(bytes(_templateFromStorage.specification)) ==
            keccak256(bytes(_newSpecification))
        ) revert InvalidSpecification();
        _templateFromStorage.addrezz = _newTemplate;
        _templateFromStorage.specification = _newSpecification;
        _templateFromStorage.version++;
        emit UpgradeTemplate(
            _id,
            _newTemplate,
            _templateFromStorage.version,
            _newSpecification
        );
    }

    /// @dev Gets a template from storage.
    /// @param _id The id of the template that needs to be fetched.
    /// @return The template from storage with id `_id`.
    function storageTemplate(uint256 _id)
        internal
        view
        returns (Template storage)
    {
        if (_id == 0) revert NonExistentTemplate();
        uint256 _index = templateIdToIndex[_id];
        if (_index == 0) revert NonExistentTemplate();
        Template storage _template = templates[_index - 1];
        return _template;
    }

    /// @dev Gets a template by id.
    /// @param _id The id of the template that needs to be fetched.
    /// @return The template with id `_id`.
    function template(uint256 _id)
        external
        view
        override
        returns (Template memory)
    {
        return storageTemplate(_id);
    }

    /// @dev Used to determine whether a template with a certain id exists or not.
    /// @param _id The id of the template that needs to be checked.
    /// @return True if the template exists, false otherwise.
    function exists(uint256 _id) external view override returns (bool) {
        if (_id == 0) return false;
        uint256 _index = templateIdToIndex[_id];
        if (_index == 0) return false;
        return templates[_index - 1].id == _id;
    }

    /// @dev Gets the amount of all registered templates.
    /// @return The templates amount.
    function templatesAmount() external view override returns (uint256) {
        return templates.length;
    }

    /// @dev Gets a templates slice based on indexes. N.B.: the templates are not
    /// ordered and due to how templates are removed, it could happen to have 2
    /// disjointed slices with the same template being in both, even though it
    /// should be rare.
    /// @param _fromIndex The index from which to get templates.
    /// @param _toIndex The maximum index to which to get templates.
    /// @return A templates array representing the slice taken through the given indexes.
    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (Template[] memory)
    {
        if (_toIndex > templates.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        Template[] memory _templates = new Template[](_range);
        for (uint256 _i = 0; _i < _range; _i++)
            _templates[_i] = templates[_fromIndex + _i];
        return _templates;
    }
}
