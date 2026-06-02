"""
Based on https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/runner.py
Experiments runner for Pumpkin,
"""

import argparse
import os
import subprocess
import shutil
from config import RunnerMode, runner_modes
import datetime
# import asyncio


# def background(f):
#     def wrapped(*args, **kwargs):
#         return asyncio.get_event_loop().run_in_executor(
#             None, f, *args, **kwargs
#         )
#
#     return wrapped
#
#
# @background
def run_solver(
    solver_dir: str,
    problem: str,
    data_file: str,
    time_limit: int,
    mode: RunnerMode,
):
    # minizinc --output-mode json --json-stream -s \
    #   --solver ../Pumpkin/minizinc/pumpkin.msc -I lib \
    #   problems/nonogram/dfa.mzn \
    #   problems/nonogram/data/dfa/nonogram_25x25_seed_1.dzn
    problem_data_dir = f"problems/{problem}/data/{mode.id}"
    problem_mzn = f"problems/{problem}/{mode.id}.mzn"
    result_dir = f"results_{problem}_{time_limit}s/{mode.id}"
    output_file = f"{result_dir}/{os.path.splitext(data_file)[0]}_" + \
        (mode.id) + \
        ".jsonl"


    print(solver_dir)
    if os.path.exists(output_file):
        print(f"{output_file} already exists. Skipping...")
        return

    args = [
                "minizinc",
                "--output-mode", "json",
                "--json-stream",
                "--statistics",
                "--output-time",
                "--output-objective",
                "--all-solutions",
                "--time-limit", f"{time_limit * 1000}",
                # "--output-to-file", output_file,
            ] + mode.parameters + [
                "--solver", f"{solver_dir}/{mode.solver}",
                "--search-dir", f"{solver_dir}/{mode.lib}",
                problem_mzn, f"{problem_data_dir}/{data_file}"
            ]
    temp_file = subprocess.run(
        ["mktemp"], capture_output=True, text=True
    ).stdout.strip()

    with open(temp_file, "w") as file:
        print(" ".join(args))
        print(f"Starting at {datetime.datetime.now()}")
        subprocess.run(args, stdout=file)

    shutil.move(temp_file, os.path.realpath(output_file))

def main():
    description = "Experiments runner for regular constraint. " \
        "Runs each data file "

    argument_parser = argparse.ArgumentParser(
        description=description
    )

    argument_parser.add_argument(
        "problem",
        nargs="+",
        type=str,
        help="List of problems to run, from problems/ directory."
    )

    argument_parser.add_argument(
        "--time-limit",
        type=int,
        required=False,
        default=60,
        help="Time limit in seconds",
        dest="time_limit"
    )

    argument_parser.add_argument(
        "--solver-dir",
        type=str,
        required=False,
        default=os.environ['MZN_SOLVER_PATH'],
        help="Directory containing the library and solver to run"
    )

    args = argument_parser.parse_args()

    jobs = []

    for problem in args.problem:
        problem_data_dir = f"problems/{problem}/data"
        result_dir = f"results_{problem}_{args.time_limit}s"

        os.makedirs(result_dir, exist_ok=True)
        for mode in runner_modes.values():
            problem_data_sub_dir = f"{problem_data_dir}/{mode.id}"
            problem_files = os.listdir(problem_data_sub_dir)
            problem_files.sort()

            os.makedirs(f"{result_dir}/{mode.id}", exist_ok=True)

            for data_file in problem_files:
                jobs.append((
                    args.solver_dir,
                    problem,
                    f"{data_file}",
                    args.time_limit,
                    mode
                ))

    for job in jobs:
        run_solver(*job)


if __name__ == "__main__":
    main()
