# Contributing

Carrot v1 contracts are developed using both Hardhat/Foundry in a hybrid project
structure, so in order to contribute you need to first install Foundry locally.
Check out [this link](https://getfoundry.sh/) to easily install Foundry on your
machine.

In order to install Hardhat and all the related dependencies you also need to
run `yarn install`.

Foundry manages dependencies using git submodules, so it's advised to use
`git clone --recurse-submodules` when cloning the repo in order to have a
ready-to-go environment. If `git clone` was used without the
`--recurse-submodules` flag, you can just run
`git submodule update --init --recursive` in the cloned repo in order to easily
install the dependencies.

After having done the above, the environment should be ready to work with.

A mixed Hardhat/Foundry structure is used to make it possible to use the `tasks`
feature given by Hardhat, which is sadly not yet available on Foundry. Tasks are
used for various reasons in the project, the most important being the deployment
of the contracts suite on a given target network.

## Profiles

Profiles can be used in Foundry to specify different build configurations to
fine-tune the development process. Here we use 2 profiles:

- `test`: This profile pretty much skips all the optimizations and focuses on
  raw speed. As the name suggests, this is used to run all the available tests
  in a quick way, and without useless optimization.
- `production`: The production profile must be used when deploying contracts in
  production. This profile avhieves maximum optimization leveraging the new Yul
  IR optimizer made production-ready in solc version `0.8.13`, and also focuses
  on the production contracts, skipping compilation of the tests entirely.
  Depending on your machine, building with this profile can take some time.

All the profiles above are specified in the `foundry.toml` file at the root of
the project.

## Testing

Tests are written in Solidity and you can find them in the `tests` folder. Both
property-based fuzzing and standard unit tests are easily supported through the
use of Foundry.

## Github Actions

The repository uses GH actions to setup CI to automatically run all the
available
[tests](https://github.com/carrot-kpi/contracts/blob/feature/v1-no-automation/.github/workflows/ci.yaml)
on each push.

## Pre-commit hooks

In order to reduce the ability to make mistakes to the minimum, pre-commit hooks
are enabled to both run all the available tests (through the same command used
in the GH actions) and to lint the commit message through `husky` and
`@commitlint/config-conventional`. Please have a look at the supported formats
by checking
[this](https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional)
out.

### Deploying

In order to deploy the whole platform to a given network you can run the
following command from the root of the project:

```
FOUNDRY_PROFILE=production forge script --broadcast --slow --private-key PRIVATE_KEY --fork-url RPC_ENDPOINT --sig 'run(address)' ./scripts/Deploy.sol FEE_RECEIVER
```

the values to pass are:

- `PRIVATE_KEY`: the private key related to the account that will perform the
  deployment.
- `RPC_ENDPOINT`: the RPC endpoint that will be used to broadcast transactions.
  This will also determine the network where the deployment will happen.
- `FEE_RECEIVER`: the address of the fee receiver. This address will collect all
  the protocol fees.

Two alternative forms of the command can be used in order for the deployment to
be completed with either Trezor or Ledger hardware wallets (all the arguments
remain the same as above):

```
FOUNDRY_PROFILE=production forge script --broadcast --slow --ledger --fork-url RPC_ENDPOINT --sig 'run(address)' ./scripts/Deploy.sol FEE_RECEIVER
FOUNDRY_PROFILE=production forge script --broadcast --slow --trezor --fork-url RPC_ENDPOINT --sig 'run(address)' ./scripts/Deploy.sol FEE_RECEIVER
```

### Creating a test token

In order to create a test token with the ERC20 template + Reality oracle
template you can run the following command from the root of the project:

```
FOUNDRY_PROFILE=production forge script --broadcast --slow --private-key PRIVATE_KEY --fork-url RPC_ENDPOINT --sig 'run(address,address,uint256,uint256,address,uint256,address,address,string,uint32,uint32,string)' ./scripts/CreateManualRealityEthERC20KpiToken.sol FACTORY_ADDRESS KPI_TOKENS_MANAGER_ADDRESS COLLATERAL_TOKEN COLLATERAL_AMOUNT REALITY_ADDRESS ARBITRATOR_ADDRESS REALITY_QUESTION_TEXT REALITY_QUESTION_TIMEOUT REALITY_QUESTION_EXPIRY DESCRIPTION
```

the values to pass are:

- `PRIVATE_KEY`: the private key related to the account that will perform the
  deployment.
- `RPC_ENDPOINT`: the RPC endpoint that will be used to broadcast transactions.
  This will also determine the network where the deployment will happen.
- `FACTORY_ADDRESS`: the address of the factory contract to be used.
- `KPI_TOKENS_MANAGER_ADDRESS`: the address of the KPI tokens manager contract
  to be used.
- `COLLATERAL_TOKEN`: the address of the ERC20 token to be used as collateral.
- `COLLATERAL_AMOUNT`: the amount of the ERC20 token collateral.
- `REALITY_ADDRESS`: the address of the Reality.eth contract to be used.
- `ARBITRATOR_ADDRESS`: the address of the arbitrator to be used.
- `REALITY_QUESTION_TEXT`: the text of the question to be asked on Reality.
- `REALITY_QUESTION_TIMEOUT`: the timeout of the Reality question (in seconds).
- `REALITY_QUESTION_EXPIRY`: the expiry of the Reality question (epoch
  timestamp).
- `DESCRIPTION`: IPFS hash pointing to the KPI token's description.

### Addresses

"Official" deployments and addresses are generally tracked in the
`.addresses.json` file, even though it might be unreliable for testnets.
