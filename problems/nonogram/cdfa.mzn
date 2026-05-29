% Nonogram model
% Model by Daniël Ravensbergen
%
% Inspired by https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/problems/nonogram/nonogram.mzn


include "globals.mzn";

predicate regular_cdfa(
  array[int] of var int: x,
  int: Q,
  int: S,
  array[int] of int: d,
  int: q0,
  array[int] of int: inc,
  var int: N
);


type cdfa = record(
  int: Q,
  int: S,
  array[int] of array[int] of int: d,
  int: q0,
  array[int] of array[int] of int: inc,
  var int: N
);

type cdfa_constraint_type = record(
  int: Q,
  int: S,
  array[int] of int: d,
  int: q0,
  array[int] of int: inc,
  var int: N,
  array[int] of var int: sequence
);

int: width;
int: height;

array[_] of cdfa: row_cdfas;
array[_] of cdfa: col_cdfas;
%bool: b = trace_dbg(show(row_cdfas[1]));

array[1..height, 1..width] of var 1..2: grid;

array[int] of cdfa_constraint_type: rows = [(
  Q: row_cdfas[i].Q,
  S: row_cdfas[i].S,
  d: array1d(array2d(1..row_cdfas[i].Q, 1..row_cdfas[i].S, [row_cdfas[i].d[r][c] | r in index_set(row_cdfas[i].d), c in index_set(row_cdfas[i].d[r])])),
  q0: row_cdfas[i].q0,
  inc: array1d(array2d(1..row_cdfas[i].Q, 1..row_cdfas[i].S, [row_cdfas[i].inc[r][c] | r in index_set(row_cdfas[i].inc), c in index_set(row_cdfas[i].inc[r])])),
  N: row_cdfas[i].N,
  sequence: row(grid, i)
) | i in 1..height];

array[int] of cdfa_constraint_type: cols = [(
  Q: col_cdfas[i].Q,
  S: col_cdfas[i].S,
  d: array1d(array2d(1..col_cdfas[i].Q, 1..col_cdfas[i].S, [col_cdfas[i].d[r][c] | r in index_set(col_cdfas[i].d), c in index_set(col_cdfas[i].d[r])])),
  q0: col_cdfas[i].q0,
  inc: array1d(array2d(1..col_cdfas[i].Q, 1..col_cdfas[i].S, [col_cdfas[i].inc[r][c] | r in index_set(col_cdfas[i].inc), c in index_set(col_cdfas[i].inc[r])])),
  N: col_cdfas[i].N,
  sequence: col(grid, i)
) | i in 1..width];

bool: b = trace_dbg(show((rows)));
constraint forall (r in rows) (
  regular_cdfa(r.sequence, r.Q, r.S, r.d, r.q0, r.inc, r.N)
);

constraint forall (c in cols) (
  regular_cdfa(c.sequence, c.Q, c.S, c.d, c.q0, c.inc, c.N)
);

