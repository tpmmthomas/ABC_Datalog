

/**********************************************************************************************

***********************************************************************************************/
initLogFiles(StreamRec, StreamRepNum, StreamRepTimeNH, StreamRepTimeH,  Postfix):-
  (\+exists_directory('log')-> make_directory('log'); nl),
  fileName('record', Fname,  Postfix),
  open(Fname, write, StreamRec),

  fileName('repNum', Fname2,  Postfix),
  open(Fname2, write, StreamRepNum),
  assert(spec(repNum(StreamRepNum))),

  (exists_file('repTimeHeu.txt')->
   open('repTimeHeu.txt', append, StreamRepTimeH);
  \+exists_file('repTimeHeu.txt')->
  open('repTimeHeu.txt', write, StreamRepTimeH)),
  assert(spec(repTimeH(StreamRepTimeH))),

  (exists_file('repTimenNoH.txt')->
   open('repTimenNoH.txt', append, StreamRepTimeNH);
  \+exists_file('repTimenNoH.txt')->
  open('repTimenNoH.txt', write, StreamRepTimeNH)),
  assert(spec(repTimeNH(StreamRepTimeNH))),

  maplist(assert, [spec(debugMode(1)), spec(logStream(StreamRec))]).
  %(OverloadedPred \= [] -> concepChange(OverloadedPred,  AllSents, RepSents, CCRepairs, Signature, RSignature);        %Detect if there is conceptual changes: a predicate has multiple arities.
  %RepSents = AllSents, CCRepairs = []),



fileName(FileCore, Name, Postfix):-
    date(date(_,X,Y)),
    get_time(Stamp),
    stamp_date_time(Stamp, DateTime, local),
    date_time_value(time, DateTime, time(H,M,_)),
    appEach([X,Y,H,M], [term_string], [X1,Y1,H1,M1]),
    string_concat(Y1,X1,Date),
    string_concat(H1,M1,Time),
    appEach([Date, Time], [string_concat, '_'], [Date1, Time1]),
    appAll(string_concat, [Postfix, '.', FileCore, Time1, Date1, 'log/abc_'],[''], Name, 1).


/**********************************************************************************************
   output: write_term_c screen and write record file abc_record.txt.
***********************************************************************************************/
output(AllRepStates, ExecutionTime):-
    forall(member([fault-free, X,[_,_,_,_,_,_]], AllRepStates), X ==0),
    findall(ClS, (axiom(Cl), sort(Cl, ClS)), Facts),
    sort(Facts, OrigTheory),
    fileName('faultFree', Fname1, 'txt'),
    open(Fname1, write, Stream1),
    writeLog([nl, write_term('------------- AllRepStates -------------'), nl,
                  write_termAll(AllRepStates),nl,nl,nl, finishLog]),

    % output the execution time.
    (exists_file('aacur.txt')->
        open('aacur.txt', append, StreamC), nl(StreamC),
        write(StreamC, ExecutionTime),
        close(StreamC);
    \+exists_file('aacur.txt')->
        open('aacur.txt', write, StreamC), nl(StreamC),
        write(StreamC, ExecutionTime),
        close(StreamC)),

    trueSet(TrueSet),
    falseSet(FalseSet),
    write_term('Execution took ',[quoted(false)]),
    write_term(ExecutionTime,[quoted(false)]),
    write_term(' ms.',[quoted(false)]), nl,
    write(Stream1, 'The original theory is fault-free.'), nl(Stream1),!,
    write(Stream1, 'The fault-free theory : '), nl(Stream1),
    writeAll(Stream1, OrigTheory), nl(Stream1),
    write(Stream1, 'The true set:'), nl(Stream1),
    (TrueSet \= [] ->  writeAll(Stream1, TrueSet), !;
             write(Stream1, '[]')), nl(Stream1),
    write(Stream1, 'The false set: '), nl(Stream1),
    (FalseSet \= [] -> writeAll(Stream1, FalseSet), !;
             write(Stream1, '[]')), nl(Stream1),close(Stream1).


