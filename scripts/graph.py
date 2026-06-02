# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "matplotlib>=3.10.9",
#     "numpy>=2.4.6",
# ]
# ///
import argparse
import os
import re
import json
from dataclasses import dataclass
from enum import Enum

from numpy._typing import NDArray

from config import runner_modes

import numpy as np
import matplotlib.pyplot as plt

class SolveStatus(Enum):
    UNSATISFIABLE = -1
    UNFINISHED = 0
    ALL_SOLUTIONS = 1

@dataclass
class CollectedResult:
    states: int
    alphabet: int
    sequence: int
    counts: NDArray[np.int_]
    seed: int
    type: str

    flatIntVars: int

    status: SolveStatus
    flatTime: float
    initTime: float
    nSolutions: int

    timeline: NDArray[np.float64]

    peakDepth: NDArray[np.int_]
    propagations: NDArray[np.int_]
    nogoods: NDArray[np.int_]

    averageConflictSize: NDArray[np.int_]
    numUnitNogoodsLearned: NDArray[np.int_]
    averageLearnedNogoodLength: NDArray[np.float64]
    averageBacktrackAmount: NDArray[np.float64]
    averageLbd: NDArray[np.float64]

class Result():
    def __init__(self, states: int, alphabet: int, sequence: int, count: list[int], seed: int, type: str):
        self.states: int = states
        self.alphabet: int = alphabet
        self.sequence: int = sequence
        self.counts: list[int] = count
        self.seed: int = seed
        self.type: str = type

        self.flatIntVars = 0

        self.status: SolveStatus = SolveStatus.UNFINISHED
        self.flatTime: float = -1
        self.initTime: float = -1
        self.nSolutions: int = 0

        self.timeline: list[np.float64] = []

        self.peakDepth: list[int] = []
        self.propagations: list[int] = []
        self.nogoods: list[int] = []

        self.averageConflictSize: list[int] = []
        self.numUnitNogoodsLearned: list[int] = []
        self.averageLearnedNogoodLength: list[np.float64] = []
        self.averageBacktrackAmount: list[np.float64] = []
        self.averageLbd: list[np.float64] = []

    def collect(self) -> CollectedResult:
        return CollectedResult(
            self.states,
            self.alphabet,
            self.sequence,
            np.array(self.counts),
            self.seed,
            self.type,

            self.flatIntVars,

            self.status,
            self.flatTime,
            self.initTime,
            self.nSolutions,

            np.array(self.timeline),

            np.array(self.peakDepth),
            np.array(self.propagations),
            np.array(self.nogoods),

            np.array(self.averageConflictSize),
            np.array(self.numUnitNogoodsLearned),
            np.array(self.averageLearnedNogoodLength),
            np.array(self.averageBacktrackAmount),
            np.array(self.averageLbd)
        )

    def collectResultFromLines(self, lines) -> CollectedResult:
    
        for line in lines:
            match line:
                case {"type": "statistics", "statistics": {
                    "paths": _, "flatIntVars": flatIntVars, "flatIntConstraints": _, "method": _, "flatTime": flatTime
                }}:
                    self.flatIntVars = flatIntVars
                    self.flatTime = flatTime
    
                case {"type": "statistics", "statistics": {
                    "nodes": _, "restarts": _, "peakDepth": peakDepth, "solveTime": solveTime, "variables": _,
                    "propagators": _, "failures": _, "propagations": propagations, "nogoods": nogoods,
                    "AverageConflictSize": averageConflictSize, "NumUnitNogoodsLearned": numUnitNogoodsLearned,
                    "AverageLearnedNogoodLength": averageLearnedNogoodLength, "AverageBacktrackAmount": averageBacktrackAmount, "AverageLbd": averageLbd
                }}:
                    self.timeline.append(solveTime)
    
                    self.peakDepth.append(peakDepth)
                    self.propagations.append(propagations)
                    self.nogoods.append(nogoods)
    
                    self.averageConflictSize.append(averageConflictSize)
                    self.numUnitNogoodsLearned.append(numUnitNogoodsLearned)
                    self.averageLearnedNogoodLength.append(averageLearnedNogoodLength)
                    self.averageBacktrackAmount.append(averageBacktrackAmount)
                    self.averageLbd.append(averageLbd)
    
                case {"type": "solution", "output": {"json": solution}, "sections": ["json"], "time": _
                }:
                    pass
    
                case {"type": "statistics", "statistics": {
                    "initTime": initTime,
                    "nodes": _, "restarts": _, "peakDepth": peakDepth, "solveTime": solveTime, "variables": _,
                    "propagators": _, "failures": _, "propagations": propagations, "nogoods": nogoods,
                    "AverageConflictSize": averageConflictSize, "NumUnitNogoodsLearned": numUnitNogoodsLearned,
                    "AverageLearnedNogoodLength": averageLearnedNogoodLength, "AverageBacktrackAmount": averageBacktrackAmount, "AverageLbd": averageLbd
                }}:
                    self.initTime = initTime
    
                    self.timeline.append(solveTime)
    
                    self.peakDepth.append(peakDepth)
                    self.propagations.append(propagations)
                    self.nogoods.append(nogoods)
    
                    self.averageConflictSize.append(averageConflictSize)
                    self.numUnitNogoodsLearned.append(numUnitNogoodsLearned)
                    self.averageLearnedNogoodLength.append(averageLearnedNogoodLength)
                    self.averageBacktrackAmount.append(averageBacktrackAmount)
                    self.averageLbd.append(averageLbd)
    
    
                case {"type": "statistics", "statistics": {"nSolutions": nSolutions}}:
                    self.nSolutions = nSolutions
    
                case {'type': 'status', 'status': "UNSATISFIABLE", 'time': _}:
                    self.status = SolveStatus.UNSATISFIABLE
    
                case {'type': 'status', 'status': "ALL_SOLUTIONS", 'time': _}:
                    self.status = SolveStatus.ALL_SOLUTIONS
    
                case other:
                    print(f"states_{self.states}_alphabet_{self.alphabet}_sequence_{self.sequence}_k_{'_'.join([str(k) for k in self.counts])}_seed_{self.seed}_{self.type}")
                    print(f"don't know what to do with:\n{other}")

        return self.collect()


