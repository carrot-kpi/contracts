pragma solidity 0.8.19;

import {ConstantAnswererTrustedOracle} from "../../contracts/presets/oracles/ConstantAnswererTrustedOracle.sol";
import {InitializeOracleParams} from "../../contracts/commons/Types.sol";

contract MockConstantAnswererTrustedOracle is ConstantAnswererTrustedOracle {
    constructor(address _answerer) ConstantAnswererTrustedOracle(_answerer) {}

    function initialize(InitializeOracleParams memory _params) external payable override initializer {
        __ConstantAnswererTrustedOracle_init(_params.kpiToken, _params.templateId, _params.templateVersion);
    }

    function checkAnswerer() external view {
        _checkAnswerer();
    }

    function data() external pure override returns (bytes memory) {
        return abi.encode("");
    }
}
