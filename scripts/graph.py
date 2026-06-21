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
from typing import Callable

from matplotlib.lines import Line2D
from numpy._typing import NDArray

from config import runner_modes

import numpy as np
import matplotlib.pyplot as plt

class SolveStatus(Enum):
    UNSATISFIABLE = -1
    UNKNOWN = 0
    SOLUTION = 1
    ALL_SOLUTIONS = 2

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

        self.status: SolveStatus = SolveStatus.UNKNOWN
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
                    self.status = SolveStatus.SOLUTION
    
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
    
                case {'type': 'status', 'status': "UNKNOWN", 'time': _}:
                    print(line)
                    print(f"{self.type}, Seed: {self.seed}\nStates: {self.states}, Alphabet: {self.alphabet}, Sequence: {self.sequence}, \nCounts: {self.counts}")
                    self.status = SolveStatus.UNKNOWN

                case {'type': 'status', 'status': "UNSATISFIABLE", 'time': _}:
                    print(line)
                    print(f"{self.type}, Seed: {self.seed}\nStates: {self.states}, Alphabet: {self.alphabet}, Sequence: {self.sequence}, \nCounts: {self.counts}")
                    self.status = SolveStatus.UNSATISFIABLE
    
                case {'type': 'status', 'status': "ALL_SOLUTIONS", 'time': _}:
                    self.status = SolveStatus.ALL_SOLUTIONS
    
                case other:
                    print(f"states_{self.states}_alphabet_{self.alphabet}_sequence_{self.sequence}_k_{'_'.join([str(k) for k in self.counts])}_seed_{self.seed}_{self.type}")
                    print(f"don't know what to do with:\n{other}")

        return self.collect()


def compile_data(result_dir: str):
    parameter_names = ["states", "alphabet", "sequence", "k", "seed"]

    # Collect results
    mode_results_list: list[list[CollectedResult]] = []
    unsatisfiable = []

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

            # print(parameters)

            states = int(str(parameters.get("states")))
            alphabet = int(str(parameters.get("alphabet")))
            sequence = int(str(parameters.get("sequence")))
            counts = [int(k) for k in re.split('_', str(parameters.get("k")))]
            seed = int(str(parameters.get("seed")))

            # Gather data from the file
            with open(f"{result_sub_dir}/{result_file}", "r") as file:
                lines = [json.loads(line) for line in file]

            result = Result(states, alphabet, sequence, counts, seed, mode.id).collectResultFromLines(lines)
            if result.status == SolveStatus.UNSATISFIABLE:
                print(result.status)
                unsatisfiable.append(len(results))

            results.append(result)

        mode_results_list.append(results)
    
    print(unsatisfiable)
    output = np.delete(np.array([np.array(results, dtype=CollectedResult) for results in mode_results_list]), unsatisfiable, axis=1)
    print(output.shape)

    return output


def parseValues(results: NDArray, func: Callable, states: int | None = None, alphabet: int | None = None, max_count: int | None = None, condition: Callable | None = None):
    values = []
    labels = []
    positions = []
    for i, _ in enumerate(results):
        filter = np.where([
                (states == None or result.states == states) and
                (alphabet == None or result.alphabet == alphabet) and
                (max_count == None or max(result.counts) == max_count) and
                (condition == None or condition(result))
                for result in results[i]
        ])
        try:
            filtered_results = np.array(results[i])[filter]
        except Exception as e:
            raise Exception(f"{e}\n{filter}\n{len(results[i])}")
        solutions = [func(result) for result in filtered_results]
        #values.append((np.mean(solutions), min(solutions), max(solutions)))
        values.append(solutions)
        labels.append(results[i][0].type)
        positions.append(i)

    return values, labels, positions

def makeBoxplot(values, positions, labels, colors, title, x_label, y_label, filename, yscale, figwidth, figheight):
    # boxplot
    fig, ax = plt.subplots()
    boxplot = ax.boxplot(values, positions=positions, widths=1.5, patch_artist=True,
        showmeans=False, showfliers=True, tick_labels=labels,
        medianprops={"color": "white", "linewidth": 0.5},
        boxprops={"edgecolor": "white",
                  "linewidth": 0.5},
        whiskerprops={"linewidth": 1.5},
        capprops={"linewidth": 1.5})

    # fill with colors
    for patch, color in zip(boxplot['boxes'], colors):
        patch.set_facecolor(color)

    if yscale == "linear": ax.set_ylim(bottom=0)
    ax.set_yscale(yscale)

    fig.set_figwidth(figwidth)
    fig.set_figheight(figheight)
    plt.title(title)
    ax.set_xlabel(x_label)
    ax.set_ylabel(y_label)
    plt.grid(axis='y', which='both')
    plt.savefig(filename)
    plt.close()


def valuesByStates(results, func, state_nums, alphabet, max_count, colors, condition): 
    all_values = []
    all_positions = []
    all_labels = []
    all_colors = []

    for i, states in enumerate(state_nums):
        values, labels, positions = parseValues(results, func, states=states, alphabet=alphabet, max_count=max_count, condition=condition)
        all_values.extend(values)
        all_positions.extend([(i * 8) + ((pos + 1) * 2) for pos in positions])
        all_labels.extend([f"{label}{f"\n|Q|={states}" if label == "cdfa" else ""}" for label in labels])
        all_colors.extend(colors)

    return all_values, all_positions, all_labels, all_colors

