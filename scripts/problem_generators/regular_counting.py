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
        self.dfa.States = [state for state in range(1, num_states + 2)]
        self.dfa.setSigma({int(sym) for sym in range(1, alphabet_size + 1)})
        self.dfa.Initial = 0
        self.dfa.Final = {num_states - 1}
        self.dfa.i = False

    def generate(self):
        # Make sure a random path from 1 to n+1 exists
        guaranteed_path = [state for state in range(2, self.num_states + 1)]
        random.shuffle(guaranteed_path)
        guaranteed_path.insert(0, 1)
        guaranteed_path.append(self.num_states + 1)

        alphabet = np.arange(1, self.alphabet_size + 1).tolist()
        for i in range(self.num_states):
            # Randomize symbols
            random.shuffle(alphabet)

            # make sure this part of the random path exists
            state = guaranteed_path[i]
            next_state = guaranteed_path[i + 1]
            sym = alphabet[0]

            self.dfa.addTransition(state - 1, sym, next_state)

            # Randomly assign the other transistions
            for j in range(1, self.alphabet_size):
                next_state = random.choice(guaranteed_path)
                sym = alphabet[j]

                self.dfa.addTransition(state - 1, sym, next_state)

    def to_dfa(self) -> object:

        q: int = len(self.dfa.States)
        s: int = len(self.dfa.Sigma)

        transitions: list[list[int]] = np.zeros(shape=(q, s), dtype=int).tolist()
        for (state, sym, next_state) in self.dfa.transitions():
            transitions[state][sym - 1] = next_state

        new_dfa = DFA()
        new_dfa.setSigma(self.dfa.Sigma)
        new_dfa.States.append(1)
        new_dfa.Initial = 0
        new_dfa.i = False

        # Create k + 1 copies concatenated
        for n in range(max(self.k) + 1):
            merge_state = n * (q - 1) + 1

            # add new states
            for new_state in range(merge_state + 1, merge_state + q):
                new_dfa.States.append(new_state)

            # Add final states
            if n in self.k:
                new_dfa.addFinal(merge_state)
                for new_state in range(q - 1):
                    new_dfa.addFinal(merge_state + new_state - 1)

            # Add transitions
            for state in range(q - 1):
                for sym in range(s):
                    next_state = merge_state + transitions[state][sym];
                    new_dfa.addTransition(merge_state + state - 1, (sym + 1), next_state - 2)

        # Make final state loop to self on all.
        new_q = len(new_dfa.States)
        for sym in range(s):
            new_dfa.addTransition(new_q - 1, (sym + 1), new_q - 1)

        # Minimize
        minimal_dfa = new_dfa.minimalHopcroft()

        # for i, state in enumerate(minimal_dfa.States):
        #     if i not in minimal_dfa.delta:
        #         print(f"{i}:{state}")
        #     else:
        #         print(f"{i}:{state}:{minimal_dfa.delta[i]}")
        # print(minimal_dfa.Final)

        minimal_q: int = len(minimal_dfa.States)

        # Map DFA transitions from 1..Q inclusive with 0 being a reject trapstate.
        d = np.zeros(shape=(minimal_q, s), dtype=int)
        for i, state in enumerate(minimal_dfa.States):
            for j, sym in enumerate(range(1, self.alphabet_size + 1)):
                # map to fail state
                if i not in minimal_dfa.delta:
                    d[i][j] = 0
                # map to fail state
                elif sym not in minimal_dfa.delta[i]:
                    d[i][j] = 0
                # map state correctly
                else:
                    d[i][j] = minimal_dfa.delta[i][sym] + 1

        f = [state + 1 for state in minimal_dfa.Final]
        
        return {'Q': minimal_q, 'S': s, 'd': d.tolist(), 'q0': minimal_dfa.Initial, 'F': {'set': f}, 'sequence_length' : self.sequence_length}

    def to_cdfa(self) -> object:
        q = self.num_states
        s = self.alphabet_size

        new_dfa = self.dfa.dup()

        inc = np.zeros(shape=(q, s), dtype=int)
        for (state, sym, next_state) in self.dfa.transitions():
            if state <= self.num_states and next_state == self.num_states + 1:
                new_dfa.delTransition(state, sym, next_state)
                new_dfa.addTransition(state, sym, 1)
                inc[state][sym - 1] = 1

        d = np.zeros(shape=(q, s), dtype=int)
        for (state, sym, next_state) in new_dfa.transitions():
            d[state][sym - 1] = next_state                
        
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
    # print(cdfa)
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
