pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

contract UpgradedKPITokensFactory is KPITokensFactory {
    function isUpgraded() external pure returns (bool) {
        return true;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens factory make immutable test
/// @dev Tests KPI tokens factory immutability setting.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KPITokensFactoryMakeImmutableTest is BaseTestSetup {
    function testNotOwner() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        address _pranked = address(999);
        vm.prank(_pranked); // prank to non owner
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(_pranked))
        );
        _factory.makeImmutable();
    }

    function testSuccess() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        assertFalse(_factory.disallowUpgrades());
        vm.prank(_factory.owner());
        _factory.makeImmutable();
        assertTrue(_factory.disallowUpgrades());
        UpgradedKPITokensFactory _upgraded = new UpgradedKPITokensFactory();
        vm.expectRevert(abi.encodeWithSignature("Immutable()"));
        _factory.upgradeToAndCall(address(_upgraded), abi.encode(""));
    }
}
