pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IERC20KPIToken} from "../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager instantiation test
/// @dev Tests template instantiation in KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerInstantiateTest is BaseTestSetup {
    function testFailNotFromFactory() external {
        // FIXME: why does this fail if I uncomment stuff?
        vm.expectRevert(); /* abi.encodeWithSignature("Forbidden()") */
        oraclesManager.instantiate(address(this), 0, bytes(""));
    }

    function testSuccessERC20() external {
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
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
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        address _predictedInstanceAddress = Clones.predictDeterministicAddress(
            address(erc20KpiTokenTemplate),
            keccak256(
                abi.encodePacked(
                    _description,
                    _erc20KpiTokenInitializationData,
                    _oraclesInitializationData
                )
            ),
            address(kpiTokensManager)
        );

        vm.prank(address(factory));
        address _instance = kpiTokensManager.instantiate(
            1,
            _description,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        assertEq(_instance, _predictedInstanceAddress);
        vm.clearMockedCalls();
    }
}
