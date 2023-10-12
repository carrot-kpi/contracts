pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager instantiation test
/// @dev Tests instantiation in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerInitializeTest is BaseTestSetup {
    function testZeroAddressFactory() external {
        OraclesManager _manager = new OraclesManager();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressFactory()"));
        new ERC1967Proxy(address(_manager), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, address(0)));
    }
}
