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

## Generate Random cDFAs and equivalent DFAs

```console
  ./scripts/generate_nonograms.sh
  ```

This will fill the folder ```./problems/regular_counting/data/``` with
json files that can be used as input for the minizinc models in ```./problems/regular_counting/```

## Run experiment

```console
  uv run ./scripts/runner.py <problem> --time-limit <seconds>
  ```

Replace ```<problem>``` with the name of a directory in ```./problems/```.

Runs the ```<problem>``` experiment,
giving each instance ```<seconds>``` seconds time.

Creates a folder with results ```./results_<problem>_<seconds>s/```,
filled with .jsonl files with the statistics of each instance that was run.

## Create graphs

```console
  uv run ./scripts/graph.py --result-dir <DIR>
  ```

Replace ```<DIR>``` with the results directory you want to graph.

Creates a graph directory in ```<DIR>``` with graphs for:

- Number of solutions found by each propagator;
- The average nogood length for each propagator;
- The average number of propagations per solution for each propagator;
- The average amount of nogoods per solution for each propagator.

The first time this script is run for a results directory, it creates a
.npy file in ```<DIR>``` to store the compiled results for faster access.
As the first time you run this script the results need to be compiled,
it might take a while to run.

## Additional information

- ```./Pumpkin/``` contains a fork of Pumpkin extended with the used propagators.
- ```./scripts/problem_generators/``` containts generators for single instances
of the experiments.
- ```./paper/``` contains the paper and the [typst](https://typst.app/) file
used to generate it.
