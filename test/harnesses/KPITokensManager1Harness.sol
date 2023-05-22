pragma solidity 0.8.19;

import {KPITokensManager1} from "../../contracts/kpi-tokens-managers/KPITokensManager1.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";

contract KPITokensManager1Harness is KPITokensManager1 {
    constructor(address _factory) KPITokensManager1(_factory) {}

    function exposedLatestVersionStorageTemplate(uint256 _id)
        external
        view
        returns (Template memory)
    {
        return latestVersionStorageTemplate(_id);
    }
}
