pragma solidity 0.8.23;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {MockKPIToken} from "../../../mocks/MockKPIToken.sol";
import {IOraclesManager} from "../../../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {InitializeKPITokenParams} from "../../../../contracts/commons/Types.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Base oracle preset initialize test
/// @dev Tests initialization in base oracle preset.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract BaseOracleInitializationTest is BaseTestSetup {
    function testZeroAddressOwner() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidOwner()"));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(0),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );
    }

    function testEmptyDescription() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidDescription()"));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "",
                expiration: block.timestamp,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );
    }

    function testInvalidExpiration() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidExpiration()"));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp - 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );
    }

    function testZeroAddressKPITokensManager() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidKPITokensManager()"));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(0),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp + 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );
    }

    function testZeroTemplateId() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidTemplateId()"));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 0,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp + 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );
    }

    function testZeroTemplateVersion() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidTemplateVersion()"));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 0,
                description: "foo",
                expiration: block.timestamp + 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );
    }

    function testTransferOwnershipNotOwner() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp + 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vm.prank(address(2));
        kpiTokenInstance.transferOwnership(address(3));
    }

    function testTransferOwnershipInvalidNewOwner() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp + 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );

        vm.expectRevert(abi.encodeWithSignature("InvalidOwner()"));
        vm.prank(address(1));
        kpiTokenInstance.transferOwnership(address(0));
    }

    function testTransferOwnershipSuccess() external {
        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: address(1),
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp + 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );

        assertEq(kpiTokenInstance.owner(), address(1));
        vm.prank(address(1));
        kpiTokenInstance.transferOwnership(address(2));
        assertEq(kpiTokenInstance.owner(), address(2));
    }

    function testFuzzTransferOwnershipSuccess(address _oldOwner, address _newOwner) external {
        vm.assume(_oldOwner != address(0));
        vm.assume(_newOwner != address(0));

        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: _oldOwner,
                oraclesManager: address(1),
                kpiTokensManager: address(2),
                feeReceiver: address(3),
                kpiTokenTemplateId: 1,
                kpiTokenTemplateVersion: 1,
                description: "foo",
                expiration: block.timestamp + 1,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );

        assertEq(kpiTokenInstance.owner(), _oldOwner);
        vm.prank(_oldOwner);
        kpiTokenInstance.transferOwnership(_newOwner);
        assertEq(kpiTokenInstance.owner(), _newOwner);
    }

    function testSuccess() external {
        address _creator = address(1);
        address _feeReceiver = address(2);
        Template memory _template = kpiTokensManager.template(1);
        uint256 _kpiTokenTemplateId = _template.id;
        uint128 _kpiTokenTemplateVersion = _template.version;
        string memory _description = "test-description";
        uint256 _expiration = block.timestamp + 10;

        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: _creator,
                oraclesManager: address(oraclesManager),
                kpiTokensManager: address(kpiTokensManager),
                feeReceiver: _feeReceiver,
                kpiTokenTemplateId: _kpiTokenTemplateId,
                kpiTokenTemplateVersion: _kpiTokenTemplateVersion,
                description: _description,
                expiration: _expiration,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );

        assertEq(kpiTokenInstance.owner(), _creator);
        assertEq(kpiTokenInstance.template().addrezz, _template.addrezz);
        assertEq(kpiTokenInstance.template().id, _kpiTokenTemplateId);
        assertEq(kpiTokenInstance.template().version, _kpiTokenTemplateVersion);
        assertEq(kpiTokenInstance.template().specification, _template.specification);
        assertEq(kpiTokenInstance.finalized(), false);
        assertEq(kpiTokenInstance.description(), _description);
        assertEq(kpiTokenInstance.expiration(), _expiration);
        assertEq(kpiTokenInstance.creationTimestamp(), block.timestamp);
    }

    function testFuzzSuccess(
        address _creator,
        string memory _description,
        uint256 _expiration,
        address _kpiTokensManager,
        uint256 _kpiTokenTemplateId,
        uint128 _kpiTokenTemplateVersion
    ) external {
        vm.assume(_creator != address(0));
        vm.assume(bytes(_description).length != 0);
        vm.assume(_expiration > block.timestamp);
        vm.assume(_kpiTokensManager != address(0));
        vm.assume(_kpiTokenTemplateId != 0);
        vm.assume(_kpiTokenTemplateVersion != 0);

        MockKPIToken kpiTokenInstance = MockKPIToken(Clones.clone(address(mockKpiTokenTemplate)));
        vm.prank(address(kpiTokensManager));
        kpiTokenInstance.initialize(
            InitializeKPITokenParams({
                creator: _creator,
                oraclesManager: address(oraclesManager),
                kpiTokensManager: address(kpiTokensManager),
                feeReceiver: address(2),
                kpiTokenTemplateId: _kpiTokenTemplateId,
                kpiTokenTemplateVersion: _kpiTokenTemplateVersion,
                description: _description,
                expiration: _expiration,
                kpiTokenData: abi.encode(""),
                oraclesData: abi.encode("")
            })
        );

        assertEq(kpiTokenInstance.owner(), _creator);
        assertEq(kpiTokenInstance.finalized(), false);
        assertEq(kpiTokenInstance.description(), _description);
        assertEq(kpiTokenInstance.expiration(), _expiration);
        assertEq(kpiTokenInstance.creationTimestamp(), block.timestamp);
    }
}
