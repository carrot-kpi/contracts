pragma solidity 0.8.19;

import {IKPITokensFactory} from "./interfaces/IKPITokensFactory.sol";
import {IKPITokensManager} from "./interfaces/IKPITokensManager.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";
import {InitializeKPITokenParams} from "./commons/Types.sol";
import {CarrotUpgradeable} from "./CarrotUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens factory
/// @dev The factory contract acts as an entry point for users wanting to
/// create a KPI token. Other utility view functions are included to query
/// the storage of the contract.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KPITokensFactory is CarrotUpgradeable, IKPITokensFactory {
    address public kpiTokensManager;
    address public oraclesManager;
    address public feeReceiver;
    mapping(address => bool) public allowOraclesCreation;
    address[] internal kpiTokens;

    error ZeroAddressKpiTokensManager();
    error ZeroAddressOraclesManager();
    error ZeroAddressFeeReceiver();
    error InvalidIndices();

    event CreateToken(address token);
    event SetKpiTokensManager(address kpiTokensManager);
    event SetOraclesManager(address oraclesManager);
    event SetFeeReceiver(address feeReceiver);

    /// @dev Initializes and sets up the KPI tokens factory with the input data.
    /// @param _kpiTokensManager The address of the KPI tokens manager to be used.
    /// @param _oraclesManager The address of the oracles manager to be used.
    /// @param _feeReceiver The address of the fee receiver to be used.
    function initialize(address _kpiTokensManager, address _oraclesManager, address _feeReceiver)
        external
        initializer
    {
        if (_kpiTokensManager == address(0)) {
            revert ZeroAddressKpiTokensManager();
        }
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();

        __CarrotUpgradeable_init();
        kpiTokensManager = _kpiTokensManager;
        oraclesManager = _oraclesManager;
        feeReceiver = _feeReceiver;
    }

    /// @dev Creates a KPI token with the input data.
    /// @param _id The id of the KPI token template to be used.
    /// @param _description An IPFS cid pointing to a file describing what the KPI token is about.
    /// @param _expiration A timestamp indicating the KPI token's expiration (avoids locked funds in case
    /// something happens to an oracle and it becomes unresponsive).
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the KPI token template
    /// to initialize its linked oracle(s).
    function createToken(
        uint256 _id,
        string calldata _description,
        uint256 _expiration,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external payable override returns (address) {
        (address _instance, uint128 _templateVersion) = IKPITokensManager(kpiTokensManager).instantiate(
            msg.sender, _id, _description, _expiration, _initializationData, _oraclesInitializationData
        );
        allowOraclesCreation[_instance] = true;
        IKPIToken(_instance).initialize{value: msg.value}(
            InitializeKPITokenParams({
                creator: msg.sender,
                oraclesManager: oraclesManager,
                kpiTokensManager: kpiTokensManager,
                feeReceiver: feeReceiver,
                kpiTokenTemplateId: _id,
                kpiTokenTemplateVersion: _templateVersion,
                description: _description,
                expiration: _expiration,
                kpiTokenData: _initializationData,
                oraclesData: _oraclesInitializationData
            })
        );
        allowOraclesCreation[_instance] = false;
        kpiTokens.push(_instance);

        emit CreateToken(_instance);

        return _instance;
    }

    /// @dev KPI tokens manager address setter. Can only be called by the contract owner.
    /// @param _kpiTokensManager The new KPI tokens manager address.
    function setKpiTokensManager(address _kpiTokensManager) external override onlyOwner {
        if (_kpiTokensManager == address(0)) {
            revert ZeroAddressKpiTokensManager();
        }
        kpiTokensManager = _kpiTokensManager;
        emit SetKpiTokensManager(_kpiTokensManager);
    }

    /// @dev Oracles manager address setter. Can only be called by the contract owner.
    /// @param _oraclesManager The new oracles manager address.
    function setOraclesManager(address _oraclesManager) external override onlyOwner {
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        oraclesManager = _oraclesManager;
        emit SetOraclesManager(_oraclesManager);
    }

    /// @dev Fee receiver address setter. Can only be called by the contract owner.
    /// @param _feeReceiver The new fee receiver address.
    function setFeeReceiver(address _feeReceiver) external override onlyOwner {
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        feeReceiver = _feeReceiver;
        emit SetFeeReceiver(_feeReceiver);
    }

    /// @dev Gets the amount of all created KPI tokens.
    /// @return The KPI tokens amount.
    function kpiTokensAmount() external view override returns (uint256) {
        return kpiTokens.length;
    }

    /// @dev Gets a KPI tokens slice based on indexes.
    /// @param _fromIndex The index from which to get KPI tokens (inclusive).
    /// @param _toIndex The maximum index to which to get KPI tokens (the element
    /// at this index won't be included).
    /// @return An address array representing the slice taken between the given indexes.
    function enumerate(uint256 _fromIndex, uint256 _toIndex) external view override returns (address[] memory) {
        if (_toIndex > kpiTokens.length || _fromIndex > _toIndex) {
            revert InvalidIndices();
        }
        uint256 _range = _toIndex - _fromIndex;
        address[] memory _kpiTokens = new address[](_range);
        for (uint256 _i = 0; _i < _range; _i++) {
            _kpiTokens[_i] = kpiTokens[_fromIndex + _i];
        }
        return _kpiTokens;
    }
}
