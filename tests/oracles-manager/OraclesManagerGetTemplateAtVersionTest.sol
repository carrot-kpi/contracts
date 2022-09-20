pragma solidity 0.8.17;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";
import {IOraclesManager1} from "../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {RealityV3Oracle} from "../../contracts/oracles/RealityV3Oracle.sol";
import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager get template at version test
/// @dev Tests template at version query in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerGetTemplateAtVersionTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.template(2);
    }

    function testNonExistentVersion() external {
        Template memory _template = oraclesManager.template(1); // check that it doesn't fail
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(realityV3OracleTemplate));
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.template(10); //non-existent version
    }

    function testSuccessOnAdd() external {
        KPITokensFactory _factory = new KPITokensFactory(
            address(1),
            address(1),
            feeReceiver
        );
        RealityV3Oracle _realityV3OracleTemplate = new RealityV3Oracle();
        OraclesManager1 _oraclesManager = new OraclesManager1(
            address(_factory)
        );
        assertEq(_oraclesManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _oraclesManager.template(1);
        _oraclesManager.addTemplate(address(_realityV3OracleTemplate), "asd");
        _template = _oraclesManager.template(1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);

        _template = _oraclesManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd");
    }

    function testSuccessOnUpgrade() external {
        KPITokensFactory _factory = new KPITokensFactory(
            address(1),
            address(1),
            feeReceiver
        );
        RealityV3Oracle _realityV3OracleTemplate = new RealityV3Oracle();
        OraclesManager1 _oraclesManager = new OraclesManager1(
            address(_factory)
        );
        assertEq(_oraclesManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _oraclesManager.template(1);
        _oraclesManager.addTemplate(address(_realityV3OracleTemplate), "asd1");
        _template = _oraclesManager.template(1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);

        _template = _oraclesManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        RealityV3Oracle _newRealityV3OracleTemplate = new RealityV3Oracle();
        _oraclesManager.upgradeTemplate(
            1,
            address(_newRealityV3OracleTemplate),
            "asd2"
        );

        _template = _oraclesManager.template(1); // check current template updated
        assertEq(_template.addrezz, address(_newRealityV3OracleTemplate));
        assertEq(_template.version, 2);

        _template = _oraclesManager.template(1, 1); // fetch past template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        _template = _oraclesManager.template(1, 2); // fetch new template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_newRealityV3OracleTemplate));
        assertEq(_template.version, 2);
        assertEq(_template.specification, "asd2");
    }

    function testSuccessOnRemove() external {
        KPITokensFactory _factory = new KPITokensFactory(
            address(1),
            address(1),
            feeReceiver
        );
        RealityV3Oracle _realityV3OracleTemplate = new RealityV3Oracle();
        OraclesManager1 _oraclesManager = new OraclesManager1(
            address(_factory)
        );
        assertEq(_oraclesManager.templatesAmount(), 0);
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        Template memory _template = _oraclesManager.template(1);
        _oraclesManager.addTemplate(address(_realityV3OracleTemplate), "asd1");
        _template = _oraclesManager.template(1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);

        _template = _oraclesManager.template(1, 1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");

        // remove template
        _oraclesManager.removeTemplate(1);

        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        _template = _oraclesManager.template(1); // check deletion

        _template = _oraclesManager.template(1, 1); // fetch deleted template
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, address(_realityV3OracleTemplate));
        assertEq(_template.version, 1);
        assertEq(_template.specification, "asd1");
    }
}
