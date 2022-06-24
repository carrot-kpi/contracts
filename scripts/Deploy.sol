pragma solidity 0.8.15;

import {Clones} from "oz/proxy/Clones.sol";
import {ERC20KPIToken} from "../contracts/kpi-tokens/ERC20KPIToken.sol";
import {ManualRealityOracle} from "../contracts/oracles/ManualRealityOracle.sol";
import {OraclesManager} from "../contracts/OraclesManager.sol";
import {KPITokensManager} from "../contracts/KPITokensManager.sol";
import {KPITokensFactory} from "../contracts/KPITokensFactory.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Deploy
/// @dev Deploys the platform on a target network.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract Deploy {
    event log_string(string);
    event log_address(address);
    event log_uint(uint256);

    CheatCodes internal immutable vm =
        CheatCodes(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    string internal constant ERC20_KPI_TOKEN_SPECIFICATION =
        "QmXU4G418hZLL8yxXdjkTFSoH2FdSe6ELgUuSm5fHHJMMN";
    string internal constant MANUAL_REALITY_ETH_ORACLE_SPECIFICATION =
        "QmRvoExBSESXedwqfC1cs4DGaRymnRR1wA9YGoZbqsE8Mf";

    error ZeroAddressFeeReceiver();

    function run(address _feeReceiver) external {
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();

        vm.startBroadcast();
        KPITokensFactory _factory = new KPITokensFactory(
            address(1),
            address(1),
            _feeReceiver
        );
        emit log_string("Factory deployed at address");
        emit log_address(address(_factory));

        KPITokensManager _kpiTokensManager = new KPITokensManager(
            address(_factory)
        );
        emit log_string("KPI tokens manager deployed at address");
        emit log_address(address(_kpiTokensManager));

        ERC20KPIToken _erc20KpiTokenTemplate = new ERC20KPIToken();
        emit log_string("ERC20 KPI token template deployed at address");
        emit log_address(address(_erc20KpiTokenTemplate));

        _kpiTokensManager.addTemplate(
            address(_erc20KpiTokenTemplate),
            ERC20_KPI_TOKEN_SPECIFICATION
        );

        OraclesManager _oraclesManager = new OraclesManager(address(_factory));
        emit log_string("Oracles manager deployed at address");
        emit log_address(address(_oraclesManager));

        ManualRealityOracle _manualRealityOracleTemplate = new ManualRealityOracle();
        emit log_string("Manual Reality oracle template deployed at address");
        emit log_address(address(_manualRealityOracleTemplate));

        _oraclesManager.addTemplate(
            address(_manualRealityOracleTemplate),
            false,
            MANUAL_REALITY_ETH_ORACLE_SPECIFICATION
        );

        _factory.setKpiTokensManager(address(_kpiTokensManager));
        _factory.setOraclesManager(address(_oraclesManager));

        vm.stopBroadcast();
    }
}
