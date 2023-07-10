<br />

<p align="center">
    <img src=".github/static/logo.svg" alt="Carrot logo" width="60%" />
</p>

<br />

<p align="center">
    Carrot is a web3 protocol trying to make incentivization easier and more capital
    efficient.
</p>

<br />

<p align="center">
    <img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="License: GPL v3">
    <img src="https://github.com/carrot-kpi/v1-monorepo/actions/workflows/ci.yml/badge.svg" alt="CI">
</p>

# Carrot v1 contracts

The smart contracts powering Carrot's efficient incentivization. Both the
contracts and the tests are written in Solidity using Foundry.

## Contributing

Want to contribute? Check out the `CONTRIBUTING.md` file for more info.

## KPI token and oracle templates and managers

Carrot is designed with flexibility in mind. The maximum amount of flexibility
is achieved by allowing to create KPI token and oracle templates "on the go"
(potentially by thrid parties too). Templates are self contained apps running on
the Carrot platform and implementing both a frontend and a backend (the backend
generally consists of one or more smart contracts).

Anyone can potentially code the functionality they want/need in Carrot v1 and
use it freely, putting almost no limits on creativity for incentivization
campaigns.

This is mainly achieved using 2 contracts: `KPITokensManager` and
`OraclesManager`. These contracts act as a registry for both KPI token and
oracle templates, and at the same time can instantiate specific templates (using
ERC-1167 clones to maximize gas efficiency).

Each of these managers support template addition, removal, upgrade, update and
instantiation, as well as some readonly functions to query templates' state.

Most of these actions are protected and can only be performed by specific
entities in the platform. In particular, addition, removal, upgrade and update
can only be performed by the manager contract's owner (governance), while
template instantiation can only be initiated by the `KPITokensFactory`.

Carrot v1 comes out of the box with powerful KPI token and oracle templates,
with the goal of encouraging the community to come up with additional use cases
that can also lead to entirely custom-made products based on Carrot v1's
platform.

## KPITokensFactory

The KPI tokens factory is ideally the contract with which KPI token creators
will interact the most, and the glue of the overall architecture. Its most
important function is `createToken`, which takes in 4 parameters, `_id`,
`_description`, `_initializationData` and `_oraclesInitializationData`. The
factory is simply in charge of initializing the KPI token campaign overall, and
collecting an arbitrary protocol fee in the process.

Explanation of the input parameters follows:

- `_id`: an `uint256` telling the factory which KPI token template must be used.
- `_description`: a `string` describing what the KPI token is about (the goals,
  how they can be reached, and eventually info about how to answer any attached
  oracles, if the oracles are crowdsourced). In order to save on gas fees, it is
  _highly_ advisable and the standard procedure to upload a file to IPFS and
  pass a CID here. An official JSON schema specification for how the description
  has to look like is a current work in progress, the idea being that if the
  description of a KPI token does not conform to the JSON schema, it won't be
  shown in the official frontend operated by Carrot Labs.
- `_initializationData`: ABI-encoded KPI token initialization data specific to
  the template that the user wants to use. To know what data to use and how to
  encode it as a developer, have a look at the code for the template you want to
  use, in particular to the `initialize` function. For users, this process is
  completely abstracted as the Carrot frontend (through the template's frontend
  in the campaign creation UI) will take care of collecting the necessary data.
- `_oraclesInitializationData`: ABI-encoded oracles data specific to the
  instantiated template. This data is used by the KPI token template to
  instantiate any oracles needed to report goals' data back on-chain. To know
  what data to use and how to encode it, have a look at the code for the
  template you want to use, in particular at the `initializeOracles` function.
  Again, this process is handled autonomously by the template's frontend for end
  users.

> **Warning** The sections below are for information only. Third party template
> development is not fully supported yet and we're still defining the process
> and tooling required in order to make it a possibility.

## Implementing a KPI token template

A KPI token template can be defined by simply implementing the `IKPIToken`
interface. The functions that must be overridden are:

