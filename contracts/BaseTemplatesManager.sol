pragma solidity 0.8.21;

import {Clones} from "oz/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/IKPIToken.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IBaseTemplatesManager, Template, TemplateFeatureSet, Feature} from "./interfaces/IBaseTemplatesManager.sol";
import {IKPITokensFactory} from "./interfaces/IKPITokensFactory.sol";
import {CarrotUpgradeable} from "./CarrotUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Base templates manager
/// @dev The base templates manager contract acts as a base registry
/// contract from which both oracles and KPI token manager contracts
/// extend. All template-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the templates manager.
/// The contract will keep track of all the versions of every template
/// and will keep history of even deleted/unactive templates.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
abstract contract BaseTemplatesManager is CarrotUpgradeable, IBaseTemplatesManager {
    address public override factory;
    uint256 internal templateId;
    Template[] internal latestVersionTemplates;
    mapping(uint256 => uint256) internal templateIdToLatestVersionIndex;
    mapping(uint256 => mapping(uint128 => Template)) internal templateByIdAndVersion;
    mapping(uint256 templateId => TemplateFeatureSet) internal featureSet;

    error Forbidden();
    error NonExistentTemplate();
    error ZeroAddressFactory();
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error InvalidIndices();

    event Initialize(address owner, address factory);
    event AddTemplate(uint256 indexed id, address indexed template, string specification);
    event RemoveTemplate(uint256 indexed id);
    event UpgradeTemplate(uint256 indexed id, address indexed newTemplate, uint256 newVersion, string newSpecification);
    event UpdateTemplateSpecification(uint256 indexed id, string newSpecification, uint256 version);
    event SetFeatureSetOwner(uint256 templateId, address owner);
    event EnableFeatureFor(uint256 templateId, uint256 featureId, address account);
    event DisableFeatureFor(uint256 templateId, uint256 featureId, address account);
    event PauseFeature(uint256 templateId, uint256 featureId);
    event UnpauseFeature(uint256 templateId, uint256 featureId);

    /// @dev Initializes and sets up the base templates manager with the input data.
    /// @param _factory The address of the KPI tokens factory to be used.
    function initialize(address _owner, address _factory) external initializer {
        if (_factory == address(0)) revert ZeroAddressFactory();

        emit Initialize(_owner, _factory);

        __CarrotUpgradeable_init(_owner);
        factory = _factory;
    }

    /// @dev Adds a template to the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _template The template's address.
    /// @param _specification An IPFS cid pointing to the template's specification.
    function addTemplate(address _template, string calldata _specification) external override onlyOwner {
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = ++templateId;
        Template memory _templateStruct =
            Template({id: _id, addrezz: _template, version: 1, specification: _specification});
        latestVersionTemplates.push(_templateStruct);
        templateIdToLatestVersionIndex[_id] = latestVersionTemplates.length;

        // save an immutable copy of the template at this initial version for
        // historical reasons
        templateByIdAndVersion[_id][1] = _templateStruct;
        emit AddTemplate(_id, _template, _specification);
    }

    /// @dev Removes a template from the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _id The id of the template that must be removed.
    function removeTemplate(uint256 _id) external override onlyOwner {
        uint256 _index = templateIdToLatestVersionIndex[_id];
        if (_index == 0) revert NonExistentTemplate();
        Template storage _lastLatestVersionTemplate = latestVersionTemplates[latestVersionTemplates.length - 1];
        if (_lastLatestVersionTemplate.id != _id) {
            latestVersionTemplates[_index - 1] = _lastLatestVersionTemplate;
            templateIdToLatestVersionIndex[_lastLatestVersionTemplate.id] = _index;
        }
        delete templateIdToLatestVersionIndex[_id];
        latestVersionTemplates.pop();
        emit RemoveTemplate(_id);
    }

    /// @dev Updates a template's latest version's specification. The specification
    /// is a cid pointing to a file containing data about the template.
    /// This function can only be called by the contract owner (governance).
    /// @param _id The template's id.
    /// @param _newSpecification the updated specification for the template with id `_id`.
    function updateTemplateSpecification(uint256 _id, string calldata _newSpecification) external override onlyOwner {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        uint128 _version = latestVersionStorageTemplate(_id).version;
        _updateTemplateSpecification(_id, _version, _newSpecification);
        emit UpdateTemplateSpecification(_id, _newSpecification, _version);
    }

    /// @dev Updates the specification of a template at a specific version.
    /// The specification is a cid pointing to a file containing data about
    /// the template. This function can only be called by the contract's
    /// owner (governance).
    /// @param _id The template's id.
    /// @param _version The version of the template we want to update.
    /// @param _newSpecification the updated specification for the template with id `_id`.
    function updateTemplateSpecification(uint256 _id, uint128 _version, string calldata _newSpecification)
        external
        override
        onlyOwner
    {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        _updateTemplateSpecification(_id, _version, _newSpecification);
        emit UpdateTemplateSpecification(_id, _newSpecification, _version);
    }

    /// @dev Internal implementation of the specification update function. It checks if the
    /// updated version is the latest one, and in case it is it updates the `latestVersionTemplates`
    /// array in addition to the `templateByIdAndVersion` one.
    /// @param _id The template's id.
    /// @param _version The version of the template we want to update.
    /// @param _newSpecification the updated specification for the template with id `_id`.
    function _updateTemplateSpecification(uint256 _id, uint128 _version, string calldata _newSpecification) internal {
        Template storage _latestVersionStorageTemplate = latestVersionStorageTemplate(_id);
        Template storage _templateByIdAndVersion = templateByIdAndVersion[_id][_version];
        if (_templateByIdAndVersion.addrezz == address(0)) {
            revert NonExistentTemplate();
        }
        if (_version == _latestVersionStorageTemplate.version) {
            _latestVersionStorageTemplate.specification = _newSpecification;
        }
        _templateByIdAndVersion.specification = _newSpecification;
    }

    /// @dev Upgrades a template. This function can only be called by the contract owner (governance).
    /// @param _id The id of the template that needs to be upgraded.
    /// @param _newTemplate The new address of the template.
    /// @param _newSpecification The updated specification for the upgraded template.
    function upgradeTemplate(uint256 _id, address _newTemplate, string calldata _newSpecification)
        external
        override
        onlyOwner
    {
        if (_newTemplate == address(0)) revert ZeroAddressTemplate();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        Template storage _latestVersionTemplateFromStorage = latestVersionStorageTemplate(_id);
        if (keccak256(bytes(_latestVersionTemplateFromStorage.specification)) == keccak256(bytes(_newSpecification))) {
            revert InvalidSpecification();
        }
        _latestVersionTemplateFromStorage.addrezz = _newTemplate;
        _latestVersionTemplateFromStorage.specification = _newSpecification;
        uint128 _updatedVersion = _latestVersionTemplateFromStorage.version + 1;
        _latestVersionTemplateFromStorage.version = _updatedVersion;

        templateByIdAndVersion[_id][_updatedVersion] =
            Template({id: _id, addrezz: _newTemplate, specification: _newSpecification, version: _updatedVersion});
        emit UpgradeTemplate(_id, _newTemplate, _updatedVersion, _newSpecification);
    }

    /// @dev Gets a storage pointer to the template, in its latest, most up
    /// to date version.
    /// @param _id The id of the template that needs to be fetched.
    /// @return A storage pointer to the template with id `_id` in its most
    /// up to date version.
    function latestVersionStorageTemplate(uint256 _id) internal view returns (Template storage) {
        if (_id == 0) revert NonExistentTemplate();
        uint256 _index = templateIdToLatestVersionIndex[_id];
        if (_index == 0) revert NonExistentTemplate();
        Template storage _template = latestVersionTemplates[_index - 1];
        return _template;
    }

    /// @dev Gives full features ownership to the target address for the given
    /// template. The target address will be able to enable and disable any
    /// of the targeted template's features for any given address.
    /// @param _templateId The id of the target template the features of which will be
    /// under the control of the new owner.
    /// @param _owner The address that will own the feature set for the specified
    /// template (this can be the 0 address to give ownership back to the overall
    /// manager owner).
    function setTemplateFeaturesOwner(uint256 _templateId, address _owner) external override onlyOwner {
        featureSet[_templateId].owner = _owner;
        emit SetFeatureSetOwner(_templateId, _owner);
    }

    /// @dev Enables a certain template feature for a given account. The caller must
    /// either be the specific template feature set owner or, if unspecified, the manager
    /// contract's owner.
    /// @param _templateId The id of the template on which the new feature allowance
    /// state will be applied.
    /// @param _featureId The unique id (internal to the targeted template) of the
    /// feature to enable for the target account.
    /// @param _account The account for which the feature should be enabled on the
    /// targeted template.
    function enableTemplateFeatureFor(uint256 _templateId, uint256 _featureId, address _account) external {
        _setFeatureAllowanceStateFor(_templateId, _featureId, _account, true);
        emit EnableFeatureFor(_templateId, _featureId, _account);
    }

    /// @dev Disables a certain template feature for a given account. The caller must
    /// either be the specific template feature set owner or, if unspecified, the manager
    /// contract's owner.
    /// @param _templateId The id of the template on which the new feature allowance
    /// state will be applied.
    /// @param _featureId The unique id (internal to the targeted template) of the
    /// feature to disable for the target account.
    /// @param _account The account for which the feature should be disabled on the
    /// targeted template.
    function disableTemplateFeatureFor(uint256 _templateId, uint256 _featureId, address _account) external {
        _setFeatureAllowanceStateFor(_templateId, _featureId, _account, false);
        emit DisableFeatureFor(_templateId, _featureId, _account);
    }

    /// @dev Pauses the given feature. When a feature is paused no one can use it until
    /// it's unpaused (i.e. all the `isTemplateFeatureEnabledFor` calls for the paused
    /// feature will return `false` for any account).
    /// @param _templateId The id of the template on which the feature needs to be paused.
    /// @param _featureId The unique id (internal to the targeted template) of the
    /// feature to pause.
    function pauseFeature(uint256 _templateId, uint256 _featureId) external {
        _setFeaturePausedState(_templateId, _featureId, true);
        emit PauseFeature(_templateId, _featureId);
    }

    /// @dev Unpauses the given feature. When a feature is unpaused the standard access
    /// list mechanism is again applied to it and only allowed accounts can access it.
    /// @param _templateId The id of the template on which the feature needs to be unpaused.
    /// @param _featureId The unique id (internal to the targeted template) of the
    /// feature to unpause.
    function unpauseFeature(uint256 _templateId, uint256 _featureId) external {
        _setFeaturePausedState(_templateId, _featureId, false);
        emit UnpauseFeature(_templateId, _featureId);
    }

    /// @dev Internal function to resolve the owner of a feature set. The owner can
    /// either be a zero or non-zero address. If it's a zero address, the manager
    /// contract's owner is returned, otherwise the output will be the original value.
    /// @param _templateId The id of the feature set template.
    /// @return The feature set owner
    function _featureSetOwner(uint256 _templateId) internal view returns (address) {
        address _setOwner = featureSet[_templateId].owner;
        return _setOwner == address(0) ? owner() : _setOwner;
    }

    /// @dev Internal implementation of the feature allowance update function.
    /// @param _templateId The id of the template on which the new feature allowance
    /// state will be applied.
    /// @param _featureId The unique id (internal to the targeted template) of the
    /// feature for which to change the allowance state for the target account.
    /// @param _account The account for which the feature's allowance state should be
    /// changed on the targeted template.
    /// @param _allowed The feature allowance state to apply.
    function _setFeatureAllowanceStateFor(uint256 _templateId, uint256 _featureId, address _account, bool _allowed)
        internal
    {
        if (msg.sender != _featureSetOwner(_templateId)) revert Forbidden();
        featureSet[_templateId].feature[_featureId].allowed[_account] = _allowed;
    }

    /// @dev Internal implementation of the feature paused state update function.
    /// @param _templateId The id of the template on which the new feature paused
    /// state will be applied.
    /// @param _featureId The unique id (internal to the targeted template) of the
    /// feature for which to change the paused state.
    /// @param _paused The feature paused state to apply.
    function _setFeaturePausedState(uint256 _templateId, uint256 _featureId, bool _paused) internal {
        if (msg.sender != _featureSetOwner(_templateId)) revert Forbidden();
        featureSet[_templateId].feature[_featureId].paused = _paused;
    }

    /// @dev Utility function to query the allowance state for a given template feature
    /// and account that wants to access it.
    /// @param _templateId The id of the template on which the feature allowance
    /// state should be queried.
    /// @param _featureId The unique id (internal to the targeted template) of the
    /// feature to get the allowance state for.
    /// @param _account The account for which to query the allowance state of the given
    /// feature on the given template.
    function isTemplateFeatureEnabledFor(uint256 _templateId, uint256 _featureId, address _account)
        external
        view
        override
        returns (bool)
    {
        Feature storage _feature = featureSet[_templateId].feature[_featureId];
        return !_feature.paused && _feature.allowed[_account];
    }

    /// @dev Gets a template by id. This only works on latest-version
    /// templates, so the latest version of the template with id `_id`
    /// will be returned. To check out old versions use
    /// `template(uint256 _id, uint128 _version)`.
    /// @param _id The id of the template that needs to be fetched.
    /// @return The template with id `_id`, at its latest, most up to
    /// date version.
    function template(uint256 _id) external view override returns (Template memory) {
        return latestVersionStorageTemplate(_id);
    }

    /// @dev Gets a template by id and version. Can be used to fetch
    /// old version templates to maximize transparency.
    /// @param _id The id of the template that needs to be fetched.
    /// @param _version The version at which the template should be fetched.
    /// @return The template with id `_id` at version `_version`.
    function template(uint256 _id, uint128 _version) external view override returns (Template memory) {
        if (_id == 0) revert NonExistentTemplate();
        Template memory _template = templateByIdAndVersion[_id][_version];
        if (_template.addrezz == address(0)) revert NonExistentTemplate();
        return _template;
    }

    /// @dev Used to determine whether a template with a certain id exists
    /// or not. This function checks existance on the latest version of each
    /// template. I.e. if a template existed in the past and got deleted, this
    /// will return false.
    /// @param _id The id of the template that needs to be checked.
    /// @return True if the template exists, false otherwise.
    function templateExists(uint256 _id) external view override returns (bool) {
        if (_id == 0) return false;
        uint256 _index = templateIdToLatestVersionIndex[_id];
        if (_index == 0) return false;
        return latestVersionTemplates[_index - 1].id == _id;
    }

    /// @dev Gets the amount of all registered templates. It works on the latest
    /// versions template array and accounts for deleted templates (they won't be counted).
    /// @return The templates amount.
    function templatesAmount() external view override returns (uint256) {
        return latestVersionTemplates.length;
    }

    /// @dev Gets the next template id, i.e. the id of the next template that will
    /// be added to the manager.
    /// @return The next template id.
    function nextTemplateId() external view override returns (uint256) {
        return templateId + 1;
    }

    /// @dev Gets a templates slice off of the latest version templates array based
    /// on indexes. N.B.: the templates are not ordered and due to how templates are
    /// removed, it could happen to have 2 disjointed slices with the same template
    /// being in both, even though it should be rare.
    /// @param _fromIndex The index from which to get templates (inclusive).
    /// @param _toIndex The maximum index to which to get templates (the element at this index won't be included).
    /// @return A templates array representing the slice taken through the given indexes.
    function enumerateTemplates(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (Template[] memory)
    {
        if (_toIndex > latestVersionTemplates.length || _fromIndex > _toIndex) {
            revert InvalidIndices();
        }
        uint256 _range = _toIndex - _fromIndex;
        Template[] memory _templates = new Template[](_range);
        for (uint256 _i = 0; _i < _range; _i++) {
            _templates[_i] = latestVersionTemplates[_fromIndex + _i];
        }
        return _templates;
    }
}
