pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {TokenAmount} from "../../contracts/commons/Types.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {OracleData, MockKPIToken} from "../mocks/MockKPIToken.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory allow creator test
/// @dev Tests KPI token factory's allow creator function.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactoryAllowCreatorTest is BaseTestSetup {
    function testNotOwner() external {
        factory.setPermissionless(false);
        assertFalse(factory.permissionless());
        assertFalse(factory.creatorAllowed(address(this)));
        vm.prank(address(12344321));
        vm.expectRevert("Ownable: caller is not the owner");
        factory.allowCreator(address(this));
        assertFalse(factory.creatorAllowed(address(this)));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        factory.createToken(1, "foo", block.timestamp + 10, abi.encode("foo"), abi.encode("bar"));
    }

    function testZeroAddressCreator() external {
        factory.setPermissionless(false);
        assertFalse(factory.permissionless());
        assertFalse(factory.creatorAllowed(address(0)));
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressCreator()"));
        factory.allowCreator(address(0));
        assertFalse(factory.creatorAllowed(address(15525252)));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        factory.createToken(1, "foo", block.timestamp + 10, abi.encode("foo"), abi.encode("bar"));
    }

    function testSuccess() external {
        factory.setPermissionless(false);
        assertFalse(factory.permissionless());

        address _creator = address(9001);
        assertFalse(factory.creatorAllowed(_creator));
        vm.prank(_creator);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        factory.createToken(1, "foo", block.timestamp + 10, abi.encode("foo"), abi.encode("bar"));

        vm.prank(factory.owner());
        factory.allowCreator(_creator);
        assertTrue(factory.creatorAllowed(_creator));

        string memory _description = "foo";
        vm.prank(_creator);
        MockKPIToken _kpiToken = createKpiToken(_description);
        assertEq(_kpiToken.description(), _description);
    }
}
