pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {IBaseTemplatesManager, Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager remove template test
/// @dev Tests template removal in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerRemoveTemplateTest is BaseTestSetup {
    using stdStorage for StdStorage;

    function testNonOwner() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        kpiTokensManager.removeTemplate(1);
    }

    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.removeTemplate(10);
    }

    function testMultipleDeletionSameId() external {
        assertEq(kpiTokensManager.templatesAmount(), 1);
        kpiTokensManager.removeTemplate(1);
        assertEq(kpiTokensManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.removeTemplate(1);
    }

    function testMultipleDeletionSameIdMultipleTemplate() external {
        kpiTokensManager.addTemplate(address(101), "1");
        kpiTokensManager.addTemplate(address(102), "2");
        kpiTokensManager.addTemplate(address(103), "3");
        assertEq(kpiTokensManager.templatesAmount(), 4);
        kpiTokensManager.removeTemplate(1);
        assertEq(kpiTokensManager.templatesAmount(), 3);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.removeTemplate(1);
    }

    function testSuccess() external {
        Template memory _template = kpiTokensManager.template(1);
        assertEq(_template.id, 1);
        kpiTokensManager.removeTemplate(1);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.template(1);
    }
}
