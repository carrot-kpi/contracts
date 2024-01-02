pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {Template} from "../../contracts/BaseTemplatesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {KPITokensManagerHarness} from "../harnesses/KPITokensManagerHarness.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager update template specification test
/// @dev Tests template specification update in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerUpdateTemplateSpecificationTest is BaseTestSetup {
    function testNonOwner() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
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
        Template memory _template = kpiTokensManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.specification, _oldSpecification);
        string memory _newSpecification = "b";
        kpiTokensManager.updateTemplateSpecification(_templateId, _newSpecification);
        _template = kpiTokensManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.specification, _newSpecification);
    }

    function testNonOwnerSpecificVersion() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        kpiTokensManager.updateTemplateSpecification(0, 0, "");
    }

    function testNonExistentTemplateSpecificVersion() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.updateTemplateSpecification(0, 0, "a");
    }

    function testNonExistentVersionSpecificVersion() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        kpiTokensManager.updateTemplateSpecification(
            1,
            200, // non existent version
            "a"
        );
    }

    function testEmptySpecificationSpecificVersion() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        kpiTokensManager.updateTemplateSpecification(0, 1, "");
    }

    function testSuccessPastVersion() external {
        assertEq(kpiTokensManager.templatesAmount(), 1);

        string memory _oldSpecification = "a";
        kpiTokensManager.addTemplate(address(2), _oldSpecification);
        uint256 _templateId = kpiTokensManager.templatesAmount();
        Template memory _template = kpiTokensManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.version, 1);
        assertEq(_template.specification, _oldSpecification);

        // add an additional template to the set by upgrading
        string memory _upgradedSpecification = "b";
        kpiTokensManager.upgradeTemplate(_templateId, address(3), _upgradedSpecification);
        // templates amount is 2 because the test templates manager starts with
        // one template being present
        assertEq(kpiTokensManager.templatesAmount(), 2);
        Template memory _upgradedTemplate = kpiTokensManager.template(_templateId);
        assertEq(_upgradedTemplate.id, _templateId);
        assertEq(_upgradedTemplate.version, 2);
        assertEq(_upgradedTemplate.specification, _upgradedSpecification);

        string memory _newSpecification = "new";
        kpiTokensManager.updateTemplateSpecification(_templateId, 1, _newSpecification);
        Template memory _updatedTemplate = kpiTokensManager.template(_templateId, 1);
        Template memory _upgradedTemplatePostUpdate = kpiTokensManager.template(_templateId, 2);

        // check that the upgraded template was left unchanged
        assertEq(_upgradedTemplate.id, _upgradedTemplatePostUpdate.id);
        assertEq(_upgradedTemplate.version, _upgradedTemplatePostUpdate.version);
        assertEq(_upgradedTemplate.specification, _upgradedTemplatePostUpdate.specification);

        // check that the updated template was in fact updated
        assertEq(_updatedTemplate.id, 2);
        assertEq(_updatedTemplate.version, 1);
        assertEq(_updatedTemplate.specification, _newSpecification);
    }

    function testSuccessExplicitLatestVersion() external {
        ERC1967Proxy _proxy = new ERC1967Proxy(
            address(new KPITokensManagerHarness()),
            abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, owner, factory)
        );
        KPITokensManagerHarness kpiTokensManager = KPITokensManagerHarness(address(_proxy));

        assertEq(kpiTokensManager.templatesAmount(), 0);

        address _templateAddress = address(1);
        string memory _specification = "a";
        kpiTokensManager.addTemplate(_templateAddress, _specification);

        assertEq(kpiTokensManager.templatesAmount(), 1);

        Template memory _template = kpiTokensManager.template(1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.specification, _specification);

        string memory _newSpecification = "new";
        kpiTokensManager.updateTemplateSpecification(_template.id, _template.version, _newSpecification);

        // the harness function explicitly reads from the latest version
        // templates array
        Template memory _latestVersionTemplate = kpiTokensManager.exposedLatestVersionStorageTemplate(_template.id);
        assertEq(_latestVersionTemplate.specification, _newSpecification);

        // the template reading function operates on the template by id and
        // version array, so with the assertion above we check that both
        // templates were updated correctly.
        Template memory _templateByIdAndVersion = kpiTokensManager.template(_template.id, _template.version);
        assertEq(_templateByIdAndVersion.specification, _newSpecification);
    }
}
