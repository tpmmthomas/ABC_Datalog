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

trueSet([]).
falseSet([]).

