pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

contract UpgradedOraclesManager is OraclesManager {
    function isUpgraded() external pure returns (bool) {
        return true;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager upgrade test
/// @dev Tests oracles manager upgrades.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerUpgradeTest is BaseTestSetup {
    function testNotOwner() external {
        OraclesManager _manager = initializeOraclesManager(address(1));
        address _pranked = address(999);
        vm.prank(_pranked); // prank to non owner
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        _manager.upgradeToAndCall(address(1234), abi.encode());
    }

    function testNonUUPSCompliantImplementationContract() external {
        OraclesManager _manager = initializeOraclesManager(address(1));
        vm.prank(_manager.owner());
        vm.expectRevert();
        _manager.upgradeToAndCall(address(1234), abi.encode());
    }

    function testSuccess() external {
        address _factory = address(1);
        OraclesManager _manager = initializeOraclesManager(_factory);
        assertEq(_manager.factory(), _factory);
        vm.expectRevert();
        UpgradedOraclesManager(address(_manager)).isUpgraded();

        vm.prank(_manager.owner());
        _manager.upgradeToAndCall(address(new UpgradedOraclesManager()), abi.encode());
        UpgradedOraclesManager _upgraded = UpgradedOraclesManager(address(_manager));
        assertTrue(_upgraded.isUpgraded());
    }
}
