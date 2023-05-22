pragma solidity 0.8.19;

import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";

contract OraclesManager1Harness is OraclesManager1 {
    constructor(address _factory) OraclesManager1(_factory) {}

    function exposedLatestVersionStorageTemplate(uint256 _id)
        external
        view
        returns (Template memory)
    {
        return latestVersionStorageTemplate(_id);
    }
}
