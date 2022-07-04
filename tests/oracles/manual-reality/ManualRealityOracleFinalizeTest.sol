pragma solidity 0.8.15;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ManualRealityOracle} from "../../../contracts/oracles/ManualRealityOracle.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Manual Reality oracle finalize test
/// @dev Tests finalization in manual Reality oracle template.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ManualRealityOracleFinalizeTest is BaseTestSetup {
    function testRealityQuestionNotFinalized() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        address _realityAddress = address(1234);
        bytes32 _questionId = bytes32("questionId");
        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature(
                "askQuestionWithMinBond(uint256,string,address,uint32,uint32,uint256,uint256)"
            ),
            abi.encode(_questionId)
        );
        vm.prank(address(oraclesManager));
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

        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature("resultFor(bytes32)"),
            abi.encode("")
        );

        vm.expectRevert();
        oracleInstance.finalize();

        vm.clearMockedCalls();
    }

    function testSuccess() external {
        ERC20KPIToken _kpiToken = createKpiToken("a", "b");

        ManualRealityOracle _oracleInstance = ManualRealityOracle(
            _kpiToken.oracles()[0]
        );

        vm.mockCall(
            address(42),
            abi.encodeWithSignature("resultFor(bytes32)"),
            abi.encode(bytes32("1234"))
        );
        vm.mockCall(
            address(_kpiToken),
            abi.encodeWithSignature(
                "finalize(uint256)",
                uint256(bytes32("1234"))
            ),
            abi.encode()
        );

        _oracleInstance.finalize();

        assertTrue(_oracleInstance.finalized());
    }
}
