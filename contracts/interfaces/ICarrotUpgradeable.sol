pragma solidity >=0.8.0;

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Carrot upgradeable interface
/// @dev Interface for the Carrot upgradeable contract.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
interface ICarrotUpgradeable {
    function disallowUpgrades() external view returns (bool);

    function makeImmutable() external;
}
