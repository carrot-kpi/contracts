pragma solidity 0.8.17;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";
import {IERC20KPIToken} from "../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager instantiation test
/// @dev Tests template instantiation in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerInstantiateTest is BaseTestSetup {
    function testFailNotFromFactory() external {
        vm.expectRevert();
        kpiTokensManager.instantiate(
            address(this),
            1,
            "a",
            block.timestamp + 60,
            abi.encode(""),
            abi.encode("")
        );
    }

    function initialize()
        internal
        returns (
            string memory,
            bytes memory,
            bytes memory
        )
    {
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

        string memory _description = "test";
        string memory _question = "test?";

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
            _question,
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
        return (
            _description,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );
    }

    function testSuccessERC20() external {
        (
            string memory _description,
            bytes memory _erc20KpiTokenInitializationData,
            bytes memory _oraclesInitializationData
        ) = initialize();

        vm.prank(address(factory));
        address _predictedInstanceAddress = kpiTokensManager
            .predictInstanceAddress(
                address(this),
                1,
                _description,
                block.timestamp + 60,
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );

        firstErc20.mint(address(this), 2);
        firstErc20.approve(_predictedInstanceAddress, 2);
        vm.mockCall(
            address(factory),
            abi.encodeWithSignature(
                "allowOraclesCreation(address)",
                _predictedInstanceAddress
            ),
            abi.encode(true)
        );

        vm.prank(address(factory));
        (address _instance, ) = kpiTokensManager.instantiate(
            address(this),
            1,
            _description,
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        assertEq(_instance, _predictedInstanceAddress);
        vm.clearMockedCalls();
    }
}
