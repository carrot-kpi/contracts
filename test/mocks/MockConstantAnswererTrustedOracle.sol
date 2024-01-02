pragma solidity 0.8.21;

import {ConstantAnswererTrustedOracle} from "../../contracts/presets/oracles/ConstantAnswererTrustedOracle.sol";
import {BaseOracle} from "../../contracts/presets/oracles/BaseOracle.sol";
import {InitializeOracleParams} from "../../contracts/commons/Types.sol";

contract MockConstantAnswererTrustedOracle is BaseOracle, ConstantAnswererTrustedOracle {
    bool public override finalized;

    constructor(address _answerer) ConstantAnswererTrustedOracle(_answerer) {}

    function initialize(InitializeOracleParams memory _params) external payable override initializer {
        __BaseOracle_init(_params.kpiToken, _params.templateId, _params.templateVersion);
    }

    function checkAnswerer() external view {
        _checkAnswerer();
    }

    function data() external pure override returns (bytes memory) {
        return abi.encode("");
    }
}
