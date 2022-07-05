pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager templates enumeration test
/// @dev Tests template enumeration in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerEnumerateTest is BaseTestSetup {
    function testNoTemplates() external {
        oraclesManager = new OraclesManager();
        oraclesManager.initialize(address(factory));
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        oraclesManager.enumerate(0, 1);
    }

    function testOneTemplateSuccess() external {
        assertEq(oraclesManager.enumerate(0, 1).length, 1);
    }

    function testMultipleTemplatesSuccess() external {
        oraclesManager.addTemplate(address(10), false, "a");
        oraclesManager.addTemplate(address(11), false, "b");
        oraclesManager.addTemplate(address(12), false, "c");
        oraclesManager.addTemplate(address(12), false, "d");
        oraclesManager.addTemplate(address(12), false, "e");
        oraclesManager.addTemplate(address(12), false, "f");
        oraclesManager.addTemplate(address(12), false, "g");
        oraclesManager.addTemplate(address(12), false, "h");
        oraclesManager.addTemplate(address(12), false, "i");
        assertEq(oraclesManager.enumerate(0, 10).length, 10);
    }

    function testInconsistentIndices() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        oraclesManager.enumerate(10, 5);
    }

    function testOneTemplateFail() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        oraclesManager.enumerate(0, 10);
    }
}
