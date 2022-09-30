pragma solidity 0.8.17;

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

        OraclesManager1 _oraclesManager = new OraclesManager1(
            address(_factory)
        );
        console2.log(
            "Oracles manager deployed at address: ",
            address(_oraclesManager)
        );

        _factory.setKpiTokensManager(address(_kpiTokensManager));
        _factory.setOraclesManager(address(_oraclesManager));

        vm.stopBroadcast();
    }
}
