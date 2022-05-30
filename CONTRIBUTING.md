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

### Deploying to testnets

In order to deploy the whole platform to a testnet you can either use the
`deploy:rinkeby` command (with a `deploy:rinkeby:verify` variant that
automatically verifies the contracts after deployment), or check out how the
deploy command works in general by executing `npx hardhat help deploy`. The
`--network` parameter will be a constant and specifies in which network the
launched command will deploy the contracts (the passed network must be specified
in the `hardhat.config.ts` file).

In order to use the deployment tasks it's important to add a `.env` file written
using the `.env.example` model anyone can find at the root of the project (**BE
CAREFUL, NEVER PUSH YOUR PERSONAL .env FILE**).

### Addresses

"Official" deployments and addresses are generally tracked in the
`.addresses.json` file, even though it might be unreliable for testnets.
