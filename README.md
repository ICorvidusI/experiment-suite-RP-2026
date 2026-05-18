# experiment-suite-RP-2026

[![Built with devenv](https://devenv.sh/assets/devenv-badge.svg)](https://devenv.sh)

This is the reproducibility package for the paper
"DFA vs cDFA based propagation for regular counting with lazy clause generation".
Here you can find the experiments used for the paper and their history.

## Setup devenv

  This suite makes use of [devenv](https://devenv.sh) to declaratively and
  deterministically set up a shell with the dependencies to run the experiments.
  To install devenv, follow [the installation from this guide](https://devenv.sh/getting-started/).

  After installing, you can enter the shell by navigating to the root folder of
  this repo and running:

  ```console
  devenv shell
  ```

  You can exit the shell by running:

  ```console
  exit
  ```

## Generate Nonograms

```console
  ./scripts/generate_nonograms.sh
  ```

## Solve nonogram using DFA based constraints

```console
  minizinc ./problems/nonogram/nonogram.mzn ./problems/nonogram/data/dfa/nonogram_{x}x{y}_seed_{z}.json
  ```
