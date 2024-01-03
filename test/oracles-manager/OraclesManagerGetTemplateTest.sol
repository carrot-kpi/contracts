pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager get template test
/// @dev Tests template query in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerGetTemplateTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.template(0);
    }

    function testSuccess() external {
        uint256 _templateId = 1;
        Template memory _template = oraclesManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.addrezz, address(mockOracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, MOCK_ORACLE_SPECIFICATION);
    }
}
