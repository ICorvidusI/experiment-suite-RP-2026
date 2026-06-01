% Model for regular counting based on regular_cdfa constraint.
% Model by Daniël Ravensbergen

predicate regular_cdfa(
  array[int] of var int: x,
  int: Q,
  int: S,
  array[int] of int: d,
  int: q0,
  array[int] of int: inc,
  var int: N
);

int: Q;
int: S;
array[1..Q, 1..S] of int: d;
int: q0;
array[1..Q, 1..S] of int: inc;
set of int: counts;

var counts: N;

int: sequence_length;
array[1..sequence_length] of var (1..S): sequence;

constraint regular_cdfa(sequence, Q, S, array1d(d), q0, array1d(inc), N);

solve satisfy;
