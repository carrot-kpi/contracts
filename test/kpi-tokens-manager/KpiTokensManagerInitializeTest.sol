pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";
import {Initializable} from "oz/proxy/utils/Initializable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager instantiation test
/// @dev Tests KPI tokens manager instantiation.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerInitializeTest is BaseTestSetup {
    function testDisabledInitializerNonProxiedImplementationContract() external {
        KPITokensManager _manager = new KPITokensManager();
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        _manager.initialize(owner, address(1));
    }

    function testZeroAddressFactory() external {
        KPITokensManager _manager = new KPITokensManager();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressFactory()"));
        new ERC1967Proxy(
            address(_manager), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, owner, address(0))
        );
    }
}
