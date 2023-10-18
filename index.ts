import type { Address } from "viem";

export enum ChainId {
    GNOSIS = 100,
    SEPOLIA = 11155111,
    SCROLL_SEPOLIA = 534351,
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
            address: "0xcfDAFea526Fbd15c7a5f14E7803921D5e68b84a9",
            deploymentBlock: 30_522_488,
        },
        kpiTokensManager: {
            address: "0x36B11a5fBaE8680962E92328183ECc6BB8782C91",
            deploymentBlock: 30_522_490,
        },
        oraclesManager: {
            address: "0xE38728A6E81a1C6c484d64842042F62eB0769236",
            deploymentBlock: 30_522_492,
        },
    },
    [ChainId.SEPOLIA]: {
        factory: {
            address: "0xA376b59eF61c945A64c36B662A04EB05FD82575e",
            deploymentBlock: 4_515_016,
        },
        kpiTokensManager: {
            address: "0xD7b37f191E9E0481673dcc1D8B4F9d77Cab358e0",
            deploymentBlock: 4_515_017,
        },
        oraclesManager: {
            address: "0x84A0937e57FAd5b3F9C257B7D84527926Ef193E1",
            deploymentBlock: 4_515_018,
        },
    },
    [ChainId.SCROLL_SEPOLIA]: {
        factory: {
            address: "0x2d2E7dC3c5CAD9020198b5FDDEc548cdBf079F68",
            deploymentBlock: 1_699_116,
        },
        kpiTokensManager: {
            address: "0xC1def83E7a2be87f8304d9207cce663159dE775b",
            deploymentBlock: 1_699_120,
        },
        oraclesManager: {
            address: "0x2B428A243Af4ce5fF4E25a4E392708A4A020d28C",
            deploymentBlock: 1_699_122,
        },
    },
};
