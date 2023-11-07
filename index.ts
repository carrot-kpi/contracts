import type { Address } from "viem";

export enum ChainId {
    GNOSIS = 100,
    SEPOLIA = 11155111,
    SCROLL_SEPOLIA = 534351,
    POLYGON_MUMBAI = 80001,
}

export interface CarrotContract {
    address: Address;
    deploymentBlock: number;
}

export interface CarrotContracts {
    factory: CarrotContract;
    kpiTokensManager: CarrotContract;
    oraclesManager: CarrotContract;
}

export const DEPLOYMENT_ADDRESSES: Record<ChainId, CarrotContracts> = {
    [ChainId.GNOSIS]: {
        factory: {
            address: "0xF451feb55eeA54EeF90AcB301212b80E03d82819",
            deploymentBlock: 30_531_786,
        },
        kpiTokensManager: {
            address: "0xAcAFe7928cDd2E02bd508a4827b62649726f9460",
            deploymentBlock: 30_531_788,
        },
        oraclesManager: {
            address: "0x35030D4680C339Dd5a043C23f99Ee45ce66198CA",
            deploymentBlock: 30_531_789,
        },
    },
    [ChainId.SEPOLIA]: {
        factory: {
            address: "0xB725486e93926101E2E629b6790D27A4729920E5",
            deploymentBlock: 4_518_508,
        },
        kpiTokensManager: {
            address: "0xdA985F91931852A92Efe59D4752E0AB090106a74",
            deploymentBlock: 4_518_509,
        },
        oraclesManager: {
            address: "0x2CeeDD7B56A36246A8B4C1d5CF4f1B5857c92283",
            deploymentBlock: 4_518_510,
        },
    },
    [ChainId.SCROLL_SEPOLIA]: {
        factory: {
            address: "0x4A827f3Bf3c38Baa091DdCAb7B801aCee6819759",
            deploymentBlock: 1_711_759,
        },
        kpiTokensManager: {
            address: "0x549ECeD431F93dbde0D7e6703F04dF1E074F096a",
            deploymentBlock: 1_711_762,
        },
        oraclesManager: {
            address: "0xdd6F7A083487d0d86487F7D5E5964110537e5c59",
            deploymentBlock: 1_711_766,
        },
    },
    [ChainId.POLYGON_MUMBAI]: {
        factory: {
            address: "0xD6e88c910329fE3597498772eB94991a0630306d",
            deploymentBlock: 42_107_159,
        },
        kpiTokensManager: {
            address: "0xe3dA4E4b76C4ed3e4227db20F20d1F25A4507f9b",
            deploymentBlock: 42_107_163,
        },
        oraclesManager: {
            address: "0xe82c4D8b993D613a28600B953e91A3A93Ae69Fd6",
            deploymentBlock: 42_107_167,
        },
    },
};
