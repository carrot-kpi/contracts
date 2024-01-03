pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager remove template test
/// @dev Tests template removal in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerRemoveTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        oraclesManager.removeTemplate(1);
    }

    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.removeTemplate(10);
    }

    function testSuccess() external {
        Template memory _template = oraclesManager.template(1);
        assertEq(_template.id, 1);
        oraclesManager.removeTemplate(1);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.template(1);
    }
}
