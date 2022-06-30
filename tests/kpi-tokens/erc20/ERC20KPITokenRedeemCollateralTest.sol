pragma solidity 0.8.15;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token redeem test
/// @dev Tests redemption in ERC20 KPI token.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPITokenRedeemCollateralTest is BaseTestSetup {
    function testNotInitialized() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(0));
    }

    function testNotFinalized() external {
        ERC20KPIToken kpiTokenInstance = createKpiToken("a", "b");
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(0));
    }

    function testNoRedeemRegistration() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSignature("NoRedemptionPossible()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder), 0);
        assertEq(firstErc20.balanceOf(address(kpiTokenInstance)), 109.67 ether);
    }

    function testBelowLowerBoundSingleOracleExpired() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);

        vm.warp(_expiration);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(0);

        vm.prank(holder);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSignature("NoRedemptionPossible()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder), 0);
        assertEq(firstErc20.balanceOf(address(kpiTokenInstance)), 109.67 ether);
    }

    function testAtLowerBoundSingleOracleExpired() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);

        vm.warp(_expiration);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(10);

        vm.prank(holder);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder), 0);
        assertEq(firstErc20.balanceOf(address(kpiTokenInstance)), 109.67 ether);
    }

    function testOverHigherBoundSingleOracle() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);

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

        vm.prank(holder);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder), 0 ether);
        assertEq(firstErc20.balanceOf(holder), 1.096700000000000000 ether);
        assertEq(
            firstErc20.balanceOf(address(kpiTokenInstance)),
            108.573300000000000000 ether
        );
    }

    function testOverHigherBoundSingleOracleDoubleRedemption() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);

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

        vm.prank(holder);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder), 0 ether);
        assertEq(firstErc20.balanceOf(holder), 1.096700000000000000 ether);
        assertEq(
            firstErc20.balanceOf(address(kpiTokenInstance)),
            108.573300000000000000 ether
        );
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
    }

    function testOverHigherBoundSingleOracleExpired() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);

        vm.warp(_expiration);

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

        vm.prank(holder);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 22 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        kpiTokenInstance.redeemCollateral(address(firstErc20));

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

    function testIntermediateSingleOracleDoubleRedemption() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 22 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
    }

    function testIntermediateSingleOracleExpired() external {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 22 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder, 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 99 ether);

        vm.warp(_expiration);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(11);

        assertEq(firstErc20.balanceOf(holder), 0 ether);
        vm.prank(holder);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        vm.expectRevert(abi.encodeWithSignature("NoRedemptionPossible()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(firstErc20.balanceOf(holder1), 0 ether);

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        vm.expectRevert(abi.encodeWithSignature("NoRedemptionPossible()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(firstErc20.balanceOf(holder2), 0 ether);
    }

    function testBelowLowerBoundSingleOracleMultipleParticipantsExpired()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        vm.warp(_expiration);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(0);

        vm.prank(holder1);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        vm.expectRevert(abi.encodeWithSignature("NoRedemptionPossible()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(firstErc20.balanceOf(holder1), 0 ether);

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        vm.expectRevert(abi.encodeWithSignature("NoRedemptionPossible()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(firstErc20.balanceOf(holder2), 0 ether);
    }

    function testAtLowerBoundSingleOracleMultipleParticipantsExpired()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        vm.warp(_expiration);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(10);

        vm.prank(holder1);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 1.096700000000000000 ether);

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 10.967000000000000000 ether);
    }

    function testOverHigherBoundSingleOracleMultipleParticipantsDoubleRedemption()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 1.096700000000000000 ether);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 10.967000000000000000 ether);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
    }

    function testOverHigherBoundSingleOracleMultipleParticipantsExpired()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        vm.warp(_expiration);

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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 0.365566666666666666 ether);

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 3.655666666666666666 ether);
    }

    function testIntermediateSingleOracleMultipleParticipantsDoubleRedemption()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 0.365566666666666666 ether);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 3.655666666666666666 ether);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
    }

    function testIntermediateSingleOracleMultipleParticipantsExpired()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        vm.warp(_expiration);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(11);

        vm.prank(holder1);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder1);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
    }

    function testIntermediateSingleOracleMultipleParticipantsMixedApproach()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        assertEq(firstErc20.balanceOf(address(this)), 0 ether);

        vm.prank(holder1);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 0.365566666666666666 ether);

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 3.655666666666666666 ether);

        kpiTokenInstance.registerRedemption();
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(address(this)), 0);
        assertEq(kpiTokenInstance.totalSupply(), 0 ether);
        assertEq(
            firstErc20.balanceOf(address(this)),
            32.535433333333333333 ether
        );

        assertEq(
            firstErc20.balanceOf(address(kpiTokenInstance)),
            73.113333333333333335 ether
        );
        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));
        assertEq(firstErc20.balanceOf(address(kpiTokenInstance)), 2);
        assertEq(
            firstErc20.balanceOf(address(this)),
            105.648766666666666666 ether
        );
    }

    function testIntermediateSingleOracleMultipleParticipantsMixedApproachDoubleRedemption()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        factory.createToken(
            1,
            "a",
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
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
        assertEq(firstErc20.balanceOf(address(this)), 0 ether);

        vm.prank(holder1);
        kpiTokenInstance.redeem();
        assertEq(kpiTokenInstance.balanceOf(holder1), 0);
        assertEq(kpiTokenInstance.totalSupply(), 99 ether);
        assertEq(firstErc20.balanceOf(holder1), 0.365566666666666666 ether);

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(holder2), 0);
        assertEq(kpiTokenInstance.totalSupply(), 89 ether);
        assertEq(firstErc20.balanceOf(holder2), 3.655666666666666666 ether);

        kpiTokenInstance.registerRedemption();
        kpiTokenInstance.redeemCollateral(address(firstErc20));
        assertEq(kpiTokenInstance.balanceOf(address(this)), 0);
        assertEq(kpiTokenInstance.totalSupply(), 0 ether);
        assertEq(
            firstErc20.balanceOf(address(this)),
            32.535433333333333333 ether
        );
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));

        assertEq(
            firstErc20.balanceOf(address(kpiTokenInstance)),
            73.113333333333333335 ether
        );
        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));
        assertEq(firstErc20.balanceOf(address(kpiTokenInstance)), 2);
        assertEq(
            firstErc20.balanceOf(address(this)),
            105.648766666666666666 ether
        );
    }

    function testIntermediateSingleOracleMultipleParticipantsMixedApproachExpired()
        external
    {
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
            templateId: 1,
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
                address(this),
                1,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 110 ether);

        uint256 _expiration = block.timestamp + 60;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            _predictedKpiTokenAddress
        );

        kpiTokenInstance.transfer(holder1, 1 ether);
        kpiTokenInstance.transfer(holder2, 10 ether);
        assertEq(kpiTokenInstance.balanceOf(holder1), 1 ether);
        assertEq(kpiTokenInstance.balanceOf(holder2), 10 ether);
        assertEq(kpiTokenInstance.balanceOf(address(this)), 89 ether);

        vm.warp(_expiration);

        address oracle = kpiTokenInstance.oracles()[0];
        vm.prank(oracle);
        kpiTokenInstance.finalize(11);

        vm.prank(holder2);
        kpiTokenInstance.registerRedemption();
        vm.prank(holder2);
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        kpiTokenInstance.redeemCollateral(address(firstErc20));
    }
}
