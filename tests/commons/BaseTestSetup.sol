pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "oz/proxy/transparent/ProxyAdmin.sol";
import {ERC20PresetMinterPauser} from "oz/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC20KPIToken} from "../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {KPITokensManager1} from "../../contracts/kpi-tokens-managers/KPITokensManager1.sol";
import {RealityV3Oracle} from "../../contracts/oracles/RealityV3Oracle.sol";
import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {IERC20KPIToken} from "../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Base test setup
/// @dev Test hook to set up a base test environment for each test.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
abstract contract BaseTestSetup is Test {
    string internal constant MANUAL_REALITY_ETH_SPECIFICATION =
        "QmRvoExBSESXedwqfC1cs4DGaRymnRR1wA9YGoZbqsE8Mf";
    string internal constant ERC20_KPI_TOKEN_SPECIFICATION =
        "QmXU4G418hZLL8yxXdjkTFSoH2FdSe6ELgUuSm5fHHJMMN";

    ERC20PresetMinterPauser internal firstErc20;
    ERC20PresetMinterPauser internal secondErc20;
    address internal feeReceiver;
    KPITokensFactory internal factory;
    ERC20KPIToken internal erc20KpiTokenTemplate;
    KPITokensManager1 internal kpiTokensManager;
    RealityV3Oracle internal realityV3OracleTemplate;
    address internal oraclesManagerImplementation;
    OraclesManager1 internal oraclesManager;
    ProxyAdmin internal oraclesManagerProxyAdmin;
    TransparentUpgradeableProxy internal oraclesManagerProxy;

    function setUp() external {
        firstErc20 = new ERC20PresetMinterPauser("Token 1", "TKN1");
        secondErc20 = new ERC20PresetMinterPauser("Token 2", "TKN2");

        feeReceiver = address(400);
        factory = new KPITokensFactory(address(1), address(1), feeReceiver);

        erc20KpiTokenTemplate = new ERC20KPIToken();
        kpiTokensManager = new KPITokensManager1(address(factory));
        kpiTokensManager.addTemplate(
            address(erc20KpiTokenTemplate),
            ERC20_KPI_TOKEN_SPECIFICATION
        );

        realityV3OracleTemplate = new RealityV3Oracle();
        oraclesManager = new OraclesManager1(address(factory));
        oraclesManager.addTemplate(
            address(realityV3OracleTemplate),
            MANUAL_REALITY_ETH_SPECIFICATION
        );

        factory.setKpiTokensManager(address(kpiTokensManager));
        factory.setOraclesManager(address(oraclesManager));
    }

    function createKpiToken(string memory _description, string memory _question)
        internal
        returns (ERC20KPIToken)
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

        firstErc20.mint(address(this), 2);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                address(this),
                1,
                _description,
                block.timestamp + 60,
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2);

        factory.createToken(
            1,
            _description,
            block.timestamp + 60,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        return
            ERC20KPIToken(
                factory.enumerate(
                    kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                    kpiTokensAmount > 0 ? kpiTokensAmount : 1
                )[0]
            );
    }
}