% If no repairs found, output the current result of semi-repairs.
output(AllRepStates, ExecutionTime):-
    notin([fault-free|_], AllRepStates),!,
    fileName('faulty', Fname2, 'txt'),
    open(Fname2, write, Stream2),
    write_term_c('******************************************'),
    write_term_c('Execution took '),
    write_term_c(ExecutionTime),
    write_term_c(' ms.'),nl,
    nl, write_term_c('The faulty theory cannot be repaired.'),
    write_term_c('The semi-repaired theories are:'),

    findall(RepTheory, member([faulty,_,[[_,_], _, _, RepTheory, _, _]], AllRepStates),TBS),
    deleteAll(TBS, [], TBS1),
    sort(TBS1, TBSS),
    length(AllRepStates, SemiNumRaw),
    length(TBSS, SemiNum),

    write_Spec(Stream2, ExecutionTime, 0, SemiNum),
    writeFile(faulty, Stream2, TBSS, AllRepStates),
    writeLog([nl, write_term_c('------------- TBSS -------------'), nl,
                  write_term_All(TBSS),nl,nl,nl,
                  write_term_c('SemiNumRaw is: '), write_term_c(SemiNumRaw),nl,
                  write_term_c('SemiNum is: '), write_term_c(SemiNum),nl, finishLog]),
    close(Stream2),
    nl, write_term_c('In total, there are '),write_term_c(SemiNum), write_term_c(' semi-repaired theories.'), nl.

output([[fault-free,0,[[[],[]],_,_,_,_,_]]], _):-
    nl,print('The input theory is fault free'), !.

output(AllRepStates, ExecutionTime):-
    setof(ClS, Cl^(axiom(Cl), sort(Cl, ClS)), OrigTheory),
    length(OrigTheory, AxiomNum),
    assert(spec(axiomNu(AxiomNum))),
    fileName('faultFree', Fname1, 'txt'),
    open(Fname1, write, Stream1),

    % output the execution time.
    (exists_file('aacur.txt')->
        open('aacur.txt', append, StreamC), nl(StreamC),
        write(StreamC, ExecutionTime),
        close(StreamC);
    \+exists_file('aacur.txt')->
        open('aacur.txt', write, StreamC), nl(StreamC),
        write(StreamC, ExecutionTime),
        close(StreamC)),

    writeLog([nl, write_term_c('------------- AllRepStates -------------'), nl,
              write_term_All(AllRepStates),nl,nl,nl, finishLog]),

    trueSet(TrueSet),
    falseSet(FalseSet),
    write_term_c('Execution took '),
    write_term_c(ExecutionTime),
    write_term_c(' ms.'), nl,nl,


    nl, write_term_c('The original theory : '), nl, write_term_All(OrigTheory), nl,

    (TrueSet \= [] -> write_term_c('The original True  Set is: '), nl, trueSet(TS), write_term_All(TS), !;
      TrueSet == []->         write_term_c('The original True  Set is empty.'), nl),
    (FalseSet \= [] -> write_term_c('The original False Set is: '), nl, falseSet(FS), write_term_All(FS), !;
     FalseSet == []->    write_term_c('The original False Set is empty.'), nl),

    findall([TheoryA, RepPlan, TheoryB],
            (member([fault-free, _,[[RepPlan,_],_,_,TheoryA,_,_]], AllRepStates), TheoryB = [];
             member([faulty, _,[_,_,_,TheoryB,_,_]], AllRepStates), TheoryA = []),
             AllResult),

    transposeF(AllResult, [TAS, RepPlanAll1, TBS]),
    delete(TAS, [], TAS1),
    delete(TBS, [], TBS1),
    sort(TAS1, TASS),
    sort(TBS1, TBSS),
    sort(RepPlanAll1, RepPlanAll),
    length(TASS, FullyNum),
    length(TBSS, SemiNum),
    length(TASS, FullyNumRaw),
    length(TBSS, SemiNumRaw),

    writeLog([nl, write_term_c('------------- TASS -------------'), nl,
                    write_term_c('FullyNumRaw is: '), write_term_c(FullyNumRaw),nl,
                    write_term_c('FullyNum is: '), write_term_c(FullyNum),nl,nl,nl,
                  write_term_All(TASS),nl,nl,nl,
                  write_term_c('------------- TBSS -------------'), nl,
                  write_term_c('SemiNumRaw is: '), write_term_c(SemiNumRaw),nl,
                  write_term_c('SemiNum is: '), write_term_c(SemiNum),nl,nl,nl,
                  write_term_All(TBSS),nl,nl,nl, finishLog]),


    write_Spec(Stream1, ExecutionTime, FullyNum, SemiNum),
    write(Stream1, 'The original theory : '), nl(Stream1),
    writeAll(Stream1, OrigTheory), nl(Stream1),
    write(Stream1, 'The original true set:'), nl(Stream1),
    (TrueSet \= [] ->  writeAll(Stream1, TrueSet), !;
             write(Stream1, '[]')), nl(Stream1),
    write(Stream1, 'The original false set: '), nl(Stream1),
    (FalseSet \= [] -> writeAll(Stream1, FalseSet), !;
             write(Stream1, '[]')), nl(Stream1),
    spec(pft(TrueSetNew)),
    write(Stream1, '*** The revised true set:'), nl(Stream1),
    (TrueSetNew \= [] ->  writeAll(Stream1, TrueSetNew), !;
             write(Stream1, '[]')), nl(Stream1),

    write(Stream1, 'All of '),  write(Stream1, FullyNum),
    write(Stream1, ' sorted repair plans are from: '), nl(Stream1),
    writeAll(Stream1, RepPlanAll), nl(Stream1),



    writeFile(fault-free, Stream1, TASS, AllRepStates),
    (TBSS \=[]-> fileName('faulty', Fname2, 'txt'),
                open(Fname2, write, Stream2),
                write_Spec(Stream2, ExecutionTime, FullyNum, SemiNum),
                writeFile(faulty, Stream2, TBSS, AllRepStates),
                close(Stream2); true),

    findall(R, spec(round(R)), RoundsA),
    sort(RoundsA, RoundsAs), write_term_c(RoundsAs),

    write(Stream1, 'Solutions are found at rounds:'),write(Stream1,RoundsAs),nl(Stream1),nl,
    nl, write_term_c('In total, there are '), write_term_c(FullyNum), write_term_c(' solutions with '),
    close(Stream1),
    write_term_c(SemiNum), write_term_c(' semi-solutions remaining.'),nl.


