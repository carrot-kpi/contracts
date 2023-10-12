pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager templates amount test
/// @dev Tests templates amount query in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerTemplatesAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        kpiTokensManager = initializeKPITokensManager(address(factory) /* , address(0) */ );
        assertEq(kpiTokensManager.templatesAmount(), 0);
    }

    function testOneTemplate() external {
        assertEq(kpiTokensManager.templatesAmount(), 1);
    }

    function testMultipleTemplates() external {
        kpiTokensManager.addTemplate(address(10), "a");
        kpiTokensManager.addTemplate(address(11), "b");
        kpiTokensManager.addTemplate(address(12), "c");
        assertEq(kpiTokensManager.templatesAmount(), 4);
    }
}
