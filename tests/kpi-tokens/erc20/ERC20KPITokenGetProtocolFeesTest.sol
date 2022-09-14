pragma solidity 0.8.17;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager1} from "../../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../../../contracts/commons/Types.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token get protocol fee test test
/// @dev Tests protocol fee query in ERC20 KPI token.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPITokenGetProtocolFeesTest is BaseTestSetup {
    function testTooManyCollaterals() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](6);
        for (uint160 i = 1; i <= 6; i++)
            collaterals[i - 1] = IERC20KPIToken.Collateral({
                token: address(i),
                amount: i,
                minimumPayout: i - 1
            });

        vm.expectRevert(abi.encodeWithSignature("TooManyCollaterals()"));
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testNoCollaterals() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](0);

        vm.expectRevert(abi.encodeWithSignature("NoCollaterals()"));
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testZeroAmountCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        uint256[] memory collaterals = new uint256[](1);
        collaterals[0] = 0;

        vm.expectRevert(abi.encodeWithSignature("InvalidCollateral()"));
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testZeroAddressCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        TokenAmount[] memory collaterals = new TokenAmount[](1);
        collaterals[0] = TokenAmount({token: address(0), amount: 1});

        vm.expectRevert(abi.encodeWithSignature("InvalidCollateral()"));
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testSuccess() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        uint256[] memory collaterals = new uint256[](2);
        collaterals[0] = 10 ether;
        collaterals[1] = 5 ether;

        uint256[] memory fees = abi.decode(
            kpiTokenInstance.protocolFee(abi.encode(collaterals)),
            (uint256[])
        );

        assertEq(fees.length, 2);
        assertEq(fees[0], 30000000000000000);
        assertEq(fees[1], 15000000000000000);
    }
}
