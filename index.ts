import type { ChainContract } from "viem";
import { sepolia, arbitrumSepolia } from "viem/chains";

export enum ChainId {
    Sepolia = sepolia.id,
    ArbitrumSepolia = arbitrumSepolia.id,
}

export interface CarrotContracts {
    factory: ChainContract;
    kpiTokensManager: ChainContract;
    oraclesManager: ChainContract;
}

export const DEPLOYMENT_ADDRESSES: Record<ChainId, CarrotContracts> = {
    [ChainId.Sepolia]: {
        factory: {
            address: "0xB725486e93926101E2E629b6790D27A4729920E5",
            blockCreated: 4_518_508,
        },
        kpiTokensManager: {
            address: "0xdA985F91931852A92Efe59D4752E0AB090106a74",
            blockCreated: 4_518_509,
        },
        oraclesManager: {
            address: "0x2CeeDD7B56A36246A8B4C1d5CF4f1B5857c92283",
            blockCreated: 4_518_510,
        },
    },
    [ChainId.ArbitrumSepolia]: {
        factory: {
            address: "0xD6e88c910329fE3597498772eB94991a0630306d",
            blockCreated: 17_609_984,
        },
        kpiTokensManager: {
            address: "0xe3dA4E4b76C4ed3e4227db20F20d1F25A4507f9b",
            blockCreated: 17_610_015,
        },
        oraclesManager: {
            address: "0xe82c4D8b993D613a28600B953e91A3A93Ae69Fd6",
            blockCreated: 17_610_046,
        },
    },
};
