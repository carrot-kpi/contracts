import type { Address } from "viem";

export enum SupportedChainId {
    GNOSIS = 100,
    SEPOLIA = 11155111,
    SCROLL_SEPOLIA = 534351,
}

export interface CarrotContractAddresses {
    factory: Address;
    kpiTokensManager: Address;
    oraclesManager: Address;
}

export const DEPLOYMENT_ADDRESSES: Record<SupportedChainId, CarrotContractAddresses> = {
    [SupportedChainId.GNOSIS]: {
        factory: "0xD503Bdcc3Cd38D3cEaBa1efA43EFCc03b7Fb1CbA",
        kpiTokensManager: "0xCd85e0690f85A52D260273E5B51336D1151F2832",
        oraclesManager: "0xc9E426B468d334AF6208ef9b3bA5f599d1417c6e",
    },
    [SupportedChainId.SEPOLIA]: {
        factory: "0x44bBb970E534bCE4B42C5a34b15d5B049704417A",
        kpiTokensManager: "0xA4537024597F8B9243AbE105D0Cb297Ea2562ef1",
        oraclesManager: "0x940d1D2F5c5724a37593D323bFde54F81D6f11C0",
    },
    [SupportedChainId.SCROLL_SEPOLIA]: {
        factory: "0x64a0745EF9d3772d9739D9350873eD3703bE45eC",
        kpiTokensManager: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        oraclesManager: "0xD3Fe5d463dD1fd943CCC2271F2ea980B898B5DA3",
    },
};
