:- working_directory(_, '../src').
:-[main].

logic(datalog).

theoryName(parentnh).

axiom([+parent(a,b)]).
axiom([+parent(a,c)]).
axiom([+parent(d,b)]).
axiom([+male(a)]).
axiom([+female(c)]).
axiom([+female(d)]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Preferred Structure:

trueSet([father(a,b),father(a,c),mother(d,b)]).
falseSet([mother(a,b),mother(a,c),father(d,b)]).
protect([]).
heuristics([]).

theoryFile:- pass.
