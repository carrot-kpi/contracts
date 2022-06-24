pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory set oracles manager test
/// @dev Tests factory setter for oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract FactorySetOraclesManagerTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        factory.setOraclesManager(address(2));
    }

    function testZeroAddressManager() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressOraclesManager()")
        );
        factory.setOraclesManager(address(0));
    }

    function testSuccess() external {
        assertEq(factory.oraclesManager(), address(oraclesManager));
        address _newOraclesManager = address(2);
        factory.setOraclesManager(_newOraclesManager);
        assertEq(factory.oraclesManager(), _newOraclesManager);
    }
}
