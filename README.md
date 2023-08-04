# ABC_Datalog
The ABC system is a domain-independent system for repairing faulty Datalog-like theories by combining three existing techniques: abduction, belief revision and conceptual change. Accordingly, it is named the ABC repair system (ABC). Given an observed assertion and a current theory, abduction adds axioms, or deletes preconditions, which explain that observation by making the corresponding assertion derivable from the expanded theory. Belief revision incorporates a new piece of information which conflicts with the input theory by deleting old axioms. Conceptual change uses the reformation algorithm for blocking unwanted proofs or unblocking wanted proofs. The former two techniques change an axiom as a whole, while reformation changes the language in which the theory is written. These three techniques are complementary. But they have not previously been combined into one system. We align these three techniques in ABC, which is capable of repairing logical theories with better result than each individual technique alone. Datalog is used as the underlying logic of theories in this thesis, but the proposed system has the potential to be adapted to theories in other logics.


# evaluation theories
This folder contains the faulty theories tested in the evaluation in our project. The ones with name *h.pl is a theory with heuristics, while ones with name *nh.pl is the corresponding theory without heuristics.


# code
This folder contains the code of the ABC repair system, which is written in Prolog. The predicate abc/0 in file main.pl is the main entrance. An example of running the code is given below, where PATH is the directory to your code. Ideally, three commands below should be done one by one to make sure none is failed.

:- working_directory(_, PATH).
:- [main, theories/swan].
:- abc.

The output file will be under the folder named 'log'. Files with abc_*_*_faultFree.txt gives the repaire solutions of produced fault-free theories; 'abc_*_*_record.txt' gives the details of ABC's process.

# sampleOutput.txt
It is a sample output file, whose original name is of format _abc_..._faultFree.txt_.

# How to run the code
Step1. Prepare the theory input file e.g., any file in folder 'evaluation theories'. It has to include a Datalog theory given by _axiom([...])_, and the preferred structure given by _trueSet([...])_ and _falseSet([...])_. Then one can put the items to protect from being changed in _protect([...])_, and heuristics to apply in _heuristics([...])._

Step2. Load the theory file and main.pl in a Prolog console.

Step3. Call predicate _abc._ The output files include _abc_..._faultFree.txt_ which contains the repair solutions; _abc_..._record.txt_ which has the log information of ABC's procedure, and _abc_..._repNum.txt_ which is the pruned sub-optimal.


