:- working_directory(_, '../src').
:-[main].

logic(fol).
theoryName(car).

axiom([+human(a1)]).
axiom([+human(b1)]).
axiom([+car(x1,auto)]).
axiom([+producer(x1,p1)]).
axiom([+driver(a1,x1)]).
axiom([+accident(x1,b1)]).

axiom([+human(a2)]).
axiom([+human(b2)]).
axiom([+car(x2,nonauto)]).
axiom([+producer(x2,p2)]).
axiom([+driver(a2,x2)]).
axiom([+accident(x2,b2)]).

axiom([-accident(\x,\b),-driver(\a,\x),+checkInjury(\a,\b)]).
axiom([-driver(\a,\x),+legalLiable(\a,\x)]).

trueSet([checkInjury(a1,b1),checkInjury(a2,b2),legalLiable(a2,x2),legalLiable(p1,x1)]).
falseSet([legalLiable(a1,x1),legalLiable(p2,x2)]).

% for all accidents, there is at least one who is the legal reliable.
% For all x,y accident(x,y) => exists a, legalLiable(a,x)
% [-accident(\x,\y),+legalLiable(f(\x,\y),\x)] (Need to try for all x,y)

% Problem 1: function f is not defined => We cannot proof it with current implementation.
% Problem 2: Put this to the theorem prover, will not try for all x,y, but just one.

% Suggestion
% Try to accept the above into theorem prover => Modification on preprocess
% Theorem prover substitutes functions into separate variables (Solve problem with unknown functions)
% Considering all possible substitutions of predicates with variables only , if any have faults then consider it as a fault.