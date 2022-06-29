pragma solidity 0.8.15;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token initialize test
/// @dev Tests initialization in ERC20 KPI token.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPITokenInitializeTest is BaseTestSetup {
    function testZeroAddressCreator() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidCreator()"));
        kpiTokenInstance.initialize(
            address(0),
            address(0),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(uint256(1))
        );
    }

    function testZeroAddressKpiTokensManager() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidKpiTokensManager()"));
        kpiTokenInstance.initialize(
            address(1),
            address(0),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(uint256(1))
        );
    }

    function testEmptyDescription() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidDescription()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "",
            block.timestamp + 60,
            abi.encode(uint256(1))
        );
    }

    function testInvalidData() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        vm.expectRevert();
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(uint256(1))
        );
    }

    function testTooManyCollaterals() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](6);
        for (uint8 i = 0; i < 6; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        vm.expectRevert(abi.encodeWithSignature("TooManyCollaterals()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testInvalidName() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](5);
        for (uint8 i = 0; i < 5; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        vm.expectRevert(abi.encodeWithSignature("InvalidName()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "", "TKN", 10 ether)
        );
    }

    function testInvalidSymbol() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](5);
        for (uint8 i = 0; i < 5; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        vm.expectRevert(abi.encodeWithSignature("InvalidSymbol()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "", 10 ether)
        );
    }

    function testInvalidSupply() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](5);
        for (uint8 i = 0; i < 5; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        vm.expectRevert(abi.encodeWithSignature("InvalidTotalSupply()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 0)
        );
    }

    function testDuplicatedCollaterals() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](2);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(10000),
            amount: 200,
            minimumPayout: 0
        });
        collaterals[1] = IERC20KPIToken.Collateral({
            token: address(10000),
            amount: 100,
            minimumPayout: 0
        });

        vm.expectRevert(abi.encodeWithSignature("DuplicatedCollateral()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 100 ether)
        );
    }

    function testZeroAddressCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(0),
            amount: 0,
            minimumPayout: 0
        });

        vm.expectRevert(abi.encodeWithSignature("InvalidCollateral()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testZeroAmountCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 0,
            minimumPayout: 0
        });

        vm.expectRevert(abi.encodeWithSignature("InvalidCollateral()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testSameMinimumPayoutCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 1,
            minimumPayout: 1
        });

        vm.expectRevert(abi.encodeWithSignature("InvalidCollateral()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testGreaterMinimumPayoutCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 1,
            minimumPayout: 10
        });

        vm.expectRevert(abi.encodeWithSignature("InvalidCollateral()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testSuccess() external {
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

        kpiTokenInstance.initialize(
            address(this),
            address(kpiTokensManager),
            10,
            "a",
            block.timestamp + 60,
            abi.encode(collaterals, "Token", "TKN", 100 ether)
        );

        (
            IERC20KPIToken.Collateral[] memory onChainCollaterals,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool onChainAndRelationship,
            uint256 onChainInitialSupply,
            string memory onChainName,
            string memory onChainSymbol
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

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, address(firstErc20));
        assertEq(onChainCollaterals[0].amount, 10 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 1 ether);
        assertEq(onChainFinalizableOracles.length, 0);
        assertEq(kpiTokenInstance.totalSupply(), 100 ether);
        assertEq(onChainInitialSupply, 100 ether);
        assertEq(kpiTokenInstance.creator(), address(this));
        assertEq(kpiTokenInstance.description(), "a");
        assertTrue(!onChainAndRelationship);
        assertEq(onChainName, "Token");
        assertEq(onChainSymbol, "TKN");
    }

    function testExpirationInThePast() external {
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

        vm.expectRevert(abi.encodeWithSignature("InvalidExpiration()"));
        factory.createToken(
            1,
            "a",
            block.timestamp - 1,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );
    }

    function testExpirationCurrentTimestamp() external {
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

        vm.expectRevert(abi.encodeWithSignature("InvalidExpiration()"));
        factory.createToken(
            1,
            "a",
            block.timestamp,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );
    }

    function testInitializationSuccess() external {
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

        uint256 _expiration = block.timestamp + 3;
        factory.createToken(
            1,
            "a",
            _expiration,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        ERC20KPIToken _token = ERC20KPIToken(_predictedKpiTokenAddress);
        assertEq(_token.expiration(), _expiration);
        assertTrue(!_token.expired());
    }
}
