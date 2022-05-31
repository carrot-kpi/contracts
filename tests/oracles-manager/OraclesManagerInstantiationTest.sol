pragma solidity 0.8.14;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager instantiation test
/// @dev Tests instantiation in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerInstantiationTest is BaseTestSetup {
    function testZeroAddressFactory() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressFactory()")
        );
        new OraclesManager(
            address(0) /* , address(0) */
        );
    }

    function testZeroAddressJobsRegistry() external {
        new OraclesManager(
            address(factory) /* , address(0) */
        );
    }
}
