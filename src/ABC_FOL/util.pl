:-[fileOps].
/*
  This file contains the basic functions/predicates that assist other ABC system's functions.
  Update Date: 13.08.2022
*/


adverseEnum(0,[]) :- !.
adverseEnum(N,List) :-
    Num is N-1,
    adverseEnum(Num, ListFront),
    append(ListFront,[N],List).

/*********************************************************************************************************************************
    allTheoremsC(ABox, Constant, Theorems): get all theorems whose arguments include the targeted constant.
    * Inequality only between constants at the same position in arguments of predicates.
    Input:  ABox: the ABox of the KG.
            EC: the equivalence class.
            Constant: the targeted constant, e.g., [c].
    Output: Theorems is a list of theorem whose argument contains the constant.
**********************************************************************************************************************************/
allTheoremsC(Abox, C, Theorems):-    % all theorems whose arguemnts contain C1
  findall([+[P| Args]], (member([+[P| Args]], Abox), memberNested(C, Args)),
        Theorems).

% allConstraintsC(Abox, C, Theorems):-    % all theorems whose arguemnts contain C1
%   findall([-[P| Args]], (member([-[P| Args]], Abox), memberNested(C, Args)),
%         Theorems).

% get all theorems that contain predicate P.
allTheoremsP(Abox, P, Theorems):-    % all theorems whose arguemnts contain C1
  findall([+[P| Args]], member([+[P| Args]], Abox),
        Theorems).

% allConstraintsP(Abox, P, Theorems):-    % all theorems whose arguemnts contain C1
%   findall([-[P| Args]], member([-[P| Args]], Abox),
%         Theorems).
/**********************************************************************************************
    appAll(Predicate, List, ArgumentList, nth, Output):
        apply the predicate to one element in the List.
        * The output has to be the last argument of the Predicate.
        and take its output as the nth (n > 0) input argument for the next calculation.
        Count from 0, so if arity(Predicate) = M, then max(N) = M-1.
        Output is resulted by applying all elements in the list.
        * e.g., appAll(append, [[1],[2],[3]], [[5]], X, 1), X = [3, 2, 1, 5].
        * e.g., appAll(sum, [1,2,3], [5], Y, 1). Y = 5+1+2+3 = 11
***********************************************************************************************/
appAll(_, [], [Out], Out, _):-!.
appAll(_, [], ArgsNew, Out, _):-!,
    last(ArgsNew, Out).
appAll(Predicate, [H| T], Args, Output, N):- !,
    append([Predicate, H], Args, E1),
    append(E1, [Out], EList),
    Expression =..EList,
    call(Expression),
    Pos is N-1,     % the first input is the element in the list
    replacePos(Pos, Args, Out, ArgsNew),    % replace the Pos element in Args with Out resulting ArgsNew
    appAll(Predicate, T, ArgsNew, Output, N).


/**********************************************************************************************
    appEach(List, [Predicate, ExtraArgu1, ExtraArgu2,..], OutputList):
        apply the predicate to each element in the List and other arguments in ArgumentList.
        appEach/2 succeed when all expressions succeed.
        appEach/3, appEach/4 succeed when at least one expression is succeed.
    Input:     Predicate: the predicate to call
            List: each of elements in List will be the first argument when call Predicate.
            ExtraArgusList: a list of the other arguments for Predicate.
                            If artiy of Predicate is 1, then ExtraArgusList = [].
    Output:    OutputList is a list of each output.
    * The length of Output is same with List, which is the nth(Output) = Predicate(nth(List), Argument).
    * e.g., appEach([[1],[2],[3]], [append, [5]], X), X = [[1, 5], [2, 5], [3, 5]].
    * e.g., appEach([1,2,3], [sum, 5], Y). Y = [6, 7, 8]
***********************************************************************************************/
% Args is the list of extra arguments.
appEach([], _):- !.
appEach([H| T], [Predicate| Args]):- !,
    append([Predicate, H], Args, EList),
    Expression =..EList,
    call(Expression),
    appEach(T, [Predicate| Args]).

appEach([], _, []):- !.
appEach([H| T], [Predicate| Args], Output):- !,
    append([Predicate, H], Args, E1),
    append(E1, [HOut], EList),
    Expression =..EList,
    (call(Expression)-> Output = [HOut| TOut], !;
    \+call(Expression)-> Output = TOut,
    writeLog([nl,write_term_c('--Failed to apply '),nl,write_term_c(Expression),nl,  finishLog])),
    appEach(T, [Predicate| Args], TOut).

/**********************************************************************************************
    appLiteral(Literal, [Predicate, N, ExtraArgs1， ExtraArgs2...], OutLiteral):
        get Output by apply the predicate to the proposition in Literal
        along with other arguments in ExtraArgsList, except the last argument with +/-.
        The last argument with +/-, which will be assigned to OutLiteral.
    Input: N(counting from 0): the position of the proposition in the arguments of Predicate.
    appLiteral is similar to the predicate appEach/4.
***********************************************************************************************/
appLiteral(+Prop, Func):- !,
    appProp(Prop, Func).
appLiteral(-Prop, Func):- !,
    appProp(Prop, Func).
appLiteral(+Prop, Func, +PropNew):- !,
    appProp(Prop, Func, PropNew).
appLiteral(-Prop, Func, -PropNew):- !,
    appProp(Prop, Func, PropNew).


appProp(Prop, [Predicate| [N| ExtraArgs]]):-
    split_at(N, ExtraArgs,  ArgsFront, ArgsBack),
    append([Predicate| ArgsFront], [Prop| ArgsBack], EList),
    Expression =..EList,
    call(Expression).

appProp(Prop, [Predicate| [N| ExtraArgs]], PropNew):-
    number(N), !,
    split_at(N, ExtraArgs,  ArgsFront, ArgsBack),!,
    append([Predicate| ArgsFront], [Prop| ArgsBack], E1),
    append(E1, [PropNew], EList),
    Expression =..EList,
    call(Expression).

appProp(Prop, Predicate, PropNew):- !,
    Expression =..[Predicate, Prop, PropNew],
    call(Expression).


/***********************************************************************************************
     argsMis(Args1, Args2, Mismatches): get the mismatches which make Args1 ununifies Args2.
    Input:    Args1: a list of arguments, e.g., [[a], vble(x),[d], vble(x)]
             Args2: another arguments: e.g., [[a], [c], [d], [d]]
    Output: MisPairs: the list of mismatched constants between Args1 and Args2
            MisPairPos: the positions of these mismatched constants
    Example:argsMis([[a], vble(x),[d], vble(x) ],[[e], [c], [d], [d]], X, Y),
            X = [([a], [e]),  ([c], [d])],
            Y = [[([a], [e])], [], [], [([c], [d])]].
**********************************************************************************************/
argsMis([], [], [], []):- !.
argsMis([A1| Args1], [A2| Args2], MisPairs, [MisPair1| MisPos2]):-
    argPairMis(A1, A2, Sigma, MisPair1),
    extractNestedPairs(MisPair1,MisPair1Ex),
    subst(Sigma, Args1, ArgsSb1),
    subst(Sigma, Args2, ArgsSb2),
    argsMis(ArgsSb1, ArgsSb2, MisPairs2, MisPos2),
    append(MisPair1Ex, MisPairs2, MisPairs).

argPairMis(C, C, [],[]):- !.
argPairMis(Y, vble(X), [], [occurs]):- 
    is_func(Y),
    memberNested(vble(X),Y),
    !.
argPairMis(vble(X), Y, [], [occurs]):- 
    is_func(Y),
    memberNested(vble(X),Y),
    !.
argPairMis(Y, vble(X), Y/vble(X), []):- (is_cons(Y);is_func(Y)), !.
argPairMis(vble(X), Y, Y/vble(X), []):- (is_cons(Y);is_func(Y)),!.
argPairMis(vble(X), vble(Y), vble(X)/ vble(Y), []):-!.
argPairMis([Cons1], [Cons2], [], [([Cons1], [Cons2])]):-
    Cons1 \= Cons2.
argPairMis([Func1|F1Arg],[Func2|F2Arg],[],[([Func1|F1Arg], [Func2|F2Arg])]):- 
    Func1 \= Func2.
argPairMis([Func1|F1Arg],[Func1|F2Arg],Sigma, MisPair):- 
    argsMisFunc([Func1|F1Arg],[Func1|F2Arg],Sigma,MisPair).

argsMisFunc([],[],[],[]):- !.
argsMisFunc([A1|Args1],[A2|Args2],Sigma,[MisPair1| MisPos2]):-
    argPairMis(A1,A2,Sigma2,MisPair1),
    subst(Sigma2, Args1, ArgsSb1),
    subst(Sigma2, Args2, ArgsSb2),
    argsMisFunc(ArgsSb1,ArgsSb2,SigmaR,MisPos2),
    compose1(Sigma2,SigmaR,Sigma).
    % append(MisPair1,MisPairsR,MisPairs).

extractNestedPairs(L,Lout):-
    findall((A,B),
        memberNested((A,B),L),
        Lout).

