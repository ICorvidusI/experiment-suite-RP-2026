% Model for regular counting based on regular constraint.
% Model by Daniël Ravensbergen

include "globals.mzn";

int: Q;
int: S;
array[1..Q, 1..S] of int: d;
int: q0;
set of int: F;

int: sequence_length;
array[1..sequence_length] of var (1..S): sequence;
array[1..sequence_length] of var (1..S): reverse_sequence = reverse(sequence);

constraint regular(sequence, Q, S, d, q0, F);
constraint regular(reverse_sequence, Q, S, d, q0, F);

solve satisfy;
