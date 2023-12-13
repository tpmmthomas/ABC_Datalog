:- working_directory(_, '../src').
:-[main].

logic(fol).

theoryName(eggtimer).

axiom([+human(a1)]).
axiom([+dog(a1)]).
axiom([-human(\x), +legal_liable(\x)]).
axiom([-dog(\y), -legal_liable(\y)]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Preferred Structure:
trueSet([]).
falseSet([polygon(eggtimer,set_of(v1,v2,v3,v4),set_of(l1,l2,l3,l4))]).
protect([]).
heuristics([]).     %noAxiomAdd

theoryFile:- pass. 
