pragma solidity 0.8.21;

import {ConstrainedOracle, Constraint} from "../../contracts/presets/oracles/ConstrainedOracle.sol";
import {IBaseTemplatesManager, Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {InitializeOracleParams} from "../../contracts/commons/Types.sol";
import {BaseOracle} from "../../contracts/presets/oracles/BaseOracle.sol";

contract MockBaseOracle is BaseOracle {
    bool public override finalized;

    function initialize(InitializeOracleParams memory _params) external payable override initializer {
        __BaseOracle_init(_params.kpiToken, _params.templateId, _params.templateVersion);
    }

    function data() external pure override returns (bytes memory) {
        return abi.encode("");
    }
}
