pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager templates amount test
/// @dev Tests templates amount query in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerTemplatesAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        oraclesManager = new OraclesManager();
        oraclesManager.initialize(address(factory));
        assertEq(oraclesManager.templatesAmount(), 0);
    }

    function testOneTemplate() external {
        assertEq(oraclesManager.templatesAmount(), 1);
    }

    function testMultipleTemplates() external {
        oraclesManager.addTemplate(address(10), false, "a");
        oraclesManager.addTemplate(address(11), false, "b");
        oraclesManager.addTemplate(address(12), false, "c");
        assertEq(oraclesManager.templatesAmount(), 4);
    }
}
