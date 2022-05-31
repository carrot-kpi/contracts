pragma solidity 0.8.14;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager remove template test
/// @dev Tests template removal in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerRemoveTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokensManager.removeTemplate(0);
    }

    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        kpiTokensManager.removeTemplate(10);
    }

    function testSuccess() external {
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            0
        );
        assertTrue(_template.exists);
        kpiTokensManager.removeTemplate(0);
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        kpiTokensManager.template(0);
    }
}