def main():
    description = "Visualize the data from an experiment."

    argument_parser = argparse.ArgumentParser(
        description=description
    )

    argument_parser.add_argument(
        "--result-dir",
        type=str,
        required=True,
        help="Directory containing the results of an experiment."
    )

    args = argument_parser.parse_args()

    result_dir = args.result_dir
    graph_dir = f"{result_dir}/graphs"

    parameter_names = ["states", "alphabet", "sequence", "k", "seed"]

    # Collect results
    mode_results_list: list[list[CollectedResult]] = []

    for mode in runner_modes.values():
        result_sub_dir = f"{result_dir}/{mode.id}"
        result_files = os.listdir(result_sub_dir)
        result_files.sort()

        results = []

        for result_file in result_files:
            # Parse file name to gather parameters
            par_txt = re.sub(f"_{mode.id}.jsonl", "", result_file)
            for var in parameter_names: par_txt = re.sub(f"_{var}_", f";{var}_", par_txt)
            parameters: dict[str, str | list[str]] = {
                par_arr[0]: par_arr[1]
                for par_arr in [
                    re.split('_', parameter, maxsplit=1) + [parameter]
                    for parameter in re.split(';', par_txt)
                ]
            }

            states = int(str(parameters.get("states")))
            alphabet = int(str(parameters.get("alphabet")))
            sequence = int(str(parameters.get("sequence")))
            counts = [int(k) for k in re.split('_', str(parameters.get("k")))]
            seed = int(str(parameters.get("seed")))

            # Gather data from the file
            with open(f"{result_sub_dir}/{result_file}", "r") as file:
                lines = [json.loads(line) for line in file]

            results.append(Result(states, alphabet, sequence, counts, seed, mode.id).collectResultFromLines(lines))

        mode_results_list.append(results)

    os.makedirs(f"{graph_dir}", exist_ok=True)

    mode_results = np.array(mode_results_list, dtype=CollectedResult)

    color = ["blue", "orange", "black"]
    for i, mode in enumerate(runner_modes.values()):

        x = mode_results[i][100].timeline
        y = np.arange(1, len(mode_results[i][100].timeline) + 1)
        
        plt.plot(x, y, color=color[i], label=f"{mode_results[i][100].type}_{mode_results[i][100].states}")

    plt.legend()

    plt.savefig(f"{graph_dir}/nogood_plot_test.png")

    # plt.style.use('_mpl-gallery')
    #
    # # make data:
    # np.random.seed(1)
    # x = [2, 4, 6]
    # y = [3.6, 5, 4.2]
    # yerr = [0.9, 1.2, 0.5]
    #
    # # plot:
    # fig, ax = plt.subplots()
    #
    # ax.errorbar(x, y, yerr, fmt='o', linewidth=2, capsize=6)
    #
    # ax.set(xlim=(0, 8), xticks=np.arange(1, 8),
    #        ylim=(0, 8), yticks=np.arange(1, 8))
    #
    # plt.show()


if __name__ == "__main__":
    main()
