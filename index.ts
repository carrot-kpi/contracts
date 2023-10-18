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
            address: "0x2DeCdbFd3D8bFf96463A31F0E0Cd1CF923bB3624",
            deploymentBlock: 30520566,
        },
        kpiTokensManager: {
            address: "0x70196593711Eee2d4253e5E69504032c6bF1A152",
            deploymentBlock: 30520569,
        },
        oraclesManager: {
            address: "0xfC807e51487fC43466fB8C26Ba2e48113555Ea1b",
            deploymentBlock: 30520573,
        },
    },
    [ChainId.SEPOLIA]: {
        factory: {
            address: "0xBb82A54Ef3aFE4219e8b28fD7e304D9644021478",
            deploymentBlock: 4514303,
        },
        kpiTokensManager: {
            address: "0x84Cf8F902c5E1f9de8332a7E5035868C59984687",
            deploymentBlock: 4514306,
        },
        oraclesManager: {
            address: "0xCB346f8E8346bdE33Ca2b8979e5cA1891713Dd16",
            deploymentBlock: 4514308,
        },
    },
    [ChainId.SCROLL_SEPOLIA]: {
        factory: {
            address: "0x22d8655b405F6a8D6Bb7c5838AaF187a32158B07",
            deploymentBlock: 1695804,
        },
        kpiTokensManager: {
            address: "0x10E1A22034C5AF1E793c2Ac189b90ca47b252fF9",
            deploymentBlock: 1695809,
        },
        oraclesManager: {
            address: "0xd1c1153fd809Aae3bb431b586C032C4856abaeD4",
            deploymentBlock: 1695813,
        },
    },
};