- `initialize`: this function is called by the factory while initializing the
  KPI token and contains all the initialization logic (collateral transfers,
  state setup, KPI token minting and transfer to any eligible party etc). 10
  input parameters are passed in by the factory in a struct:
  - `creator`: the address of the account creating the KPI token.
  - `oraclesManager`: the address of the oracles manager contract, which can be
    used to instantiate oracles.
  - `kpiTokensManager`: the address of the KPI tokens manager contract.
  - `feeReceiver`: the address of the contract to be sent any fees collected by
    the protocol.
  - `kpiTokenTemplateId`: the identifier of the KPI token template being used.
  - `kpiTokenTemplateVersion`: the version of the KPI token template being used.
  - `kpiTokenTemplateVersion`: the version of the KPI token template being used.
  - `description`: the description of the campaign. Officially, it should be an
    IPFS CID pointing to the specification of the campaign.
  - `expiration`: a UNIX epoch timestamp at which the KPI token will expire. The
    expiration logic should make the KPI token expire worthless when this
    timestamp is reached. This is used to defend against a maliciously
    unresponsive oracle that might cause funds to get stuck in the KPI token.
  - `kpiTokenData`: template-specific ABI-encoded data that will the used to
    initizalize the chosen KPI token template.
  - `oraclesData`: template-specific ABI-encoded data that will the used to
    initizalize the chosen oracle template(s).
- `finalize`: finalization logic is implemented here. This function should only
  be callable by the oracles associated with the token. Once all the oracles
  have reported their final results, logic to properly allocate the collaterals
  (either to the KPI token holders or the KPI token creator, depending on the
  results) must be implemented accordingly. Any non-redeemable collateral should
  at this point be sent back to the KPI token creator.
- `redeem`: this is the function KPI token holders call to redeem the collateral
  they have earned (if any was unlocked by `finalize`). This function should
  ideally (but not necessarily) burn the user-held KPI token(s) in exchange for
  the collateral.
- `owner`: a view function returning the address of the KPI token's owner.
- `transferOwnership`: a function to change the KPI token's ownership.
- `template`: a view function to fetch the template used to create the KPI
  token.
- `description`: a view function to fetch the KPI token campaign's description.
- `finalized`: a view function that helps understand if the KPI token is in a
  finalized state or not.
- `expiration`: a view function that returns the expiration timestamp of the KPI
  token.
- `creationTimestamp`: a view function that returns the creation timestamp of
  the KPI token.
- `data`: a view function that returns ABI-encoded data about the internal state
  of the KPI token (what the function returns specifically is up to the template
  implementation).
- `oracles`: a view function that returns an address array of the oracles being
  used by the KPI token.

In general, a good place to have a look at to get started with KPI token
development is the
[`ERC20KPIToken`](https://github.com/carrot-kpi/erc20-kpi-token-template)
implementation.

## Implementing an oracle template

An oracle template can be defined by simply implementing the `IOracle`
interface. The functions that must be overridden are:

- `initialize`: this function is called by a KPI token template while
  initializing a campaign, and when the point has been reached that the KPI
  token needs to instantiate its oracles. The input parameters passed by the KPI
  token are the following:
  - `creator`: the address of the account creating the KPI token.
  - `kpiToken`: the address of the KPI token that wants to create the oracle.
  - `templateId`: the identifier of the oracle template being used.
  - `templateVersion`: the version of the oracle template being used.
  - `data`: template-specific ABI-encoded data that will the used to initizalize
    the oracle.
- `kpiToken`: view function returning the KPI token address this oracle is
  attached to.
- `template`: a view function to fetch the template used to create the oracle.
- `finalized`: a view function that helps understand if the oracle is in a
  finalized state or not.
- `data`: a view function that returns ABI-encoded data about the internal state
  of the oracle (what the function returns specifically is up to the template
  implementation).

In general, a good place to have a look at to get started with oracle
development is the
[`RealityV3Oracle`](https://github.com/carrot-kpi/reality-eth-v3-oracle-template)
implementation.
