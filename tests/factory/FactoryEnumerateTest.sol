pragma solidity 0.8.17;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory enumerate test
/// @dev Tests KPI tokens enumeration.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract FactoryEnumerateTest is BaseTestSetup {
    function testNoTemplates() external {
        factory = new KPITokensFactory(address(1), address(2), address(3));
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        factory.enumerate(0, 1);
    }

    function testOneTemplateSuccess() external {
        createKpiToken("a", "a");
        assertEq(factory.enumerate(0, 1).length, 1);
    }

    function testMultipleTemplatesSuccess() external {
        createKpiToken("a", "a");
        createKpiToken("b", "b");
        createKpiToken("c", "c");
        createKpiToken("d", "d");
        createKpiToken("e", "e");
        createKpiToken("f", "f");
        createKpiToken("g", "g");
        createKpiToken("h", "h");
        createKpiToken("i", "i");
        createKpiToken("j", "j");
        assertEq(factory.enumerate(0, 10).length, 10);
    }

    function testInconsistentIndices() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        factory.enumerate(10, 5);
    }

    function testOneTemplateFail() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        factory.enumerate(0, 10);
    }
}
