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
    address public override owner;
    string public override description;
    bool public override finalized;
    uint256 public override expiration;
    uint256 public override creationTimestamp;
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

        owner = _owner;
        description = _description;
        expiration = _expiration;
        creationTimestamp = block.timestamp;
        kpiTokensManager = _kpiTokensManager;
        templateId = _templateId;
        templateVersion = _templateVersion;
    }

    /// @dev Transfers ownership of the KPI token. The owner is the one that has a claim
    /// over the unused, leftover collateral on finalization.
    /// @param _newOwner The new owner.
    function transferOwnership(address _newOwner) external override {
        if (_newOwner == address(0)) revert InvalidOwner();
        address _owner = owner;
        if (msg.sender != _owner) revert Forbidden();
        owner = _newOwner;
        emit OwnershipTransferred(_owner, _newOwner);
    }

    /// @dev Returns the KPI token's template as fetched from Carrot's KPI tokens manager,
    /// given the template's id and version.
    function template() external view override returns (Template memory) {
        return IBaseTemplatesManager(kpiTokensManager).template(templateId, templateVersion);
    }
}
