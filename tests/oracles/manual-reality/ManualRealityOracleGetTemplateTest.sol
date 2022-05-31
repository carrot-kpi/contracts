pragma solidity 0.8.14;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ManualRealityOracle} from "../../../contracts/oracles/ManualRealityOracle.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Manual Reality oracle get template test
/// @dev Tests template query in manual Reality oracle template.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ManualRealityOracleGetTemplateTest is BaseTestSetup {
    function testSuccess() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        address _realityAddress = address(1234);
        bytes32 _questionId = bytes32("questionId");
        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature(
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(_questionId)
        );
        CHEAT_CODES.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            abi.encode(
                _realityAddress,
                address(1),
                0,
                "a",
                60,
                block.timestamp + 60
            )
        );

        assertEq(oracleInstance.template().id, _template.id);

        CHEAT_CODES.clearMockedCalls();
    }
}
