pragma solidity 0.8.23;

import {IKPIToken} from "../../contracts/interfaces/IKPIToken.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {InitializeKPITokenParams} from "../../contracts/commons/Types.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {BaseKPIToken} from "../../contracts/presets/kpi-tokens/BaseKPIToken.sol";

struct OracleData {
    uint256 templateId;
    bytes data;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI token template implementation
/// @dev A KPI token template implementation
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract MockKPIToken is BaseKPIToken {
    bool public override finalized;
    address[] internal _oracles;

    function initialize(InitializeKPITokenParams memory _params) external payable override initializer {
        __BaseKPIToken_init(
            _params.creator,
            _params.description,
            _params.expiration,
            _params.kpiTokensManager,
            _params.kpiTokenTemplateId,
            _params.kpiTokenTemplateVersion
        );

        OracleData[] memory _oracleData = abi.decode(_params.oraclesData, (OracleData[]));
        for (uint8 _i = 0; _i < _oracleData.length; _i++) {
            _oracles.push(
                IOraclesManager(_params.oraclesManager).instantiate(
                    _params.creator, _oracleData[_i].templateId, _oracleData[_i].data
                )
            );
        }
    }

    function finalize(uint256 _result) external override {}

    function redeem(bytes memory _data) external override {}

    function data() external pure override returns (bytes memory) {
        return abi.encode();
    }

    function oracles() external view override returns (address[] memory) {
        return _oracles;
    }
}
