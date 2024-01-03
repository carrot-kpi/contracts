pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager add template test
/// @dev Tests template addition in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerAddTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(_pranked))
        );
        kpiTokensManager.addTemplate(address(2), "");
    }

    function testZeroAddressTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressTemplate()"));
        kpiTokensManager.addTemplate(address(0), "");
    }

    function testEmptySpecification() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        kpiTokensManager.addTemplate(address(1), "");
    }

    function testSuccess() external {
        string memory _specification = "test";
        address _templateAddress = address(1);
        kpiTokensManager.addTemplate(_templateAddress, _specification);
        uint256 _addedTemplateId = kpiTokensManager.templatesAmount();
        Template memory _template = kpiTokensManager.template(_addedTemplateId);
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.version, 1);
        assertEq(_template.specification, _specification);
    }

    function testFuzzSuccess(address _templateAddress, string memory _specification) external {
        vm.assume(_templateAddress != address(0));
        vm.assume(bytes(_specification).length != 0);
        kpiTokensManager.addTemplate(_templateAddress, _specification);
        uint256 _addedTemplateId = kpiTokensManager.templatesAmount();
        Template memory _template = kpiTokensManager.template(_addedTemplateId);
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.version, 1);
        assertEq(_template.specification, _specification);
    }
}
