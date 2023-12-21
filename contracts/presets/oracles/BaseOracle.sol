pragma solidity >=0.8.0;

import {IBaseTemplatesManager, Template} from "../../interfaces/IBaseTemplatesManager.sol";
import {Initializable} from "oz-upgradeable/proxy/utils/Initializable.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title BaseOracle contract
/// @dev A base oracle preset that provides basic but functional
/// implementations for a set of Carrot oracle functions.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
abstract contract BaseOracle is IOracle, Initializable {
    bool public override finalized;
    address public override kpiToken;
    address internal oraclesManager;
    uint128 internal templateVersion;
    uint256 internal templateId;

    error ZeroAddressKPIToken();
    error InvalidTemplateId();
    error InvalidTemplateVersion();

    /// @dev Initializes the internal state of the preset, allowing it to provide
    /// basic but functional implementations for the most common Carrot oracle functions.
    /// This function can only be called while initializing an oracle instance. If you
    /// extend from this contract, make sure you call this, otherwise no state will be
    /// initialized.
    /// @param _kpiToken The attached KPI token address (used to initialize the base
    /// oracle preset).
    /// @param _templateId The oracle's template id (used to initialize the base
    /// oracle preset).
    /// @param _templateVersion The oracle's template version (used to initialize the base
    /// oracle preset).
    function __BaseOracle_init(address _kpiToken, uint256 _templateId, uint128 _templateVersion)
        internal
        onlyInitializing
    {
        if (_kpiToken == address(0)) revert ZeroAddressKPIToken();
        if (_templateId == 0) revert InvalidTemplateId();
        if (_templateVersion == 0) revert InvalidTemplateVersion();

        kpiToken = _kpiToken;
        oraclesManager = msg.sender;
        templateId = _templateId;
        templateVersion = _templateVersion;
    }

    /// @dev Returns the oracle's template as fetched from Carrot's oracles manager, given the
    /// template's id and version.
    function template() external view override returns (Template memory) {
        return IBaseTemplatesManager(oraclesManager).template(templateId, templateVersion);
    }

    /// @dev Queries the oracles template manager's feature registry to know if a custom feature
    /// of this oracle is enabled for a target account or not.
    /// @param _featureId The identifier of the queried custom feature.
    /// @param _account The target account.
    /// @return Whether the feature with the given identifier is enabled for the given account
    /// or not.
    function isFeatureEnabledFor(uint256 _featureId, address _account) internal view returns (bool) {
        return IBaseTemplatesManager(oraclesManager).isTemplateFeatureEnabledFor(templateId, _featureId, _account);
    }
}
