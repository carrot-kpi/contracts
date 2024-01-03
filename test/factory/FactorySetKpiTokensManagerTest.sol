pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory set KPI tokens manager test
/// @dev Tests factory setter for the KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactorySetKpiTokensManagerTest is BaseTestSetup {
    function testNonOwner() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(_pranked))
        );
        factory.setKpiTokensManager(address(2));
    }

    function testZeroAddressManager() external {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressKpiTokensManager()"));
        factory.setKpiTokensManager(address(0));
    }

    function testSuccess() external {
        assertEq(factory.kpiTokensManager(), address(kpiTokensManager));
        address _newKpiTokensManager = address(2);
        factory.setKpiTokensManager(_newKpiTokensManager);
        assertEq(factory.kpiTokensManager(), _newKpiTokensManager);
    }
}
