pragma solidity 0.8.19;

import {IBaseTemplatesManager} from "../contracts/interfaces/IBaseTemplatesManager.sol";
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Update template specification at version.
/// @dev Updates a template specification at a certain version on a target network.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract UpdateTemplateSpecificationAtVersion is Script {
    error ZeroAddress();
    error ZeroId();
    error ZeroVersion();
    error InvalidSpecification();

    function run(
        address _templatesManager,
        uint256 _templateId,
        uint128 _templateVersion,
        string calldata _specification
    ) external {
        if (_templatesManager == address(0)) revert ZeroAddress();
        if (_templateId == 0) revert ZeroId();
        if (_templateVersion == 0) revert ZeroVersion();
        if (bytes(_specification).length == 0) revert InvalidSpecification();

        vm.startBroadcast();
        IBaseTemplatesManager(_templatesManager).updateTemplateSpecification(
            _templateId,
            _templateVersion,
            _specification
        );
        vm.stopBroadcast();
    }
}
