# Based on https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/config.py
from collections import namedtuple

RunnerMode = namedtuple('RunnerMode', ['id', 'solver', 'lib', 'parameters', 'name'])

runner_modes = {
    "decomposition": RunnerMode("decomp", 'pumpkin-decomposition.msc', 'lib-decomposition', [], 'Decomposition'),
    "dfa": RunnerMode("dfa", "pumpkin.msc", "lib", [], 'DFA propagator'),
    # "cdfa": RunnerMode("cdfa", "pumpkin.msc", "lib", [], 'cDFA propagator')
}
