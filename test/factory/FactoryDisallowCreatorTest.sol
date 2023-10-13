pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {TokenAmount} from "../../contracts/commons/Types.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {OracleData, MockKPIToken} from "../mocks/MockKPIToken.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory disallow creator test
/// @dev Tests KPI token factory's disallow creator function.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactoryDisallowCreatorTest is BaseTestSetup {
    function testNotOwner() external {
        factory.setPermissionless(false);
        assertFalse(factory.permissionless());

        address _creator = address(900010101);
        factory.allowCreator(_creator);
        assertTrue(factory.creatorAllowed(_creator));

        vm.prank(address(12344321));
        vm.expectRevert("Ownable: caller is not the owner");
        factory.disallowCreator(_creator);

        assertTrue(factory.creatorAllowed(_creator));
        vm.prank(_creator);
        string memory _description = "foo";
        MockKPIToken _kpiToken = createKpiToken(_description);
        assertEq(_kpiToken.description(), _description);
    }

    function testZeroAddressCreator() external {
        factory.setPermissionless(false);
        assertFalse(factory.permissionless());

        vm.expectRevert(abi.encodeWithSignature("ZeroAddressCreator()"));
        factory.disallowCreator(address(0));
    }

    function testSuccess() external {
        factory.setPermissionless(false);
        assertFalse(factory.permissionless());

        address _creator = address(900010101);
        factory.allowCreator(_creator);
        assertTrue(factory.creatorAllowed(_creator));
        vm.prank(_creator);
        string memory _description = "foo";
        MockKPIToken _kpiToken = createKpiToken(_description);
        assertEq(_kpiToken.description(), _description);

        vm.prank(factory.owner());
        factory.disallowCreator(_creator);
        assertFalse(factory.creatorAllowed(_creator));

        vm.prank(_creator);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        createKpiToken(_description);
    }
}
