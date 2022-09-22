pragma solidity 0.8.17;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {RealityV3Oracle} from "../../../contracts/oracles/RealityV3Oracle.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager1} from "../../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
import {Template} from "../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {InitializeOracleParams} from "../../../contracts/commons/Types.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Manual Reality oracle finalize test
/// @dev Tests finalization in manual Reality oracle template.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ManualRealityOracleFinalizeTest is BaseTestSetup {
    function testRealityQuestionNotFinalized() external {
        RealityV3Oracle oracleInstance = RealityV3Oracle(
            Clones.clone(address(realityV3OracleTemplate))
        );
        Template memory _template = oraclesManager.template(1);
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
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: _template.id,
                templateVersion: _template.version,
                data: abi.encode(
                    _realityAddress,
                    address(1),
                    0,
                    "a",
                    60,
                    block.timestamp + 60
                )
            })
        );

        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature("resultForOnceSettled(bytes32)"),
            abi.encode("")
        );

        vm.expectRevert();
        oracleInstance.finalize();

        vm.clearMockedCalls();
    }

    function testSuccess() external {
        ERC20KPIToken _kpiToken = createKpiToken("a", "b");

        RealityV3Oracle _oracleInstance = RealityV3Oracle(
            _kpiToken.oracles()[0]
        );

        vm.mockCall(
            address(42),
            abi.encodeWithSignature("resultForOnceSettled(bytes32)"),
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
