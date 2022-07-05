pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager instantiation test
/// @dev Tests instantiation in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerInstantiationTest is BaseTestSetup {
    function testZeroAddressFactory() external {
        oraclesManager = new OraclesManager();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressFactory()"));
        oraclesManager.initialize(address(0));
    }
}
