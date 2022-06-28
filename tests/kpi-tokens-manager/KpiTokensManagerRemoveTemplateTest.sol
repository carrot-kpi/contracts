pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import "forge-std/console.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager remove template test
/// @dev Tests template removal in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerRemoveTemplateTest is BaseTestSetup {
    using stdStorage for StdStorage;

    function testNonOwner() external {
        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        kpiTokensManager.removeTemplate(1);
    }

    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.removeTemplate(10);
    }

    function testSuccess() external {
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            1
        );
        assertEq(_template.id, 1);
        kpiTokensManager.removeTemplate(1);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.template(1);
    }
}
