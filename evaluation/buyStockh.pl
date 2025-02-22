:- working_directory(_, '../src').
:-[main].

logic(datalog).

theoryName(buyStockh).

axiom([-goodPrice(\x),+buyStock(\x)]).
axiom([-goodPrice(\x),-riskyCompany(\y),+dontBuyStock(\x)]).
axiom([-inFusion(\x,steel),+riskyCompany(\x)]).
axiom([-closing(\x,\y),+riskyCompany(\x)]).
axiom([-inFusion(\x,steel),-stong(steel),+notRiskyCompany(\x)]).
axiom([+goodPrice(acme)]).
axiom([+inFusion(acme,steel)]).
axiom([+strong(steel)]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Preferred Structure:

trueSet([buyStock(acme)]).
falseSet([]).


protect([eqq,arity(eqq),acme,steel]).
heuristics([ noAxiomDele]).
theoryFile:- pass.
