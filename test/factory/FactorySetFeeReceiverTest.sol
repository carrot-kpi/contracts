pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory set fee receiver test
/// @dev Tests factory setter for the fee receiver.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactorySetFeeReceiverTest is BaseTestSetup {
    function testNonOwner() external {
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        factory.setFeeReceiver(address(2));
    }

    function testZeroAddressFeeReceiver() external {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressFeeReceiver()"));
        factory.setFeeReceiver(address(0));
    }

    function testSuccess() external {
        assertEq(factory.feeReceiver(), feeReceiver);
        address _newFeeReceiver = address(2);
        factory.setFeeReceiver(_newFeeReceiver);
        assertEq(factory.feeReceiver(), _newFeeReceiver);
    }
}
