pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {BaseTemplatesManager} from "../../contracts/BaseTemplatesManager.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {MockKPIToken, OracleData} from "../mocks/MockKPIToken.sol";
import {MockOracle} from "../mocks/MockOracle.sol";
import {MockBaseOracle} from "../mocks/MockBaseOracle.sol";
import {MockConstrainedOracle} from "../mocks/MockConstrainedOracle.sol";
import {MockConstantAnswererTrustedOracle} from "../mocks/MockConstantAnswererTrustedOracle.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Base test setup
/// @dev Test hook to set up a base test environment for each test.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
abstract contract BaseTestSetup is Test {
    string internal constant MOCK_KPI_TOKEN_SPECIFICATION = "fake-kpi-token-spec";
    string internal constant MOCK_ORACLE_SPECIFICATION = "fake-oracle-spec";
    address internal constant MOCK_CONSTANT_TRUSTED_ORACLE_ANSWERER = address(9999119999);

    address internal owner;
    address internal feeReceiver;
    KPITokensFactory internal factory;
    MockKPIToken internal mockKpiTokenTemplate;
    KPITokensManager internal kpiTokensManager;
    MockOracle internal mockOracleTemplate;
    MockBaseOracle internal mockBaseOracleTemplate;
    MockConstrainedOracle internal mockConstrainedOracleTemplate;
    MockConstantAnswererTrustedOracle internal mockConstantAnswererTrustedOracle;
    OraclesManager internal oraclesManager;

    function setUp() external {
        feeReceiver = address(400);
        owner = address(this);
        factory = initializeKPITokensFactory(address(1), address(1), feeReceiver);

        mockKpiTokenTemplate = new MockKPIToken();
        kpiTokensManager = initializeKPITokensManager(address(factory));
        kpiTokensManager.addTemplate(address(mockKpiTokenTemplate), "fake-kpi-token-spec");

        mockOracleTemplate = new MockOracle();
        mockBaseOracleTemplate = new MockBaseOracle();
        mockConstrainedOracleTemplate = new MockConstrainedOracle();
        mockConstantAnswererTrustedOracle = new MockConstantAnswererTrustedOracle(MOCK_CONSTANT_TRUSTED_ORACLE_ANSWERER);
        oraclesManager = initializeOraclesManager(address(factory));
        oraclesManager.addTemplate(address(mockOracleTemplate), "fake-oracle-spec");
        oraclesManager.addTemplate(address(mockBaseOracleTemplate), "fake-oracle-spec");
        oraclesManager.addTemplate(address(mockConstrainedOracleTemplate), "fake-oracle-spec");
        oraclesManager.addTemplate(address(mockConstantAnswererTrustedOracle), "fake-oracle-spec");

        factory.setKpiTokensManager(address(kpiTokensManager));
        factory.setOraclesManager(address(oraclesManager));
        factory.setPermissionless(true); // permissionless is specifically tested
    }

    function createKpiToken(string memory _description) internal returns (MockKPIToken) {
        OracleData[] memory _oracles = new OracleData[](1);
        _oracles[0] = OracleData({templateId: 1, data: abi.encode(_description)});

        return MockKPIToken(
            factory.createToken(1, _description, block.timestamp + 60, abi.encode(""), abi.encode(_oracles))
        );
    }

    function createKpiTokenWithFactory(KPITokensFactory _factory, string memory _description)
        internal
        returns (MockKPIToken)
    {
        OracleData[] memory _oracles = new OracleData[](1);
        _oracles[0] = OracleData({templateId: 1, data: abi.encode(_description)});

        return MockKPIToken(
            _factory.createToken(1, _description, block.timestamp + 60, abi.encode(""), abi.encode(_oracles))
        );
    }

    function initializeKPITokensFactory(address _kpiTokensManager, address _oraclesManager, address _feeReceiver)
        internal
        returns (KPITokensFactory)
    {
        KPITokensFactory _factory = new KPITokensFactory();
        ERC1967Proxy _proxy =
        new ERC1967Proxy(address(_factory), abi.encodeWithSelector(KPITokensFactory.initialize.selector, owner, _kpiTokensManager, _oraclesManager, _feeReceiver));
        return KPITokensFactory(address(_proxy));
    }

    function initializeOraclesManager(address _factory) internal returns (OraclesManager) {
        OraclesManager _manager = new OraclesManager();
        ERC1967Proxy _proxy =
        new ERC1967Proxy(address(_manager), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, owner, _factory));
        return OraclesManager(address(_proxy));
    }

    function initializeKPITokensManager(address _factory) internal returns (KPITokensManager) {
        KPITokensManager _manager = new KPITokensManager();
        ERC1967Proxy _proxy =
        new ERC1967Proxy(address(_manager), abi.encodeWithSelector(BaseTemplatesManager.initialize.selector, owner, _factory));
        return KPITokensManager(address(_proxy));
    }
}