/**********************************************************************************************************************
    writeLog: write log files.
    This function is unavailable in python-swipl ABC.
***********************************************************************************************************************/
write_term_c(X):- var(X), print('Error: an uninstantiated variable!'), pause, fail, !.
write_term_c(X):- write_term(X, [quoted(false)]).


writeLogSep(_).
writeLog(_):- spec(debugMode(X)), X \=1, !.
writeLog([]):-!.
writeLog(List):- !, spec(logStream(Stream))-> writeLog(Stream, List).
writeLog(_,[]):-!.
writeLog(_, [finishLog]):-!.
writeLog(Stream, [nl|T]):- nl(Stream), !, writeLog(Stream, T).
writeLog(_, [write_term_c(String)|_]):- var(String), print('Error: an uninstantiated variable!'), pause, fail, !.
writeLog(Stream, [write_term_c(String)|T]):-
    write(Stream, String), !,
    writeLog(Stream, T).
writeLog(_, [write_term_All(List)|_]):-
    setof(X, (member(X, List), var(X)), _),
    print('Error: an uninstantiated variable in the List!'), pause, fail, !.
writeLog(Stream, [write_term_All(List)|T]):-
    forall(member(X, List), (write(Stream, X), nl(Stream))),
    writeLog(Stream, T), !.



% write_term_cs  alist line by line
write_term_All([]) :- !.
write_term_All([C|_]) :-
    var(C),    % error: an uninstantiated variable.
    print('Error: an uninstantiated variable!'), pause, fail, !.
write_term_All([C|Cs]) :-
    write_term_c(C),nl,nl, write_term_All(Cs).

/**********************************************************************************************************************
    writeFile(Directory, OutFiles, DataList)
            Write files in Directory with the given data.
    Input:  Directory is the directory of files.
            FileName is a list of the names of files.
            DataList is a list of data to write in order.
***********************************************************************************************************************/
writeFiles(_, [], []).
writeFiles(Directory, [FileName| RestNames], [Data| RestData]):-
  atom_concat(Directory, FileName, FilePath),
  open(FilePath, write, StreamFile),
  % write a list line by line
  writeAll(StreamFile, Data),
  close(StreamFile),
  writeFiles(Directory, RestNames, RestData).

% FileName is the full path.
writeFiles([], []).
writeFiles([FileName| RestNames], [Data| RestData]):-
  open(FileName, write, StreamFile),
  % write a list line by line
  writeAll(StreamFile, Data),
  close(StreamFile),
  writeFiles(RestNames, RestData).

