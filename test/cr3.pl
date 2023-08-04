:- working_directory(_, '../code').
:-[main].

theoryName(cr3).


axiom([-mum(\x,\y,\w),-mum(\z,\y,\w),+eqst(\x,\z)]).
axiom([+mum(lily,tina,birth)]).
axiom([+mum(lily,victor,step)]).
axiom([+mum(anna,victor,step)]).

trueSet([]).
falseSet([eqst(anna,lily),eqst(lily,anna)]).
protect([eqst]).
heuristics([]).

theoryFile:- pass.
