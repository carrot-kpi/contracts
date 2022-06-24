pragma solidity 0.8.15;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token redeem test
/// @dev Tests redemption in ERC20 KPI token.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPITokenRedeemTest is BaseTestSetup {
    function testNotInitialized() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeem();
    }

    function testNotFinalized() external {
        ERC20KPIToken kpiTokenInstance = createKpiToken("a", "b");
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeem();
    }

    function testNoBalance() external {
        ERC20KPIToken kpiTokenInstance = createKpiToken("a", "b");
        vm.prank(kpiTokenInstance.oracles()[0]);
        kpiTokenInstance.finalize(0);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vm.prank(address(12345));
        kpiTokenInstance.redeem();
    }

    function testBelowLowerBoundSingleOracle() external {
        address holder = address(123321);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 110 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 11,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 110 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(0);

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
        assertEq(onChainCollaterals[0].amount, 0 ether);

        vm.prank(holder);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder), 0);
        assertEq(firstErc20.balanceOf(holder), 0 ether);
    }

    function testAtLowerBoundSingleOracle() external {
        address holder = address(123321);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 110 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 11,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 110 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(10);

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
        assertEq(onChainCollaterals[0].amount, 0 ether);

        vm.prank(holder);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder), 0);
        assertEq(firstErc20.balanceOf(holder), 0 ether);
    }

    function testOverHigherBoundSingleOracle() external {
        address holder = address(71899398389892);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 110 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 11,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 110 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 99 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(12);

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
        assertEq(onChainCollaterals[0].amount, 109.67 ether);

        assertEq(firstErc20.balanceOf(holder), 0 ether);
        vm.prank(holder);
        kpiTokenInstance.redeem();

        (onChainCollaterals, , , , , ) = abi.decode(
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
        assertEq(onChainCollaterals[0].amount, 108.5733 ether);

        assertEq(kpiTokenInstance.balanceOf(holder), 0);
        assertEq(firstErc20.balanceOf(holder), 1.0967 ether);
    }

    function testIntermediateSingleOracle() external {
        address holder = address(71899398389892);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 22 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 13,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 22 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 22 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 99 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(11);

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
        assertEq(onChainCollaterals[0].amount, 7.311333333333333334 ether);
        assertEq(firstErc20.balanceOf(address(this)), 0);

        assertEq(firstErc20.balanceOf(holder), 0 ether);
        vm.prank(holder);
        kpiTokenInstance.redeem();

        (onChainCollaterals, , , , , ) = abi.decode(
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
        assertEq(onChainCollaterals[0].amount, 7.238220000000000001 ether);

        assertEq(kpiTokenInstance.balanceOf(holder), 0);
        assertEq(firstErc20.balanceOf(holder), 0.073113333333333333 ether);
    }

    function testBelowLowerBoundSingleOracleMultipleParticipants() external {
        address holder1 = address(123321);
        address holder2 = address(19929999);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 110 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 11,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 110 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(0);

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
        assertEq(onChainCollaterals[0].amount, 0 ether);

        vm.prank(holder1);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(firstErc20.balanceOf(holder1), 0 ether);

        vm.prank(holder2);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(firstErc20.balanceOf(holder2), 0 ether);
    }

    function testAtLowerBoundSingleOracleMultipleParticipants() external {
        address holder1 = address(123321);
        address holder2 = address(19929999);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 110 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 11,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 110 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(10);

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
        assertEq(onChainCollaterals[0].amount, 0 ether);

        vm.prank(holder1);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(firstErc20.balanceOf(holder1), 0 ether);

        vm.prank(holder2);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(firstErc20.balanceOf(holder2), 0 ether);
    }

    function testOverHigherBoundSingleOracleMultipleParticipants() external {
        address holder1 = address(123321);
        address holder2 = address(19929999);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 110 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 11,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 110 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(100);

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
        assertEq(onChainCollaterals[0].amount, 109.67 ether);

        vm.prank(holder1);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 1.0967 ether);

        vm.prank(holder2);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 10.967 ether);
    }

    function testIntermediateSingleOracleMultipleParticipants() external {
        address holder1 = address(123321);
        address holder2 = address(19929999);

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 110 ether,
            minimumPayout: 0
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
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 13,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 110 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(11);

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
        assertEq(onChainCollaterals[0].amount, 36.556666666666666667 ether);
        assertEq(firstErc20.balanceOf(address(this)), 0);

        vm.prank(holder1);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 0.365566666666666666 ether);

        vm.prank(holder2);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 3.655666666666666666 ether);
    }
}
