pragma solidity 0.8.15;

import {Ownable} from "oz/access/Ownable.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";
import {IOracle} from "./interfaces/oracles/IOracle.sol";
import {IOraclesManager} from "./interfaces/IOraclesManager.sol";
import {IKPITokensFactory} from "./interfaces/IKPITokensFactory.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager
/// @dev The oracles manager contract acts as a template
/// registry for oracle implementations. Additionally, templates
/// can also only be instantiated by the manager itself,
/// exclusively by request of a KPI token being created. All
/// templates-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManager is Ownable, IOraclesManager {
    address public immutable factory;
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
        bool automatable,
        string specification
    );
    event RemoveTemplate(uint256 indexed id);
    event UpgradeTemplate(
        uint256 indexed id,
        address indexed newTemplate,
        uint8 versionBump,
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

    /// @dev Calculates the salt value used in CREATE2 when
    /// instantiating new templates. the salt is calculated as
    /// keccak256(abi.encodePacked(`_creator`, `_initializationData`)).
    /// @param _creator The KPI token creator.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @return The salt value.
    function salt(address _creator, bytes calldata _initializationData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_creator, _initializationData));
    }

    /// @dev Predicts an oracle template instance address based on the input data.
    /// @param _creator The KPI token creator.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @return The address at which the template with the given input
    /// parameters will be instantiated.
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        bytes calldata _initializationData
    ) external view override returns (address) {
        return
            Clones.predictDeterministicAddress(
                storageTemplate(_id).addrezz,
                salt(_creator, _initializationData),
                address(this)
            );
    }

    /// @dev Instantiates a given template using EIP 1167 minimal proxies.
    /// The input data will both be used to choose the instantiated template
    /// and to feed it initialization data.
    /// @param _creator The KPI token creator.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @return The address at which the template with the given input
    /// parameters has been instantiated.
    function instantiate(
        address _creator,
        uint256 _id,
        bytes calldata _initializationData
    ) external override returns (address) {
        if (!IKPITokensFactory(factory).allowOraclesCreation(msg.sender))
            revert Forbidden();
        Template storage _template = storageTemplate(_id);
        address _instance = Clones.cloneDeterministic(
            _template.addrezz,
            salt(_creator, _initializationData)
        );
        IOracle(_instance).initialize(msg.sender, _id, _initializationData);
        return _instance;
    }

    /// @dev Adds a template to the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _template The template's address.
    /// @param _automatable Whether the template is automatable or not.
    /// @param _specification An IPFS cid pointing to a structured JSON
    /// describing the template.
    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _specification
    ) external override onlyOwner {
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (_automatable) revert AutomationNotSupported();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = ++templateId;
        templates.push(
            Template({
                id: _id,
                addrezz: _template,
                version: Version({major: 1, minor: 0, patch: 0}),
                specification: _specification,
                automatable: false
            })
        );
        templateIdToIndex[_id] = templates.length;
        emit AddTemplate(_id, _template, _automatable, _specification);
    }

    /// @dev Removes a template from the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _id The id of the template that must be removed.
    function removeTemplate(uint256 _id) external override onlyOwner {
        uint256 _index = templateIdToIndex[_id];
        if (_index == 0) revert NonExistentTemplate();
        unchecked {
            _index--;
        }
        Template storage _lastTemplate = templates[templates.length - 1];
        if (_lastTemplate.id != _id) {
            templates[_index] = _lastTemplate;
            templateIdToIndex[_lastTemplate.id] = _index;
        } else {
            delete templateIdToIndex[_id];
        }
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
    /// @param _versionBump A bitmask describing the version bump to be applied (major, minor, patch).
    /// @param _newSpecification The updated specification for the upgraded template.
    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
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
        if (_versionBump & 1 == 1) _templateFromStorage.version.patch++;
        else if (_versionBump & 2 == 2) {
            _templateFromStorage.version.minor++;
            _templateFromStorage.version.patch = 0;
        } else if (_versionBump & 4 == 4) {
            _templateFromStorage.version.major++;
            _templateFromStorage.version.minor = 0;
            _templateFromStorage.version.patch = 0;
        } else revert InvalidVersionBump();
        emit UpgradeTemplate(
            _id,
            _newTemplate,
            _versionBump,
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

    /// @dev Gets a templates slice based on indexes.
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
