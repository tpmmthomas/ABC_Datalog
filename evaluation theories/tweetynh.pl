:- working_directory(_, '/Users/lixue/GoogleDrive/publish/ACS/code').
:-[main].


axiom([+penguin(tweety)]).
axiom([+bird(polly)]).
axiom([-bird(\x), +fly(\x)]).
axiom([-penguin(\y), +bird(\y)]).
axiom([-bird(\y), +feather(\y)]).

trueSet([feather(tweety),feather(polly), fly(polly)]).
falseSet([fly(tweety)]).



protect([]).
heuristics([]).

theoryFile:- pass.