def plotByStatesAndWithoutX(all_values, all_positions, all_labels, all_colors, graph_dir, file_name, title, setup, alphabet, max_count, x, x_name):

    # boxplot
    makeBoxplot(all_values, all_positions, all_labels, all_colors,
        f"{title} {setup}", "", title,
        f"{graph_dir}/{file_name}_vs_states_boxplot_alphabet_{alphabet}{f"_counts_1_{max_count}" if max_count is not None else ""}.png",
        "log", 10, 8)

    all_values = np.array(all_values, dtype=list)
    all_labels = np.array(all_labels)
    all_positions = np.array(all_positions)
    all_colors = np.array(all_colors)

    exclude_X_indices = np.where(np.mod(np.arange(len(all_values)), 3) != x)
    all_values = all_values[exclude_X_indices].tolist()
    all_labels = all_labels[exclude_X_indices].tolist()
    all_positions = all_positions[exclude_X_indices]
    all_colors = all_colors[exclude_X_indices]

    # boxplot without X
    makeBoxplot(all_values, all_positions, all_labels, all_colors,
        f"{title} {setup}", "", title,
        f"{graph_dir}/{file_name}_vs_states_boxplot_without_{x_name}_alphabet_{alphabet}{f"_counts_1_{max_count}" if max_count is not None else ""}.png",
        "linear", 10, 6)


