pragma solidity 0.8.17;

import {Clones} from "oz/proxy/Clones.sol";
import {TransparentUpgradeableProxy} from "oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "oz/proxy/transparent/ProxyAdmin.sol";
import {ERC20KPIToken} from "../contracts/kpi-tokens/ERC20KPIToken.sol";
import {RealityV3Oracle} from "../contracts/oracles/RealityV3Oracle.sol";
import {OraclesManager1} from "../contracts/oracles-managers/OraclesManager1.sol";
import {KPITokensManager1} from "../contracts/kpi-tokens-managers/KPITokensManager1.sol";
import {KPITokensFactory} from "../contracts/KPITokensFactory.sol";
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Deploy
/// @dev Deploys the platform on a target network.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract Deploy is Script {
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
        console2.log("Factory deployed at address: ", address(_factory));

        KPITokensManager1 _kpiTokensManager = new KPITokensManager1(
            address(_factory)
        );
        console2.log(
            "KPI tokens manager deployed at address: ",
            address(_kpiTokensManager)
        );

        ERC20KPIToken _erc20KpiTokenTemplate = new ERC20KPIToken();
        console2.log(
            "ERC20 KPI token template deployed at address: ",
            address(_erc20KpiTokenTemplate)
        );

        _kpiTokensManager.addTemplate(
            address(_erc20KpiTokenTemplate),
            ERC20_KPI_TOKEN_SPECIFICATION
        );

        OraclesManager1 _oraclesManager = new OraclesManager1(
            address(_factory)
        );
        console2.log(
            "Oracles manager deployed at address: ",
            address(_oraclesManager)
        );

        RealityV3Oracle _realityV3OracleTemplate = new RealityV3Oracle();
        console2.log(
            "Manual Reality oracle template deployed at address: ",
            address(_realityV3OracleTemplate)
        );

        _oraclesManager.addTemplate(
            address(_realityV3OracleTemplate),
            MANUAL_REALITY_ETH_ORACLE_SPECIFICATION
        );

        _factory.setKpiTokensManager(address(_kpiTokensManager));
        _factory.setOraclesManager(address(_oraclesManager));

        vm.stopBroadcast();
    }
}
