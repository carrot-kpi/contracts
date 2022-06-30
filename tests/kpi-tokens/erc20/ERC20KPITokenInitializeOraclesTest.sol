pragma solidity 0.8.15;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token initialize oracles test
/// @dev Tests oracles initialization in ERC20 KPI token.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPITokenInitializeOraclesTest is BaseTestSetup {
    function initializeKpiToken(
        address oraclesManager,
        bytes memory oracleData,
        string memory expectedErrorSignature
    ) internal returns (ERC20KPIToken) {
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

        vm.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );

        if (bytes(expectedErrorSignature).length > 0) {
            vm.expectRevert(abi.encodeWithSignature(expectedErrorSignature));
        }

        address feeReceiver = address(1234);
        kpiTokenInstance.initialize(
            address(this),
            address(kpiTokensManager),
            oraclesManager,
            feeReceiver,
            1,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 100 ether),
            oracleData
        );

        return (kpiTokenInstance);
    }

    function testZeroAddressOraclesManager() external {
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
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            data: secondManualRealityEthInitializationData
        });

        initializeKpiToken(
            address(0),
            abi.encode(oracleData, true),
            "InvalidOraclesManager()"
        );
    }

    function testTooManyOracles() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](6);
        for (uint8 i = 0; i < 6; i++) {
            oracleData[i] = IERC20KPIToken.OracleData({
                templateId: 1,
                lowerBound: 0,
                higherBound: 0,
                weight: 1,
                data: abi.encode(
                    address(2), // fake reality.eth address
                    address(this), // arbitrator
                    0, // template id
                    "a", // question
                    200, // question timeout
                    block.timestamp + 200 // expiry
                )
            });
        }

        initializeKpiToken(
            address(123),
            abi.encode(oracleData, true),
            "TooManyOracles()"
        );
    }

    function testNoOracles() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](0);
        initializeKpiToken(
            address(123),
            abi.encode(oracleData, true),
            "NoOracles()"
        );
    }

    function testSameOracleBounds() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 0,
            weight: 1,
            data: abi.encode(
                address(2), // fake reality.eth address
                address(this), // arbitrator
                0, // template id
                "a", // question
                200, // question timeout
                block.timestamp + 200 // expiry
            )
        });

        initializeKpiToken(
            address(123),
            abi.encode(oracleData, true),
            "InvalidOracleBounds()"
        );
    }

    function testInvalidOracleBounds() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 1,
            higherBound: 0,
            weight: 1,
            data: abi.encode(
                address(2), // fake reality.eth address
                address(this), // arbitrator
                0, // template id
                "a", // question
                200, // question timeout
                block.timestamp + 200 // expiry
            )
        });
        initializeKpiToken(
            address(123),
            abi.encode(oracleData, true),
            "InvalidOracleBounds()"
        );
    }

    function testZeroWeight() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 0,
            data: abi.encode(
                address(2), // fake reality.eth address
                address(this), // arbitrator
                0, // template id
                "a", // question
                200, // question timeout
                block.timestamp + 200 // expiry
            )
        });
        initializeKpiToken(
            address(123),
            abi.encode(oracleData, true),
            "InvalidOracleWeights()"
        );
    }

    function testSuccessAndSingleOracle() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        bytes memory manualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: manualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, true),
            ""
        );

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
            ,
            ,

        ) = abi.decode(
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

        assertEq(onChainFinalizableOracles.length, 1);
        IERC20KPIToken.FinalizableOracle
            memory finalizableOracle = onChainFinalizableOracles[0];
        assertEq(finalizableOracle.addrezz, address(2));
        assertEq(finalizableOracle.lowerBound, 0);
        assertEq(finalizableOracle.higherBound, 1);
        assertEq(finalizableOracle.finalProgress, 0);
        assertEq(finalizableOracle.weight, 1);
        assertTrue(!finalizableOracle.finalized);
        assertTrue(andRelationship);

        vm.clearMockedCalls();
    }

    function testSuccessNoAndSingleOracle() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        bytes memory manualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: manualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            ""
        );

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
            ,
            ,

        ) = abi.decode(
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

        assertEq(onChainFinalizableOracles.length, 1);
        IERC20KPIToken.FinalizableOracle
            memory finalizableOracle = onChainFinalizableOracles[0];
        assertEq(finalizableOracle.addrezz, address(2));
        assertEq(finalizableOracle.lowerBound, 0);
        assertEq(finalizableOracle.higherBound, 1);
        assertEq(finalizableOracle.finalProgress, 0);
        assertEq(finalizableOracle.weight, 1);
        assertTrue(!finalizableOracle.finalized);
        assertTrue(!andRelationship);

        vm.clearMockedCalls();
    }

    function testSuccessAndMultipleOracles() external {
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
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, true),
            ""
        );

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
            ,
            ,

        ) = abi.decode(
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

        assertEq(onChainFinalizableOracles.length, 2);

        assertEq(onChainFinalizableOracles[0].addrezz, address(2));
        assertEq(onChainFinalizableOracles[0].lowerBound, 0);
        assertEq(onChainFinalizableOracles[0].higherBound, 1);
        assertEq(onChainFinalizableOracles[0].finalProgress, 0);
        assertEq(onChainFinalizableOracles[0].weight, 1);
        assertTrue(!onChainFinalizableOracles[0].finalized);

        assertEq(onChainFinalizableOracles[1].addrezz, address(2));
        assertEq(onChainFinalizableOracles[1].lowerBound, 5 ether);
        assertEq(onChainFinalizableOracles[1].higherBound, 10 ether);
        assertEq(onChainFinalizableOracles[1].finalProgress, 0);
        assertEq(onChainFinalizableOracles[1].weight, 3);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(andRelationship);

        vm.clearMockedCalls();
    }

    function testSuccessNoAndMultipleOracles() external {
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
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            ""
        );

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
            ,
            ,

        ) = abi.decode(
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

        assertEq(onChainFinalizableOracles.length, 2);

        assertEq(onChainFinalizableOracles[0].addrezz, address(2));
        assertEq(onChainFinalizableOracles[0].lowerBound, 0);
        assertEq(onChainFinalizableOracles[0].higherBound, 1);
        assertEq(onChainFinalizableOracles[0].finalProgress, 0);
        assertEq(onChainFinalizableOracles[0].weight, 1);
        assertTrue(!onChainFinalizableOracles[0].finalized);

        assertEq(onChainFinalizableOracles[1].addrezz, address(2));
        assertEq(onChainFinalizableOracles[1].lowerBound, 5 ether);
        assertEq(onChainFinalizableOracles[1].higherBound, 10 ether);
        assertEq(onChainFinalizableOracles[1].finalProgress, 0);
        assertEq(onChainFinalizableOracles[1].weight, 3);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(!andRelationship);

        vm.clearMockedCalls();
    }
}
