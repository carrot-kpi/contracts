pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager upgrade template test
/// @dev Tests template upgrade in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerUpgradeTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokensManager.upgradeTemplate(1, address(1), uint8(0), "");
    }

    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.upgradeTemplate(2, address(1), uint8(0), "a");
    }

    function testEmptySpecification() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        kpiTokensManager.upgradeTemplate(1, address(1), uint8(0), "");
    }

    function testSameSpecification() external {
        uint256 _templateId = 1;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        kpiTokensManager.upgradeTemplate(
            _templateId,
            address(1),
            uint8(0),
            _template.specification
        );
    }

    function testInvalidVersionBump() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidVersionBump()"));
        kpiTokensManager.upgradeTemplate(1, address(1), uint8(8), "a");
    }

    function testSuccessPatchBump() external {
        uint256 _templateId = 1;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        kpiTokensManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(1),
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 1);
    }

    function testSuccessMinorBump() external {
        uint256 _templateId = 1;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        kpiTokensManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(2),
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 1);
        assertEq(_template.version.patch, 0);
    }

    function testSuccessMajorBump() external {
        uint256 _templateId = 1;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        kpiTokensManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(4),
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 2);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
    }
}
