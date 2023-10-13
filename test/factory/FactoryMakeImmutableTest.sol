pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

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
        vm.prank(address(999)); // prank to non owner
        vm.expectRevert("Ownable: caller is not the owner");
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
        _factory.upgradeTo(address(_upgraded));
    }
}
