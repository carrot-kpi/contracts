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
/// @title Factory upgrade test
/// @dev Tests factory upgrades.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactoryUpgradeTest is BaseTestSetup {
    function testNotOwner() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        vm.prank(address(999)); // prank to non owner
        vm.expectRevert("Ownable: caller is not the owner");
        _factory.upgradeToAndCall(address(1234), abi.encode());
    }

    function testNonUUPSCompliantImplementationContract() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        vm.prank(_factory.owner());
        vm.expectRevert();
        _factory.upgradeToAndCall(address(1234), abi.encode());
    }

    function testSuccess() external {
        address _kpiTokensManager = address(1);
        address _oraclesManager = address(2);
        address _feeReceiver = address(3);
        KPITokensFactory _factory = initializeKPITokensFactory(_kpiTokensManager, _oraclesManager, _feeReceiver);
        assertEq(_factory.kpiTokensManager(), _kpiTokensManager);
        assertEq(_factory.oraclesManager(), _oraclesManager);
        assertEq(_factory.feeReceiver(), _feeReceiver);
        vm.expectRevert();
        UpgradedKPITokensFactory(address(_factory)).isUpgraded();

        vm.prank(_factory.owner());
        _factory.upgradeTo(address(new UpgradedKPITokensFactory()));
        UpgradedKPITokensFactory _upgraded = UpgradedKPITokensFactory(address(_factory));
        assertTrue(_upgraded.isUpgraded());
    }
}
