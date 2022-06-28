pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager update template specification test
/// @dev Tests template specification update in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerUpdateTemplateSpecificationTest is BaseTestSetup {
    function testNonOwner() external {
        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokensManager.updateTemplateSpecification(0, "");
    }

    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.updateTemplateSpecification(3, "a");
    }

    function testEmptySpecification() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        kpiTokensManager.updateTemplateSpecification(0, "");
    }

    function testSuccess() external {
        string memory _oldSpecification = "a";
        kpiTokensManager.addTemplate(address(2), _oldSpecification);
        uint256 _templateId = kpiTokensManager.templatesAmount();
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertEq(_template.id, _templateId);
        assertEq(_template.specification, _oldSpecification);
        string memory _newSpecification = "b";
        kpiTokensManager.updateTemplateSpecification(
            _templateId,
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.specification, _newSpecification);
    }
}
