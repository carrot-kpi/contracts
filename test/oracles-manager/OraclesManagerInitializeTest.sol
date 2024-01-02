pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";
import {Initializable} from "oz/proxy/utils/Initializable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager instantiation test
/// @dev Tests instantiation in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerInitializeTest is BaseTestSetup {
    function testDisabledInitializerNonProxiedImplementationContract() external {
        OraclesManager _manager = new OraclesManager();
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        _manager.initialize(owner, address(1));
    }

    function testZeroAddressFactory() external {
        OraclesManager _manager = new OraclesManager();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressFactory()"));
        new ERC1967Proxy(
            address(_manager), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, owner, address(0))
        );
    }
}
