pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {MockOracle} from "../mocks/MockOracle.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager get template at version test
/// @dev Tests template at version query in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerGetTemplateAtVersionTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.template(20_000);
    }

    function testNonExistentVersion() external {
        Template memory _template = oraclesManager.template(1); // check that it doesn't fail
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(mockOracleTemplate));
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.template(10); //non-existent version
    }

    function testSuccessOnAdd() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(1), feeReceiver);
        MockOracle _mockOracleTemplate = new MockOracle();
        OraclesManager _oraclesManager = initializeOraclesManager(address(_factory));
        assertEq(_oraclesManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _oraclesManager.template(1);
        _oraclesManager.addTemplate(address(_mockOracleTemplate), "asd");
        _template = _oraclesManager.template(1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);

        _template = _oraclesManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd");
    }

    function testSuccessOnUpgrade() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(1), feeReceiver);
        MockOracle _mockOracleTemplate = new MockOracle();
        OraclesManager _oraclesManager = initializeOraclesManager(address(_factory));
        assertEq(_oraclesManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _oraclesManager.template(1);
        _oraclesManager.addTemplate(address(_mockOracleTemplate), "asd1");
        _template = _oraclesManager.template(1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);

        _template = _oraclesManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        MockOracle _newMockOracleTemplate = new MockOracle();
        _oraclesManager.upgradeTemplate(1, address(_newMockOracleTemplate), "asd2");

        _template = _oraclesManager.template(1); // check current template updated
        assertEq(_template.addrezz, address(_newMockOracleTemplate));
        assertEq(_template.version, 2);

        _template = _oraclesManager.template(1, 1); // fetch past template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        _template = _oraclesManager.template(1, 2); // fetch new template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_newMockOracleTemplate));
        assertEq(_template.version, 2);
        assertEq(_template.specification, "asd2");
    }

    function testSuccessOnRemove() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(1), feeReceiver);
        MockOracle _mockOracleTemplate = new MockOracle();
        OraclesManager _oraclesManager = initializeOraclesManager(address(_factory));
        assertEq(_oraclesManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _oraclesManager.template(1);
        _oraclesManager.addTemplate(address(_mockOracleTemplate), "asd1");
        _template = _oraclesManager.template(1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);

        _template = _oraclesManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        // remove template
        _oraclesManager.removeTemplate(1);

        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        _template = _oraclesManager.template(1); // check deletion

        _template = _oraclesManager.template(1, 1); // fetch deleted template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_mockOracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");
    }
}
