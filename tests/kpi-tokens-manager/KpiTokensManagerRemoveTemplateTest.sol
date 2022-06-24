pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import "forge-std/console.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager remove template test
/// @dev Tests template removal in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerRemoveTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokensManager.removeTemplate(0);
    }

    function testNonExistentTemplate() external {
        vm.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        kpiTokensManager.removeTemplate(10);
    }

    function testSuccess() external {
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            0
        );
        assertTrue(_template.exists);
        kpiTokensManager.removeTemplate(0);
        vm.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        kpiTokensManager.template(0);
    }

    function testTemplateWithoutKey() external {
        console.log("WTF 1");
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            0
        );
        assertTrue(_template.exists);
        bytes32 _asd = vm.load(address(factory), bytes32(uint256(0)));
        console.log("WTF 2");
        // console2.log(_asd);
    }
}
