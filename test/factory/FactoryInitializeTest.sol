pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory instantiation test
/// @dev Tests factory instantiation.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract FactoryInitializeTest is BaseTestSetup {
    function testZeroAddressKpiTokensManager() external {
        KPITokensFactory _factory = new KPITokensFactory();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressKpiTokensManager()"));
        new ERC1967Proxy(
            address(_factory),
            abi.encodeWithSelector(
                KPITokensFactory.initialize.selector,
                address(0),
                address(1),
                address(2)
            )
        );
    }

    function testZeroAddressOraclesManager() external {
        KPITokensFactory _factory = new KPITokensFactory();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressOraclesManager()"));
        new ERC1967Proxy(
            address(_factory),
            abi.encodeWithSelector(
                KPITokensFactory.initialize.selector,
                address(1),
                address(0),
                address(2)
            )
        );
    }

    function testZeroAddressFeeReceiver() external {
        KPITokensFactory _factory = new KPITokensFactory();
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressFeeReceiver()"));
        new ERC1967Proxy(
            address(_factory),
            abi.encodeWithSelector(
                KPITokensFactory.initialize.selector,
                address(1),
                address(2),
                address(0)
            )
        );
    }

    function testSuccess() external {
        initializeKPITokensFactory(address(1), address(2), address(3));
    }
}
