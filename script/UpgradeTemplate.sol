pragma solidity 0.8.19;

import {IBaseTemplatesManager} from "../contracts/interfaces/IBaseTemplatesManager.sol";
import {Script} from "forge-std/Script.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Upgrade template.
/// @dev Upgrades a template on a target network.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract UpgradeTemplate is Script {
    error ZeroAddress();
    error ZeroId();
    error InvalidSpecification();

    function run(
        address _templatesManager,
        uint256 _templateId,
        address _templateAddress,
        string calldata _specification
    ) external {
        if (_templatesManager == address(0)) revert ZeroAddress();
        if (_templateId == 0) revert ZeroId();
        if (_templateAddress == address(0)) revert ZeroAddress();
        if (bytes(_specification).length == 0) revert InvalidSpecification();

        vm.startBroadcast();
        IBaseTemplatesManager(_templatesManager).upgradeTemplate(_templateId, _templateAddress, _specification);
        vm.stopBroadcast();
    }
}
