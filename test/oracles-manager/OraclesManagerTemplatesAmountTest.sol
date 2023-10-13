pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager templates amount test
/// @dev Tests templates amount query in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerTemplatesAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        oraclesManager = initializeOraclesManager(address(factory));
        assertEq(oraclesManager.templatesAmount(), 0);
    }

    function testOneTemplate() external {
        oraclesManager = initializeOraclesManager(address(factory));
        oraclesManager.addTemplate(address(10), "a");
        assertEq(oraclesManager.templatesAmount(), 1);
    }

    function testMultipleTemplates() external {
        oraclesManager = initializeOraclesManager(address(factory));
        oraclesManager.addTemplate(address(10), "a");
        oraclesManager.addTemplate(address(11), "b");
        oraclesManager.addTemplate(address(12), "c");
        assertEq(oraclesManager.templatesAmount(), 3);
    }
}
