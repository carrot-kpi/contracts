pragma solidity >=0.8.0;

import {IOraclesManager} from "./IOraclesManager.sol";
import {InitializeOracleParams} from "../commons/Types.sol";
import {Template} from "./IBaseTemplatesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracle interface
/// @dev Oracle interface.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
interface IOracle {
    event Initialize(
        address creator, address indexed kpiToken, uint256 indexed templateId, uint128 indexed templateVersion
    );

    event Finalize(uint256 result);

    function initialize(InitializeOracleParams memory _params) external payable;

    function kpiToken() external returns (address);

    function template() external view returns (Template memory);

    function finalized() external view returns (bool);

    function data() external view returns (bytes memory);
}
