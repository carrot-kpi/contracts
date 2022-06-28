pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager get template test
/// @dev Tests template query in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerGetTemplateTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.template(2);
    }

    function testSuccess() external {
        uint256 _templateId = 1;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertEq(_template.id, _templateId);
        assertEq(_template.addrezz, address(erc20KpiTokenTemplate));
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        assertEq(_template.specification, ERC20_KPI_TOKEN_SPECIFICATION);
    }
}
