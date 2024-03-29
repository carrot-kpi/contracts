pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory set oracles manager test
/// @dev Tests factory setter for oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactorySetOraclesManagerTest is BaseTestSetup {
    function testNonOwner() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        factory.setOraclesManager(address(2));
    }

    function testZeroAddressManager() external {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressOraclesManager()"));
        factory.setOraclesManager(address(0));
    }

    function testSuccess() external {
        assertEq(factory.oraclesManager(), address(oraclesManager));
        address _newOraclesManager = address(2);
        factory.setOraclesManager(_newOraclesManager);
        assertEq(factory.oraclesManager(), _newOraclesManager);
    }
}
