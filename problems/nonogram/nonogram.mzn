% Nonogram model
% Model by Daniël Ravensbergen
%
% Inspired by https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/problems/nonogram/nonogram.mzn


include "globals.mzn";

type Dfa = record(
  int: Q,
  int: S,
  array[int] of array[int] of int: d,
  int: q0,
  array[1..1] of int: F
);

type dfa_constraint_type = record(
  set of int: F,
  int: Q,
  int: S,
  array[int,int] of int: d,
  int: q0,
  array[int] of var int: sequence
);

int: width;
int: height;

array[_] of Dfa: row_dfas;
array[_] of Dfa: col_dfas;
%bool: b = trace_dbg(show(row_dfas[1]));

array[1..height, 1..width] of var 1..2: grid;

array[int] of dfa_constraint_type: rows = [(
  Q: row_dfas[i].Q,
  S: row_dfas[i].S,
  d: array2d(1..row_dfas[i].Q, 1..row_dfas[i].S, [row_dfas[i].d[r][c] | r in index_set(row_dfas[i].d), c in index_set(row_dfas[i].d[r])]),
  q0: row_dfas[i].q0,
  F: array2set(row_dfas[i].F),
  sequence: row(grid, i)
) | i in 1..height];

array[int] of dfa_constraint_type: cols = [(
  Q: col_dfas[i].Q,
  S: col_dfas[i].S,
  d: array2d(1..col_dfas[i].Q, 1..col_dfas[i].S, [col_dfas[i].d[r][c] | r in index_set(col_dfas[i].d), c in index_set(col_dfas[i].d[r])]),
  q0: col_dfas[i].q0,
  F: array2set(col_dfas[i].F),
  sequence: col(grid, i)
) | i in 1..width];

bool: b = trace_dbg(show((rows)));
constraint forall (r in rows) (
  regular(r.sequence, r.Q, r.S, r.d, r.q0, r.F)
);

constraint forall (c in cols) (
  regular(c.sequence, c.Q, c.S, c.d, c.q0, c.F)
);

