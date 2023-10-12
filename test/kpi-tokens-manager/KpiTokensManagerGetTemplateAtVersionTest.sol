pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {MockKPIToken} from "../mocks/MockKPIToken.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";

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
        assertEq(_template.addrezz, address(mockKpiTokenTemplate));
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.template(10); //non-existent version
    }

    function testSuccessOnAdd() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(1), feeReceiver);
        MockKPIToken _mockKpiTokenTemplate = new MockKPIToken();
        KPITokensManager _kpiTokensManager = initializeKPITokensManager(address(_factory));
        assertEq(_kpiTokensManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _kpiTokensManager.template(1);
        _kpiTokensManager.addTemplate(address(_mockKpiTokenTemplate), "asd");
        _template = _kpiTokensManager.template(1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);

        _template = _kpiTokensManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd");
    }

    function testSuccessOnUpgrade() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(1), feeReceiver);
        MockKPIToken _mockKpiTokenTemplate = new MockKPIToken();
        KPITokensManager _kpiTokensManager = initializeKPITokensManager(address(_factory));
        assertEq(_kpiTokensManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _kpiTokensManager.template(1);
        _kpiTokensManager.addTemplate(address(_mockKpiTokenTemplate), "asd1");
        _template = _kpiTokensManager.template(1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);

        _template = _kpiTokensManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        MockKPIToken _newMockKpiTokenTemplate = new MockKPIToken();
        _kpiTokensManager.upgradeTemplate(1, address(_newMockKpiTokenTemplate), "asd2");

        _template = _kpiTokensManager.template(1); // check current template updated
        assertEq(_template.addrezz, address(_newMockKpiTokenTemplate));
        assertEq(_template.version, 2);

        _template = _kpiTokensManager.template(1, 1); // fetch past template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        _template = _kpiTokensManager.template(1, 2); // fetch new template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_newMockKpiTokenTemplate));
        assertEq(_template.version, 2);
        assertEq(_template.specification, "asd2");
    }

    function testSuccessOnRemove() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(1), feeReceiver);
        MockKPIToken _mockKpiTokenTemplate = new MockKPIToken();
        KPITokensManager _kpiTokensManager = initializeKPITokensManager(address(_factory));
        assertEq(_kpiTokensManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _kpiTokensManager.template(1);
        _kpiTokensManager.addTemplate(address(_mockKpiTokenTemplate), "asd1");
        _template = _kpiTokensManager.template(1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);

        _template = _kpiTokensManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        // remove template
        _kpiTokensManager.removeTemplate(1);

        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        _template = _kpiTokensManager.template(1); // check deletion

        _template = _kpiTokensManager.template(1, 1); // fetch deleted template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockKpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");
    }
}
