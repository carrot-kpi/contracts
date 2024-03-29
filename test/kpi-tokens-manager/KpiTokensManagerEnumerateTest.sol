pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager templates enumeration test
/// @dev Tests template enumeration in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerEnumerateTest is BaseTestSetup {
    function testNoTemplates() external {
        kpiTokensManager = initializeKPITokensManager(address(factory));
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        kpiTokensManager.enumerateTemplates(0, 1);
    }

    function testOneTemplateSuccess() external {
        assertEq(kpiTokensManager.enumerateTemplates(0, 1).length, 1);
    }

    function testMultipleTemplatesSuccess() external {
        kpiTokensManager.addTemplate(address(10), "a");
        kpiTokensManager.addTemplate(address(11), "b");
        kpiTokensManager.addTemplate(address(12), "c");
        kpiTokensManager.addTemplate(address(12), "d");
        kpiTokensManager.addTemplate(address(12), "e");
        kpiTokensManager.addTemplate(address(12), "f");
        kpiTokensManager.addTemplate(address(12), "g");
        kpiTokensManager.addTemplate(address(12), "h");
        kpiTokensManager.addTemplate(address(12), "i");
        assertEq(kpiTokensManager.enumerateTemplates(0, 10).length, 10);
    }

    function testInconsistentIndices() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        kpiTokensManager.enumerateTemplates(10, 5);
    }

    function testOneTemplateFail() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        kpiTokensManager.enumerateTemplates(0, 10);
    }
}
