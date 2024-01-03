pragma solidity 0.8.23;

import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";

contract OraclesManagerHarness is OraclesManager {
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
