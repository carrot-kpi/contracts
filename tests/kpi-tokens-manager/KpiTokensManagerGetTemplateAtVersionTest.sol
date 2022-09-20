pragma solidity 0.8.17;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";
import {IKPITokensManager1} from "../../contracts/interfaces/kpi-tokens-managers/IKPITokensManager1.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {ERC20KPIToken} from "../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {KPITokensManager1} from "../../contracts/kpi-tokens-managers/KPITokensManager1.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager get template test
/// @dev Tests template query in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerGetTemplateAtVersionTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.template(2);
    }

    function testNonExistentVersion() external {
        Template memory _template = kpiTokensManager.template(1); // check that it doesn't fail
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(erc20KpiTokenTemplate));
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.template(10); //non-existent version
    }

    function testSuccessOnAdd() external {
        KPITokensFactory _factory = new KPITokensFactory(
            address(1),
            address(1),
            feeReceiver
        );
        ERC20KPIToken _erc20KpiTokenTemplate = new ERC20KPIToken();
        KPITokensManager1 _kpiTokensManager = new KPITokensManager1(
            address(_factory)
        );
        assertEq(_kpiTokensManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _kpiTokensManager.template(1);
        _kpiTokensManager.addTemplate(address(_erc20KpiTokenTemplate), "asd");
        _template = _kpiTokensManager.template(1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);

        _template = _kpiTokensManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd");
    }

    function testSuccessOnUpgrade() external {
        KPITokensFactory _factory = new KPITokensFactory(
            address(1),
            address(1),
            feeReceiver
        );
        ERC20KPIToken _erc20KpiTokenTemplate = new ERC20KPIToken();
        KPITokensManager1 _kpiTokensManager = new KPITokensManager1(
            address(_factory)
        );
        assertEq(_kpiTokensManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _kpiTokensManager.template(1);
        _kpiTokensManager.addTemplate(address(_erc20KpiTokenTemplate), "asd1");
        _template = _kpiTokensManager.template(1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);

        _template = _kpiTokensManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        ERC20KPIToken _newErc20KpiTokenTemplate = new ERC20KPIToken();
        _kpiTokensManager.upgradeTemplate(
            1,
            address(_newErc20KpiTokenTemplate),
            "asd2"
        );

        _template = _kpiTokensManager.template(1); // check current template updated
        assertEq(_template.addrezz, address(_newErc20KpiTokenTemplate));
        assertEq(_template.version, 2);

        _template = _kpiTokensManager.template(1, 1); // fetch past template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        _template = _kpiTokensManager.template(1, 2); // fetch new template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_newErc20KpiTokenTemplate));
        assertEq(_template.version, 2);
        assertEq(_template.specification, "asd2");
    }

    function testSuccessOnRemove() external {
        KPITokensFactory _factory = new KPITokensFactory(
            address(1),
            address(1),
            feeReceiver
        );
        ERC20KPIToken _erc20KpiTokenTemplate = new ERC20KPIToken();
        KPITokensManager1 _kpiTokensManager = new KPITokensManager1(
            address(_factory)
        );
        assertEq(_kpiTokensManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _kpiTokensManager.template(1);
        _kpiTokensManager.addTemplate(address(_erc20KpiTokenTemplate), "asd1");
        _template = _kpiTokensManager.template(1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);

        _template = _kpiTokensManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        // remove template
        _kpiTokensManager.removeTemplate(1);

        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        _template = _kpiTokensManager.template(1); // check deletion

        _template = _kpiTokensManager.template(1, 1); // fetch deleted template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_erc20KpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");
    }
}
