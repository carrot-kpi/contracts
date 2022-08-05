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
        oraclesManager = new OraclesManager(address(factory));
        vm.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        oraclesManager.enumerate(0, 1);
    }

    function testOneTemplateSuccess() external {
        assertEq(oraclesManager.enumerate(0, 1).length, 1);
    }

    function testMultipleTemplatesSuccess() external {
        oraclesManager.addTemplate(address(10), "a");
        oraclesManager.addTemplate(address(11), "b");
        oraclesManager.addTemplate(address(12), "c");
        oraclesManager.addTemplate(address(12), "d");
        oraclesManager.addTemplate(address(12), "e");
        oraclesManager.addTemplate(address(12), "f");
        oraclesManager.addTemplate(address(12), "g");
        oraclesManager.addTemplate(address(12), "h");
        oraclesManager.addTemplate(address(12), "i");
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
