pragma solidity >=0.8.0;

import {InitializeKPITokenParams} from "../commons/Types.sol";
import {IKPITokensManager} from "./IKPITokensManager.sol";
import {Template} from "./IBaseTemplatesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI token interface
/// @dev KPI token interface.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
interface IKPIToken {
    event Initialize(
        address indexed creator,
        uint256 creationTimestamp,
        uint256 indexed templateId,
        uint128 indexed templateVersion,
        string description,
        uint256 expiration
    );

    event Finalize(address indexed oracle, uint256 result);

    function initialize(InitializeKPITokenParams memory _params) external payable;

    function finalize(uint256 _result) external;

    function redeem(bytes memory _data) external;

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function template() external view returns (Template memory);

    function description() external view returns (string memory);

    function finalized() external view returns (bool);

    function expiration() external view returns (uint256);

    function creationTimestamp() external view returns (uint256);

    function data() external view returns (bytes memory);

    function oracles() external view returns (address[] memory);
}
