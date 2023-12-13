import subprocess
import re


def consistent(theory):
    TEXTO = "set(prolog_style_variables).\n"  ## Important for us
    TEXTO += "assign(max_seconds, 59).\n\n"  ## Directive for max_timing

    TEXTO += "formulas(assumptions).\n"
    for linea in theory:
        TEXTO += f"{linea}.\n"
    TEXTO += "end_of_list.\n\n"

    TEXTO += "formulas(goals).\n"
    TEXTO += "%% EMPTY  \n"
    TEXTO += "end_of_list.\n"

    P9_INPUT = "theory_p9.in"

    fichero = open(f"{P9_INPUT}", mode="w")
    fichero.write(TEXTO)
    fichero.close()

    proc = subprocess.run(["prover9", "-f", f"{P9_INPUT}"], stdout=subprocess.PIPE)

    # print(str(proc.stdout))
    return not ("THEOREM PROVED" in str(proc.stdout))


def prolog_to_p9(axiom):
    def var_to_upper(match):
        return match.group(1).upper()

    # Break the axiom into a list of literals
    axioms = axiom.split(",")
    axioms = [a.strip() for a in axioms]
    # Combine back elements in the list if it does not start with +/-
    i = 0
    while i + 1 < len(axioms):
        if axioms[i + 1][0] not in "+-":
            axioms[i] += "," + axioms[i + 1]
            del axioms[i + 1]
            i = -1
        i += 1
    # Turn variables into uppercase
    axioms = [re.sub(r"\\([a-z0-9]+[\),])", var_to_upper, a) for a in axioms]
    if len(axioms) == 1:
        if axioms[0][0] == "+":
            return axioms[0][1:]
        else:
            return axioms[0]
    pluses = [a for a in axioms if a[0] == "+"]
    minuses = [a for a in axioms if a[0] == "-"]
    if len(pluses) == 0:
        return " | ".join(["(" + a + ")" for a in minuses])
    elif len(minuses) == 0:
        return " | ".join([a[1:] for a in pluses])
    else:
        return (
            "("
            + " & ".join([a[1:] for a in minuses])
            + ") -> ("
            + " | ".join([a[1:] for a in pluses])
            + ")"
        )


def read_theory(filename):
    theory = []
    # Check if it is a .pl file
    if filename[-3:] != ".pl":
        return theory
    with open(filename, "r") as f:
        for line in f:
            # Match the line with a regex
            if re.match(r"^axiom\(\[.*\]\)\.$", line):
                # extract the axiom content
                axiom = re.search(r"\[(.*)\]", line).group(1)
                axiom = prolog_to_p9(axiom)
                theory.append(axiom)
    return theory


def consistency_check(theory_file):
    theory = read_theory(theory_file)
    if consistent(theory):
        print("CONSISTENT")
    else:
        print("INCONSISTENT")


if __name__ == "__main__":
    consistency_check("./evaluation/consistent.pl")

# print(read_theory("./evaluation/eggtimer.pl"))
# # th = [
# #     "human(a1)",
# #     "dog(a2)",
# #     "human(X) -> legal_liable(X)",
# #     "dog(Y) -> -legal_liable(Y)",
# #     # "legal_liable(a1)",
# # ]
