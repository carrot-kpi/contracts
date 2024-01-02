pragma solidity >=0.8.0;

import {IBaseTemplatesManager, Template} from "../../interfaces/IBaseTemplatesManager.sol";
import {Initializable} from "oz-upgradeable/proxy/utils/Initializable.sol";
import {IKPIToken} from "../../interfaces/IKPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title BaseKPIToken contract
/// @dev A base KPI token preset that provides basic but functional
/// implementations for a set of Carrot KPI token functions.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
abstract contract BaseKPIToken is IKPIToken, Initializable {
    address internal internalOwner;
    string internal internalDescription;
    uint256 internal internalExpiration;
    uint256 internal internalCreationTimestamp;
    address internal kpiTokensManager;
    uint128 internal templateVersion;
    uint256 internal templateId;

    error InvalidOwner();
    error InvalidKPITokensManager();
    error InvalidTemplateId();
    error InvalidTemplateVersion();
    error InvalidDescription();
    error InvalidExpiration();
    error Forbidden();

    /// @dev Initializes the internal state of the preset, allowing it to provide
    /// basic but functional implementations for the most common Carrot KPI token functions.
    /// This function can only be called while initializing a KPI token instance. If you
    /// extend from this contract, make sure you call this, otherwise no state will be
    /// initialized.
    /// @param _owner The address of the KPI token owner.
    /// @param _description The description of the KPI token.
    /// @param _expiration The expiration timestamp of the KPI token.
    /// @param _kpiTokensManager The KPI tokens manager address.
    /// @param _templateId The KPI token's template id.
    /// @param _templateVersion The KPI token's template version.
    function __BaseKPIToken_init(
        address _owner,
        string memory _description,
        uint256 _expiration,
        address _kpiTokensManager,
        uint256 _templateId,
        uint128 _templateVersion
    ) internal onlyInitializing {
        if (_owner == address(0)) revert InvalidOwner();
        if (bytes(_description).length == 0) revert InvalidDescription();
        if (_expiration <= block.timestamp) revert InvalidExpiration();
        if (_kpiTokensManager == address(0)) revert InvalidKPITokensManager();
        if (_templateId == 0) revert InvalidTemplateId();
        if (_templateVersion == 0) revert InvalidTemplateVersion();

        internalOwner = _owner;
        internalDescription = _description;
        internalExpiration = _expiration;
        internalCreationTimestamp = block.timestamp;
        kpiTokensManager = _kpiTokensManager;
        templateId = _templateId;
        templateVersion = _templateVersion;
    }

    /// @dev Transfers ownership of the KPI token. The owner is the one that has a claim
    /// over the unused, leftover collateral on finalization.
    /// @param _newOwner The new owner.
    function transferOwnership(address _newOwner) external override {
        if (_newOwner == address(0)) revert InvalidOwner();
        address _owner = internalOwner;
        if (msg.sender != _owner) revert Forbidden();
        internalOwner = _newOwner;
        emit OwnershipTransferred(_owner, _newOwner);
    }

    /// @dev Returns the KPI token's owner.
    function owner() external view virtual override returns (address) {
        return internalOwner;
    }

    /// @dev Returns the KPI token's description.
    function description() external view virtual override returns (string memory) {
        return internalDescription;
    }

    /// @dev Returns the KPI token's expiration.
    function expiration() external view virtual override returns (uint256) {
        return internalExpiration;
    }

    /// @dev Returns the KPI token's creation timestamp.
    function creationTimestamp() external view virtual override returns (uint256) {
        return internalCreationTimestamp;
    }

    /// @dev Returns the KPI token's template as fetched from Carrot's KPI tokens manager,
    /// given the template's id and version.
    function template() external view override returns (Template memory) {
        return IBaseTemplatesManager(kpiTokensManager).template(templateId, templateVersion);
    }

    /// @dev Queries the KPI tokens template manager's feature registry to know if a custom feature
    /// of this KPI token is enabled for a target account or not.
    /// @param _featureId The identifier of the queried custom feature.
    /// @param _account The target account.
    /// @return Whether the feature with the given identifier is enabled for the given account
    /// or not.
    function isFeatureEnabledFor(uint256 _featureId, address _account) internal view returns (bool) {
        return IBaseTemplatesManager(kpiTokensManager).isTemplateFeatureEnabledFor(templateId, _featureId, _account);
    }
}
