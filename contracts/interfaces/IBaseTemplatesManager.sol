pragma solidity >=0.8.0;

struct Template {
    address addrezz;
    uint128 version;
    uint256 id;
    string specification;
}

struct Feature {
    bool paused;
    mapping(address account => bool access) allowed;
}

struct TemplateFeatureSet {
    address owner;
    mapping(uint256 id => Feature) feature;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Base templates manager interface
/// @dev Interface for the base templates manager contract.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
interface IBaseTemplatesManager {
    function factory() external returns (address);

    function addTemplate(address _template, string calldata _specification) external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(uint256 _id, address _newTemplate, string calldata _newSpecification) external;

    function updateTemplateSpecification(uint256 _id, string calldata _newSpecification) external;

    function updateTemplateSpecification(uint256 _id, uint128 _version, string calldata _newSpecification) external;

    function isTemplateFeatureEnabledFor(uint256 _templateId, uint256 _featureId, address _account)
        external
        view
        returns (bool);

    function setTemplateFeaturesOwner(uint256 _templateId, address _owner) external;

    function enableTemplateFeatureFor(uint256 _templateId, uint256 _featureId, address _account) external;

    function disableTemplateFeatureFor(uint256 _templateId, uint256 _featureId, address _account) external;

    function pauseFeature(uint256 _templateId, uint256 _featureId) external;

    function unpauseFeature(uint256 _templateId, uint256 _featureId) external;

    function template(uint256 _id) external view returns (Template memory);

    function template(uint256 _id, uint128 _version) external view returns (Template memory);

    function templateExists(uint256 _id) external view returns (bool);

    function templatesAmount() external view returns (uint256);

    function nextTemplateId() external view returns (uint256);

    function enumerateTemplates(uint256 _fromIndex, uint256 _toIndex) external view returns (Template[] memory);
}
