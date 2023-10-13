pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager get template test
/// @dev Tests template query in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerGetTemplateTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.template(2);
    }

    function testSuccess() external {
        uint256 _templateId = 1;
        Template memory _template = kpiTokensManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.addrezz, address(mockKpiTokenTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, MOCK_KPI_TOKEN_SPECIFICATION);
    }
}
