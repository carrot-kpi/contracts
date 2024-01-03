pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager add template test
/// @dev Tests template addition in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerAddTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(1)));
        oraclesManager.addTemplate(address(2), "");
    }

    function testZeroAddressTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressTemplate()"));
        oraclesManager.addTemplate(address(0), "");
    }

    function testEmptySpecification() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        oraclesManager.addTemplate(address(1), "");
    }

    function testSuccess() external {
        string memory _specification = "test";
        address _templateAddress = address(1);
        oraclesManager.addTemplate(_templateAddress, _specification);
        uint256 _addedTemplateId = oraclesManager.templatesAmount();
        Template memory _template = oraclesManager.template(_addedTemplateId);
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.version, 1);
        assertEq(_template.specification, _specification);
        assertEq(_template.id, _addedTemplateId);
    }
}
