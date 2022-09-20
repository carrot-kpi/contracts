pragma solidity 0.8.17;

import {InitializeKPITokenParams} from "../../../contracts/commons/Types.sol";
import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager1} from "../../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token collect protocol fee test
/// @dev Tests ERC20 KPI token protocol fee collection.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPITokenCollectProtocoFeeTest is BaseTestSetup {
    function initializeKpiToken() internal returns (address, ERC20KPIToken) {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 1 ether
        });

        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "b", // question
            300, // question timeout
            block.timestamp + 300 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 0,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            value: 0,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        vm.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );

        address feeReceiver = address(1234);
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(this),
                oraclesManager: address(oraclesManager),
                kpiTokensManager: address(kpiTokensManager),
                feeReceiver: feeReceiver,
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "a",
                expiration: block.timestamp + 60,
                kpiTokenData: abi.encode(
                    collaterals,
                    "Token",
                    "TKN",
                    100 ether
                ),
                oraclesData: abi.encode(oracleData, false)
            })
        );

        return (feeReceiver, kpiTokenInstance);
    }

    function testExcessiveCollection() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 9.9999999999 ether
        });

        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "b", // question
            300, // question timeout
            block.timestamp + 300 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 0,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            value: 0,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        vm.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );

        vm.expectRevert(
            abi.encodeWithSignature("InvalidMinimumPayoutAfterFee()")
        );
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(this),
                oraclesManager: address(oraclesManager),
                kpiTokensManager: address(kpiTokensManager),
                feeReceiver: address(1234),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "a",
                expiration: block.timestamp + 60,
                kpiTokenData: abi.encode(
                    collaterals,
                    "Token",
                    "TKN",
                    100 ether
                ),
                oraclesData: abi.encode(oracleData, false)
            })
        );
    }

    function testSuccessSingleCollateral() external {
        (, ERC20KPIToken kpiTokenInstance) = initializeKpiToken();

        (IERC20KPIToken.Collateral[] memory onChainCollaterals, , , , , ) = abi
            .decode(
                kpiTokenInstance.data(),
                (
                    IERC20KPIToken.Collateral[],
                    IERC20KPIToken.FinalizableOracle[],
                    bool,
                    uint256,
                    string,
                    string
                )
            );

        assertEq(onChainCollaterals.length, 1);

        IERC20KPIToken.Collateral memory onChainCollateral = onChainCollaterals[
            0
        ];

        assertEq(onChainCollateral.token, address(firstErc20));
        assertEq(onChainCollateral.amount, 9.97 ether);
        assertEq(onChainCollateral.minimumPayout, 1 ether);

        vm.clearMockedCalls();
    }

    function testSuccessMultipleCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        secondErc20.mint(address(this), 3 ether);
        secondErc20.approve(address(kpiTokenInstance), 3 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](2);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 1 ether
        });
        collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 3 ether,
            minimumPayout: 2 ether
        });

        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "b", // question
            300, // question timeout
            block.timestamp + 300 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 0,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            value: 0,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        vm.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );

        address feeReceiver = address(42);
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(this),
                oraclesManager: address(oraclesManager),
                kpiTokensManager: address(kpiTokensManager),
                feeReceiver: feeReceiver,
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "a",
                expiration: block.timestamp + 60,
                kpiTokenData: abi.encode(
                    collaterals,
                    "Token",
                    "TKN",
                    100 ether
                ),
                oraclesData: abi.encode(oracleData, false)
            })
        );

        (IERC20KPIToken.Collateral[] memory onChainCollaterals, , , , , ) = abi
            .decode(
                kpiTokenInstance.data(),
                (
                    IERC20KPIToken.Collateral[],
                    IERC20KPIToken.FinalizableOracle[],
                    bool,
                    uint256,
                    string,
                    string
                )
            );

        assertEq(onChainCollaterals.length, 2);

        assertEq(onChainCollaterals[0].token, address(firstErc20));
        assertEq(onChainCollaterals[0].amount, 9.97 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 1 ether);

        assertEq(onChainCollaterals[1].token, address(secondErc20));
        assertEq(onChainCollaterals[1].amount, 2.991 ether);
        assertEq(onChainCollaterals[1].minimumPayout, 2 ether);

        vm.clearMockedCalls();
    }
}
