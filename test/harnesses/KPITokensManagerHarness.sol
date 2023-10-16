pragma solidity 0.8.21;

import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";

contract KPITokensManagerHarness is KPITokensManager {
    function exposedLatestVersionStorageTemplate(uint256 _id) external view returns (Template memory) {
        return latestVersionStorageTemplate(_id);
    }
}
