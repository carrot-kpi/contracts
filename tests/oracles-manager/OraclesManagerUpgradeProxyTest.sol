pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {TransparentUpgradeableProxy} from "oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager upgrade proxy test
/// @dev Tests proxy upgrade in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerUpgradeProxyTest is BaseTestSetup {
    function testUpgrade() external {
        assertEq(
            oraclesManagerProxyAdmin.getProxyImplementation(
                TransparentUpgradeableProxy(payable(address(oraclesManager)))
            ),
            oraclesManagerImplementation
        );
        assertEq(
            oraclesManagerProxyAdmin.getProxyAdmin(
                TransparentUpgradeableProxy(payable(address(oraclesManager)))
            ),
            address(oraclesManagerProxyAdmin)
        );
        assertEq(oraclesManagerProxyAdmin.owner(), address(this));
        assertEq(oraclesManager.templatesAmount(), 1);
        address _newImplementation = address(new OraclesManager());
        assertTrue(oraclesManagerImplementation != _newImplementation);
        oraclesManagerProxyAdmin.upgrade(
            TransparentUpgradeableProxy(payable(address(oraclesManager))),
            _newImplementation
        );
        assertEq(
            oraclesManagerProxyAdmin.getProxyImplementation(
                TransparentUpgradeableProxy(payable(address(oraclesManager)))
            ),
            _newImplementation
        );
        assertEq(
            oraclesManagerProxyAdmin.getProxyAdmin(
                TransparentUpgradeableProxy(payable(address(oraclesManager)))
            ),
            address(oraclesManagerProxyAdmin)
        );
        assertEq(oraclesManagerProxyAdmin.owner(), address(this));
        address _newlySetImplementation = address(
            uint160(
                uint256(
                    vm.load(
                        address(oraclesManagerProxy),
                        bytes32(
                            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                        )
                    )
                )
            )
        );
        assertEq(_newlySetImplementation, _newImplementation);
        assertEq(oraclesManager.templatesAmount(), 1);
    }
}
