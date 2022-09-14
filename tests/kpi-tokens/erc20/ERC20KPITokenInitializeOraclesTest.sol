pragma solidity 0.8.17;

import {InitializeKPITokenParams} from "../../../contracts/commons/Types.sol";
import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager1} from "../../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
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
        string memory expectedErrorSignature,
        uint256 value
    ) internal returns (ERC20KPIToken) {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[] memory collaterals = prepareCollateral(
            address(kpiTokenInstance)
        );
        mockCalls(oracleData, oraclesManager);

        if (bytes(expectedErrorSignature).length > 0) {
            vm.expectRevert(abi.encodeWithSignature(expectedErrorSignature));
        }

        kpiTokenInstance.initialize{value: value}(
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
                oraclesData: oracleData
            })
        );

        return (kpiTokenInstance);
    }

    function prepareCollateral(address kpiTokenInstance)
        internal
        returns (IERC20KPIToken.Collateral[] memory)
    {
        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 1 ether
        });

        return collaterals;
    }

    function mockCalls(bytes memory oracleData, address oraclesManager)
        internal
    {
        (IERC20KPIToken.OracleData[] memory _oracleDatas, ) = abi.decode(
            oracleData,
            (IERC20KPIToken.OracleData[], bool)
        );
        for (uint256 _i = 0; _i < _oracleDatas.length; _i++) {
            IERC20KPIToken.OracleData memory _oracleData = _oracleDatas[_i];
            vm.mockCall(
                oraclesManager,
                abi.encodeWithSignature(
                    "instantiate(address,uint256,bytes)",
                    address(this),
                    _oracleData.templateId,
                    _oracleData.data
                ),
                abi.encode(
                    address(bytes20(keccak256(abi.encodePacked(100 + _i))))
                )
            );
        }
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
                value: 0,
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
            "TooManyOracles()",
            0
        );
    }

    function testNoOracles() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](0);
        initializeKpiToken(
            address(123),
            abi.encode(oracleData, true),
            "NoOracles()",
            0
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
            value: 0,
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
            "InvalidOracleBounds()",
            0
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
            value: 0,
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
            "InvalidOracleBounds()",
            0
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
            value: 0,
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
            "InvalidOracleWeights()",
            0
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
            value: 0,
            data: manualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, true),
            "",
            0
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
        assertEq(finalizableOracle.lowerBound, 0);
        assertEq(finalizableOracle.higherBound, 1);
        assertEq(finalizableOracle.finalResult, 0);
        assertEq(finalizableOracle.weight, 1);
        assertTrue(!finalizableOracle.finalized);
        assertTrue(andRelationship);
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
            value: 0,
            data: manualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            "",
            0
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
        assertEq(finalizableOracle.lowerBound, 0);
        assertEq(finalizableOracle.higherBound, 1);
        assertEq(finalizableOracle.finalResult, 0);
        assertEq(finalizableOracle.weight, 1);
        assertTrue(!finalizableOracle.finalized);
        assertTrue(!andRelationship);
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
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, true),
            "",
            0
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

        assertEq(onChainFinalizableOracles[0].lowerBound, 0);
        assertEq(onChainFinalizableOracles[0].higherBound, 1);
        assertEq(onChainFinalizableOracles[0].finalResult, 0);
        assertEq(onChainFinalizableOracles[0].weight, 1);
        assertTrue(!onChainFinalizableOracles[0].finalized);

        assertEq(onChainFinalizableOracles[1].lowerBound, 5 ether);
        assertEq(onChainFinalizableOracles[1].higherBound, 10 ether);
        assertEq(onChainFinalizableOracles[1].finalResult, 0);
        assertEq(onChainFinalizableOracles[1].weight, 3);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(andRelationship);
    }

    function testFailureZeroValueSingleOracle() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            10 ether // minimum bond
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 10 ether,
            data: firstManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        vm.expectRevert(abi.encodeWithSignature("NotEnoughValue()"));
        initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            "NotEnoughValue()",
            0
        );
    }

    function testFailureSomeValueSingleOracle() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            10 ether // minimum bond
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 10 ether,
            data: firstManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        vm.expectRevert(abi.encodeWithSignature("NotEnoughValue()"));
        initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            "NotEnoughValue()",
            2 ether
        );
    }

    function testSuccessValueSingleOracle() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            1 ether // minimum bond
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 1 ether,
            data: firstManualRealityEthInitializationData
        });
        initializeKpiToken(
            address(3),
            abi.encode(oracleData, false),
            "",
            10 ether
        );
    }

    function testFailureZeroValueMultipleOracles() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            10 ether // minimum bond
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            12.28 ether // minimum bond
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 10 ether,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 12.28 ether,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        vm.expectRevert(abi.encodeWithSignature("NotEnoughValue()"));
        initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            "NotEnoughValue()",
            0
        );
    }

    function testFailureSomeValueMultipleOracles() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            10 ether // minimum bond
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            12.28 ether // minimum bond
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 10 ether,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 12.28 ether,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        vm.expectRevert(abi.encodeWithSignature("NotEnoughValue()"));
        initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            "NotEnoughValue()",
            10 ether
        );
    }

    function testSuccessWithValueMultipleOracles() external {
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            10 ether // minimum bond
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200, // expiry
            12.28 ether // minimum bond
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 10 ether,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            value: 12.28 ether,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            "",
            22.28 ether
        );
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
        ERC20KPIToken kpiTokenInstance = initializeKpiToken(
            oraclesManager,
            abi.encode(oracleData, false),
            "",
            0
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

        assertEq(onChainFinalizableOracles[0].lowerBound, 0);
        assertEq(onChainFinalizableOracles[0].higherBound, 1);
        assertEq(onChainFinalizableOracles[0].finalResult, 0);
        assertEq(onChainFinalizableOracles[0].weight, 1);
        assertTrue(!onChainFinalizableOracles[0].finalized);

        assertEq(onChainFinalizableOracles[1].lowerBound, 5 ether);
        assertEq(onChainFinalizableOracles[1].higherBound, 10 ether);
        assertEq(onChainFinalizableOracles[1].finalResult, 0);
        assertEq(onChainFinalizableOracles[1].weight, 3);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(!andRelationship);
    }
}
