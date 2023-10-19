pragma solidity 0.8.21;

import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "oz/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "oz-upgradeable/proxy/utils/Initializable.sol";
import {ICarrotUpgradeable} from "./interfaces/ICarrotUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Carrot upgradeable
/// @dev The Carrot upgradeable contract contains shared logic to be used
/// across Carrot to implement UUPS-compatible proxiable contracts.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract CarrotUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable, ICarrotUpgradeable {
    bool public disallowUpgrades;

    error Immutable();

    event MakeImmutable();

    constructor() {
        _disableInitializers();
    }

    /// @dev The function acts as a replacement for constructors in a proxy-based context.
    /// Calling this correctly initializes part of the internal state of the proxy.
    function __CarrotUpgradeable_init(address _owner) internal onlyInitializing {
        __Ownable_init(_owner);
    }

    /// @dev Makes the contract immutable and not upgradeable anymore. Use with caution.
    function makeImmutable() external override onlyOwner {
        disallowUpgrades = true;
        emit MakeImmutable();
    }

    /// @dev Part of the UUPS pattern, this function authorizes any upgrades to the
    /// proxy that points to this implementation contract. In this case if the
    /// owner of the contract is calling this and the `disallowUpgrades` state variable
    /// is false, the upgrade will be allowed.
    function _authorizeUpgrade(address) internal view override onlyOwner {
        if (disallowUpgrades) revert Immutable();
    }
}
