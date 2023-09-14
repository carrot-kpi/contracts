pragma solidity 0.8.19;

import {ConstrainedOracle, Constraint} from "../../contracts/presets/oracles/ConstrainedOracle.sol";
import {BaseOracle} from "../../contracts/presets/oracles/BaseOracle.sol";
import {IBaseTemplatesManager, Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {InitializeOracleParams} from "../../contracts/commons/Types.sol";

contract MockConstrainedOracle is BaseOracle, ConstrainedOracle {
    function initialize(InitializeOracleParams memory _params) external payable override initializer {
        (Constraint _constraint, uint256 _value0, uint256 _value1) =
            abi.decode(_params.data, (Constraint, uint256, uint256));
        __BaseOracle_init(_params.kpiToken, _params.templateId, _params.templateVersion);
        __ConstrainedOracle_init(_constraint, _value0, _value1);
    }

    function toCompletionPercentage(uint256 _result) external view returns (uint256) {
        return _toCompletionPercentage(_result);
    }

    function data() external view override returns (bytes memory) {
        return abi.encode(constraint, value0, value1);
    }
}
