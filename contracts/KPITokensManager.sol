pragma solidity 0.8.15;

import {Ownable} from "oz/access/Ownable.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";
import {IOracle} from "./interfaces/oracles/IOracle.sol";
import {IKPITokensManager} from "./interfaces/IKPITokensManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager
/// @dev The KPI token manager contract acts as a template
/// registry for KPI token implementations. Additionally, templates
/// can also only be instantiated by the manager itself,
/// exclusively by request of the factory contract. All
/// templates-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KPITokensManager is Ownable, IKPITokensManager {
    address public immutable factory;
    EnumerableTemplateSet private templates;

    error ZeroAddressFactory();
    error Forbidden();
    error InvalidTemplate();
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error InvalidVersionBump();
    error NoKeyForTemplate();
    error NonExistentTemplate();
    error InvalidIndices();

    event AddTemplate(
        uint256 indexed id,
        address template,
        string specification
    );
    event RemoveTemplate(uint256 indexed id);
    event UpgradeTemplate(
        uint256 indexed id,
        address newTemplate,
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
    /// keccak256(abi.encodePacked(`_description`, `_initializationData`, `_oraclesInitializationData`)).
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The salt value.
    function salt(
        address _creator,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _creator,
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }

    /// @dev Predicts a KPI token template instance address based on the input data.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters will be instantiated.
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external view override returns (address) {
        return
            Clones.predictDeterministicAddress(
                storageTemplate(_id).addrezz,
                salt(
                    _creator,
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }

    /// @dev Instantiates a given template using EIP 1167 minimal proxies.
    /// The input data will both be used to choose the instantiated template
    /// and to feed it initialization data.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters has been instantiated.
    function instantiate(
        address _creator,
        uint256 _id,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external override returns (address) {
        if (msg.sender != factory) revert Forbidden();
        return
            Clones.cloneDeterministic(
                storageTemplate(_id).addrezz,
                salt(
                    _creator,
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
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
        uint256 _id = ++templates.ids;
        templates.values.push(
            Template({
                id: _id,
                addrezz: _template,
                version: Version({major: 1, minor: 0, patch: 0}),
                specification: _specification
            })
        );
        templates.index[_id] = templates.values.length;
        emit AddTemplate(_id, _template, _specification);
    }

    /// @dev Removes a template from the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _id The id of the template that must be removed.
    function removeTemplate(uint256 _id) external override onlyOwner {
        uint256 _index = templates.index[_id];
        if (_index == 0) revert NonExistentTemplate();
        unchecked {
            _index--;
        }
        Template storage _lastTemplate = templates.values[
            templates.values.length - 1
        ];
        if (_lastTemplate.id != _id) {
            templates.values[_index] = _lastTemplate;
            templates.index[_lastTemplate.id] = _index;
        } else {
            delete templates.index[_id];
        }
        templates.values.pop();
        emit RemoveTemplate(_id);
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

    /// @dev Updates a template specification. The specification is an IPFS cid
    /// pointing to a structured JSON file containing data about the template.
    /// This function can only be called by the contract owner (governance).
    /// @param _id The template's id.
    /// @param _newSpecification The updated specification for the template with id `_id`.
    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override onlyOwner {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        storageTemplate(_id).specification = _newSpecification;
        emit UpdateTemplateSpecification(_id, _newSpecification);
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
        uint256 _index = templates.index[_id];
        if (_index == 0) revert NonExistentTemplate();
        Template storage _template = templates.values[_index - 1];
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
        uint256 _index = templates.index[_id];
        if (_index == 0) return false;
        return templates.values[_index - 1].id == _id;
    }

    /// @dev Gets the amount of all registered templates.
    /// @return The templates amount.
    function templatesAmount() external view override returns (uint256) {
        return templates.values.length;
    }

    /// @dev Gets a templates slice based on indexes.
    /// @param _fromIndex The index from which to get templates.
    /// @param _toIndex The maximum index to which to get templates.
    /// @return A templates array representing the slice taken between the given indexes.
    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (Template[] memory)
    {
        if (_toIndex > templates.values.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        Template[] memory _templates = new Template[](_range);
        for (uint256 _i = 0; _i < _range; _i++)
            _templates[_i] = templates.values[_fromIndex + _i];
        return _templates;
    }
}
