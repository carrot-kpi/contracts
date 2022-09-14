pragma solidity 0.8.17;

import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {ERC20KPIToken} from "../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IERC20KPIToken} from "../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
import {KPITokensManager1} from "../contracts/kpi-tokens-managers/KPITokensManager1.sol";
import {KPITokensFactory} from "../contracts/KPITokensFactory.sol";
import {Vm} from "forge-std/Vm.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Create manual RealityEth ERC20 KPI token
/// @dev Creates a manual Reality ERC20 Kpi token on the target chain.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract CreateManualRealityEthERC20KpiToken {
    struct Args {
        KPITokensFactory factory;
        KPITokensManager1 kpiTokensManager;
        address collateralToken;
        uint256 collateralAmount;
        uint256 minimumPayout;
        uint256 lowerBound;
        uint256 higherBound;
        address reality;
        address arbitrator;
        string question;
        uint32 questionTimeout;
        uint32 expiry;
        string description;
        uint256 expiration;
    }

    event log_string(string);
    event log_address(address);

    Vm internal constant VM =
        Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));

    function run(
        KPITokensFactory _factory,
        KPITokensManager1 _kpiTokensManager,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _minimumPayout,
        uint256 _lowerBound,
        uint256 _higherBound,
        address _reality,
        address _arbitrator,
        string calldata _question,
        uint32 _questionTimeout,
        uint32 _expiry,
        string calldata _description,
        uint256 _expiration
    ) external {
        Args memory _args = Args({
            factory: _factory,
            kpiTokensManager: _kpiTokensManager,
            collateralToken: _collateralToken,
            collateralAmount: _collateralAmount,
            minimumPayout: _minimumPayout,
            lowerBound: _lowerBound,
            higherBound: _higherBound,
            reality: _reality,
            arbitrator: _arbitrator,
            question: _question,
            questionTimeout: _questionTimeout,
            expiry: _expiry,
            description: _description,
            expiration: _expiration
        });

        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: _args.collateralToken,
            amount: _args.collateralAmount,
            minimumPayout: _args.minimumPayout
        });
        bytes memory _kpiTokenInitializationData = abi.encode(
            _collaterals,
            "Manual Reality.eth KPI",
            "KPI",
            100_000 ether
        );

        IERC20KPIToken.OracleData[]
            memory _oraclesData = new IERC20KPIToken.OracleData[](1);
        _oraclesData[0] = IERC20KPIToken.OracleData({
            templateId: 1,
            lowerBound: _args.lowerBound,
            higherBound: _args.higherBound,
            weight: 1,
            value: 0,
            data: abi.encode(
                _args.reality,
                _args.arbitrator,
                uint256(1),
                _args.question,
                _args.questionTimeout,
                _args.expiry,
                0
            )
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oraclesData,
            false
        );

        address _predictedKpiTokenAddress = _args
            .kpiTokensManager
            .predictInstanceAddress(
                msg.sender,
                1,
                _args.description,
                _kpiTokenInitializationData,
                _oraclesInitializationData
            );
        emit log_string("KPI token will be deployed at address");
        emit log_address(_predictedKpiTokenAddress);

        VM.startBroadcast();
        IERC20(_args.collateralToken).approve(
            _predictedKpiTokenAddress,
            _args.collateralAmount
        );

        _args.factory.createToken(
            1,
            _args.description,
            _args.expiration,
            _kpiTokenInitializationData,
            _oraclesInitializationData
        );
        VM.stopBroadcast();
    }
}