% In FOL, an argument is either a constant, e.g., [c] or a variable, e.g., vble(v), or a function.
is_cons(X):- X = [Y], atomic(Y).
is_func(X):- X = [P | Rest],!, length(Rest,LRest), LRest > 0, P \= vble(_).
arg(X):- is_cons(X),!.
arg(X):- X = vble(_),!.
arg(X):- is_func(X),!.


% Assertion protect check
asserProCheck([_|_],_):- !. % for rules, pass.
asserProCheck([+[P|_]], ProtectedList):-
    notin(asst(P), ProtectedList).

/***********************************************************************************************
 compos1(Sub,SublistIn,SublistOut):
     SublistOut is the result of composing singleton substitution Subst with substitution SublistIn.
    compose1([bruce]/vble(x), [vble(x)/vble(y),[bruce]/vble(y)],X).
    X = [[bruce]/vble(x), [bruce]/vble(y)].

 Built in compose predicate fails when the second input is [], which is unwanted.
    compose(vble(x)/[bruce], [],X).   %     false.
**********************************************************************************************/
compose1([], SublistIn, SublistIn) :- !.
compose1(Sub, SublistIn, SublistOut) :-     % Append new substitution
    subst(Sub, SublistIn, SublistMid),        % after applying it to the old one
    (Sub = [_]-> append(Sub, SublistMid, SubTem);
     Sub = _/_-> SubTem = [Sub|SublistMid]),
    sort(SubTem, SublistOut).     % remove duplicates.

combineSubs(CurSubOut,[],CurSubOut).
combineSubs([],[(_,_,Sub,_,_)|T],CurSubOut):-
    combineSubs(Sub,T,CurSubOut).
combineSubs(Subs,[(_,_,Sub,_,_)|T],CurSubOut):-
    Subs \= [],
    compose1(Sub,Subs,SubsOut),
    combineSubs(SubsOut,T,CurSubOut).

/**********************************************************************************************************************
    convertClause(In, Clause): convert input axiom into CNF form with head at the front and body in the end.
    Input:    In is an input axiom
    Output: Clause is a Horn clause.
        For reducing the search space of resolution, the Clause has its head at the front and body in the end.
************************************************************************************************************************/
convertClause(AxiomIn, Clause) :-
    appEach(AxiomIn, [appLiteral, convert],  Clause1),
    sort(Clause1, Clause).        % Remove duplicate literals and sort literals where positive literal will be the head of Clause.

convertEq(AxiomIn,Clause) :-
    appEach(AxiomIn,[appProp,convert], Clause1),
    sort(Clause1,Clause).

%% convert(In,Out): convert normal Prolog syntax to internal representation or
%% vice versa.

%% These variable/constant conventions need revisiting for serious use

% X is a variable
convert(\X,vble(X)) :-  !.                      % Convert X into a variable
/*    atom_chars(X,[?|T]),              % variable is start with ?
    Out = vble(T),!.
    atomic(X), atom_chars(X,[H|_]),             % if first letter
    char_code(H,N), 109<N, N<123, !.            % is n-z
*/

convert(vble(X),vble(X)) :-  !.                      % Convert X into a variable

% A is a constant
convert(A,[A]) :-             % Convert A into a constant, where A is either an atom or a number
    atomic(A), !.

% A is a number
convert(A,[A]) :-             % Convert A into a constant
    number(A),!.



% E is compound
convert(E,[F|NArgs]) :-
    var(E), !,                                  % If E is output and input compound
    maplist(convert,Args,NArgs), E=..[F|Args].  % Recurse on all args of F


convert(E,[F|NArgs]) :-                     % If E is input and compound then
    \+ var(E), \+ atomic(E), !,
    E=..[F|Args],  % break it into components
    maplist(convert,Args,NArgs).                % and recurse on them

/*renvert internal representation to normal Prolog syntax */

revert([],[]):- !.

% X is a variable
revert(vble(X),\X) :-  !.                     % revert a variable

% A is a constant or number
revert([A],A) :- !.                          % revert a constant and number

%% These variable/constant conventions need revisiting for serious use
% E is compound
revert(E,E) :-
    atomic(E), !.                               % If E is output and input compound

% E is compound: F(NArgs).
revert(E,FactE) :-
    is_list(E),!,                                  % If E is output and input compound
    E =[F|Args],
    maplist(revert,Args,NArgs), FactE=..[F|NArgs].  % Recurse on all args of F

revert(E,[F|NArgs]) :-
    var(E), !,                                  % If E is output and input compound
    maplist(revert,Args,NArgs), E=..[F|Args].  % Recurse on all args of F

/**********************************************************************************************
    deleteAll(ListsInput, ListDel, ListOut) let the following true:
    ListOut = ListsInput - ListDel
**********************************************************************************************/
deleteAll([], _, []):-!.
deleteAll(ListsInput, [], ListsInput):-!.
deleteAll(ListsInput, [H|T], ListOut):-
    delete(ListsInput, H, ListRest),
    deleteAll(ListRest, T, ListOut).

% succeed if ArgsG and ArgsT can be unified by ignoring the tail of the longer argument list.

diff(ArgsG, ArgsT, ArgsTail):-
    length(ArgsG, LG),
    length(ArgsT, LT),
    (LG = LT-> ArgsTail = [], !,
        unification(ArgsG, ArgsT,_,[],_,_,[]);
    LG > LT-> choose(LT,ArgsG,GFront),deleteAll(ArgsG,GFront,ArgsTail),%split_at(LT, ArgsG, GFront, ArgsTail), !,
        unification(GFront, ArgsT,_,[],_,_,[]);
    LT > LG-> choose(LG,ArgsT,TFront),deleteAll(ArgsT,TFront,ArgsTail),%split_at(LG, ArgsT, TFront, ArgsTail),
        unification(ArgsG, TFront,_,[],_,_,[])).

% drop the last element from the input list
dropTail(ListIn, ListOut):-
    length(ListIn, L), M is L-1,
    split_at(M, ListIn, ListOut, _).

/**********************************************************************************************************************
costRepairs (R, C): calculate the cost C by split R into members one by one.
costRepair （_, _, C）:C is 0 when (R, _) is a member of Rs, otherwise C is 1.
************************************************************************************************************************/
% if a name was already split, then additional splits to the same name are free
costRepairs([], 0) :- !.
costRepairs([R|Rs], C) :- costRepair(R, Rs, C1), costRepairs(Rs, C2), C is C1 + C2.

costRepair((R, _), Rs, 0) :- member((R, _), Rs), !.
costRepair(_, _, 1).
/**********************************************************************************************************************
        dummyTerm(Term, ClP, TheoryIn, DummyTOut):
            generate the Dummy term.
        Input:  Term, e.g., mum.
                TheoryIn: the input theory.
                After renaming Term to DummyTOut in its clause CL1, the unification between CL1 and ClP is broken.
        Output: DummyTOut the dummy term, e.g., dummy_mum_2
************************************************************************************************************************/
dummyTerm([Term], TheoryIn, [DummyTOut]):- !,
    dummyTerm(Term, TheoryIn, DummyTOut).

dummyTerm(Term, TheoryIn, DummyTOut):-
    % if the term is already dummy, e.g., dummy_mum_2, get the original term
    (atom_concat(dummy_, Term0, Term)->                % Term0: mum_2
        atom_concat(TermOrig, STail, Term0),         % STail = _2, TermOrig = mum
        atom_chars(STail, ['_'|SerStr]),
        term_string(SNum, SerStr), !;            % Ser = '2'
        TermOrig = Term, SNum = 0),
    atom_concat(dummy_, TermOrig, DummyTerm1),
    term_string(DummyTerm1, NameString),
    string_concat(NameString, "_", NamePre),

    findall(Prop, (    member(Axiom, TheoryIn),
                    (member(+Prop, Axiom);
                     member(-Prop, Axiom))),
            AllProp),
    flatten(AllProp, AllF1),    % the list of all predicate symbol and constant
    sort(AllF1, AllF),
    findall([Num, Cand], (    member(T, AllF),
                        term_string(T, String),
                        %sub_string(String,_,_,_,NamePre),    % the name prefix is contained by the string.
                        split_string(String,"_", "dummy_", [StrTermOrig, NumLast]), %split_string("dummy_load2_2", "_", "", X).X = ["dummy", "load2", "2"].
                        term_string(TermOrig, StrTermOrig),
                        term_string(Num, NumLast),
                        number(NumLast),
                        (Num > SNum-> Cand = T, !; Cand =[])),
            DummyPairs),
    (DummyPairs = [] ->
        string_concat(NamePre, "1", DummyTstr),
        term_string(DummyTOut, DummyTstr), !;
    % heuristics, the smaller the serial number is, the more likely an individual belongs to.
    % so start with assignming the smallest serial number which bigger than Term.
     DummyPairs = [_|_]->
         sort(DummyPairs, PSorted),
         transposeF(PSorted,[_,X]),
         (X = [DummyTOut|_], !;     % fails when the input term has the largest serial number.
         NewNum is SNum +1,
         term_string(NewNum, NewNumStr),
         string_concat('_', NewNumStr, NewTail),
         string_concat(NameString, NewTail, DummyTStr),
         term_string(DummyTOut, DummyTStr))).



