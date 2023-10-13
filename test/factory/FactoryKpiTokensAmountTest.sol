pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory KPI tokens amount test
/// @dev Tests KPI tokens enumeration.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactoryKpiTokensAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        factory = initializeKPITokensFactory(address(1), address(2), address(3));
        assertEq(factory.kpiTokensAmount(), 0);
    }

    function testOneTemplate() external {
        factory = initializeKPITokensFactory(address(1), address(1), address(this));
        kpiTokensManager = initializeKPITokensManager(address(factory));
        kpiTokensManager.addTemplate(address(mockKpiTokenTemplate), "fake");

        oraclesManager = initializeOraclesManager(address(factory));
        oraclesManager.addTemplate(address(mockOracleTemplate), "fake");

        factory.setKpiTokensManager(address(kpiTokensManager));
        factory.setOraclesManager(address(oraclesManager));
        factory.allowCreator(address(this));
        createKpiToken("asd");
        assertEq(factory.kpiTokensAmount(), 1);
    }

    function testMultipleTemplates() external {
        createKpiToken("a");
        createKpiToken("c");
        assertEq(factory.kpiTokensAmount(), 2);
    }
}
