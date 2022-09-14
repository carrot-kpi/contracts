pragma solidity 0.8.17;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {IERC20KPIToken} from "../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../../contracts/commons/Types.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory create token test
/// @dev Tests KPI token creation.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract FactoryCreateTokenTest is BaseTestSetup {
    function testInvalidTemplateId() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        factory.createToken(
            10,
            "a",
            block.timestamp + 60,
            abi.encode(1),
            abi.encode(2)
        );
    }

    function testInvalidKpiTokenTemplateInitializationData() external {
        vm.expectRevert(bytes(""));
        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            abi.encode(1),
            abi.encode(2)
        );
    }

    function testInvalidOracleTemplateInitializationData() external {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 2,
            minimumPayout: 1
        });
        bytes memory _erc20KpiTokenInitializationData = abi.encode(
            _collaterals,
            bytes32("Test"),
            bytes32("TST"),
            100 ether
        );
        vm.expectRevert(bytes(""));
        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            abi.encode(2)
        );
    }

    function testSuccess() external {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2,
            minimumPayout: 1
        });
        bytes memory _erc20KpiTokenInitializationData = abi.encode(
            _collaterals,
            "Test",
            "TST",
            100 ether
        );

        address _reality = address(42);
        vm.mockCall(
            _reality,
            abi.encodeWithSignature(
                "askQuestionWithMinBond(uint256,string,address,uint32,uint32,uint256,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory realityV3OracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "question",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 0,
            data: realityV3OracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 2);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                address(this),
                1,
                "a",
                block.timestamp + 60,
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2);

        assertEq(factory.kpiTokensAmount(), 0);
        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        assertEq(factory.kpiTokensAmount(), 1);
        assertEq(factory.enumerate(0, 1)[0], _predictedKpiTokenAddress);
    }
}
