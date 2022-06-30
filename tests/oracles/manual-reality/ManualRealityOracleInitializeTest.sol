pragma solidity 0.8.15;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ManualRealityOracle} from "../../../contracts/oracles/ManualRealityOracle.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Manual Reality oracle intialize test
/// @dev Tests initialization in manual Reality oracle template.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ManualRealityOracleInitializeTest is BaseTestSetup {
    function testZeroAddressKpiToken() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressKpiToken()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(0),
            _template.id,
            abi.encode(uint256(1))
        );
    }

    function testInvalidTemplate() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        uint256 _templateId = 123;
        vm.mockCall(
            address(oraclesManager),
            abi.encodeWithSignature("exists(uint256)", _templateId),
            abi.encode(false)
        );
        vm.prank(address(oraclesManager));
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oracleInstance.initialize(
            address(1),
            _templateId,
            abi.encode(uint256(1))
        );
    }

    function testZeroAddressReality() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressReality()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            abi.encode(address(0), address(1), 0, "a", 60, block.timestamp + 60)
        );
    }

    function testZeroAddressArbitrator() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressArbitrator()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            abi.encode(address(1), address(0), 0, "a", 60, block.timestamp + 60)
        );
    }

    function testEmptyQuestion() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        vm.expectRevert(abi.encodeWithSignature("InvalidQuestion()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            abi.encode(address(1), address(1), 0, "", 60, block.timestamp + 60)
        );
    }

    function testInvalidTimeout() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        vm.expectRevert(abi.encodeWithSignature("InvalidQuestionTimeout()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            abi.encode(address(1), address(1), 0, "a", 0, block.timestamp + 60)
        );
    }

    function testInvalidOpeningTimestamp() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        vm.expectRevert(abi.encodeWithSignature("InvalidOpeningTimestamp()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            abi.encode(address(1), address(1), 0, "a", 60, block.timestamp)
        );
    }

    function testSuccess() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(1);
        address _realityAddress = address(1234);
        bytes32 _questionId = bytes32("questionId");
        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature(
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(_questionId)
        );
        uint256 _openingTs = block.timestamp + 60;
        emit log_address(address(oraclesManager));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            abi.encode(_realityAddress, address(1), 0, "a", 60, _openingTs)
        );

        assertEq(oracleInstance.template().id, _template.id);

        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature("getArbitrator(bytes32)"),
            abi.encode(address(1))
        );
        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature("getTimeout(bytes32)"),
            abi.encode(uint32(60))
        );
        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature("getOpeningTS(bytes32)"),
            abi.encode(_openingTs)
        );
        bytes memory _data = oracleInstance.data();
        (
            address _onChainReality,
            bytes32 _onChainQuestionId,
            address _onChainArbitrator,
            uint256 _onChainRealityTemplateId,
            string memory _onChainQuestion,
            uint32 _onChainTimeout,
            uint32 _onChainOpeningTs
        ) = abi.decode(
                _data,
                (address, bytes32, address, uint256, string, uint32, uint32)
            );
        assertEq(_onChainReality, _realityAddress);
        assertEq(_onChainQuestionId, _questionId);
        assertEq(_onChainArbitrator, address(1));
        assertEq(_onChainRealityTemplateId, 0);
        assertEq(_onChainQuestion, "a");
        assertEq(_onChainTimeout, 60);
        assertEq(_onChainOpeningTs, _openingTs);

        vm.clearMockedCalls();
    }
}
