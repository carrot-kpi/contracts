pragma solidity 0.8.21;

import {OraclesManager} from "../contracts/OraclesManager.sol";
import {KPITokensManager} from "../contracts/KPITokensManager.sol";
import {KPITokensFactory} from "../contracts/KPITokensFactory.sol";
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../contracts/BaseTemplatesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Deploy
/// @dev Deploys the protocol on a target network.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract Deploy is Script {
    function run(address _owner, address _feeReceiver) external {
        vm.startBroadcast();

        address _kpiTokensManagerImplementationAddress = address(new KPITokensManager());
        address _oraclesManagerImplementationAddress = address(new OraclesManager());
        address _factoryImplementationAddress = address(new KPITokensFactory());

        uint256 _initialNonce = vm.getNonce(msg.sender);

        address _predictedKPITokensManagerAddress = computeCreateAddress(msg.sender, _initialNonce + 1);
        address _predictedOraclesManagerAddress = computeCreateAddress(msg.sender, _initialNonce + 2);

        address _factoryAddress = address(
            new ERC1967Proxy(
                _factoryImplementationAddress,
                abi.encodeWithSelector(
                    KPITokensFactory.initialize.selector,
                    _owner,
                    _predictedKPITokensManagerAddress,
                    _predictedOraclesManagerAddress,
                    _feeReceiver
                )
            )
        );

        address _kpiTokensManagerAddress = address(
            new ERC1967Proxy(
                _kpiTokensManagerImplementationAddress,
                abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, _owner, _factoryAddress)
            )
        );

        address _oraclesManagerAddress = address(
            new ERC1967Proxy(
                _oraclesManagerImplementationAddress,
                abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, _owner, _factoryAddress)
            )
        );

        if (_predictedKPITokensManagerAddress != _kpiTokensManagerAddress) {
            console2.log("Wrong KPI tokens manager predicted address");
            revert();
        }
        if (_predictedOraclesManagerAddress != _oraclesManagerAddress) {
            console2.log("Wrong oracles manager predicted address");
            revert();
        }

        console2.log("Factory address:", _factoryAddress);
        console2.log("KPI tokens manager address:", _kpiTokensManagerAddress);
        console2.log("Oracles manager address:", _oraclesManagerAddress);

        vm.stopBroadcast();
    }
}
