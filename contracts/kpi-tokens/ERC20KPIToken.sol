pragma solidity 0.8.15;

import {IERC20Upgradeable, ERC20Upgradeable} from "oz-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "oz-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "oz-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IOraclesManager} from "../interfaces/IOraclesManager.sol";
import {IKPITokensManager} from "../interfaces/IKPITokensManager.sol";
import {IERC20KPIToken} from "../interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../commons/Types.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token template implementation
/// @dev A KPI token template imlementation. The template produces ERC20 tokens
/// that can be distributed arbitrarily to communities or specific entities in order
/// to incentivize them to reach certain KPIs. Backing these tokens there are potentially
/// a multitude of other ERC20 tokens (up to 5), the release of which is linked to
/// reaching the predetermined KPIs or not. In order to check if these KPIs are reached
/// on-chain, oracles oracles are employed, and based on the results conveyed back to
/// the KPI token template, the collaterals are either unlocked or sent back to the
/// original KPI token creator. Interesting logic is additionally tied to the conditions
/// and collaterals, such as the possibility to have a minimum payout (a per-collateral
/// sum that will always be paid out to KPI token holders regardless of the fact that
/// KPIs are reached or not), weighted KPIs and multiple detached resolution or all-in-one
/// reaching of KPIs (explained more in details later).
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPIToken is
    ERC20Upgradeable,
    IERC20KPIToken,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant INVALID_ANSWER =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant MULTIPLIER = 64;

    bool internal allOrNone;
    uint16 internal toBeFinalized;
    address public creator;
    Collateral[] internal collaterals;
    FinalizableOracle[] internal finalizableOracles;
    string public description;
    uint256 public expiration;
    IKPITokensManager.Template internal kpiTokenTemplate;
    uint256 internal initialSupply;
    uint256 internal totalWeight;
    mapping(address => uint256) internal registeredBurn;
    mapping(address => uint256) internal postFinalizationCollateralAmount;

    error Forbidden();
    error NotInitialized();
    error InvalidCollateral();
    error InvalidFeeReceiver();
    error InvalidOraclesManager();
    error InvalidOracleBounds();
    error InvalidOracleWeights();
    error InvalidExpiration();
    error InvalidDescription();
    error TooManyCollaterals();
    error TooManyOracles();
    error InvalidName();
    error InvalidSymbol();
    error InvalidTotalSupply();
    error InvalidCreator();
    error InvalidKpiTokensManager();
    error ZeroAddressOraclesManager();
    error InvalidMinimumPayoutAfterFee();
    error DuplicatedCollateral();
    error Expired();
    error NoOracles();
    error NoCollaterals();
    error NothingToRedeem();
    error ZeroAddressToken();
    error ZeroAddressReceiver();
    error NothingToRecover();

    event Initialize(
        address indexed creator,
        uint256 indexed templateId,
        string description,
        uint256 expiration,
        bytes kpiTokenData,
        bytes oraclesData
    );
    event InitializeOracles(FinalizableOracle[] finalizableOracles);
    event CollectProtocolFees(TokenAmount[] collected, address _receiver);
    event Finalize(address indexed oracle, uint256 result);
    event RecoverERC20(
        address indexed token,
        uint256 amount,
        address indexed receiver
    );
    event Redeem(
        address indexed account,
        uint256 burned,
        RedeemedCollateral[] redeemed
    );
    event RegisterRedemption(address indexed account, uint256 burned);
    event RedeemCollateral(
        address indexed account,
        address indexed receiver,
        address collateral,
        uint256 amount
    );

    /// @dev Initializes the template through the passed in data. This function is
    /// generally invoked by the factory,
    /// in turn invoked by a KPI token creator.
    /// @param _creator Since the factory is assumed to be the caller of this function,
    /// it must forward the original caller (msg.sender, the KPI token creator) here.
    /// @param _kpiTokensManager The factory-forwarded address of the KPI tokens manager.
    /// @param _oraclesManager The factory-forwarded address of the oracles manager.
    /// @param _feeReceiver The factory-forwarded address of the fee receiver.
    /// @param _kpiTokenTemplateId The id of the template.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the
    /// @param _expiration A timestamp determining the expiration date of the KPI token (the
    /// expiration date is used to avoid a malicious/unresponsive oracle from locking up the
    /// funds and should be set accordingly).
    /// @param _kpiTokenData An ABI-encoded structure forwarded by the factory from the KPI token
    /// creator, containing the initialization parameters for the ERC20 KPI token template.
    /// In particular the structure is formed in the following way:
    /// - `Collateral[] memory _collaterals`: an array of `Collateral` structs conveying
    ///   information about the collaterals to be used (a limit of maximum 5 different
    ///   collateral is enforced, and duplicates are not allowed).
    /// - `string memory _erc20Name`: The `name` of the created ERC20 token.
    /// - `string memory _erc20Symbol`: The `symbol` of the created ERC20 token.
    /// - `string memory _erc20Supply`: The initial supply of the created ERC20 token.
    /// @param _oraclesData An ABI-encoded structure forwarded by the factory from the KPI token
    /// creator, containing the initialization parameters for the chosen oracle templates.
    /// In particular the structure is formed in the following way:
    /// - `OracleData[] memory _oracleDatas`: data about the oracle, such as:
    ///     - `uint256 _templateId`: The id of the chosed oracle template.
    ///     - `uint256 _lowerBound`: The number at which the oracle's reported result is
    ///       interpreted in a failed KPI (not reached). If the oracle linked to this lower
    ///       bound reports a final number above this, we know the KPI is at least partially
    ///       reached.
    ///     - `uint256 _higherBound`: The number at which the oracle's reported result
    ///       is interpreted in a full verification of the KPI (fully reached). If the
    ///       oracle linked to this higher bound reports a final number equal or greater
    ///       than this, we know the KPI has fully been reached.
    ///     - `uint256 _weight`: The KPI weight determines the importance of it and how
    ///       much of the collateral a specific KPI "governs". If for example we have 2
    ///       KPIs A and B with respective weights 1 and 2, a third of the deposited
    ///       collaterals goes towards incentivizing A, while the remaining 2/3rds go
    ///       to B (i.e. B is valued as a more critical KPI to reach compared to A, and
    ///       collaterals reflect this).
    ///     - `uint256 _data`: ABI-encoded, oracle-specific data used to effectively
    ///       instantiate the oracle in charge of monitoring this KPI and reporting the
    ///       final result on-chain.
    /// - `bool _allOrNone`: Whether all KPIs should be at least partly reached in
    ///   order to unlock collaterals for KPI token holders to redeem (minus the minimum
    ///   payout amount, which is unlocked under any circumstance).
    function initialize(
        address _creator,
        address _kpiTokensManager,
        address _oraclesManager,
        address _feeReceiver,
        uint256 _kpiTokenTemplateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _kpiTokenData,
        bytes memory _oraclesData
    ) external override initializer {
        initializeState(
            _creator,
            _kpiTokensManager,
            _kpiTokenTemplateId,
            _description,
            _expiration,
            _kpiTokenData
        );

        (Collateral[] memory _collaterals, , , ) = abi.decode(
            _kpiTokenData,
            (Collateral[], string, string, uint256)
        );

        collectCollateralsAndFees(_creator, _collaterals, _feeReceiver);
        initializeOracles(_creator, _oraclesManager, _oraclesData);

        emit Initialize(
            _creator,
            _kpiTokenTemplateId,
            _description,
            _expiration,
            _kpiTokenData,
            _oraclesData
        );
    }

    /// @dev Utility function used to perform checks and partially initialize the state
    /// of the KPI token. This is only invoked by the more generic `initialize` function.
    /// @param _creator Since the factory is assumed to be the caller of this function,
    /// it must forward the original caller (msg.sender, the KPI token creator) here.
    /// @param _kpiTokensManager The factory-forwarded address of the KPI tokens manager.
    /// @param _kpiTokenTemplateId The id of the template.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the
    /// @param _expiration A timestamp determining the expiration date of the KPI token (the
    /// @param _data ABI-encoded data used to configura the KPI token (see the doc of the
    /// `initialize` function for more on this).
    function initializeState(
        address _creator,
        address _kpiTokensManager,
        uint256 _kpiTokenTemplateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _data
    ) internal onlyInitializing {
        if (_creator == address(0)) revert InvalidCreator();
        if (_kpiTokensManager == address(0)) revert InvalidKpiTokensManager();
        if (bytes(_description).length == 0) revert InvalidDescription();
        if (_expiration <= block.timestamp) revert InvalidExpiration();

        (
            ,
            string memory _erc20Name,
            string memory _erc20Symbol,
            uint256 _erc20Supply
        ) = abi.decode(_data, (Collateral[], string, string, uint256));

        if (bytes(_erc20Name).length == 0) revert InvalidName();
        if (bytes(_erc20Symbol).length == 0) revert InvalidSymbol();
        if (_erc20Supply == 0) revert InvalidTotalSupply();

        __ReentrancyGuard_init();
        __ERC20_init(_erc20Name, _erc20Symbol);
        _mint(_creator, _erc20Supply);

        initialSupply = _erc20Supply;
        creator = _creator;
        description = _description;
        expiration = _expiration;
        kpiTokenTemplate = IKPITokensManager(_kpiTokensManager).template(
            _kpiTokenTemplateId
        );
    }

    /// @dev Utility function used to collect collateral and fees from the KPI token
    /// creator. This is only invoked by the more generic `initialize` function.
    /// @param _creator The KPI token creator.
    /// @param _collaterals The collaterals array as taken from the ABI-encoded data
    /// passed in by the KPI token creator.
    /// @param _feeReceiver The factory-forwarded address of the fee receiver.
    function collectCollateralsAndFees(
        address _creator,
        Collateral[] memory _collaterals,
        address _feeReceiver
    ) internal onlyInitializing {
        if (_collaterals.length == 0) revert NoCollaterals();
        if (_collaterals.length > 5) revert TooManyCollaterals();
        if (_feeReceiver == address(0)) revert InvalidFeeReceiver();

        TokenAmount[] memory _collectedFees = new TokenAmount[](
            _collaterals.length
        );
        for (uint8 _i = 0; _i < _collaterals.length; _i++) {
            Collateral memory _collateral = _collaterals[_i];
            if (
                _collateral.token == address(0) ||
                _collateral.amount == 0 ||
                _collateral.minimumPayout >= _collateral.amount
            ) revert InvalidCollateral();
            for (uint8 _j = _i + 1; _j < _collaterals.length; _j++)
                if (_collateral.token == _collaterals[_j].token)
                    revert DuplicatedCollateral();
            IERC20Upgradeable(_collateral.token).safeTransferFrom(
                _creator,
                address(this),
                _collateral.amount
            );
            uint256 _fee = calculateProtocolFee(_collateral.amount);
            if (_fee > 0) {
                IERC20Upgradeable(_collateral.token).safeTransfer(
                    _feeReceiver,
                    _fee
                );
            }
            uint256 _amountMinusFees;
            unchecked {
                _amountMinusFees = _collateral.amount - _fee;
            }
            if (_amountMinusFees <= _collateral.minimumPayout)
                revert InvalidMinimumPayoutAfterFee();
            unchecked {
                _collateral.amount = _amountMinusFees;
            }
            _collectedFees[_i] = TokenAmount({
                token: _collateral.token,
                amount: _fee
            });
            collaterals.push(_collateral);
        }

        emit CollectProtocolFees(_collectedFees, _feeReceiver);
    }

    /// @dev Initializes the oracles tied to this KPI token (both the actual oracle
    /// instantiation and configuration data needed to interpret the relayed result
    /// at the KPI-token level). This function is only invoked by the `initialize` function.
    /// @param _creator The KPI token creator.
    /// @param _oraclesManager The address of the oracles manager, used to instantiate
    /// the oracles.
    /// @param _data ABI-encoded data used to create and configura the oracles (see
    /// the doc of the `initialize` function for more on this).
    function initializeOracles(
        address _creator,
        address _oraclesManager,
        bytes memory _data
    ) internal onlyInitializing {
        if (_oraclesManager == address(0)) revert InvalidOraclesManager();

        (OracleData[] memory _oracleDatas, bool _allOrNone) = abi.decode(
            _data,
            (OracleData[], bool)
        );

        if (_oracleDatas.length == 0) revert NoOracles();
        if (_oracleDatas.length > 5) revert TooManyOracles();

        FinalizableOracle[]
            memory _finalizableOracles = new FinalizableOracle[](
                _oracleDatas.length
            );
        for (uint16 _i = 0; _i < _oracleDatas.length; _i++) {
            OracleData memory _oracleData = _oracleDatas[_i];
            if (_oracleData.higherBound <= _oracleData.lowerBound)
                revert InvalidOracleBounds();
            if (_oracleData.weight == 0) revert InvalidOracleWeights();
            totalWeight += _oracleData.weight;
            address _instance = IOraclesManager(_oraclesManager).instantiate(
                _creator,
                _oracleData.templateId,
                _oracleData.data
            );
            FinalizableOracle memory _finalizableOracle = FinalizableOracle({
                addrezz: _instance,
                lowerBound: _oracleData.lowerBound,
                higherBound: _oracleData.higherBound,
                finalProgress: 0,
                weight: _oracleData.weight,
                finalized: false
            });
            _finalizableOracles[_i] = _finalizableOracle;
            finalizableOracles.push(_finalizableOracle);
        }

        toBeFinalized = uint16(_oracleDatas.length);
        allOrNone = _allOrNone;

        emit InitializeOracles(_finalizableOracles);
    }

    /// @dev Given an input address, returns a storage pointer to the
    /// `FinalizableOracle` struct associated with it. It reverts if
    /// the association does not exists.
    /// @param _address The finalizable oracle address.
    function finalizableOracle(address _address)
        internal
        view
        returns (FinalizableOracle storage)
    {
        for (uint256 _i = 0; _i < finalizableOracles.length; _i++) {
            FinalizableOracle storage _finalizableOracle = finalizableOracles[
                _i
            ];
            if (
                !_finalizableOracle.finalized &&
                _finalizableOracle.addrezz == _address
            ) return _finalizableOracle;
        }
        revert Forbidden();
    }

    /// @dev Finalizes a condition linked with the KPI token. Exclusively
    /// callable by oracles linked with the KPI token in order to report the
    /// final outcome for a KPI once everything has played out "in the real world".
    /// Based on the reported results and the template configuration, collateral is
    /// either reserved to be redeemed by KPI token holders when full finalization is
    /// reached (i.e. when all the oracles have reported their final result), or sent
    /// back to the original KPI token creator (for example when KPIs have not been
    /// met, minus any present minimum payout). The possible scenarios are the following:
    ///
    /// If a result is either invalid or below the lower bound set for the KPI:
    /// - If an "all or none" approach has been chosen at the KPI token initialization
    /// time, all the collateral is sent back to the KPI token creator and the KPI token
    /// expires worthless on the spot.
    /// - If no "all or none" condition has been set, the KPI contracts calculates how
    /// much of the collaterals the specific condition "governed" (through the weighting
    /// mechanism), subtracts any minimum payout for these and sends back the right amount
    /// of collateral to the KPI token creator.
    ///
    /// If a result is in the specified range (and NOT above the higher bound) set for
    /// the KPI, the same calculations happen and some of the collateral gets sent back
    /// to the KPI token creator depending on how far we were from reaching the full KPI
    /// progress.
    ///
    /// If a result is at or above the higher bound set for the KPI token, pretty much
    /// nothing happens to the collateral, which is fully assigned to the KPI token holders
    /// and which will become redeemable once the finalization process has ended for all
    /// the oracles assigned to the KPI token.
    ///
    /// Once all the oracles associated with the KPI token have reported their end result and
    /// finalize, the remaining collateral, if any, becomes redeemable by KPI token holders.
    /// @param _result The oracle end result.
    function finalize(uint256 _result) external override nonReentrant {
        if (!_isInitialized()) revert NotInitialized();

        FinalizableOracle storage _oracle = finalizableOracle(msg.sender);
        if (_isFinalized() || _isExpired()) {
            _oracle.finalized = true;
            emit Finalize(msg.sender, _result);
            return;
        }

        if (_result <= _oracle.lowerBound || _result == INVALID_ANSWER) {
            bool _allOrNone = allOrNone;
            handleLowOrInvalidResult(_oracle, _allOrNone);
            if (_allOrNone) {
                toBeFinalized = 0;
                _oracle.finalized = true;
                registerPostFinalizationCollateralAmounts();
                emit Finalize(msg.sender, _result);
                return;
            }
        } else {
            handleIntermediateOrOverHigherBoundResult(_oracle, _result);
        }

        _oracle.finalized = true;
        unchecked {
            --toBeFinalized;
        }

        if (_isFinalized()) registerPostFinalizationCollateralAmounts();

        emit Finalize(msg.sender, _result);
    }

    /// @dev Handles collateral state changes in case an oracle reported a low or invalid
    /// answer. In particular:
    /// - If an "all or none" approach has been chosen at the KPI token initialization
    /// level, all the collateral minus any minimum payour is marked to be recovered
    /// by the KPI token creator. From the KPI token holder's point of view, the token
    /// expires worthless on the spot.
    /// - If no "all or none" condition has been set, the KPI contract calculates how
    /// much of the collaterals the specific condition "governed" (through the weighting
    /// mechanism), subtracts any minimum payout for these and sends back the right amount
    /// of collateral to the KPI token creator.
    /// @param _oracle The oracle being finalized.
    /// @param _allOrNone Whether all the oracles are in an "all or none" configuration or not.
    function handleLowOrInvalidResult(
        FinalizableOracle storage _oracle,
        bool _allOrNone
    ) internal {
        for (uint256 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            uint256 _reimboursement;
            if (_allOrNone) {
                unchecked {
                    _reimboursement =
                        _collateral.amount -
                        _collateral.minimumPayout;
                }
            } else {
                uint256 _numerator = ((_collateral.amount -
                    _collateral.minimumPayout) * _oracle.weight) << MULTIPLIER;
                _reimboursement = (_numerator / totalWeight) >> MULTIPLIER;
            }
            unchecked {
                _collateral.amount -= _reimboursement;
            }
        }
    }

    /// @dev Handles collateral state changes in case an oracle reported an intermediate answer.
    /// In particular if a result is in the specified range (and NOT above the higher bound) set
    /// for the KPI, the same calculations happen and some of the collateral gets sent back
    /// to the KPI token creator depending on how far we were from reaching the full KPI
    /// progress.
    ///
    /// If a result is at or above the higher bound set for the KPI token, pretty much
    /// nothing happens to the collateral, which is fully assigned to the KPI token holders
    /// and which will become redeemable once the finalization process has ended for all
    /// the oracles assigned to the KPI token.
    ///
    /// Once all the oracles associated with the KPI token have reported their end result and
    /// finalize, the remaining collateral, if any, becomes redeemable by KPI token holders.
    /// @param _oracle The oracle being finalized.
    /// @param _result The result the oracle is reporting.
    function handleIntermediateOrOverHigherBoundResult(
        FinalizableOracle storage _oracle,
        uint256 _result
    ) internal {
        uint256 _oracleFullRange;
        uint256 _finalOracleProgress;
        unchecked {
            _oracleFullRange = _oracle.higherBound - _oracle.lowerBound;
            _finalOracleProgress = _result >= _oracle.higherBound
                ? _oracleFullRange
                : _result - _oracle.lowerBound;
        }
        _oracle.finalProgress = _finalOracleProgress;
        if (_finalOracleProgress < _oracleFullRange) {
            for (uint8 _i = 0; _i < collaterals.length; _i++) {
                Collateral storage _collateral = collaterals[_i];
                uint256 _numerator = ((_collateral.amount -
                    _collateral.minimumPayout) *
                    _oracle.weight *
                    (_oracleFullRange - _finalOracleProgress)) << MULTIPLIER;
                uint256 _denominator = _oracleFullRange * totalWeight;
                uint256 _reimboursement = (_numerator / _denominator) >>
                    MULTIPLIER;
                unchecked {
                    _collateral.amount -= _reimboursement;
                }
            }
        }
    }

    /// @dev After the KPI token has successfully been finalized, this function registers
    /// the collaterals situation before any redemptions happens. This is used to be able
    /// to handle the separate burn/redeem feature, increasing the overall security of the
    /// solution (a subset of malicious/unresponsive tokens will not be enough to jeopardize
    /// the whole campaign).
    function registerPostFinalizationCollateralAmounts() internal {
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral memory _collateral = collaterals[_i];
            postFinalizationCollateralAmount[_collateral.token] = _collateral
                .amount;
        }
    }

    /// @dev Callable by the KPI token creator, this function lets them recover any ERC20
    /// token sent to the KPI token contract. An arbitrary receiver address can be specified
    /// so that the function can be used to also help users that did something wrong by
    /// mistake by sending ERC20 tokens here. Two scenarios are possible here:
    /// - The KPI token creator wants to recover unused collateral that has been unlocked
    ///   by the KPI token after one or more oracle finalizations.
    /// - The KPI token creator wants to recover an arbitrary ERC20 token sent by mistake
    ///   to the KPI token contract (even the ERC20 KPI token itself can be recovered from
    ///   the contract).
    /// @param _token The ERC20 token address to be rescued.
    /// @param _receiver The address to which the rescued ERC20 tokens (if any) will be sent.
    function recoverERC20(address _token, address _receiver) external override {
        if (_receiver == address(0)) revert ZeroAddressReceiver();
        if (msg.sender != creator) revert Forbidden();
        bool _expired = _isExpired();
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral memory _collateral = collaterals[_i];
            if (_collateral.token == _token) {
                uint256 _balance = IERC20Upgradeable(_token).balanceOf(
                    address(this)
                );
                uint256 _unneededBalance = _balance;
                if (_expired) {
                    _collateral.amount = 0;
                } else {
                    unchecked {
                        _unneededBalance -= _collateral.amount;
                    }
                }
                if (_unneededBalance == 0) revert NothingToRecover();
                IERC20Upgradeable(_token).safeTransfer(
                    _receiver,
                    _unneededBalance
                );
                emit RecoverERC20(_token, _unneededBalance, _receiver);
                return;
            }
        }
        uint256 _reimboursement = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        if (_reimboursement == 0) revert NothingToRecover();
        IERC20Upgradeable(_token).safeTransfer(_receiver, _reimboursement);
        emit RecoverERC20(_token, _reimboursement, _receiver);
    }

    /// @dev Given a collateral amount, calculates the protocol fee as a percentage of it.
    /// @param _amount The collateral amount end result.
    /// @return The protocol fee amount.
    function calculateProtocolFee(uint256 _amount)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return (_amount * 3_000) / 1_000_000;
        }
    }

    /// @dev Only callable by KPI token holders, lets them redeem any collateral
    /// left in the contract after finalization, proportional to their balance
    /// compared to the total supply and left collateral amount. If the KPI token
    /// has expired worthless, this simply burns the user's KPI tokens.
    function redeem() external override nonReentrant {
        if (!_isFinalized() && block.timestamp < expiration) revert Forbidden();
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        if (_kpiTokenBalance == 0) revert Forbidden();
        RedeemedCollateral[]
            memory _redeemedCollaterals = new RedeemedCollateral[](
                collaterals.length
            );
        bool _expired = _isExpired();
        uint256 _initialSupply = initialSupply;
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            uint256 _redeemableAmount = 0;
            if (!_expired) {
                unchecked {
                    _redeemableAmount =
                        (postFinalizationCollateralAmount[_collateral.token] *
                            _kpiTokenBalance) /
                        _initialSupply;
                    _collateral.amount -= _redeemableAmount;
                }
                if (_redeemableAmount > 0) {
                    IERC20Upgradeable(_collateral.token).safeTransfer(
                        msg.sender,
                        _redeemableAmount
                    );
                }
            }
            _redeemedCollaterals[_i] = RedeemedCollateral({
                token: _collateral.token,
                amount: _redeemableAmount
            });
        }
        _burn(msg.sender, _kpiTokenBalance);
        emit Redeem(msg.sender, _kpiTokenBalance, _redeemedCollaterals);
    }

    /// @dev Only callable by KPI token holders, lets them register their redemption
    /// by burning the KPI tokens they have. Using this function, any collateral gained
    /// by the KPI token resolution must be explicitly requested by the user through
    /// the `redeemCollateral` function.
    function registerRedemption() external override {
        if (!_isFinalized() && block.timestamp < expiration) revert Forbidden();
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        if (_kpiTokenBalance == 0) revert Forbidden();
        _burn(msg.sender, _kpiTokenBalance);
        registeredBurn[msg.sender] = _kpiTokenBalance;
        emit RegisterRedemption(msg.sender, _kpiTokenBalance);
    }

    /// @dev Only callable by KPI token holders that have previously explicitly burned their
    /// KPI tokens through the `registerRedemption` function, this redeems the collateral
    /// token specified as input in the function. The function reverts if either an invalid
    /// collateral is specified or if zero of the given collateral can be redeemed.
    function redeemCollateral(address _token, address _receiver)
        external
        override
    {
        if (_token == address(0)) revert ZeroAddressToken();
        if (_receiver == address(0)) revert ZeroAddressReceiver();
        if (!_isFinalized() && block.timestamp < expiration) revert Forbidden();
        if (_isExpired()) revert Expired();
        uint256 _burned = registeredBurn[msg.sender];
        if (_burned == 0) revert Forbidden();
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            if (_collateral.token == _token) {
                uint256 _redeemableAmount;
                unchecked {
                    _redeemableAmount =
                        (postFinalizationCollateralAmount[_collateral.token] *
                            _burned) /
                        initialSupply;
                    if (_redeemableAmount == 0) revert NothingToRedeem();
                    _collateral.amount -= _redeemableAmount;
                }
                IERC20Upgradeable(_token).safeTransfer(
                    _receiver,
                    _redeemableAmount
                );
                delete registeredBurn[msg.sender];
                emit RedeemCollateral(
                    msg.sender,
                    _token,
                    _receiver,
                    _redeemableAmount
                );
                return;
            }
        }
        revert InvalidCollateral();
    }

    /// @dev Given ABI-encoded data about the collaterals a user intends to use
    /// to create a KPI token, gives back a fee breakdown detailing how much
    /// fees will be taken from the collaterals. The ABI-encoded params must be
    /// a `TokenAmount` array (with a maximum of 5 elements).
    /// @return An ABI-encoded fee breakdown represented by a `TokenAmount` array.
    function protocolFee(bytes calldata _data)
        external
        pure
        returns (bytes memory)
    {
        TokenAmount[] memory _collaterals = abi.decode(_data, (TokenAmount[]));

        if (_collaterals.length == 0) revert NoCollaterals();
        if (_collaterals.length > 5) revert TooManyCollaterals();

        TokenAmount[] memory _fees = new TokenAmount[](_collaterals.length);
        for (uint8 _i = 0; _i < _collaterals.length; _i++) {
            TokenAmount memory _collateral = _collaterals[_i];
            if (_collateral.token == address(0) || _collateral.amount == 0)
                revert InvalidCollateral();
            for (uint8 _j = _i + 1; _j < _collaterals.length; _j++)
                if (_collateral.token == _collaterals[_j].token)
                    revert DuplicatedCollateral();
            _fees[_i] = TokenAmount({
                token: _collateral.token,
                amount: calculateProtocolFee(_collateral.amount)
            });
        }

        return abi.encode(_fees);
    }

    /// @dev View function to check if the KPI token is finalized.
    /// @return A bool describing whether the token is finalized or not.
    function _isFinalized() internal view returns (bool) {
        return toBeFinalized == 0;
    }

    /// @dev View function to check if the KPI token is finalized.
    /// @return A bool describing whether the token is finalized or not.
    function finalized() external view override returns (bool) {
        return _isFinalized();
    }

    /// @dev View function to check if the KPI token is expired. A KPI token is
    /// considered expired when not finalized before the expiration date comes.
    /// @return A bool describing whether the token is finalized or not.
    function _isExpired() internal view returns (bool) {
        return !_isFinalized() && expiration <= block.timestamp;
    }

    /// @dev View function to check if the KPI token is expired. A KPI token is
    /// considered expired when not finalized before the expiration date comes.
    /// @return A bool describing whether the token is finalized or not.
    function expired() external view override returns (bool) {
        return _isExpired();
    }

    /// @dev View function to check if the KPI token is initialized.
    /// @return A bool describing whether the token is initialized or not.
    function _isInitialized() internal view returns (bool) {
        return creator != address(0);
    }

    /// @dev View function to query all the oracles associated with the KPI token at once.
    /// @return The oracles array.
    function oracles() external view override returns (address[] memory) {
        if (!_isInitialized()) revert NotInitialized();
        address[] memory _oracleAddresses = new address[](
            finalizableOracles.length
        );
        for (uint256 _i = 0; _i < _oracleAddresses.length; _i++)
            _oracleAddresses[_i] = finalizableOracles[_i].addrezz;
        return _oracleAddresses;
    }

    /// @dev View function returning all the most important data about the KPI token, in
    /// an ABI-encoded structure. The structure includes collaterals, finalizable oracles,
    /// "all-or-none" flag, initial supply of the ERC20 KPI token, along with name and symbol.
    /// @return The ABI-encoded data.
    function data() external view returns (bytes memory) {
        return
            abi.encode(
                collaterals,
                finalizableOracles,
                allOrNone,
                initialSupply,
                name(),
                symbol()
            );
    }

    /// @dev View function returning info about the template used to instantiate this KPI token.
    /// @return The template struct.
    function template()
        external
        view
        override
        returns (IKPITokensManager.Template memory)
    {
        return kpiTokenTemplate;
    }
}
