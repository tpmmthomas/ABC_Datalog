:- working_directory(_, '../src').
:-[main].

logic(datalog).

theoryName(mumRichedh).

% Birth mother
axiom([+mum(diana,william)]).
axiom([+mum(lady_di,william)]).
% Step mother
axiom([+mum(camilla,william)]).
% Mother are unique
axiom([-mum(\x,\z),-mum(\y,\z),+eq(\x,\y)]).

trueSet([eq(diana,lady_di)]).
falseSet([eq(diana,camilla), eq(diana,william), eq(camilla,william)]).



protect([eq,arity(eq),camilla, diana, william, prop(eq)]).
heuristics([ noRuleChange, noAnalogy, noAxiomDele, noPrecDele,noAxiomAdd]).

theoryFile:- pass.
