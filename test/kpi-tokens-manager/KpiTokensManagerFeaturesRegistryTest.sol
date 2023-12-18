pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";
import {Initializable} from "oz/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";
import {KPITokensManagerHarness} from "../harnesses/KPITokensManagerHarness.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager features registry test
/// @dev Tests the features registry feature of the KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KPITokensManagerFeaturesRegistryTest is BaseTestSetup {
    function testSetFeatureSetOwnerNotOwner() external {
        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(123)));
        kpiTokensManager.setTemplateFeaturesOwner(1, address(3));
    }

    function testSetFeatureSetOwnerSuccessNonExistentTemplateFeatureSet() external {
        KPITokensManagerHarness _kpiTokensManagerHarness = initializeKPITokensManagerHarness(owner, address(factory));
        address _newOwner = address(3);
        _kpiTokensManagerHarness.setTemplateFeaturesOwner(1, _newOwner);
        assertEq(_kpiTokensManagerHarness.exposedFeatureSetOwner(1), _newOwner);
    }

    function testSetFeatureSetOwnerSuccessAlreadyExistentTemplateFeatureSet() external {
        KPITokensManagerHarness _kpiTokensManagerHarness = initializeKPITokensManagerHarness(owner, address(factory));
        // this creates the feature set
        _kpiTokensManagerHarness.enableTemplateFeatureFor(1, 1, address(1));
        assertEq(_kpiTokensManagerHarness.exposedFeatureSetOwner(1), address(0));

        address _newOwner = address(3);
        _kpiTokensManagerHarness.setTemplateFeaturesOwner(1, _newOwner);
        assertEq(_kpiTokensManagerHarness.exposedFeatureSetOwner(1), _newOwner);
    }

    function testEnableFeatureForSuccessWithNoSpecificFeatureSetOwner() external {
        address _targetAccount = address(5);
        kpiTokensManager.enableTemplateFeatureFor(1, 1, _targetAccount);
        assertTrue(kpiTokensManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));
    }

    function testEnableFeatureForSuccessWithNonStandardFeatureSetOwner() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        kpiTokensManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        address _targetAccount = address(142);
        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        kpiTokensManager.enableTemplateFeatureFor(_templateId, 1, _targetAccount);
    }

    function testEnableFeatureForSuccessWithNonStandardFeatureSetOwnerSuccess() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        kpiTokensManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        address _targetAccount = address(142);
        assertFalse(kpiTokensManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
        vm.prank(_featureOwner);
        kpiTokensManager.enableTemplateFeatureFor(_templateId, 1, _targetAccount);
        assertTrue(kpiTokensManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
    }

    function testDisableFeatureForSuccessWithNoSpecificFeatureSetOwner() external {
        address _targetAccount = address(5);
        assertFalse(kpiTokensManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));
        // enable the feature in order to disable it later
        kpiTokensManager.enableTemplateFeatureFor(1, 1, _targetAccount);
        assertTrue(kpiTokensManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));

        kpiTokensManager.disableTemplateFeatureFor(1, 1, _targetAccount);
        assertFalse(kpiTokensManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));
    }

    function testDisableFeatureForSuccessWithNonStandardFeatureSetOwner() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        kpiTokensManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        address _targetAccount = address(142);
        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        kpiTokensManager.disableTemplateFeatureFor(_templateId, 1, _targetAccount);
    }

    function testDisableFeatureForSuccessWithNonStandardFeatureSetOwnerSuccess() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        address _targetAccount = address(142);
        // enable the feature in order to disable it later
        kpiTokensManager.enableTemplateFeatureFor(1, 1, _targetAccount);
        assertTrue(kpiTokensManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));

        // transfer ownership
        kpiTokensManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        assertTrue(kpiTokensManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
        vm.prank(_featureOwner);
        kpiTokensManager.disableTemplateFeatureFor(_templateId, 1, _targetAccount);
        assertFalse(kpiTokensManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
    }
}
