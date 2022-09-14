pragma solidity 0.8.17;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {ERC20KPIToken} from "../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {KPITokensManager1} from "../../contracts/kpi-tokens-managers/KPITokensManager1.sol";
import {RealityV3Oracle} from "../../contracts/oracles/RealityV3Oracle.sol";
import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory KPI tokens amount test
/// @dev Tests KPI tokens enumeration.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract FactoryKpiTokensAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        factory = new KPITokensFactory(address(1), address(2), address(3));
        assertEq(factory.kpiTokensAmount(), 0);
    }

    function testOneTemplate() external {
        factory = new KPITokensFactory(address(1), address(1), address(this));
        kpiTokensManager = new KPITokensManager1(address(factory));
        kpiTokensManager.addTemplate(
            address(erc20KpiTokenTemplate),
            ERC20_KPI_TOKEN_SPECIFICATION
        );

        realityV3OracleTemplate = new RealityV3Oracle();
        oraclesManager = new OraclesManager1(address(factory));
        oraclesManager.addTemplate(
            address(realityV3OracleTemplate),
            MANUAL_REALITY_ETH_SPECIFICATION
        );

        factory.setKpiTokensManager(address(kpiTokensManager));
        factory.setOraclesManager(address(oraclesManager));
        createKpiToken("asd", "dsa");
        assertEq(factory.kpiTokensAmount(), 1);
    }

    function testMultipleTemplates() external {
        createKpiToken("a", "b");
        createKpiToken("c", "d");
        assertEq(factory.kpiTokensAmount(), 2);
    }
}
