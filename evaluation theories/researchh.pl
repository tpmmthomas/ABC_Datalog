:- working_directory(_, '/Users/lixue/GoogleDrive/publish/ACS/code').
:-[main].

axiom([-activeReasercher(\x),+writes(\x, papers)]).
axiom([-writes(\x, papers),+author(\x)]).
axiom([-author(\x),+employee(\x)]).
axiom([+activeReasercher(ann)]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Preferred Structure:

trueSet([activeReasercher(ann)]).
falseSet([employee(ann)]).


protect([ann, author,[-writes(\x, papers),+author(\x)]]).
heuristics([ noAxiomAdd, noAxiomDele]).     %noAxiomAdd

theoryFile:- pass.
