# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "numpy>=2.4.4",
#     "fado>=2.2.0"
# ]
# ///
"""
Licence:

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your Option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
"""

"""
Regular counting problem generator.
inspired by https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/problem_generators/nonogram.py

Example usage:
uv run problem_generators/nonogram.py \
    --width 5 --height 3 --density 0.5 --seed 42
"""

import argparse
import random
import os
import json
from typing import Sequence
import numpy as np
from FAdo.fa import DFA

class RegularCountingInstance:
    def __init__(self, num_states: int, alphabet_size: int, sequence_length: int, k: set[int]):
        self.num_states = num_states
        self.alphabet_size = alphabet_size
        self.sequence_length = sequence_length
        self.k = k

        self.dfa = DFA();
        self.dfa.States = np.arange(1, num_states + 1).tolist()
        self.dfa.Sigma = set(np.arange(1, alphabet_size + 1).tolist())
        self.dfa.Initial = 0
        self.dfa.Final = {num_states - 1}

    def generate(self):
        # Make sure a random path from 1 to n exists
        guaranteed_path = np.arange(2, self.num_states).tolist()
        random.shuffle(guaranteed_path)
        guaranteed_path.insert(0, 1)
        guaranteed_path.append(self.num_states)

        alphabet = np.arange(1, self.alphabet_size + 1).tolist()
        for i in range(self.num_states - 1):
            # Randomize symbols
            random.shuffle(alphabet)

            # make sure this part of the random path exists
            state = guaranteed_path[i]
            next_state = guaranteed_path[i + 1]
            sym = alphabet[0]

            self.dfa.addTransition(state, sym, next_state)

            # Randomly assign the other transistions
            for j in range(1, self.alphabet_size):
                next_state = random.choice(guaranteed_path)
                sym = alphabet[j]

                self.dfa.addTransition(state, sym, next_state)

    def to_dfa(self) -> object:

        transitions = np.zeros(shape=(self.num_states, self.alphabet_size), dtype=int)
        for (state, sym, next_state) in self.dfa.transitions():
            transitions[state - 1][sym - 1] = next_state

        new_dfa = DFA()
        new_dfa.States.append(1)

        # Create k + 1 copies concatenated
        for n in range(max(self.k) + 1):
            merge_state = n * (self.num_states - 1)

            for new_state in range(1, self.num_states):
                new_dfa.States.append(merge_state + (new_state + 1))

            # Add final states
            if n in self.k:
                new_dfa.addFinal(merge_state)
                for new_state in range(self.num_states - 2):
                    new_dfa.addFinal(merge_state + (new_state + 1))

            # Add transitions
            for state in range(self.num_states - 1):
                for sym in range(self.alphabet_size):
                    next_state = merge_state + transitions[state][sym];
                    new_dfa.addTransition(merge_state + (state + 1), (sym + 1), next_state)

        # Minimize
        new_dfa.minimalBrzozowski()

        q: int = len(new_dfa.States)
        s: int = self.alphabet_size

        d = np.zeros(shape=(q, s), dtype=int)
        for (state, sym, next_state) in new_dfa.transitions():
            d[state - 1][sym - 1] = next_state

        f = [state + 1 for state in new_dfa.Final]
        
        return {'Q': q, 'S': s, 'd': d.tolist(), 'q0': 1, 'F': {'set': f}, 'sequence_length' : self.sequence_length}

    def to_cdfa(self) -> object:

        new_dfa = self.dfa.dup()

        for sym in new_dfa.Sigma:
            new_dfa.addTransition(self.num_states, sym, 1)

        q = self.num_states
        s = self.alphabet_size

        d = np.zeros(shape=(q, s), dtype=int)
        inc = np.zeros(shape=(q, s), dtype=int)
        for (state, sym, next_state) in new_dfa.transitions():
            d[state - 1][sym - 1] = next_state

            if next_state == self.num_states:
                inc[state - 1][sym - 1] = 1
        
        return {'Q': q, 'S': s, 'd': d.tolist(), 'q0': 1, 'inc': inc.tolist(), 'counts': {'set': self.k}, 'sequence_length' : self.sequence_length}

def main():
    argument_parser = argparse.ArgumentParser(
        description="RegularCounting problem generator"
    )

    argument_parser.add_argument(
        "--num-states",
        type=int,
        required=True,
        help="Number of states of the cDFA."
    )

    argument_parser.add_argument(
        "--alphabet-size",
        type=int,
        required=True,
        help="Amount of symbols in the alphabet."
    )

    argument_parser.add_argument(
        "--sequence-length",
        type=int,
        required=True,
        help="Length of the sequence consumed by the automata."
    )

    argument_parser.add_argument(
        "--k",
        nargs="+",
        type=int,
        required=True,
        help="List of counts to count to."
    )

    argument_parser.add_argument(
        "--seed",
        type=int,
        required=True,
        help="Seed for pseudo-random number generator"
    )

    argument_parser.add_argument(
        "--data-dir",
        type=str,
        required=False,
        default="./problems/regular_counting/data",
        help="Directory of regular counting data files to write to.",
        dest="data"
    )

    args = argument_parser.parse_args()

    random.seed(args.seed)

    # Generate the problem
    rc = RegularCountingInstance(args.num_states, args.alphabet_size, args.sequence_length, args.k)
    rc.generate()

    # Make sure the internal direcories exist.
    os.makedirs(args.data + "/dfa", exist_ok=True)
    os.makedirs(args.data + "/cdfa", exist_ok=True)
    if not os.path.islink(args.data + "/decomp"):
        os.symlink(args.data + "/dfa", args.data + "/decomp", target_is_directory=True)

    # Generate the DFAs for this RegularCounting.
    dfa = json.dumps(rc.to_dfa(), indent=2)
    # print(dfa)
    data_file = os.path.join(
        os.path.realpath(args.data + "/dfa"),
        "regular_counting_"
        f"states_{args.num_states}_alphabet_{args.alphabet_size}_"
        f"sequence_{args.sequence_length}_"
        f"k_{'_'.join(str(k) for k in args.k)}_"
        f"seed_{args.seed}.json"
    )
    with open(data_file, "w") as data_file:
        print(dfa, file=data_file)

    # Generate the cDFA for this RegularCounting.
    cdfa = json.dumps(rc.to_cdfa(), indent=2)
    #print(cdfa)
    data_file = os.path.join(
        os.path.realpath(args.data + "/cdfa"),
        "regular_counting_"
        f"states_{args.num_states}_alphabet_{args.alphabet_size}_"
        f"sequence_{args.sequence_length}_"
        f"k_{'_'.join(str(k) for k in args.k)}_"
        f"seed_{args.seed}.json"
    )
    with open(data_file, "w") as data_file:
        print(cdfa, file=data_file)


if __name__ == "__main__":
    main()
