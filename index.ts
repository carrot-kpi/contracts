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
            address: "0xaa86ed8C3360C7Baf3badAED4bF5F092Ce775E59",
            deploymentBlock: 30_487_127,
        },
        kpiTokensManager: {
            address: "0x1E067451364b07034646cC03b8bF8e2851C7B84b",
            deploymentBlock: 30_487_131,
        },
        oraclesManager: {
            address: "0xAf7b4F675d980afB65F2Cf4897bf12dCf54D7a03",
            deploymentBlock: 30_487_135,
        },
    },
    [ChainId.SEPOLIA]: {
        factory: {
            address: "0x5A3B67F89533cB8c54e647fD24413c7AD87fb8D2",
            deploymentBlock: 4_501_023,
        },
        kpiTokensManager: {
            address: "0xCe7DC298A060AD4a51F3D220643F0482D3916Adc",
            deploymentBlock: 4_501_026,
        },
        oraclesManager: {
            address: "0xFd6b407B1FBe945977C34842c3745D22e8A57c2E",
            deploymentBlock: 4_501_028,
        },
    },
    [ChainId.SCROLL_SEPOLIA]: {
        factory: {
            address: "0xB6044f769f519a634A5150645484b18d0C031ae8",
            deploymentBlock: 1_643_192,
        },
        kpiTokensManager: {
            address: "0xEc0B101CDC03ae65F78cF5477F2b9e0FaB9f2b28",
            deploymentBlock: 1_643_199,
        },
        oraclesManager: {
            address: "0xcA9b84f307c7E7825C6e9B1da732f0a7e953889D",
            deploymentBlock: 1_643_204,
        },
    },
};
