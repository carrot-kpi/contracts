pragma solidity >=0.8.0;

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager interface
/// @dev Interface for the oracles manager contract.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
interface IOraclesManager {
    struct Version {
        uint32 major;
        uint32 minor;
        uint32 patch;
    }

    struct Template {
        uint256 id;
        address addrezz;
        Version version;
        string specification;
        bool automatable;
    }

    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external returns (address);

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _specification
    ) external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function exists(uint256 _id) external view returns (bool);

    function templatesAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}
