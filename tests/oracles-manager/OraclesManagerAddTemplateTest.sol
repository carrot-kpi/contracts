pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager add template test
/// @dev Tests template addition in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerAddTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oraclesManager.addTemplate(address(2), false, "");
    }

    function testZeroAddressTemplate() external {
        vm.expectRevert(
            abi.encodeWithSignature("ZeroAddressTemplate()")
        );
        oraclesManager.addTemplate(address(0), false, "");
    }

    function testEmptySpecification() external {
        vm.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        oraclesManager.addTemplate(address(1), false, "");
    }

    function testSuccess() external {
        string memory _specification = "test";
        address _templateAddress = address(1);
        oraclesManager.addTemplate(_templateAddress, false, _specification);
        uint256 _addedTemplateId = oraclesManager.templatesAmount();
        IOraclesManager.Template memory _template = oraclesManager.template(
            _addedTemplateId
        );
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        assertEq(_template.specification, _specification);
        assertTrue(!_template.automatable);
        assertTrue(_template.exists);
    }
}
