# UniswapV2, an updated clone of UniswapV2 using Foundry

## Using this repo

1. `git clone git@github.com:Jeiwan/zuniswapv2.git`
1. Ensure you have installed Rust and Cargo: [Install Rust](https://www.rust-lang.org/tools/install)
1. Install Foundry:
   `cargo install --git https://github.com/gakonst/foundry --bin forge --locked`
1. Install dependency contracts:
   `git submodule update --init --recursive`
1. Run tests:
   `forge test`


# Coverage Report
| File                         | % Lines          | % Statements     | % Branches     | % Funcs        |
|------------------------------|------------------|------------------|----------------|----------------|
| src/UniswapV2Factory.sol     | 100.00% (12/12)  | 100.00% (17/17)  | 100.00% (6/6)  | 100.00% (1/1)  |
| src/UniswapV2Library.sol     | 100.00% (34/34)  | 96.61% (57/59)   | 87.50% (14/16) | 100.00% (8/8)  |
| src/UniswapV2Pair.sol        | 94.03% (63/67)   | 94.44% (85/90)   | 78.57% (22/28) | 100.00% (8/8)  |
| src/UniswapV2Router.sol      | 93.02% (40/43)   | 94.83% (55/58)   | 77.27% (17/22) | 100.00% (7/7)  |
| src/libraries/Math.sol       | 88.89% (8/9)     | 90.00% (9/10)    | 75.00% (3/4)   | 100.00% (2/2)  |
| src/libraries/UQ112x112.sol  | 0.00% (0/2)      | 0.00% (0/2)      | 100.00% (0/0)  | 0.00% (0/2)    |
| test/UniswapV2Pair.t.sol     | 40.00% (6/15)    | 36.84% (7/19)    | 0.00% (0/6)    | 50.00% (2/4)   |
| test/mocks/ERC20Mintable.sol | 0.00% (0/1)      | 0.00% (0/1)      | 100.00% (0/0)  | 0.00% (0/1)    |
| Total                        | 89.07% (163/183) | 89.84% (230/256) | 75.61% (62/82) | 84.85% (28/33) |