writeFile(_, _, [], _):-!.
writeFile(Type, Stream, Theories, AllStates):-
    retractall(spec(round(_))),
    forall(member(RepTheory, Theories),
            (    nth0(Num, Theories, RepTheory),    % RepTheory is the (Num+1)th solution
                Rank is Num+1,
                % ** unify every single repair in the list of repairs (SetOfRepairs) to RepairSorrted
                   findall((Round, Repairs),
                               (member([Type, Round,[[Reps,_],_,_,RepTheory,_,_]], AllStates),
                                appEach(Reps, [revertFormRep], Repairs)), % rever the form of repair information back to the input form
                           RepInfo),

                   RepInfo \= [],
                   appEach(RepTheory,[appEach, [appLiteral,revert]], Axioms),

                   (Type == fault-free, spec(screenOutput(true))->!,
                nl, write_term_c('------------------ Solution No. '), write_term_c(Rank),
                    write_term_c(' as below ------------------'), nl,
                forall(member((RR,Rep), RepInfo),(write_term_c('Repair plans found at Layer/CallNum '),
                                    write_term_c(RR), write_term_c(' :'),nl,write_term_All(Rep), nl)),
                nl, write_term_c('Repaired theory: '), nl,write_term_All(Axioms),nl;true),

                write(Stream, '------------------ Solution No. '), write(Stream, Rank),
                write(Stream, ' as below------------------'), nl(Stream),
                forall(member((RR,Rep), RepInfo),
                                (    assert(spec(round(RR))),
                                    write(Stream, 'Repair plans found at Round '),
                                    write(Stream, RR), write(Stream,' :'), nl(Stream),
                                    writeAll(Stream, Rep),nl(Stream))),
                nl(Stream),
                write(Stream, 'Repaired Theory: '), nl(Stream),
                writeAll(Stream, Axioms), nl(Stream))).

% write a list line by line
writeAll(_, []):- !.
writeAll(Stream1,[C|Cs]) :- write(Stream1, C), write(Stream1, '.'), nl(Stream1), writeAll(Stream1, Cs).

% write a list in one line connected
writeList(_, []):- !.
writeList(Stream1,[C|Cs]):- write(Stream1, C), writeList(Stream1, Cs).

writeLists(_, _, []):- !.
writeLists(Stream1,S, [C|Cs]):-
    writeList(Stream1, C),
    (length(Cs, 0)-> !;
     \+length(Cs, 0)-> write(Stream1, S),writeLists(Stream1,S, Cs)).

write_Spec(Stream, ExecutionTime, FullyNum, SemiNum):-
    spec(costLimit(Cost)),
    spec(roundLimit(Round)),
    date(Date), term_string(Date, DateStr),
    spec(heuris(Heuristics)),
    spec(protList(Protected)),    % if there is protected item(s)), output it(them).
    spec(inputTheorySize(AxiomNum)),
    spec(faultsNum(InsuffNum, IncompNum)),

    write(Stream, DateStr), nl(Stream),
    write(Stream, '----------------------------------------------------------------------------------'),nl(Stream),
    write(Stream,'Theory size: '), write(Stream, AxiomNum),nl(Stream),
    write(Stream,'Faults Number: '), write(Stream, (InsuffNum, IncompNum)),nl(Stream),
    write(Stream,'Cost Limit is: '), write(Stream, Cost),nl(Stream),
    write(Stream,'RoundLimit is: '), write(Stream, Round),nl(Stream),
    write(Stream,'Running time: '), write(Stream, ExecutionTime), write(Stream, ' ms.'), nl(Stream),
    write(Stream,'Heuristics applied:'), write(Stream, Heuristics),  nl(Stream),
    write(Stream,'The protected item(s):'), write(Stream, Protected), nl(Stream),
    write(Stream,'Total Solution number is: '),write(Stream, FullyNum),  nl(Stream),
    (SemiNum == []->write(Stream,'No incomplete repaired theory left.'),nl(Stream), !;
    SemiNum \= []->    write(Stream, 'Remaining semi-repaired theories: '), write(Stream, SemiNum),nl(Stream)),
    write(Stream, '----------------------------------------------------------------------------------'),nl(Stream).


