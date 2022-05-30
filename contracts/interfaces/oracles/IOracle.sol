pragma solidity >=0.8.0;

import "../IOraclesManager.sol";

/**
 * @title IOracle
 * @dev IOracle contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IOracle {
    function initialize(
        address _kpiToken,
        uint256 _templateId,
        bytes memory _initializationData
    ) external;

    function kpiToken() external returns (address);

    function template() external view returns (IOraclesManager.Template memory);

    function finalized() external returns (bool);

    function data() external view returns (bytes memory);
}
