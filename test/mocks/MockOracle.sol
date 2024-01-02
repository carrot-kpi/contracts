pragma solidity 0.8.21;

import {Initializable} from "oz/proxy/utils/Initializable.sol";
import {IOracle} from "../../contracts/interfaces/IOracle.sol";
import {IKPIToken} from "../../contracts/interfaces/IKPIToken.sol";
import {IBaseTemplatesManager, Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {InitializeOracleParams} from "../../contracts/commons/Types.sol";

contract MockOracle is IOracle, Initializable {
    address public constant RESULT_GETTER = address(4321);

    bool public override finalized;
    address public kpiToken;
    address internal oraclesManager;
    uint128 internal templateVersion;
    uint256 internal templateId;

    error Forbidden();
    error ZeroAddressKpiToken();

    function initialize(InitializeOracleParams memory _params) external payable override initializer {
        if (_params.kpiToken == address(0)) revert ZeroAddressKpiToken();
        oraclesManager = msg.sender;
        templateVersion = _params.templateVersion;
        templateId = _params.templateId;
        kpiToken = _params.kpiToken;
    }

    function finalize() external {
        if (finalized) revert Forbidden();
        finalized = true;
        IKPIToken(kpiToken).finalize(0);
    }

    function data() external pure override returns (bytes memory) {
        return abi.encode("");
    }

    function template() external view override returns (Template memory) {
        return IBaseTemplatesManager(oraclesManager).template(templateId, templateVersion);
    }
}
