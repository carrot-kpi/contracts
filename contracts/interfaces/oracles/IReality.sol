pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title KPIToken
 * @dev KPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IReality {
    function askQuestion(
        uint256 _templateId,
        string calldata _question,
        address _arbitrator,
        uint32 _timeout,
        uint32 _openingTs,
        uint256 _nonce
    ) external returns (bytes32 _questionId);

    function resultFor(bytes32 _id) external returns (bytes32);
}
