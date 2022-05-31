pragma solidity 0.8.14;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager get template test
/// @dev Tests template query in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerGetTemplateTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        oraclesManager.template(1);
    }

    function testSuccess() external {
        uint256 _templateId = 0;
        IOraclesManager.Template memory _template = oraclesManager.template(
            _templateId
        );
        assertEq(_template.id, _templateId);
        assertEq(_template.addrezz, address(manualRealityOracleTemplate));
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        assertEq(_template.specification, MANUAL_REALITY_ETH_SPECIFICATION);
        assertTrue(!_template.automatable);
        assertTrue(_template.exists);
    }
}