outputJsonFirst(Stream1):-
    trueSet(TrueSet),
    falseSet(FalseSet),
    spec(costLimit(Cost)),
    spec(roundLimit(Round)),
    spec(heuris(Heuristics)),
    spec(protList(Protected)), % if there is protected item(s)), output it(them).
    spec(inputTheorySize(AxiomNum)),

    setof(ClS, Cl^(axiom(Cl), sort(Cl, ClS)), OrigTheory),
    length(OrigTheory, AxiomNum),
    assert(spec(axiomNu(AxiomNum))),

    date(Date), term_string(Date, DateStr),
    writeList(Stream1, ['{\"job time\": \"', DateStr, '\", \"parameters\": {\"hueristics\":\"', Heuristics,
                         '\", \"protected\":\"', Protected, '\", \"cost limit\":\"', Cost,
                         '\", \"round limit\":\"', Round, '\"}, \"preferred structure\": {\"true set\":\"',
                         TrueSet, '\", \"false set\":\"', FalseSet, '\"}, \"original theory\":\"', OrigTheory, '\", "output": [']).

outputJsonSecond(Stream1, AllRepStates, ExecutionTime, NO):-
    (second_json(true)->write(Stream1, ','), !; true),
    assert(second_json(true)),
    % TODO: update with instantiated ps, and avoid assert one vairable multiple times.
    trueSet(TrueSetNew),
    falseSet(FalseSetNew),
    spec(faultsNum(InsuffNum, IncompNum)),
    writeList(Stream1, ['{\"Instantiated PS Serial NO\": ', NO, ', \"execution time (ms)\": ', ExecutionTime,
                    ', \"instantiated preferred structure\": {\"instantiated true set\":\"', TrueSetNew, '\", \"instantiated false set\":\"',
                    FalseSetNew, '\"}, \"faults number\":{\"insufficiencies\":\"', InsuffNum, '\", \"incompatabilities\":\"', IncompNum, '\"},']),

    findall((TheoryA,Round, RepPlan),
            member([fault-free, Round,[[RepPlan,_],_,_,TheoryA,_,_]], AllRepStates),
             TAS),

    findall((TheoryB,Round, RepPlan),
             member([faulty, Round,[[RepPlan,_],_,_,TheoryB,_,_]], AllRepStates),
             TBS),

    removeDuplicate(TAS, TASS),
    removeDuplicate(TBS, TBSS),
    length(TASS, FullyNum),
    length(TBSS, SemiNum),

    findall(R, spec(round(R)), RoundsA),
    sort(RoundsA, RoundsAs), write_term_c(RoundsAs),

    writeList(Stream1, ['\"fully repaired theories number\":\"', FullyNum, '\", \"semi repaired theories number\":\"', SemiNum,
                        '\",\"all fully repaired theories (fault-free)\": [']),
    print('OK'),
    findall(FaultFreeList,
            (member((RepTheory, Layer/N, Repairs), TASS),
             appEach(RepTheory,[appEach, [appLiteral,revert]], Axioms),
             FaultFreeList = ['{\"search depth of repairs generation\": ', Layer,
             ', \"the current total number of calling repInsInc\":\"', N, '\",\"repairs\":\"', Repairs,
             '\",\"repaired fault-free theory\":\"', Axioms, '\"}']),
            FaultFreeLists1),
    writeLists(Stream1, ',', FaultFreeLists1),

    print('---------'),
    print(TBSS),
    write(Stream1, '],\"all semi-repaired theories (faulty)\": ['),
    findall(FaultFreeList,
            (member((RepTheory, Layer/N, Repairs), TBSS),
             appEach(RepTheory,[appEach, [appLiteral,revert]], Axioms),
             FaultFreeList = ['{\"search depth of repairs generation\": ', Layer,
             ', \"the current total number of calling repInsInc\":\"', N, '\", \"repairs\":\"', Repairs,
             '\", \"semi-repaired theory\":\"', Axioms, '\"}']),
             FaultFreeLists2),
    writeLists(Stream1, ',', FaultFreeLists2),
    write(Stream1, ']}').


removeDuplicate(AllRepStates, AllRepStatesFine):-
    remDup(AllRepStates, [], AllRepStatesFine).

remDup([], SOut, SOut):-!.

% The theory state is already in SIn.
remDup([(Theory, Round, Repair)|Rest], SIn, Sout):-
    findall(M, (member(M, SIn), M = (Theory, _,_)), Duplicates),
    (Duplicates = [] ->  remDup(Rest, [(Theory, Round, Repair)| SIn], Sout), !;
    Duplicates \= [] ->  remDup(Rest, SIn, Sout)).
