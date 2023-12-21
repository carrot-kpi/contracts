pragma solidity 0.8.21;

import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";

contract KPITokensManagerHarness is KPITokensManager {
    function exposedLatestVersionStorageTemplate(uint256 _id) external view returns (Template memory) {
        return latestVersionStorageTemplate(_id);
    }

    function exposedFeatureSetOwner(uint256 _templateId) external view returns (address) {
        return featureSet[_templateId].owner;
    }

    function exposedFeaturePaused(uint256 _templateId, uint256 _featureId) external view returns (bool) {
        return featureSet[_templateId].feature[_featureId].paused;
    }
}
