# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "numpy>=2.4.4",
# ]
# ///
"""
Nonogram problem generator.
Adapted from https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/problem_generators/nonogram.py

Example usage:
uv run problem_generators/nonogram.py \
    --width 5 --height 3 --density 0.5 --seed 42
"""

import argparse
import random
import os
import json
import numpy as np
from numpy._typing import NDArray


class NonogramInstance:
    def __init__(self, width: int, height: int):
        self.width = width
        self.height = height

        self.grid = np.zeros((height, width), dtype=int)

    def generate(self, density: float):
        for x in range(self.width):
            for y in range(self.height):
                self.grid[y][x] = int(random.random() < density)

    def hint(self, line: NDArray[np.int_]) -> NDArray[np.int_]:
        hint: list[int] = []

        current_value = 0

        for cell in line:
            if cell:
                current_value += 1
            elif current_value != 0:
                hint.append(current_value)
                current_value = 0

        # Always insert the last (non-zero) value,
        # or 0 if the entire line is empty
        if current_value != 0 or len(hint) == 0:
            hint.append(current_value)

        return np.array(hint, dtype=int)

    def column_hint(self, x: int) -> NDArray[np.int_]:
        assert x >= 0, "column should be non-negative"
        assert x < self.width, "column should be less than width"

        line = self.grid[:,x]

        return self.hint(line)

    def row_hint(self, y: int) -> NDArray[np.int_]:
        assert y >= 0, "row should be non-negative"
        assert y < self.height, "row should be less than height"

        line = self.grid[y]

        return self.hint(line)

        # def hint_to_regex(self, hint: list[int]) -> str:
        #     # Starts and ends with any number of empty cells
        #     start = "(1*) "
        #     end = " (1*)"
        #     # Gaps have at least one empty cell
        #     gap = " (1+) "
        #     # Each hint is encoded as exactly that number of filled cells
        #     hints = [f"(2{{{value}}})" for value in hint]
        #     # Between hints, there's a gap
        #     middle = gap.join(hints)

        #     return start + middle + end

    def hint_to_dfa(self, hint: NDArray[np.int_]) -> object:
        q = int(sum(hint) + len(hint))
        d = np.zeros((q, 2), dtype=int)

        acc = 0

        # The states are numbered 1..Q, so index generation looks a bit weird.
        for n in hint:
            # 0*(1{1})
            d[acc][0] = acc + 1 # to self
            d[acc][1] = acc + 2 # to next

            # 1{n-1}
            for i in range(1, n):
                d[acc + i][1] = acc + i + 2 # to next
            
            # 0{1}
            d[acc + n][0] = acc + n + 2 # to next
            acc += n + 1
        
        # End with 0*
        d[q - 1][0] = q # to next
        d[q - 1][1] = 0 # to fail

        return {'Q': q, 'S': 2, 'd': d.tolist(), 'q0': 1, 'F': {"set": [q]}}

    def hint_to_cdfa(self, hint: NDArray[np.int_], n: int) -> object:
        if hint[0] == 0 or hint[0] == n:
            q = 1
            d = np.ones((1, 2), dtype=int)      # Both to self

            inc = np.zeros((1, 2), dtype=int)   # increment on fill
            inc[0][1] = 1

            count = int(hint[0])

        elif len(set(hint)) == 1:
            q = int(hint[0] + 1)
            d = np.ones((q, 2), dtype=int)
            inc = np.zeros((q, 2), dtype=int)

            for i in range(q - 1):
                d[i][0] = i + 1 # To self
                d[i][1] = i + 2 # To next

            d[q - 1][0] = 1     # Back to start
            d[q - 1][1] = q     # To self
            
            for i in range(1, q - 1):
                inc[i][0] = n + 1   # In the middle, don't put empty.

            inc[q - 2][1] = 1       # You should take the transition to the last node count times,
            inc[q - 1][1] = n + 1   # But not any more times.

            count = int(len(hint))


        else:
            q = int(len(hint) * 2 + 1)
            d = np.ones((q, 2), dtype=int)
            inc = np.zeros((q, 2), dtype=int)

            for i in range(q):
                d[i][i % 2] = i + 1             # To self on empty for odd states and on fill for even states (start numbering at 1)
                d[i][(i + 1) % 2] = i + 2       # To next on fill for odd states and on empty for even states

                inc[i][1] = (n + 1) ** (i // 2) # count 1 for the first hint, (n + 1) for the second, etc. The last transition counts more than the count.

            # keep looping to self for both at the last state
            d[q - 1][0] = q
            d[q - 1][1] = q

            count = 0
            for i in range(len(hint)):
                count += int(hint[i]) * ((n + 1) ** i)

        return {'Q': q, 'S': 2, 'd': d.tolist(), 'q0': 1, "inc": inc.tolist(), "N": count}

        # def hint_to_cdfas(self, hint: NDArray[np.int_], n: int) -> NDArray:

        #     cdfas = []

        #     for (i, h) in enumerate(hint):
        #         
        #         cdfas.add({'Q': q, 'S': 2, 'd': d.tolist(), 'q0': 1, "inc": inc.tolist(), "N": count})
        #     
        #     return np.array(cdfas)


    def dfas_json(self, seed: int) -> str:
        # Start by describing the instance
        description = "\n".join([
            "Instance for Nonogram model",
            "generated using scripts/problem_generators/nonogram.py",
            f"Instance generated for grid size {self.width}x{self.height}",
            f"using {seed} as seed.",
            "",
            "Generated board:",
            ""
        ])

        boardStr = "\n".join([
            " ".join([
                str(cell + 1)
            for cell in row])
        for row in self.grid])

        row_dfas = [
            self.hint_to_dfa(self.row_hint(y))
            for y in range(self.height)
        ]
        col_dfas = [
            self.hint_to_dfa(self.column_hint(x))
            for x in range(self.width)
        ]

        return json.dumps({"description": description + boardStr, "width": self.width, "height": self.height, "row_dfas": row_dfas, "col_dfas": col_dfas}, indent=2)

    def cdfas_json(self, seed: int) -> str:
        # Start by describing the instance
        description = "\n".join([
            "Instance for Nonogram model",
            "generated using scripts/problem_generators/nonogram.py",
            f"Instance generated for grid size {self.width}x{self.height}",
            f"using {seed} as seed.",
            "",
            "Generated board:",
            ""
        ])

        boardStr = "\n".join([
            " ".join([
                str(cell + 1)
            for cell in row])
        for row in self.grid])

        row_cdfas = [
            self.hint_to_cdfa(self.row_hint(y), self.width)
            for y in range(self.height)
        ]
        col_cdfas = [
            self.hint_to_cdfa(self.column_hint(x), self.height)
            for x in range(self.width)
        ]

        return json.dumps({"description": description + boardStr, "width": self.width, "height": self.height, "row_cdfas": row_cdfas, "col_cdfas": col_cdfas}, indent=2)



def main():
    argument_parser = argparse.ArgumentParser(
        description="Nonogram problem generator"
    )

    argument_parser.add_argument(
        "--width",
        type=int,
        required=True,
        help="Width of the Nonogram grid"
    )

    argument_parser.add_argument(
        "--height",
        type=int,
        required=True,
        help="Width of the Nonogram grid"
    )

    argument_parser.add_argument(
        "--seed",
        type=int,
        required=True,
        help="Seed for pseudo-random number generator"
    )

    argument_parser.add_argument(
        "--density",
        type=float,
        required=False,
        default=0.5,
        help="Density of the cells. This portion of the grid will be filled."
    )

    argument_parser.add_argument(
        "--data-dir",
        type=str,
        required=False,
        default="./problems/nonogram/data",
        help="Directory of nonogram data files to write to.",
        dest="data"
    )

    args = argument_parser.parse_args()

    random.seed(args.seed)

    nonogram = NonogramInstance(args.width, args.height)
    nonogram.generate(args.density)

    # Make sure the internal direcories exist.
    os.makedirs(args.data + "/dfa", exist_ok=True)
    os.makedirs(args.data + "/cdfa", exist_ok=True)
    if not os.path.islink(args.data + "/decomp"):
        os.symlink(args.data + "/dfa", args.data + "/decomp", target_is_directory=True)

    # Generate the DFAs for this Nonogram.
    dfa = nonogram.dfas_json(args.seed)
    #print(dfa)
    data_file = os.path.join(
        os.path.realpath(args.data + "/dfa"),
        "nonogram_"
        f"{args.width}x{args.height}_"
        f"seed_{args.seed}.json"
    )
    with open(data_file, "w") as data_file:
        print(dfa, file=data_file)

    # Generate the cDFA for this Nonogram.
    cdfa = nonogram.cdfas_json(args.seed)
    #print(cdfa)
    data_file = os.path.join(
        os.path.realpath(args.data + "/cdfa"),
        "nonogram_"
        f"{args.width}x{args.height}_"
        f"seed_{args.seed}.json"
    )
    with open(data_file, "w") as data_file:
        print(cdfa, file=data_file)


if __name__ == "__main__":
    main()
