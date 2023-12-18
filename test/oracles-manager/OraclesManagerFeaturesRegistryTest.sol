pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";
import {Initializable} from "oz/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";
import {OraclesManagerHarness} from "../harnesses/OraclesManagerHarness.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager features registry test
/// @dev Tests the features registry feature of the oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerFeaturesRegistryTest is BaseTestSetup {
    function testSetFeatureSetOwnerNotOwner() external {
        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(123)));
        oraclesManager.setTemplateFeaturesOwner(1, address(3));
    }

    function testSetFeatureSetOwnerSuccessNonExistentTemplateFeatureSet() external {
        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        address _newOwner = address(3);
        _oraclesManagerHarness.setTemplateFeaturesOwner(1, _newOwner);
        assertEq(_oraclesManagerHarness.exposedFeatureSetOwner(1), _newOwner);
    }

    function testSetFeatureSetOwnerSuccessAlreadyExistentTemplateFeatureSet() external {
        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        // this creates the feature set
        _oraclesManagerHarness.enableTemplateFeatureFor(1, 1, address(1));
        assertEq(_oraclesManagerHarness.exposedFeatureSetOwner(1), address(0));

        address _newOwner = address(3);
        _oraclesManagerHarness.setTemplateFeaturesOwner(1, _newOwner);
        assertEq(_oraclesManagerHarness.exposedFeatureSetOwner(1), _newOwner);
    }

    function testEnableFeatureForSuccessWithNoSpecificFeatureSetOwner() external {
        address _targetAccount = address(5);
        oraclesManager.enableTemplateFeatureFor(1, 1, _targetAccount);
        assertTrue(oraclesManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));
    }

    function testEnableFeatureForSuccessWithNonStandardFeatureSetOwner() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        oraclesManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        address _targetAccount = address(142);
        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        oraclesManager.enableTemplateFeatureFor(_templateId, 1, _targetAccount);
    }

    function testEnableFeatureForSuccessWithNonStandardFeatureSetOwnerSuccess() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        oraclesManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        address _targetAccount = address(142);
        assertFalse(oraclesManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
        vm.prank(_featureOwner);
        oraclesManager.enableTemplateFeatureFor(_templateId, 1, _targetAccount);
        assertTrue(oraclesManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
    }

    function testDisableFeatureForSuccessWithNoSpecificFeatureSetOwner() external {
        address _targetAccount = address(5);
        assertFalse(oraclesManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));
        // enable the feature in order to disable it later
        oraclesManager.enableTemplateFeatureFor(1, 1, _targetAccount);
        assertTrue(oraclesManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));

        oraclesManager.disableTemplateFeatureFor(1, 1, _targetAccount);
        assertFalse(oraclesManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));
    }

    function testDisableFeatureForSuccessWithNonStandardFeatureSetOwner() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        oraclesManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        address _targetAccount = address(142);
        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        oraclesManager.disableTemplateFeatureFor(_templateId, 1, _targetAccount);
    }

    function testDisableFeatureForSuccessWithNonStandardFeatureSetOwnerSuccess() external {
        uint256 _templateId = 1;
        address _featureOwner = address(1);
        address _targetAccount = address(142);
        // enable the feature in order to disable it later
        oraclesManager.enableTemplateFeatureFor(1, 1, _targetAccount);
        assertTrue(oraclesManager.isTemplateFeatureEnabledFor(1, 1, _targetAccount));

        // transfer ownership
        oraclesManager.setTemplateFeaturesOwner(_templateId, _featureOwner);

        assertTrue(oraclesManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
        vm.prank(_featureOwner);
        oraclesManager.disableTemplateFeatureFor(_templateId, 1, _targetAccount);
        assertFalse(oraclesManager.isTemplateFeatureEnabledFor(_templateId, 1, _targetAccount));
    }
}
