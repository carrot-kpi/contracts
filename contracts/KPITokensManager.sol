pragma solidity 0.8.23;

import {Clones} from "oz/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/IKPIToken.sol";
import {BaseTemplatesManager} from "./BaseTemplatesManager.sol";
import {Template} from "./interfaces/IBaseTemplatesManager.sol";
import {IKPITokensManager} from "./interfaces/IKPITokensManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager
/// @dev The KPI tokens manager contract acts as a template
/// registry for KPI token implementations. Additionally, templates
/// can also only be instantiated by the manager itself,
/// exclusively by request of the factory contract. All
/// template-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KPITokensManager is BaseTemplatesManager, IKPITokensManager {
    /// @dev Calculates the salt value used in CREATE2 when
    /// instantiating new templates.
    /// @param _creator The KPI token creator address.
    /// @param _id The KPI token template id being used.
    /// @param _description An IPFS cid pointing to a file describing what the KPI token is about.
    /// @param _expiration A timestamp indicating when the KPI token will expire.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The salt value.
    function salt(
        address _creator,
        uint256 _id,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(_creator, _id, _description, _expiration, _initializationData, _oraclesInitializationData)
        );
    }

    /// @dev Predicts a KPI token template instance address based on the input data.
    /// @param _creator The KPI token creator address.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a file describing what the KPI token is about.
    /// @param _expiration A timestamp indicating when the KPI token will expire.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters will be deployed.
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external view override returns (address) {
        return Clones.predictDeterministicAddress(
            latestVersionStorageTemplate(_id).addrezz,
            salt(_creator, _id, _description, _expiration, _initializationData, _oraclesInitializationData)
        );
    }

    /// @dev Instantiates a given template using ERC 1167 minimal proxies.
    /// @param _creator The KPI token creator address.
    /// @param _templateId The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a file describing what the KPI token is about.
    /// @param _expiration A timestamp indicating when the KPI token will expire.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters has been instantiated.
    function instantiate(
        address _creator,
        uint256 _templateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external override returns (address, uint128) {
        if (msg.sender != factory) revert Forbidden();
        Template memory _template = latestVersionStorageTemplate(_templateId);
        address _instance = Clones.cloneDeterministic(
            _template.addrezz,
            salt(_creator, _templateId, _description, _expiration, _initializationData, _oraclesInitializationData)
        );
        return (_instance, _template.version);
    }
}