def plotAll(graph_dir, file_name, results, func, condition, state_nums, alphabet_sizes, max_counts, title, ylabel, yscale, ymin, ymax):
    fig, (ax1, ax2) = plt.subplots(1, 2)

    markers = ["o", "^", "x"]
    linestyles = ["-", "--", "-."]

    count_colors = ["tab:brown", "tab:orange", "tab:red", "tab:blue"]

    line_handles = [Line2D([0], [0], color="black", marker=marker, linestyle=linestyle, label=label) for marker, linestyle, label in zip(markers, linestyles, ["cDFA", "decomp", "DFA"])]
    color_handles = [Line2D([0], [0], color=color, label=f"{'{'}1, {label}{'}'}") for color, label in zip(count_colors, max_counts)]

    fig.legend(handles=line_handles, loc='outside upper right', bbox_to_anchor=(1.005, .9), title="Type")
    fig.legend(handles=color_handles, loc='outside upper right', bbox_to_anchor=(1.005, .75), title="Counts")

    fig.set_figwidth(11)
    fig.set_figheight(6)

    fig.suptitle(title)
    fig.supylabel(ylabel)

    for alphabet, ax in zip(alphabet_sizes, [ax1, ax2]):
        # Compare all num_solutions avg in a graph.
        for i, max_count in enumerate(max_counts):
            all_values, _, _, _ = valuesByStates(results, func, state_nums, alphabet, max_count, [], condition)

            for idx in range(3):
                indices = np.where(np.mod(np.arange(len(all_values)), 3) == idx)

                avgs = []
                for values in np.array(all_values, dtype=list)[indices]:
                    avgs.append(np.mean(values) if len(values) > 0 else 0)

                ax.plot(state_nums, avgs, markers[idx] + linestyles[idx], linewidth=2, color=count_colors[i], zorder=idx+2)

        ax.set_title(f"\nwith |Σ|={alphabet}")
        ax.set_xlabel("|Q| amount of states of cDFA")
        ax.grid(axis="y", which='both')
        ax.grid(axis="x")
        ax.set_xticks(state_nums)
        ax.set_ylim(bottom=ymin, top=ymax)
        ax.set_yscale(yscale)

    plt.savefig(f"{graph_dir}/{file_name}.png", dpi=300)
    plt.close()


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

    if os.path.isfile(f"{result_dir}/compiled_data.npy"):
        # Load precompiled if it exists
        results = np.load(f"{result_dir}/compiled_data.npy", allow_pickle=True)
    else:
        # Compile and save
        results = compile_data(result_dir)
        np.save(f"{result_dir}/compiled_data", results, allow_pickle=True)

    # reorder from decomp, DFA, cDFA to cDFA, decomp, DFA
    new_indices = [2, 0, 1]
    results = results[new_indices]

    os.makedirs(f"{graph_dir}", exist_ok=True)

    colors = ["tab:blue", "tab:orange", "tab:brown"]
    state_nums = [3, 5, 7, 9]
    alphabet_sizes = [3, 6]
    max_counts = [2, 4, 8, 16]

    for result in results.flatten():
        if result.status != SolveStatus.SOLUTION:
            print(f"{result.type}: {result.status}")
            print(f"  {result.states, result.alphabet, result.counts, result.seed}")

    plotAll(graph_dir, "all_solveTime", results,
            lambda r: r.timeline[-1] if r.status == SolveStatus.SOLUTION else r.timeline[-1] * 2, None,
            state_nums, alphabet_sizes, max_counts,
            "Average solve time",
            "Average solve time (s)", 'log', 0.00_01, 100)

    plotAll(graph_dir, "all_AverageLearnedNogoodLength", results,
            lambda r: r.averageLearnedNogoodLength[-1],
            lambda r: r.nSolutions == 1 and r.nogoods[-1] != 0,
            state_nums, alphabet_sizes, max_counts,
            "Average learned nogood length",
            "Average learned nogood length", 'log', 5, 700)

    plotAll(graph_dir, "all_LBD", results,
            lambda r: r.averageLbd[-1],
            lambda r: r.nSolutions == 1 and r.nogoods[-1] != 0,
            state_nums, alphabet_sizes, max_counts,
            "Average LBD",
            "Average LBD", 'log', 3, 155)

    plotAll(graph_dir, "all_num_propagations", results,
            lambda r: r.propagations[-1] if r.status == SolveStatus.SOLUTION else r.propagations[-1] * 2, None,
            state_nums, alphabet_sizes, max_counts,
            "Average number of propagations",
            "Average number of propagations", 'log', 10, 4000_000)

    plotAll(graph_dir, "all_num_nogoods", results,
            lambda r: r.nogoods[-1] if r.status == SolveStatus.SOLUTION else r.nogoods[-1] * 2, None,
            state_nums, alphabet_sizes, max_counts,
            "Average number of conflicts",
            "Average number of conflicts", 'symlog', -.1, 30_000)

    # Plot all individual boxplots.
    for alphabet in alphabet_sizes:
        for max_count in max_counts:
            # Compare number of solutions
            setup =  f"\nwith |Σ|={alphabet}, counts={"{1, "}{max_count}{'}'}"
            all_values, all_positions, all_labels, all_colors = valuesByStates(results, lambda r: r.timeline[-1] if r.status == SolveStatus.SOLUTION else r.timeline[-1] * 2,
                                                                               state_nums, alphabet, max_count, colors,
                                                                               None)
            plotByStatesAndWithoutX(all_values, all_positions, all_labels, all_colors, graph_dir,
                                    "solveTime", "Solve time",
                                    setup, alphabet, max_count, 2, "dfa")

            # Compare learned nogood length
            setup =  f"\nwith |Σ|={alphabet}, counts={"{1, "}{max_count}{'}'}"
            all_values, all_positions, all_labels, all_colors = valuesByStates(results, lambda r: r.averageLearnedNogoodLength[-1],
                                                                               state_nums, alphabet, max_count, colors,
                                                                               lambda r: r.nSolutions == 1 and r.nogoods[-1] != 0)
            plotByStatesAndWithoutX(all_values, all_positions, all_labels, all_colors, graph_dir,
                                    "LearnedNogoodLength", "Learned nogood length",
                                    setup, alphabet, max_count, 2, "dfa")

            # Compare ldb
            setup =  f"\nwith |Σ|={alphabet}, counts={"{1, "}{max_count}{'}'}"
            all_values, all_positions, all_labels, all_colors = valuesByStates(results, lambda r: r.averageLbd[-1],
                                                                               state_nums, alphabet, max_count, colors,
                                                                               lambda r: r.nSolutions == 1 and r.nogoods[-1] != 0)
            plotByStatesAndWithoutX(all_values, all_positions, all_labels, all_colors, graph_dir,
                                    "LBD", "LBD",
                                    setup, alphabet, max_count, 2, "dfa")


            # Compare number of propagations
            setup =  f"\nwith |Σ|={alphabet}, counts={"{1, "}{max_count}{'}'}"
            all_values, all_positions, all_labels, all_colors = valuesByStates(results, lambda r: r.propagations[-1] if r.status == SolveStatus.SOLUTION else r.propagations[-1] * 2,
                                                                               state_nums, alphabet, max_count, colors,
                                                                               None)
            plotByStatesAndWithoutX(all_values, all_positions, all_labels, all_colors, graph_dir,
                                    "propagations", "Average number of propagations per solution",
                                    setup, alphabet, max_count, 1, "decomp")

            # Compare number of nogoods
            setup =  f"\nwith |Σ|={alphabet}, counts={"{1, "}{max_count}{'}'}"
            all_values, all_positions, all_labels, all_colors = valuesByStates(results, lambda r: r.nogoods[-1] if r.status == SolveStatus.SOLUTION else r.nogoods[-1] * 2,
                                                                               state_nums, alphabet, max_count, colors,
                                                                               None)
            plotByStatesAndWithoutX(all_values, all_positions, all_labels, all_colors, graph_dir,
                                    "nogoods", "Number of nogoods",
                                    setup, alphabet, max_count, 1, "decomp")

        # Compare peak depth
        #plotByStates(results, lambda r: r.peakDepth[-1], graph_dir, "peak_depth", "Peak depth", setup, state_nums, alphabet, None, colors)

        #setup =  f"after running for 60s\nwith |Σ|={alphabet}"



    #print(f"{results[i][-1].type} time: {results[i][-1].timeline[0]}")
    
    # plt.plot(x, y, color=color[i], label=f"{results[i][-1].type}_{results[i][-1].states}")



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
