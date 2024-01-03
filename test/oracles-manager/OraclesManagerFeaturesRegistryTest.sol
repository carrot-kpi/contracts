pragma solidity 0.8.23;

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

    function testPauseFeatureFailureNoSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));

        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));

        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testPauseFeatureFailureWithSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        address _newOwner = address(3);
        _oraclesManagerHarness.setTemplateFeaturesOwner(_templateId, _newOwner);

        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));

        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testPauseFeatureSuccessNoSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));

        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);
        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testPauseFeatureSuccessWithSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        address _newOwner = address(3);
        _oraclesManagerHarness.setTemplateFeaturesOwner(_templateId, _newOwner);

        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));

        vm.prank(_newOwner);
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testUnpauseFeatureFailureNoSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);
        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));

        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        _oraclesManagerHarness.unpauseFeature(_templateId, _featureId);

        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testUnpauseFeatureFailureWithSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        address _newOwner = address(3);
        _oraclesManagerHarness.setTemplateFeaturesOwner(_templateId, _newOwner);
        vm.prank(_newOwner);
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));

        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        _oraclesManagerHarness.unpauseFeature(_templateId, _featureId);

        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testUnpauseFeatureSuccessNoSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
        _oraclesManagerHarness.unpauseFeature(_templateId, _featureId);
        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testUnpauseFeatureSuccessWithSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));
        address _newOwner = address(3);
        _oraclesManagerHarness.setTemplateFeaturesOwner(_templateId, _newOwner);
        vm.prank(_newOwner);
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        assertTrue(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));

        vm.prank(_newOwner);
        _oraclesManagerHarness.unpauseFeature(_templateId, _featureId);

        assertFalse(_oraclesManagerHarness.exposedFeaturePaused(_templateId, _featureId));
    }

    function testDisabledFeatureWhenPausedWithoutSpecificFeatureSetOwner() external {
        uint256 _templateId = 1;
        uint256 _featureId = 1;
        address _account = address(1991);

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));

        // start by enabling the feature for the target account
        assertFalse(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));
        _oraclesManagerHarness.enableTemplateFeatureFor(_templateId, _featureId, _account);
        assertTrue(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));

        // then pause the feature
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        // the allowance for the target user is still there, but when the feature is paused
        // isTemplateFeatureEnabledFor must return false
        assertFalse(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));

        // now unpause the feature
        _oraclesManagerHarness.unpauseFeature(_templateId, _featureId);

        // check that the allowance mapping state has always been there because the target
        // account should now be enabled again
        assertTrue(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));
    }

    function testDisabledFeatureWhenPausedWithSpecificFeatureSetOwner() external {
        // this test is the same as the above except for the fact that the
        // target feature set will have a specific owner

        uint256 _templateId = 1;
        uint256 _featureId = 1;
        address _account = address(1991);
        address _featureOwner = address(1997);

        OraclesManagerHarness _oraclesManagerHarness = initializeOraclesManagerHarness(owner, address(factory));

        // give ownership of the feature to the feature owner
        _oraclesManagerHarness.setTemplateFeaturesOwner(_templateId, _featureOwner);

        // start by enabling the feature for the target account (we do this in 2 steps,
        // with the first failing because of the fact that we're calling the function
        // using the manager's owner instead of the feature owner).
        assertFalse(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));
        vm.expectRevert(abi.encodeWithSelector(BaseTemplatesManager.Forbidden.selector));
        _oraclesManagerHarness.enableTemplateFeatureFor(_templateId, _featureId, _account);
        assertFalse(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));

        assertFalse(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));
        vm.prank(_featureOwner);
        _oraclesManagerHarness.enableTemplateFeatureFor(_templateId, _featureId, _account);
        assertTrue(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));

        // then pause the feature
        vm.prank(_featureOwner);
        _oraclesManagerHarness.pauseFeature(_templateId, _featureId);

        // the allowance for the target user is still there, but when the feature is paused
        // isTemplateFeatureEnabledFor must return false
        assertFalse(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));

        // now unpause the feature
        vm.prank(_featureOwner);
        _oraclesManagerHarness.unpauseFeature(_templateId, _featureId);

        // check that the allowance mapping state has always been there because the target
        // account should now be enabled again
        assertTrue(_oraclesManagerHarness.isTemplateFeatureEnabledFor(_templateId, _featureId, _account));
    }
}
