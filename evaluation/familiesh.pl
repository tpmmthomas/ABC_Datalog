:- working_directory(_, '../src').
:-[main].

logic(datalog).

theoryName(familiesh).

axiom([+parent(a,b,birth)]).
axiom([+parent(a,c,step)]).
axiom([+families(\x,\y), -parent(\x,\y,birth)]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Preferred Structure:

trueSet([families(a,b),families(a,c)]).
falseSet([]).
protect([a,b,c]).
heuristics([ noAss2Rule,noAxiomDele]).

theoryFile:- pass.