% construct dummy terms for appRepair(arityInc(P, TargetL, TargetCl)
dummyTermArityInc([], DefCons, UniqCons):-
   DefCons = dummy_Normal1,
      UniqCons = dummy_Abnormal1, !.

dummyTermArityInc(Sorted, DefCons, UniqCons):-
   last(Sorted, Largest),
   NewSer is Largest +1,
   atom_string(NewSer, NewSerStr),
   appEach(['dummy_Normal_', 'dummy_Abnormal_'],
          [string_concat, NewSerStr], [DefConsStr,UniqConsStr]),
   appEach([DefCons, UniqCons], [term_string], [DefConsStr, UniqConsStr]).

/**********************************************************************************************
    empty(X, Y):- flatten empty list, e.g., empty([[[]], [[]],[]], []);empty([a,[]],[a, []])
       input: X is a list
       output: Y is [] if X is a list of empty lists.
***********************************************************************************************/
empty(X, []):- flatten(X,[]),!.
empty(X, X):- \+flatten(X,[]).



/*****************************************************************************************************************
essSubs(Suffs, Rule, SubsList):-
    get the substitutions of Rule if it is involved in all proofs of a preferred proposition.
Input:     Suffs: a list of sufficiencies.
        Rule: a rule.
Outpt:    SubsList: a list of substitutions [Subs1, Subs2,...]
                    where Subs1 is the substitutions applied to Rule in a proof.
****************************************************************************************************************/
essSubs([], _, []).

% if there is one proof which does not contain Rule, then Rule is not essential for this sufficiency.
essSubs([(_,Proofs)|Rest], Rule, SubsOut):-
    setof(Proof, (member(Proof, Proofs),
                notin((_,Rule,_,_,_), Proof)),
            [_|_]), !,
    essSubs(Rest, Rule, SubsOut).        % continue checking the next.

% Otherwise, record the substitutions of Rule in these proofs where it is essential.
essSubs([(_,Proofs)|Rest], Rule, SubsOut):-
    findall(Subs, (    member(Proof, Proofs),
                    member((_,Rule,Subs,_,_), Proof)),
            AllSubs),
    essSubs(Rest, Rule, SubsRest),        % continue checking the next.
    append(AllSubs, SubsRest, SubsOut).

notEss2suff([], _).
notEss2suff([(_,Proofs)|Rest], Axiom):-
    forall(member(Proof, Proofs), member((_,Axiom,_,_,_), Proof)),
    !, fail;
    notEss2suff(Rest, Axiom).

/*********************************************************************************************************************************
   general(ClauseIn, ClauseOut, ReSubs): Generalise the axiom by replace the constant which occur more than once with a variable.
   Input:  ClauseIn: the clause to be generalised.
   Output: ClauseOut: the gneralised Clause which has no constant that occurs more than once.
           ReSubs: the substitution satisfies: ClauseOut* ReSubs = ClauseIn
**********************************************************************************************************************************/
generalise([], []):- !.
generalise(ClauseIn, ClauseOut):-
   generalise(ClauseIn, ClauseOut, _, _).
generalise(ClauseIn, ClauseOut, Cons2Vbles, ReSubs):-
   % get the list of link constants which occur both in the head and the body.
   findall(Constant,
           (member(+[_| ArgHead], ClauseIn),
            member(Constant, ArgHead),
            member(-[_| ArgBody], ClauseIn),
            member(Constant, ArgBody)),
           Cons1),
   % get the list of constants which occur at least twice in the body.
   findall(Constant,
           (member(-[P1| ArgB1], ClauseIn),
            member(-[P2| ArgB2], ClauseIn),
            [P1| ArgB1] \= [P2| ArgB2],
            member(Constant, ArgB1),
            member(Constant, ArgB2)),
           Cons2),
    % get the list of constants which occur at least twice in the head.
   findall(Constant,
           (member(+[P1| ArgB1], ClauseIn),
            member(+[P2| ArgB2], ClauseIn),
            [P1| ArgB1] \= [P2| ArgB2],
            member(Constant, ArgB1),
            member(Constant, ArgB2)),
           Cons3),
   % get the list of variables in the input clause.
   findall(X,
           ( (member(+[P1| Arg], ClauseIn);
              member(-[P2| Arg], ClauseIn)),
             member(vble(X), Arg)),
           AvoidList),
   % combine all constant candidates and remove the duplicates by sort them.
   append(Cons1, Cons2, ConsT),
   append(ConsT,Cons3,Cons),
   sort(Cons, ConsList),
   getNewVble(ConsList, AvoidList, Cons2Vbles, ReSubs),
   appEach(ClauseIn, [appLiteral, [replaceS, 1, Cons2Vbles]],  ClauseOut).
/*
% Get substitutions of a new variable for each constant in ConsList
% and the new variable should not occur in the AvoidList.
getNewVble([[c]], [vble(z),vble(x)], NewVbleSub, ReSubs).
NewVbleSub = [([c], vble(z))],
ReSubs = [[c]/vble(z)].
*/
getNewVble(ConsList, AvoidList, NewVbleSub, ReSubs):-
   char_code(z, Zcode),
   getNewVble(ConsList, AvoidList, Zcode, NewVbleSub, ReSubs).

getNewVble([], _, _, [], []):-!.
% Get one valid new variable with ascii code : Code.
getNewVble([C| CRest], AvoidList, Code, [(C, vble(Char))| RestVbleSub], [C/vble(Char)| ReSubs]):-
   char_code(Char, Code),
   notin(Char, AvoidList),        % the new variable is Char iff it is not one of the list of variables.
   NextCode is Code - 1, !,
   getNewVble(CRest, AvoidList, NextCode, RestVbleSub, ReSubs).
% If the char of Code is already in the variable list, then try the one before it on ascii table.
getNewVble(ConsList, AvoidList, Code, NewVbleSub, ReSubs):-
   NewCode is Code -1,
   getNewVble(ConsList, AvoidList, NewCode, NewVbleSub, ReSubs).


/**********************************************************************************************
   gensymVble(N, ListOut):
   Input: N is the length of the independent variables list.
   Output: ListOut is the list of independent variables generated by gensym/2.
   * An independent variable starts with iv.
   Example: gensymVble(3,X).  X = [vble(iv6), vble(iv7)|vble(iv8)].
**********************************************************************************************/
gensymVble(1, vble(Exp)):- gensym(iv, Exp), !.
gensymVble(N, [vble(H)|T]):- gensym(iv, H), M is N-1, gensymVble(M, T).

/**********************************************************************************************************************
   init(Files, Vabs): read files to parameters and setup logs.
   Input:  Files: the files to read.
   Output:    Vabs: record files' content.
***********************************************************************************************************************/
init(FileList, Variables):-
    readInputs(FileList, Variables).

init(FileList, Variables, HeurPath):-
    init(FileList, Variables),
    open(HeurPath, read, StrInp),
    readFile(StrInp, Inp),       % the input abox is a list
    delete(Inp, end_of_file, InpData),
    close(StrInp),
    InpData = [Hur, ProtectedList, _, RsBanned, RsList, _],
    maplist(assert, [spec(heuris(Hur)), % do not output solutions to screen.
                     spec(protList(ProtectedList)),
                     spec(rsb(RsBanned)),
                     spec(rsa(RsList))]).

/**********************************************************************************************
   mergeTailSort(ListsInput, ListOut): combine all the tails without duplicates for a head in a list.
   * the output list is sorted based on the head of each eleme
   ListsInput = [(2,d),(1,a),(1,a),(4,d),(1,t)]
   ListOut = [(1, [a, t]),  (2, [d]),  (4, [d])].
**********************************************************************************************/
mergeTailSort([], []):- !.
mergeTailSort(ListsInput, ListOut):-
   mTail(ListsInput, [], ListTem),
   sort(ListTem, ListOut).
mTail([], ListOut, ListOut):-!.
mTail(ListIn, ListTem, ListOut):-
   ListIn = [(X,_)| TList],
   (member((X, _), ListTem)->
       % if the head has been recorded, continue to the next pair.
       mTail(TList, ListTem, ListOut);
       % otherwise, find the list of all the tails without duplicates for the head X.
       setof(Y1, member((X,Y1), ListIn), YS),
       ListTem2 = [(X, YS)| ListTem],
       sort(ListTem2, ListTem3),
       mTail(TList, ListTem3, ListOut)).

/**********************************************************************************************
    mergeAll(ListsInput, [], ListOut) let the following true:
    ListOut = the list of all the elements in the sublists of ListsInput.
**********************************************************************************************/
mergeAll([], ListOut, ListOut):-!.
mergeAll([HList|TList], ListIn, ListOut):-
    merge(HList, ListIn, ListTem1),    % append H and ListIn.
    sort(ListTem1, ListTem2),      % remove duplicates.
    mergeAll(TList, ListTem2, ListOut).


/**********************************************************************************************************************
    negate an iterm
***********************************************************************************************************************/
negateCl([],[]).
negateCl([H|L], [H1| L1]):- negate(H, H1), negateCl(L, L1).

%% negate a literal.
negate(+X,-X):- !.
negate(-X,+X):-!.
negate([+X],[-X]):-!.
negate([-X],[+X]):-!.
negate([X],[-X]):-!.
negate(X,-X).
negate([],[]).

/**********************************************************************************************************************
    When vble(X) occur in the argument list Args, rename it with a new name which does not occur in Args.
***********************************************************************************************************************/
newVble(vble(X), Args, vble(NewX)):-
    memberNested(vble(X), Args),
    string_concat(X,'1',Y),
    term_string(Term, Y),
    (nestedNotin(vble(Term), Args)->NewX = Term, !;
     newVble(vble(Term), Args, vble(NewX))).

/**********************************************************************************************************************
    check existances.
***********************************************************************************************************************/

nestedNotin(_,List):- \+is_list(List), nl,print('ERROR: '), pause, print(List), print(' is not a list'),nl,fail,!.
nestedNotin(X,List):- \+memberNested(X,List), !.

notin(_, List):- \+is_list(List), nl,print('ERROR: '), pause, print(List), print(' is not a list'),nl,fail,!.
notin(X, List):- \+member(X, List), !.


occur(_, List):- \+is_list(List), nl,print('ERROR: '), print(List), print(' is not a list'),nl, fail,!.
occur(X, List):- member(X, List), !.    % avoid redo member(_, List) where '_' is assigned values

/**********************************************************************************************************************
   orderAxiom(ClIn, ClOut): then order the literals in a clause
   1. the head of the clause will be in the front of it.
   2. the equalities/inequalities literals will be the end of its body.
   3. the equalities will be in front of the inequalities.
   * the order is for the reduce the search space of sl resolution.
************************************************************************************************************************/
orderAxiom(ClIn, ClOut):-
   findall(-[=|Arg], member(-[=|Arg], ClIn), Eq),
   findall(-[\=|Arg], member(-[\=|Arg], ClIn), InEq),
   subtract(ClIn, Eq, A1),
   subtract(A1, InEq, A2),
   (notin(+_, A2)->    % A2 has no + literal
       append(A2, Eq, A4),
       append(A4, InEq, ClOut);
   member(+Head, A2)->
       subtract(A2, [+Head], A3),
       append(A3, Eq, A4),
       append(A4, InEq, A5),
       append([+Head], A5, ClOut)).


/**********************************************************************************************
    orphanVb: check if there is orhpan variable in the input theory
    Input: an axiom
    Output: The axiom and the orphans if there are orphan variables, otherwise, [].
**********************************************************************************************/
orphanVb([], []):- !.
orphanVb(Axiom,  OpVbles):-
    member(+[_| ArgsHead], Axiom),
    findall(vble(X), (member(-[_| ArgsBody], Axiom), member(vble(X), ArgsBody)), BodyVbles),
    % exists orphan variables.
    setof(vble(X),
            (member(vble(X), ArgsHead),
             notin(vble(X), BodyVbles)),    % vble(X) is not a member of BodyVbles
            OpVbles), !,
    nl, nl,nl,write_term_c('---------- Error: orphan variable is found in: ----------'), nl,
    write_term_c(Axiom), nl, write_term_c(OpVbles).

orphanVb(_, []).

prop(+[PT| ArgsT], [PT| ArgsT]).
prop(-[PT| ArgsT], [PT| ArgsT]).



/*********************************************************************************************************************
    propArityInc(PropListIn, TheoryIn, TheoryOut, DefaultConstants): Get TheoryOut by propagation all arity increments on TheoryIn.
    Input:  PropListIn is the list of predicates, to which the arity increment needs to propagate.
            PredListIn: [(P1,N1,L1), (P2,N2,L2)...]: add Ni new arguments to the predicate Pi to get Li.
            TheoryIn is the input theory which has only the original clauses.
            DefCons is the default constants of these propagations.
    Output: TheoryOut is the repaired theory.
    Note:   Orphan variables: the variables only in the head of a rule, not in the body of that rule.
*********************************************************************************************************************/
% No predicate to propagate.
propArityInc([], Theory, Theory, _):- !.

propArityInc([(P, N, L)| PropList1], TheoryIn, TheoryOut, DefCons):-
    propArityIncTheo([add_n(P,N,L)], TheoryIn, TheoryTem, DefCons, [], PropList2),  % Increase the airty of P from N to L.
    append(PropList1, PropList2, PropList),
    propArityInc(PropList, TheoryTem, TheoryOut, DefCons).




%% ArgLast is the argument list which should be added as the new arguments to all the instances of predicate P.
%% PropList is the list of predicates to propgate the arity increment, because these predicates occur in the rules having P.
propArityIncTheo(_, [], [],_, PredList, PredList):- !.

propArityIncTheo([add_n(P,N,L)], [ClauseH| Rest], [ClauseR| RestNew], ArgLast, PredListIn, PredListOut):-
    propArityIncCl([add_n(P,N,L)], ClauseH, ClauseR, ArgLast, PredListIn, PredListTem),
    propArityIncTheo([add_n(P,N,L)],  Rest, RestNew, ArgLast, PredListTem, PredListOut).


mergeProp([POld| Args], POld, PNew, ArgDiff, inc, [PNew| ArgsNew]):-
    append(Args, ArgDiff, ArgsNew), !.
mergeProp([POld| Args], POld, PNew, ArgsG, dec, [PNew| ArgsNew]):-
    length(ArgsG, Arity),
    split_at(Arity, Args, ArgsNew,_), !.
mergeProp([POld| Args], POld, PNew, _, equ, [PNew| Args]):- !.
mergeProp(Prop, _, _, _, _, Prop).


/*********************************************************************************************************************************
    propArityIncCl(PredListIn, ClauseIn, ClauseOut, DefaultArgs, IndepVbles, PredListOut):
        increase the arity of predicate P by adding DefaultArgs to the original literals of predicate P.
    Input:  PredListIn is the list of predicates, to which the arity increment needs to propagate.
            PredListIn: [(P1,N1,L1), (P2,N2,L2)...]: add Ni new arguments to the predicate Pi to get Li.
            DefaultArgs: the list of N default constants for the new arguments.
            ClauseIn: an input clause.
    Output: ClauseOut: the repaired clause.
            IndepVbles: the list of independent variables for propagation.
            PredList [(Pred, AOrig, ATarg)]: the list of predicates from the body of a repaired rule.
            PredList is recorded for propagation to avoid orphan variable.
            AOrig is the original arity of the predicate Pred;
            ATarg is the targeted arity of the airty increment of predicate Pred.
    The format of a clause: [+[persecutes,[saul],[christians]]].
    TODO: consider whether  we should add independent variables to the literals in a rule?
**********************************************************************************************************************************/
% Nothing to repair.
propArityIncCl(_, [], [], _, _, PredList, PredList):- !.

% Add default constants as the new arguments to an assertion of P.
propArityIncCl([add_n(P, N, L)], [+[P | Args]], [+[P | ArgsOut]], DefArgs, PredList, PredList):-
    length(Args, M), L is M + N, append(Args, DefArgs, ArgsOut), !,
    spec(protList(ProtectedOld)),
    (member([+[P | Args]], ProtectedOld)->
        sort([[+[P | ArgsOut]]| ProtectedOld], ProtNew),
        retractall(spec(protList(_))),
        assert(spec(protList(ProtNew))),!; true).

% If the head of a rule contains P, then add new variables to it and one of the literals in its body.
propArityIncCl([add_n(P, N, L)], [+[P| Arg]| Body], [+[P| ArgNew]| BodyNew], _, PropListIn, PropListOut):-
    % The predicate of this rule's head is P, and its arity is not the desired L.
    length(Arg, M),
    % To update the arity to L, N new independent variables need to be added to the head.
    L is M + N,
    gensymVble(N, IndepVbles),
    append(Arg, [IndepVbles], ArgNew), !,
    spec(protList(ProtectedList)),

    (    % if the target predicate also occurs in the body
        setof((-[P| ArgB], -[P| ArgNewB]),         % get a pair of old literal and its new literal by adding the new arguments.
                (member(-[P| ArgB], Body),
                 length(ArgB, M),
                  L is M + N,
                 append(ArgB, [IndepVbles], ArgNewB)),
            BodyPairs)->
        appAll(replaceS, BodyPairs, [Body], BodyNew, 1),    % replace the old ones with new ones.
        PropListOut = PropListIn;

        % if the target predicate does not occur in the body
        notin(-[P| _], Body)->            % Otherwise, get the rest predicates in the body, the arity of one or them needs to increase by N for propagation.
        setof((PredC, ArgsC, N, LTarg),                % If there is no such a predicate, fail. Because if IndepVbles occur only in the head of this repaired rule, they are orphan variables, not allowed in Datalog.
                  (member(-[PredC| ArgsC], Body),
                   PredC \= P,
                   notin(arity(PredC), ProtectedList),          % The predicate's arity is not protected from being changed.
                   length(ArgsC, LOrig),
                   LTarg is LOrig + N),                          % The targeted arity of the arity increment of the predicate.
          PropListNew),                                      % Get a list of predicates to propagate the arity increment with no redundancy.
        member((PT, ArgTarg, N, L1), PropListNew),                    % Get one predicate from the body of this rule, to which the airty increment needs to propagate.
        PropListOut = [(PT, N, L1)| PropListIn],
        append(ArgTarg, [IndepVbles], ArgNew1),
        % Get the propagated body of this rule.
        replaceS(-[PT| ArgTarg], -[PT| ArgNew1], Body, BodyNew)),

    % update the protected list.
    spec(protList(ProtectedOld)),
    (member([+[P| Arg]| Body], ProtectedOld)->
        sort([[+[P| ArgNew]| BodyNew]| ProtectedOld], ProtNew),
        retractall(spec(protList(_))),
        assert(spec(protList(ProtNew))), !; true).


% If the body of a rule contains P, then add new arguments(independent variables) to the literals of P.
% No further propagation needed.
propArityIncCl([add_n(P, N, L)], RuleIn, RuleOut, _, PropList, PropList):-
    (RuleIn = [+H| Body]; notin(+_, RuleIn), Body = RuleIn, H = []),
    % if the target predicate also occurs in the body
    setof((-[P| ArgB], -[P| ArgNewB]),         % get a pair of old literal and its new literal by adding the new arguments.
            (member(-[P| ArgB], Body),
             length(ArgB, M),
             L is M + N,
             gensymVble(N, IndepVbles),     % Generate N independent variables.
             append(ArgB, [IndepVbles], ArgNewB)),
        BodyPairs),
    appAll(replaceS, BodyPairs, [Body], BodyNew, 1),!,
    (H \= []-> RuleOut = [+H| BodyNew];
    H = []-> RuleOut = BodyNew),
    % update the protected list.
    spec(protList(ProtectedOld)),
    (member(RuleIn, ProtectedOld)->
        sort([RuleOut| ProtectedOld],ProtNew),
        retractall(spec(protList(_))),
        assert(spec(protList(ProtNew))),!; true).

% Nothing to change when predicate P does not occur in the Clause
propArityIncCl([add_n(_,_,_)], Clause, Clause, _, PredList, PredList).


/**********************************************************************************************************************
    readFile(Stream, String): read Stream
    Input:  Stream:
    Output: String is the content in file Stream
***********************************************************************************************************************/
readFile(Stream,[]) :-
    at_end_of_stream(Stream), !.

readFile(Stream,[X|L]) :-
    \+ at_end_of_stream(Stream),
    read(Stream,X),
    readFile(Stream,L).

/**********************************************************************************************************************
    readInputs(InpFileList, InpDataList)
            Read input files and return the corresponding input data.
    Input:  InpFileList is a list of the directories of input files
    Output: A list of input data.
************************************************************************************************************************/
readInputs([], []).
readInputs([FileIn| Rest], [InpData| RestInp]):-
  open(FileIn, read, StrInp),
  readFile(StrInp, Inp),       % the input abox is a list
  delete(Inp, end_of_file, InpData),
  close(StrInp),
  readInputs(Rest, RestInp).


% remove " in files
removeQuote(FileList):-
    readInputs(FileList, DataList),
    writeFiles(FileList, DataList).
/**********************************************************************************************
  replace(E, SubE, ListIn,ListOut): replace element E in ListIn with SubE to get ListOut.
  If E does not occur in the list, ListOut = ListIn.
***********************************************************************************************/
replace([], List, List):-!.
replace((_, _), [], []):-!.
replace((E, SubE), ListIn,ListOut):- replace(E, SubE, ListIn,ListOut).
replace([(E, SubE)| Rest], ListIn,ListOut):-
  replace(E, SubE, ListIn,ListTem),
  replace(Rest, ListTem, ListOut).

replace(_, _, [], []):-!.
replace(E, SubE, [H|T], [SubE|T2]) :- H = E, replace(E, SubE, T, T2), !.
replace(E, SubE, [H|T], [H|T2]) :- H \= E, replace(E, SubE, T, T2).


replaceS(E, ListIn, ListOut):-
  replace(E, ListIn,ListOut).

replaceS(E, SubE, ListIn, ListOut):-
  replace(E, SubE, ListIn,ListOut).

replaceNested(_,_,[],[]):- !.
replaceNested(E,SubE,[+H|T],[+H2|T2]):-
    replaceNested(E,SubE,H,H2),
    replaceNested(E,SubE,T,T2).
replaceNested(E,SubE,[-H|T],[-H2|T2]):-
    replaceNested(E,SubE,H,H2),
    replaceNested(E,SubE,T,T2).
replaceNested(E,SubE,[H|T],[SubE|T2]):- H = E, replaceNested(E, SubE, T, T2), !.
replaceNested(E,SubE,[H|T],[H2|T2]):-
    H \= E,
    is_func(H),!,
    replaceNested(E,SubE,H,H2),
    replaceNested(E,SubE,T,T2).
replaceNested(E, SubE, [H|T], [H|T2]) :- H \= E, replaceNested(E, SubE, T, T2).

/**********************************************************************************************
    repList(ListToRep, Rep, ListIn,ListOut): for each element in ListToRep,
    replace it with Rep in ListIn and get ListOut.
***********************************************************************************************/
repList(_, _, [], []):-!.
repList([], _, List, List):-!.
repList([HEle| TEle], Rep, -ListIn, -ListOut) :- !,
    replace(HEle, Rep, ListIn, ListTem),
    repList(TEle, Rep, -ListTem, -ListOut).
repList([HEle| TEle], Rep, +ListIn, +ListOut) :- !,
    replace(HEle, Rep, ListIn, ListTem),
    repList(TEle, Rep, +ListTem, +ListOut).
repList([HEle| TEle], dummy, ListIn, ListOut) :- !,
    gensym(dummy, NewEle),
    replace(HEle, NewEle, ListIn, ListTem),
    repList(TEle, ListTem, ListOut).
repList([HEle| TEle], Rep, ListIn, ListOut) :- !,
    replace(HEle, Rep, ListIn, ListTem),
    repList(TEle, Rep, ListTem, ListOut).

/**********************************************************************************************
    replacePos(P, ListIn, Sub, ListOut): only replace position P in ListIn with Sub to get ListOut.
    Counting from 0: replacePos(1, [0,1,2,3], d, X). X = [0, d, 2, 3].
***********************************************************************************************/
% Step case: find Ith argument and recurse on it
replacePos(_, [],_, []):-!.
replacePos(P, ListIn, Sub, ListOut) :-
    split_at(P, ListIn, FronList, [_| AfterList]),
    split_at(P, ListOut, FronList, [Sub| AfterList]).


replacePosList([], List,_, List).
replacePosList([H| Rest], ListIn, Sub, ListOut) :-
    replacePos(H, ListIn, Sub, ListTem),
    replacePosList(Rest, ListTem, Sub, ListOut).
/**********************************************************************************************
    revertFormRep: revert the writing fromat from the internal to the output format.
***********************************************************************************************/

revertFormRep(dele_pre(-Pre, RuleIn), dele_pre(-PreA, RuleOut)):- !,
    revert(Pre, PreA),
    appEach(RuleIn, [appLiteral,  revert], RuleOut).

revertFormRep(add_pre(-Pre, RuleIn), add_pre(-PreA, RuleOut)):- !,
    revert(Pre, PreA),
    appEach(RuleIn, [appLiteral,  revert], RuleOut).

revertFormRep(delete(Clause), delete(ClauseOut)):- !,
    appEach(Clause, [appLiteral,  revert], ClauseOut).

revertFormRep(expand(Clause), expand(ClauseOut)):- !,
    appEach(Clause, [appLiteral,  revert], ClauseOut).

revertFormRep(analogy(R1, R2), analogy(R1Out, R2Out)):- !,
    appEach([R1, R2], [appEach, [appLiteral,  revert]], [R1Out, R2Out]).

revertFormRep(ass2rule(R1, R2), ass2rule(R1Out, R2Out)):- !,
    appEach([R1, R2], [appEach, [appLiteral,  revert]], [R1Out, R2Out]).

revertFormRep(X,X).
/**********************************************************************************************************************
    rewriteVble(Goals, InputClause, ClNew, AllSubs):
            rewrite the variables in InputClause which occur in the Goals.
    Input: Goals: a list of sub-goals.
           Anc: the derivation of Goals from the original goal.
           InputClause: the input clause which will be used to resolve the left most subgoal in Goals.
    Output: ClNew: the rewritten clause.
            AllSubs: the substitutions of from the input goals to the output goals.
************************************************************************************************************************/
% REW1: when there is no goal nor input clause, return.
rewriteVble([], Cl, Cl, []):- !.
rewriteVble(_, [], [], []):- !.

% REW2: when there is shared variable, rewriting is needed.
rewriteVble(Goals, InputClause, ClNew, AllSubs):-
    % generate substitutions which replace old variable vble(X) with its new name vble(NewX).
    findall(vble(NewX)/vble(X),
            (member([_|Args], Goals),
             memberNested(vble(X), Args),
             member(Literal, InputClause),
             ( Literal = -[_| ArgsInCl];
               Literal = +[_| ArgsInCl]),
             % If the variable vble(X) occur in ArgsInCl, rename it with vble(NewX).
             newVble(vble(X), ArgsInCl, vble(NewX))),
            AllSubsTem),
     sort(AllSubsTem, AllSubs),
     subst(AllSubs, InputClause, ClNew).    % GoalsNew == Goals when AllSubs = [].


/**********************************************************************************************
    From http://www.swi-prolog.org/
    split_at(N,List1, List2, List3) let the following true:
    append(List2, List3, List1),
    length(List2, N),
    split_at(1, [0,1,2], X, Y). X = [0],    Y = [1, 2].
**********************************************************************************************/
split_at(0,L,[],L) :- !.
split_at(N,[H|T],[H|L1],L2) :-
     M is N -1,
    split_at(M,T,L1,L2).

% split([e,d,r,a,g,r],a,X,Y): X = [e, d, r, a],Y = [g, r].
split([], _, _, _):- fail.
split(List, Ele, SubList1, SubList2):-
    append(SubList1,  SubList2, List),
    last(SubList1, Ele).
/**********************************************************************************************

% subst(V/E,E1,E2): E2 is the result of replacing E with V in E1.
**********************************************************************************************/

subst([Subst|Substs], E,NE) :- subst(Subst,E,NE1), subst(Substs,NE1,NE), !.
subst(_,[],[]) :-!.                          % If E1 is empty problem then do nothing
subst([],E,E) :-!.
subst(C/C, E, E):- arg(C), !.
subst(D/C, C, D):- arg(C), arg(D),  !.

%subst(Subst,[F|Args1],[F|Args2]) :-
  % atomic(F), maplist(subst(Subst),Args1,Args2),!. % If E1 is compound then recurse on args.
subst(Subst,[E1=E2|Tl],[NE1=NE2|NTl]) :-       % If E1 is unification problem then
  subst(Subst,E1,NE1), subst(Subst,E2,NE2),   % apply substitution to both sides
   subst(Subst,Tl,NTl),!.                        % then recurse on tails

subst(Subst,[+E|T],[+NE|NT]) :-         % for substituting resolution ready clauses
   subst(Subst,E,NE),!,
   subst(Subst,T,NT).

subst(Subst,[-E|T],[-NE|NT]) :-
   subst(Subst,E,NE),!,
   subst(Subst,T,NT).

subst(Subst,[V/E|T], [NV/E|NT]) :-          % If E1 is substitution then
   subst(Subst,V,NV),!,                    % apply substitution to value
   subst(Subst,T,NT).                      % then recurse on tails

subst(Subst, [Els1|T], [Els2|TSub]) :-
  subst(Subst, Els1, Els2),!,
  subst(Subst, T, TSub). % If E1 is compound then recurse on args.



% only substitute a constant, which is a list of one element, or a variable, which is vble(X).
subst(_/C, Y, Y):- %arg(C), arg(Y),
    Y \= C, !.


/**********************************************************************************************
   based on transpose from clpfd: https://github.com/SWI-Prolog/swipl-devel/blob/master/library/clp/clpfd.pl#L6371
   Input: Ls is a list of lists.
   Output: Out is the transposition of Ls, where the sublist of empty lists, e.g. [[],[],[[]]] is flatten as [].
***********************************************************************************************/
transposeF([], Out):-
     maplist(=([]), Out), !.
transposeF(Ls, Out):-
        must_be(list(list), Ls),
        lists_transpose(Ls, Ts),
        appEach(Ts, [empty], TS1),
        appEach(TS1,[delete, []], Out).    % flatten the list of empty lists as [].

lists_transpose([], []).
lists_transpose([L|Ls], Ts) :-
        maplist(same_length(L), Ls),
        foldl(transpose_, L, Ts, [L|Ls], _).

transpose_(_, Fs, Lists0, Lists) :-
        maplist(list_first_rest, Lists0, Fs, Lists).

list_first_rest([L|Ls], L, Ls).


/**********************************************************************************************************************
    theoryGraph(Graph): the theory graph based on rules.
    1. the head of the clause will be in the front of it.
    2. the equalities/inequalities literals will be the end of its body.
    3. the equalities will be in front of the inequalities.
    * the order is for the reduce the search space of sl resolution.
************************************************************************************************************************/
theoryGraph(Theory, Graph):-
    findall(Branch,
            (member([+[Pred|_]], Theory),    % get an axiom Q, whose predicate is Pred.
             extBranch(Theory, [Pred], Branch)),
            Branches),
    sort(Branches, Graph).

% get the branch by extending BranchIn.
extBranch(Rules, BranchIn, BranchOut):-
    last(BranchIn, Pred),
    member([+[Pred2|_]|Body], Rules),
    delete(Rules, [+[Pred2|_]|Body], RestTheory),
    occur(-[Pred|_], Body),
    (notin(Pred2, BranchIn)-> append(BranchIn, [Pred2], BranchNew), !;
     member(Pred2, BranchIn)-> BranchNew = BranchIn),
    extBranch(RestTheory, BranchNew, BranchOut).
extBranch(_, Branch, Branch).


/**********************************************************************************************************************
    notUnique(LF, Abox, Rules): true if F's occurances is more than once
        Input:  F: a constant/predicate;
                Abox, Rules: input KG and rules.
************************************************************************************************************************/
notUnique(F, Abox, Rules):-
    occ2s(F, Abox, 0,  NumA),
    occ2s(F, Rules, 0, NumR),
    NumA + NumR > 1.

% check whether F occcurs at least 2 times. The returned counting would be 0, 1 or 2.
occ2s(_, [], Num, Num).
occ2s(F, [Axiom| RestAxioms], NumIn, NumNew):-
    NumIn <2, !,
    findall(Prop, (member(+Prop, Axiom); member(-Prop, Axiom)),
            AllProp),
    flatten(AllProp, Props),
    delete(Props, F, PRest),
    length(Props, L1),
    length(PRest, L2),
    NumTem is L1 - L2 + NumIn,
    occ2s(F, RestAxioms, NumTem, NumNew).
% Num = 2, terminate
occ2s(_, _, Num, Num).


/* pairwise(L1,L2,Pairlist): pairs up corresponding elements of two lists.
e.g.,pairwise([equal,[tories],[conservatives]], [equal,vble(y),vble(z)],X).
X = [equal=equal, [tories]=vble(y), [conservatives]=vble(z)].
*/
% Base case
pairwise([],[],[]).             % If input two empty lists then return one.

pairwise([[H1]|T1],[[H2]|T2], POut) :- % Otherwise, pair up the heads
     pairwise(H1, H2, NewP),
     pairwise(T1,T2,T),
     append(NewP, T, POut).                % and recurse on the tails.

% Step case
pairwise([H1|T1],[H2|T2],[H1=H2|T]) :- % Otherwise, pair up the heads
     pairwise(T1,T2,T).                % and recurse on the tails.

/**********************************************************************************************************************
    termOcc(LF, Theory, OccF): count term F's occurances in the theory
        Input:  F: a constant/predicate;
                Theory: a list of axioms
        Output: OccF: the number of F's occurances in Theory.
************************************************************************************************************************/
termOcc(F, Theory, OccF):-
    cterm(F, Theory, 0, OccF).
cterm(_, [], Num, Num):-!.
cterm(F, [Axiom| RestAxioms], NumIn, NumOut):-
    findall(Prop, (member(+Prop, Axiom); member(-Prop, Axiom)),
            AllProp),
    flatten(AllProp, Props),
    delete(Props, F, PRest),
    length(Props, L1),
    length(PRest, L2),
    NumNew is L1 - L2 + NumIn,
    cterm(F, RestAxioms, NumNew, NumOut).



/********************************************
addAncestor: combine new goals (ancestors) with theory.
*******************************************/
addAncestor(Theory,[],Theory). %If no derivation, just output the theory.
addAncestor(Theory,[Head|Rest],Out):-
    Head = (_,_,_,NewGoal,_),
    is_list(NewGoal),
    NewGoal = [],
    addAncestor(Theory,Rest,Out).
addAncestor(Theory,[Head|Rest],Out):-
    Head = (_,_,_,NewGoal,_),
    is_list(NewGoal),
    NewGoal \= [],
    append(Theory,[NewGoal],TheoryNew),
    addAncestor(TheoryNew,Rest,Out).

/********************************************
findClause: find the clause in theoryl.
reorderClause: make target the first clause in the list.
*******************************************/
findClause(Target,[H|_],H):-
    member(Target,H),
    length(H,X),
    X > 1.
findClause(Target,[_|R],Out):-
    findClause(Target,R,Out).

reorderClause(Target,[H|R],[H|R]):-
    Target = H,!.

reorderClause(Target,[H|R],Out):-
    Target \= H,
    append(R,[H],NewL),
    reorderClause(Target,NewL,Out).


memberNested(Elem,List):-
    member(Elem,List).

memberNested(Elem,[H|_]):-
    is_list(H),
    memberNested(Elem,H).

memberNested(Elem,[_|R]):-
    member([_|_],R),
    memberNested(Elem,R).

memberNested(_,[]):- fail.

occursCheck(X,Funclist):-
    \+memberNested(vble(X), Funclist),!.

noTautology(Goals):-
    findall(Pred,
        (
            X = -[Pred|Arg],
            Y = +[Pred|Arg2],
            member(X,Goals),
            member(Y,Goals),
            Arg == Arg2
        )
        ,Preds),
    length(Preds,0).

checkEq([]).
checkEq([H|R]):-
    is_list(H),
    length(H,2),
    H = [A,B],
    is_cons_or_func(A),
    is_cons_or_func(B),
    checkEq(R).

is_cons_or_func(A):-
    is_cons(A).

is_cons_or_func(A):-
    is_func(A).


notLastEQ([],_).
notLastEQ(L,_):-
    last(L,Concern),
    Concern = (_,AxiomIn,_,_,_),
    AxiomIn \= [eqAxiom|_].
notLastEQ(L,EQ):-
    last(L,Concern),
    Concern = (_,AxiomIn,_,_,_),
    AxiomIn = [eqAxiom,_|T],
    T \= EQ. %Use the built-in unification since it is all constants.


sortGoals(Goals,GoalsOut):-
    removeDuplicates(Goals,[],GoalsSorted), %sort AND removed duplicates.
    sepFuncNonfunc(GoalsSorted,[],[],NonFuncGoals,FuncGoals),
    append(NonFuncGoals,FuncGoals,GoalsOut).

sepFuncNonfunc([],X,Y,X,Y). %Finished

sepFuncNonfunc([H|R],TNFGoals,TFGoals,NFGoals,FGoals):-
    hasFunc(H),
    append(TFGoals,[H],NewTFGoals),
    sepFuncNonfunc(R,TNFGoals,NewTFGoals,NFGoals,FGoals).

sepFuncNonfunc([H|R],TNFGoals,TFGoals,NFGoals,FGoals):-
    \+hasFunc(H),
    append(TNFGoals,[H],NewTNFGoals),
    sepFuncNonfunc(R,NewTNFGoals,TFGoals,NFGoals,FGoals).

hasFunc(Goal):-
    member(Goal,[+[P|Args],-[P|Args]]),
    member([_,_|_],Args).

removeDuplicates([],_,[]):-!.

removeDuplicates([H|T],Current,[H|T2]):-
    \+member(H,Current),!,
    append(Current,[H],Current2),
    removeDuplicates(T,Current2,T2).

removeDuplicates([H|T],Current,T2):-
    member(H,Current),!,
    removeDuplicates(T,Current,T2).

% Finding ancestor from deriv list
findAncestor(Deriv,IC,Deriv):-
    last(Deriv, CurDerStep),
    CurDerStep = (_,_,_,IC,_),!.

findAncestor(Deriv,IC,NewDeriv):-
    dropTail(Deriv,Ances),
    findAncestor(Ances,IC,NewDeriv).

addSameSign(+_,Y,+Y):- !.
addSameSign(-_,Y,-Y):- !.

addOpSign(+_,Y,-Y):- !.
addOpSign(-_,Y,+Y):- !.

isOpSign(+_,-_).
isOpSign(-_,+_).


% TraceBackClause: Find back the original clause that introduced IC (in the case where IC is the ancestor.)
traceBackClause(IC,[],_,IC):- !.

traceBackClause(IC,_,TheoryIn,IC):-
    member(IC,TheoryIn),
    !.

traceBackClause(IC,Deriv,TheoryIn,OrgClause):-
    last(Deriv, (_,OrgClause,_,IC,_)),
    member(OrgClause,TheoryIn),
    !.

traceBackClause(IC,Deriv,TheoryIn,OrgClause):-
    last(Deriv, (_,OrgClauseT,_,IC,_)),
    \+member(OrgClauseT,TheoryIn),
    removeLast(Deriv,DerivNew),
    traceBackClause(OrgClauseT,DerivNew,TheoryIn,OrgClause),
    !.

traceBackClause(IC,Deriv,TheoryIn,OrgClause):-
    removeLast(Deriv,DerivNew),
    traceBackClause(IC,DerivNew,TheoryIn,OrgClause).

removeLast([_],[]).
removeLast([L|R],[L|Removed]):-
    removeLast(R,Removed).

takeout(X,[X|R],R).  
takeout(X,[F |R],[F|S]) :- takeout(X,R,S).

perm([X|Y],Z) :- perm(Y,W), takeout(X,Z,W).  
perm([],[]).

choose(1, [H|_], [H]).
choose(N, [H|TL], [H|ST]) :- Less1 is N - 1, choose(Less1, TL, ST).
choose(N, [_|T], L) :- choose(N, T, L).

containsC(Const,Props):-
    member(Prop,Props),
    prop(Prop,UProp),
    memberNested(Const,UProp).

nestedDelete(List,Item,OutList,DelPos):-
    nestedDeleteHelper(0,List,Item,[],OutList,[],DelPos).

nestedDeleteHelper(_,[],_,OutList,OutList,DelPos,DelPos):- !.
nestedDeleteHelper(Pos,[H|R],Item,CurList,OutList,CurDelPos,DelPos):-
    memberNested(Item,[H]), %The item to be deleted is included, do not append
    !,
    append(CurDelPos,[Pos],CurDelPosNew),
    PosNew is Pos + 1,
    nestedDeleteHelper(PosNew,R,Item,CurList,OutList,CurDelPosNew,DelPos).
nestedDeleteHelper(Pos,[H|R],Item,CurList,OutList,CurDelPos,DelPos):-
    \+memberNested(Item,[H]), %The item to be deleted is not included
    !,
    append(CurList,[H],CurListNew),
    PosNew is Pos + 1,
    nestedDeleteHelper(PosNew,R,Item,CurListNew,OutList,CurDelPos,DelPos).


addVar([],_,[]).
addVar([(COrig, Cl)|T],AvoidList,[(COrig,vble(Y),Cl)|TOut]):-
    findall(X,
        ( (member(+[_| Arg], Cl);
            member(-[_| Arg], Cl)),
            memberNested(vble(X), Arg)),
        AvoidListTmp),
    append(AvoidList,AvoidListTmp,AvoidListNew),
    getNewVble([COrig],AvoidList,[(COrig, vble(Y))], _),
    append(AvoidListNew,[Y],AvoidListNew2),
    addVar(T,AvoidListNew2,TOut).

maxlist([],0).

maxlist([Head|Tail],Max) :-
    maxlist(Tail,TailMax),
    Head > TailMax,
    Max is Head.

maxlist([Head|Tail],Max) :-
    maxlist(Tail,TailMax),
    Head =< TailMax,
    Max is TailMax.

newArity(NewLit,FuncN,N):-
    prop(NewLit,UNewLit),
    findall(Y,
        (memberNested(Funclist,UNewLit),
        member(FuncN,Funclist),
        length(Funclist,Y)
        ),
    Ys),!,
    maxlist(Ys,Nt),
    N is Nt - 1.

newArity(NewLit,FuncN,N):-
    \+prop(NewLit,_),
    findall(Y,
        (memberNested(Funclist,NewLit),
        member(FuncN,Funclist),
        length(Funclist,Y)
        ),
    Ys),!,
    maxlist(Ys,Nt),
    N is Nt - 1.

newArity(_,_,0). %For safety

addArityP(Theory,_,0,Theory):- !. % FOr safety: if arity 0, do not change.
addArityP([],_,_,[]).
addArityP([H|R],P,N,[H2|R2]):-
    addArityClauseP(H,P,N,H2),
    addArityP(R,P,N,R2).

addArityClauseP([],_,_,[]).
addArityClauseP([+Lit|R],P,N,[+Lit2|R2]):-
    Lit = [Pred| Arg],
    addArityArgP(Arg,P,N,Arg2),
    Lit2 = [Pred|Arg2],
    addArityClauseP(R,P,N,R2).
addArityClauseP([-Lit|R],P,N,[-Lit2|R2]):-
    Lit = [Pred| Arg],
    addArityArgP(Arg,P,N,Arg2),
    Lit2 = [Pred|Arg2],
    addArityClauseP(R,P,N,R2). 

addArityArgP([],_,_,[]).
addArityArgP([C|R],P,N,[C|R2]):- %Constants and variables can be ignored.
    (is_cons(C);C = vble(_)),
    addArityArgP(R,P,N,R2).
addArityArgP([F|R],P,N,[F2|R2]):- %Function but not related to P.
    is_func(F),
    F = [Pname|Args],
    Pname \= P,!,
    addArityArgP(Args,P,N,Args2),
    F2 = [Pname|Args2],
    addArityArgP(R,P,N,R2).
addArityArgP([F|R],P,N,[F2|R2]):-%Function that needs add arity
    is_func(F),
    F = [P|Args],
    addArityArgP(Args,P,N,Args2),
    F2T = [P|Args2],
    \+length(Args2,N),!,
    findall(X,memberNested(vble(X), F2T),AvoidList),
    getNewVble([dummy], AvoidList, [(dummy, NewVble)], _),
    append(F2T,[NewVble],F2),
    addArityArgP(R,P,N,R2).
addArityArgP([F|R],P,N,[F2T|R2]):- %FUnction P that already has the correct arity
    is_func(F),
    F = [P|Args],
    addArityArgP(Args,P,N,Args2),
    F2T = [P|Args2],
    length(Args2,N),!,
    addArityArgP(R,P,N,R2).


deleteArityP([],_,_,_,[]).
deleteArityP([H|R],P,DelPos,N,[H2|R2]):-
    deleteArityClauseP(H,P,DelPos,N,H2),
    deleteArityP(R,P,DelPos,N,R2).

deleteArityClauseP([],_,_,_,[]).
deleteArityClauseP([+Lit|R],P,DelPos,N,[+Lit2|R2]):-
    Lit = [Pred| Arg],
    deleteArityArgP(Arg,P,DelPos,N,Arg2),
    Lit2 = [Pred|Arg2],
        print(Lit2),nl,
    deleteArityClauseP(R,P,DelPos,N,R2).
deleteArityClauseP([-Lit|R],P,DelPos,N,[-Lit2|R2]):-
    Lit = [Pred| Arg],
    deleteArityArgP(Arg,P,DelPos,N,Arg2),
    Lit2 = [Pred|Arg2],
    deleteArityClauseP(R,P,DelPos,N,R2). 

deleteArityArgP([],_,_,_,[]).
deleteArityArgP([C|R],P,DelPos,N,[C|R2]):-
    (is_cons(C);C = vble(_)),
    deleteArityArgP(R,P,DelPos,N,R2).
deleteArityArgP([F|R],P,DelPos,N,[F2|R2]):-
    is_func(F),
    F = [Pname|Args],
    Pname \= P,
    deleteArityArgP(Args,P,DelPos,N,Args2),
    F2 = [Pname|Args2],
    deleteArityArgP(R,P,DelPos,N,R2).
deleteArityArgP([F|R],P,DelPos,N,[F2|R2]):- 
    is_func(F),
    F = [P|Args],
    deleteArityArgP(Args,P,DelPos,N,Args2),
    F2T = [P|Args2],
    \+length(Args2,N),!,
    deletePos(F2T,DelPos,F2),
    deleteArityArgP(R,P,DelPos,N,R2).
deleteArityArgP([F|R],P,DelPos,N,[F2T|R2]):-
    is_func(F),
    F = [P|Args],
    deleteArityArgP(Args,P,DelPos,N,Args2),
    F2T = [P|Args2],
    length(Args2,N),!,
    deleteArityArgP(R,P,DelPos,N,R2).

deletePos(L,DelPos,Out):-
    sort(0,  @>, DelPos,  Sorted), %Sort delete pos in descending order
    deletePosHelper(L,Sorted,Out).

deletePosHelper(L,[],L).
deletePosHelper(L,[H|R],Out):-
    deletePosN(L,H,L2),
    deletePosHelper(L2,R,Out).

deletePosN(L,H,L2):-
    atomic(H),
    nth0(H,L,_,L2).

involvedClause(_,_,[],_,[]).
involvedClause(Goal,TheoryIn,[H|R],EC,[H|R2]):-
    slRL(Goal,TheoryIn,EC,Proof,[],[]),
    member((_,H,_,_,_), Proof),
    is_list(H),!,
    involvedClause(Goal,TheoryIn,R,EC,R2).
involvedClause(Goal,TheoryIn,[_|R],EC,R2):-
    involvedClause(Goal,TheoryIn,R,EC,R2).

allFunc(L,FP):-
    findall(FuncN,
        (
            member(Cl,L),
            (member(+Prop,Cl);member(-Prop,Cl)),
            memberNested(C,Prop),
            is_func(C),
            C = [FuncN|_]
        ),
    FPT),
    sort(FPT,FP).

addConstoFunc([],_,_,[]).
addConstoFunc([C|R],P,N,[C|R2]):- %Constants and variables can be ignored.
    (is_cons(C);C = vble(_)),
    addConstoFunc(R,P,N,R2).
addConstoFunc([F|R],P,N,[F2|R2]):- %Function but not related to P.
    is_func(F),
    F = [Pname|Args],
    Pname \= P,!,
    addConstoFunc(Args,P,N,Args2),
    F2 = [Pname|Args2],
    addConstoFunc(R,P,N,R2).
addConstoFunc([F|R],P,N,[F2|R2]):-%Function that needs add arity
    is_func(F),
    F = [P|Args],
    addConstoFunc(Args,P,N,Args2),
    F2T = [P|Args2],
    append(F2T,[N],F2),
    addConstoFunc(R,P,N,R2).


addArityP(Theory,_,0,_,Theory):- !. % FOr safety: if arity 0, do not change.
addArityP([],_,_,_,[]).
addArityP([H|R],P,N,NewCon,[H2|R2]):-
    addArityClauseP(H,P,N,NewCon,H2),
    addArityP(R,P,N,NewCon,R2).

addArityClauseP([],_,_,_,[]).

addArityClauseP([+Lit|R],P,N,NewCon,[+Lit2|R2]):-
    Lit = [P| Arg],\+length(Arg,N),!,
    append(Lit,[NewCon],Lit2),
    addArityClauseP(R,P,N,NewCon,R2).
addArityClauseP([-Lit|R],P,N,NewCon,[-Lit2|R2]):-
    Lit = [P| Arg],\+length(Arg,N),!,
    append(Lit,[NewCon],Lit2),
    addArityClauseP(R,P,N,NewCon,R2). 
addArityClauseP([+Lit|R],P,N,NewCon,[+Lit|R2]):-
    Lit = [P| Arg],length(Arg,N),!,
    addArityClauseP(R,P,N,NewCon,R2).
addArityClauseP([-Lit|R],P,N,NewCon,[-Lit|R2]):-
    Lit = [P| Arg],length(Arg,N),!,
    addArityClauseP(R,P,N,NewCon,R2). 

addArityClauseP([+Lit|R],P,N,NewCon,[+Lit2|R2]):-
    Lit = [Pred| Arg],
    addArityArgP(Arg,P,N,NewCon,Arg2),
    Lit2 = [Pred|Arg2],
    addArityClauseP(R,P,N,NewCon,R2).
addArityClauseP([-Lit|R],P,N,NewCon,[-Lit2|R2]):-
    Lit = [Pred| Arg],
    addArityArgP(Arg,P,N,NewCon,Arg2),
    Lit2 = [Pred|Arg2],
    addArityClauseP(R,P,N,NewCon,R2). 



addArityArgP([],_,_,_,[]).
addArityArgP([C|R],P,N,NewCon,[C|R2]):- %Constants and variables can be ignored.
    (is_cons(C);C = vble(_)),
    addArityArgP(R,P,N,NewCon,R2).
addArityArgP([F|R],P,N,NewCon,[F2|R2]):- %Function but not related to P.
    is_func(F),
    F = [Pname|Args],
    Pname \= P,!,
    addArityArgP(Args,P,N,NewCon,Args2),
    F2 = [Pname|Args2],
    addArityArgP(R,P,N,NewCon,R2).
addArityArgP([F|R],P,N,NewCon,[F2|R2]):-%Function that needs add arity
    is_func(F),
    F = [P|Args],
    addArityArgP(Args,P,N,NewCon,Args2),
    F2T = [P|Args2],
    \+length(Args2,N),!,
    append(F2T,[NewCon],F2),
    addArityArgP(R,P,N,NewCon,R2).
addArityArgP([F|R],P,N,NewCon,[F2T|R2]):- %FUnction P that already has the correct arity
    is_func(F),
    F = [P|Args],
    addArityArgP(Args,P,N,NewCon,Args2),
    F2T = [P|Args2],
    length(Args2,N),!,
    addArityArgP(R,P,N,NewCon,R2).


getAllReps([],[]).
getAllReps([H|R],[H2|R2]):-
    H = [[_,(_,_),_]|_],!,
    getAllRepsFault(H,H2),
    % print(H2),nl,print('hi'),nl,halt,
    getAllReps(R,R2).
getAllReps([H|R],[H2|R2]):-
    getAllReps(H,H2),
    getAllReps(R,R2).

getAllRepsFault([],[]).
getAllRepsFault([[_,(RepPlan,_),_]|R],[RepPlan|R2]):-
    getAllRepsFault(R,R2).

addListtoList([],[]).
addListtoList([H|R],[[H]|R2]):-
    addListtoList(R,R2).