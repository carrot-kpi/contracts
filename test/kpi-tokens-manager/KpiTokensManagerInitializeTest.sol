pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager instantiation test
/// @dev Tests KPI tokens manager instantiation.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KpiTokensManagerInitializeTest is BaseTestSetup {
    function testZeroAddressFactory() external {
        KPITokensManager _manager = new KPITokensManager();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressFactory()"));
        new ERC1967Proxy(address(_manager), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, address(0)));
    }
}
