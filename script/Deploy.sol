pragma solidity 0.8.19;

import {OraclesManager} from "../contracts/OraclesManager.sol";
import {KPITokensManager} from "../contracts/KPITokensManager.sol";
import {KPITokensFactory} from "../contracts/KPITokensFactory.sol";
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../contracts/BaseTemplatesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Deploy
/// @dev Deploys the platform on a target network.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract Deploy is Script {
    function run(address _feeReceiver) external {
        vm.startBroadcast();

        KPITokensFactory _factory = KPITokensFactory(
            address(
                new ERC1967Proxy(address(new KPITokensFactory()), abi.encodeWithSelector(KPITokensFactory.initialize.selector, address(1),
                address(1),
                _feeReceiver))
            )
        );
        console2.log("Factory deployed at address: ", address(_factory));

        KPITokensManager _kpiTokensManager = KPITokensManager(
            address(
                new ERC1967Proxy(address(new KPITokensManager()), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, address(_factory)))
            )
        );
        console2.log("KPI tokens manager deployed at address: ", address(_kpiTokensManager));

        OraclesManager _oraclesManager = OraclesManager(
            address(
                new ERC1967Proxy(address(new OraclesManager()), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, address(_factory)))
            )
        );
        console2.log("Oracles manager deployed at address: ", address(_oraclesManager));

        _factory.setKpiTokensManager(address(_kpiTokensManager));
        _factory.setOraclesManager(address(_oraclesManager));

        vm.stopBroadcast();
    }
}
