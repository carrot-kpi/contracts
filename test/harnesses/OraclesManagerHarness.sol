pragma solidity 0.8.19;

import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";

contract OraclesManagerHarness is OraclesManager {
    function exposedLatestVersionStorageTemplate(uint256 _id) external view returns (Template memory) {
        return latestVersionStorageTemplate(_id);
    }
}
