/*
* Typst template provided by Giovanni Grandi and adjusted by Daniël Ravensbergen.
*/

#import "@preview/finite:0.5.1": automaton

#let appendix(body) = {
  set heading(numbering: "A.1.1", supplement: [Appendix])
  counter(heading).update(0)
  body
}

#let exampleCounter = counter("example")
#let example(it) = [
  #set par(first-line-indent: 0em, spacing: 1.3em)
  #exampleCounter.step()
  *Example #context exampleCounter.display():*
  #it #h(1fr) $ballot$
]

#set page(
  paper: "a4",
  numbering: "1",
  margin: 3cm,
)

#set text(font: "New Computer Modern", lang: "en", size: 11pt)

#set document(
  title: [],
  author: (("Daniël Ravensbergen"), ("Emir Demirović"), ("Imko Marijnissen")),
  description: "tbd",
)

#set heading(numbering: "1.1")

#[
  #set page(numbering: none)
  #[
    #show: align.with(center)
    #image(
      "./tu_delft_logo.svg",
      alt: "TU Delft logo",
      height: auto,
      width: 10cm,
    )
    #title("Propagating regular counting with lazy clause generation")

    #text(size: 14pt, weight: "semibold", "When DFAs with a counter offer an advantage")

    #v(1cm)
    #[
      #set text(weight: "semibold", size: 14pt)
      #context document.author.at(0)#super[1] \
      Supervisors: #context document.author.at(1)#super[1], #context document.author.at(2)#super[1]

      #[
        #set text(weight: "regular")
        #super[1]EEMCS, Delft University of Technology, The Netherlands]
    ]

    #v(1.5cm)
    A Thesis Submitted to EEMCS Faculty Delft University of Technology,\
    In Partial Fulfilment of the Requirements\
    For the Bachelor of Computer Science and Engineering\
    #datetime.today().display("[month repr:long] [day] [year]") \

    #v(2cm)

  ]
  #[
    #set text(size: 9pt)
    Name of the student: #context document.author.at(0)\
    Final project course: CSE3000 Research Project\
    Thesis committee: Emir Demirović, Imko Marijnissen, \<Examiner>\
  ]
  #v(2cm)
  #set text(size: 10pt)
  #align(center)[
    An electronic version of this thesis is available at http://repository.tudelft.nl/.
  ]
]

#pagebreak()
#counter(page).update(1)
#set par(justify: true, first-line-indent: 1em, spacing: 0.65em)
#show figure: set block(spacing: 1cm)
#show figure.caption: c => [
  #text(weight: "bold")[
    #c.supplement #c.counter.display(c.numbering)#c.separator
  ]
  #c.body
]
#[
  #show heading: it => align(center, it)
  #show par: it => block(inset: (left: 1cm, right: 1cm), it)
  #set heading(numbering: none)
  = Abstract
  cDFAs offer a more natural encoding of counting regular patterns---a prevalent problem in timetabling and sequencing---than widely-used DFAs. A cDFA-based propagator for finite domain constraint solving has been shown to propagate more than the decomposition of a cDFA-based regular constraint. This paper extends that algorithm with explanations for lazy clause generation and shows that it is more efficient[briefly elaborate how] to model combinatorial problems with cDFA over DFA when [insert conditions of the cDFA].
/*
  The aim of this template is to make it more clear what is expected from you.
  #strong[ It is by no means required to follow this exact same structure. ]
  The abstract should be short and give the overall idea:
  what is the background, the research questions, what are your contributions, and what are the main conclusions.
  It should be readable as a stand-alone text (preferably no references to the paper or to outside literature).
*/
]

= Introduction
/*
+ Introduce the topic and explain why it is important (motivation!). //\emph{How should a scientific paper look like?}
+ Relate to the most relevant existing work from the literature (use BibTeX), explain their contributions, and (critically) indicate what is still unanswered.
//\emph{The existing state of the art describes the setup of general scientific papers, e.g.\ see~\cite{hengl2002rules}, but this may be different for computer science papers.}
+ Explain what the research questions for this work are.
  This usually is a subset of the unanswered questions. //\emph{The aim of this work is therefore to provide a good template specifically for papers in the field of computer science.}
+ Summarize the main contributions/conclusions of this research.
  NB: Make sure the title of the paper is a good match to the main research question / contribution / conclusion.
+ Briefly indicate how the rest of the paper fits together to answer the research question(s).

For a longer research paper, a section with a more elaborate discussion of the literature may follow, but for short (conference) submissions, this is often included in the introduction.

Make sure the introduction and conclusion are easily understandable by everyone with a computer science bachelor (e.g. your examiner may have a completely different expertise).
*/
Constraint programming (CP) is a paradigm for solving finite domain combinatorial satisfaction and optimization problems. These problems are often NP-Hard, meaning they require backtracking in the search space. CP allows for the pruning of unvisited branches of the search space. It does this by propagating constraints a solution needs to satisfy. One of these constraints is the regular constraint. It is satisfied when its input is in a given regular language.

Regular counting is a feature of regular languages that specifies how many times a pattern is allowed to occur. It is well known as the regular expression operation ${n}$. According to Chapman and Stolee@chapman_exploring_2016 regular counting using regex is used in 20% of 1204 python projects@hu_efficient_2025. Regular counting is useful for constraining a variety of problems such as sequencing and timetabling@beldiceanu_propagating_2013 where you want to specify the number of occurrences of patterns.

Regular counting can be modeled for CP with the aforementioned regular constraints, which are often based on deterministic finite automaton (DFA). However, Beldiceanu et al.@beldiceanu_deriving_2004@beldiceanu_propagating_2013 show that a dedicated constraint based on a counter-DFA (cDFA) is not only more straight-forward to model regular counting with, but also more efficient, as it prunes more branches, providing significant speed-up of computation. Even though they provide an algorithm for exact regular counting that is only bounds consistent@beldiceanu_propagating_2013, they show that it prunes more than earlier propagators.

Up to now, this algorithm had not been implemented with explanations for Lazy Clause Generation (LCG)---a newer technology in the field of CP. It was also not clear for what sizes of cDFA it is beneficial to use this constraint over the readily available DFA-based regular constraints.

This paper presents the first cDFA based regular counting constraint with explanations. To this end we showcase the explanations for propagating the count and variables in the input sequence and provide an exponential time algorithm for inference checking. In addition, we analyze the performance of our constraint compared to two DFA-based regular constraints propagated respectively with decomposition and Gvosdiovas et al.$quote.r.single$s@gvozdiovas_nfa_2025 LCG implementation of Pesant's@pesant_regular_2004 propagator to show that it is beneficial to use our propagator when [Insert properties of cDFA]. We show why nonograms are a bad benchmark for this purpose and that generation of random cDFAs and equivalent DFAs is a good one.

[Insert additional relevant results]

@preliminaries provides the background knowledge our research was based on, explaining CP and LCG, defining the used finite automata and explaining Beldiceanu et al.$quote.r.single$s algorithm. @related_work discusses the history of the field of CP and how it relates to our contributions. @contributions presents how we provide explanations for LCG and our approach to benchmarking. @results elaborates on how the experiments were run and showcases the compiled data. @responsible_research discusses considerations with regards to ethics and the reproducibility of our research. @conclusion summarizes our contributions, highlighting unexplored avenues of research.

= Preliminaries <preliminaries>
This section explains the following topics relevant to our research: constraint programming in @cp, lazy clause generation in @lcg, DFA and cDFA in @fa and the cDFA-based constraint in @cdfa_constraint.

== Constraint Programming <cp>
Constraint programming (CP) is a paradigm in which combinatorial problems are modeled with decision variables and constraints that need to be satisfied.

In this field, finite domain (FD) CP is one of the biggest subdomains. FD constraint solvers are programs that can solve FD combinatorial #strong[satisfaction] and #strong[optimization] problems, which respectively ask for _any_ solution and a solution that _optimizes_ a given metric. FD constraint solvers are able to prune branches of the search space without solutions, without entering them.
They do this by deducing which assignments of the variables prevent the constraints from being satisfied, or in other terms results in a conflict.
This can often lead to a sizable decrease in the search space compared to a brute-force approach.

The algorithms that make such deductions are called #strong[propagators], pruning based on a propagator's deduction #strong[propagating] a constraint, and a single results of propagating a #strong[propagation]. A proper propagator should never prune solutions.

There are two approaches to propagating a constraint. One is to use an algorithm designed for that specific constraint. The other is to decompose the constraint into many _simpler_ constraints with _simpler_ propagators. When deciding which algorithm or decomposition to use, it is worth considering the trade-off between strength---_how many_ propagations are applied and _how useful_ are they---and speed---_how fast_ are propagations computed.

Two relevant concepts that apply to propagators are #strong[bounds consistency] and #strong[domain consistency].
A propagator is #strong[bounds consistent] when, if you apply it sequentially, it doesn't propagate on the _bounds_ of the domain more than once; it has made all the deductions it can regarding the bounds.
A propagator is #strong[domain consistent] when, if you apply it sequentially, it doesn't propagate on the domain more than once; it has made all the deductions it can.

== Lazy Clause Generation <lcg>

Lazy clause generation (LCG) is an extension to FD constraint solvers based on solvers from the subdomain of Boolean CP: satisfiability-solvers (SAT-solvers).
SAT-solvers are able to solve Boolean satisfiability problems; given a set of variables and a set of Boolean clauses, they find an assignments of the variables that makes all clauses true.
SAT-solvers are able to make use of #strong[conflict learning], something FD constraint solvers can not do. When a conflict occurs, they can deduce which decisions resulted in that conflict from the clauses in an implication graph. The negation of the clause that represents that decision---also referred to as a #strong[nogood]---is then added as a new constraint. This is especially useful for searching large domains.

LCG adds advantages of SAT-solvers---like #strong[conflict learning]---to FD constraint solvers. It does this by making propagations provide Boolean clauses for both the reason for propagation and the propagation itself. This combination of reason and propagation is called an #strong[explanation]. Generally, the _shorter_ the #strong[explanation], the more useful it is, as the more clauses you add to the reason, the less generalizable it is to the rest of the search space. Because of this, LCG is known to often learn more from decomposition into smaller constraints, compared to more complex propagators@feydy_lazy_2009.

To ensure the correctness of #strong[explanations], it is good practice to implement an #strong[inference checker] for a propagation. When solving a problem with an #strong[inference checker] enabled, it will verify each #strong[explanation]. It does this by applying each clause of an #strong[explanation]'s reason and the negation of its propagation, after which the constraint should no longer be satisfied if the #strong[explanation] was correct. Because this introduces overhead, #strong[inference checkers] are generally not enabled by default.

 // and thus is more efficient at traversing large search spaces@ohrimenko_propagation_2009.
//Pumpkin makes use of an inference checker to make sure that a given explanation for a given propagation is correct. It does this
== Finite Automata <fa>
=== DFA
Recall that a deterministic finite automaton (DFA) is a finite automaton that recognizes regular languages. It is defined by the five-tuple@sipser_formal_2013:\
$
chevron.l Q, Sigma, delta, q_0, F chevron.r
$
Where:\
+ $Q$ is a finite set called the _states_;
+ $Sigma$ is a finite set called the _alphabet_;
+ $delta: Q times Sigma -> Q$ is the _transition function_;
+ $q_0 in Q$ is the _initial state_;
+ $F subset.eq Q$ is the _set of accept states_.
\
#figure(
  automaton(
    (
      q0: (q0: 1, q1: 0),
      q1: (q1: 0, q2: 1),
      q2: (q2: (0, 1)),
    ),
    initial: "q0",
    final: ("q2"),
    layout: (
      q0: (0, 0),
      q1: (rel: (3, 0)),
      q2: (rel: ()),
    ),
    style: (
      q0: (initial: (label: "")),
    ),
  ),
  caption: [DFA that accepts the sequence "01"],
) <example-dfa>

Given a finite sequence $X$, where for each $x_i in X: x_i in Sigma$, a DFA accepts $X$ iff it is in an accepting state after consuming $X$. That is: starting in $q_0$ ($q <- q_0$), for each $x_i in X$ in order, go from one state to the next, according to $delta$;\
$
q' = delta""(q, x_i): q <- q'
$

#example[
  Consider the DFA in @example-dfa. When given the string "01", it will visit the following states in order: $q_0 -> q_1 -> q_2$. The final state it ends up in is $q_2$, which is an accept state; the DFA accepts.
]

=== cDFA
Beldiceanu et al.@beldiceanu_propagating_2013 describes a subclass of counter-DFAs (cDFA). When referring to cDFAs in this paper, we mean this specific subclass. It is similar to a DFA, but differs in two aspects: It only has accepting states; it has a singular counter that is initialized to zero and increments on certain transitions. In this paper it is defined by the five-tuple:\
$
chevron.l Q, Sigma, delta, q_0, K chevron.r
$
Where:\
+ $Q$ is a finite set called the _states_;
+ $Sigma$ is a finite set called the _alphabet_;
+ $delta: Q times Sigma -> Q times NN$ is the _transition function_;
+ $q_0 in Q$ is the _initial state_;
+ $K subset.eq NN$ is the _set of accepted counts_.
\
#figure(
  automaton(
    (
      q0: (q0: 1, q1: 0),
      q1: (q1: 0, q2: ("1{k\u{2190}k+1}")),
      q2: (q2: (0, 1)),
    ),
    initial: "q0",
    final: ("q0", "q1", "q2"),
    layout: (
      q0: (0, 0),
      q1: (rel: (3, 0)),
      q2: (rel: ()),
    ),
    style: (
      q0: (initial: (label: "{k\u{2190}0}")),
    ),
  ),
  caption: [cDFA with $K = {1}$ that accepts the sequence "01"],
) <example-cdfa>

Given a finite sequence $X$, where for each $x_i in X "s.t." x_i in Sigma$, a DFA accepts $X$ iff its counter has an accepting count after consuming $X$. That is: starting in $q_0$ ($q <- q_0$), with counter $k$ initialized to zero ($k <- 0$), for each $x_i in X$ in order, go from one state to the next and increment $k$ with the count of the transition, according to $delta$;\
$
chevron.l q', italic("inc") chevron.r = delta""(q, x_i): q <- q', k <- k + italic("inc")
$
For ease of notation, when $delta""(q, cal(l)) = chevron.l q', italic("inc") chevron.r : delta_Q""(q, cal(l)) = q' "and" delta_NN""(q, cal(l)) = italic("inc") $

#example[
  Consider the cDFA in @example-cdfa. When given the string "01", it will visit the following states in order: $q_0 -> q_1 -> q_2$. It increments by one when going from $q_1$ to $q_2$. The final count is one, which is an accepted count; the cDFA accepts.
]


== cDFA based constraint <cdfa_constraint>
=== Definition
The cDFA-based regular counting constraint is defined as:\
$
"regular_cDFA"(X, A, italic("count"))
$
where:\
- $italic("dom")(italic("var"))$ is the domain of variable _var_;
- $X$ is a sequence of variables $x_1 ... x_n$, $italic("dom")(x_i) subset.eq Sigma$;
- $A$ is a cDFA;
- $italic("count")$ is a variable, with $italic("dom")(italic("count"))$ as the set of accepting counts of A;
The constraint is satisfied when $A$ counts to _count_ when consuming sequence $X$.

=== Propagating the cDFA based constraint
To explain the propagation proposed by@beldiceanu_propagating_2013 we need to start by defining the following functions:
- $"QCF"(i)$: The set of pairs $chevron.l q, c chevron.r$, where $c$ is the set of possible counter increases when the cDFA consumes a sequence of length $i$, starting in the starting state and ending in state $q$---the possible counter increases $c$ to reach state $q$ in $i$ transitions.
- $"QCB"(i)$: The set of pairs $chevron.l q, c chevron.r$, where $c$ is the set of possible counter increases after visiting state $q$ after exactly $n-i$ transitions when the cDFA consumes a sequence of length $n$, starting in the starting state and ending in some other state---the possible counter increases $c$ to reach a final state from state $q$ in $i$ transitions.
- $underline("QCF")(i)$ (and $overline("QCF")(i)$): The set of pairs $chevron.l q, c chevron.r$, where $c$ is the minimum (maximum) counter increase to reach state $q$.
- $underline("QCB")(i)$ (and $overline("QCB")(i)$): The set of pairs $chevron.l q, c chevron.r$, where $c$ is the minimum (maximum) counter increase to reach a final state from state $q$.

For polynomial time algorithms for $underline("QCF")(i)$, $overline("QCF")(i)$, $underline("QCB")(i)$ and $overline("QCB")(i)$, see @math-definitions.

#figure(
  automaton(
    (
      q0: (q0: 1, q1: 0, q2: 2),
      q1: (q1: 0, q2: ("1{k\u{2190}k+1}"), q3: "2{k\u{2190}k+1}"),
      q2: (q1: 2, q2: (0, 1)),
      q3: (q0: "2{k\u{2190}k+2}", q2: (0, 1)),

    ),
    initial: "q0",
    final: ("q0", "q1", "q2", "q3"),
    layout: (
      q0: (0, 0),
      q1: (rel: (0, 4)),
      q2: (rel: (4, 0)),
      q3: (rel: (0, -4)),
    ),
    style: (
      q0: (initial: (label: "{k\u{2190}0}")),
      q0-q0: (anchor: bottom),
      q2-q1: (curve: 0),
      q1-q3: (curve: -.5, label: (pos: .3)),
      q0-q2: (curve: -.5, label: (pos: .1)),
      q3-q2: (curve: -1, label: (dist: -.33)),
    ),
  ),
  caption: [cDFA with $Sigma = {0, 1, 2} $ and $K = {2, 3, 4}$],
) <cdfa-for-propagation>

#example[
  We will demonstrate the behaviour of $"QCF"(i)$.
  Consider the cDFA in @cdfa-for-propagation. Given an arbitrary sequence $X$ of $n=4$ variables with $Sigma$ as domain, we have:
  $
  &"QCF"(0) &&= {chevron.l q_0, {0} chevron.r}\
  &"QCF"(1) &&= {chevron.l q_0, {0} chevron.r, chevron.l q_1, {0} chevron.r, chevron.l q_2, {0} chevron.r}\
  &"QCF"(2) &&= {chevron.l q_0, {0} chevron.r, chevron.l q_1, {0} chevron.r, chevron.l q_2, {0, 1} chevron.r, chevron.l q_3, {1} chevron.r}\
  &"QCF"(3) &&= {chevron.l q_0, {0, 3} chevron.r, chevron.l q_1, {0, 1} chevron.r, chevron.l q_2, {0, 1} chevron.r, chevron.l q_3, {1} chevron.r}\
  &"QCF"(4) &&= {chevron.l q_0, {0, 3} chevron.r, chevron.l q_1, {0, 1, 3} chevron.r, chevron.l q_2, {0, 1, 2, 3} chevron.r, chevron.l q_3, {1, 2} chevron.r}
$
]

#example[
  We will demonstrate the behaviour of $"QCB"(i)$.
  Consider the cDFA in @cdfa-for-propagation. Given an arbitrary sequence $X$ of $n=4$ variables with $Sigma$ as domain, we have:
  $
  &"QCB"(5) &&= {chevron.l q_0, {0} chevron.r, chevron.l q_1, {0} chevron.r, chevron.l q_2, {0} chevron.r, chevron.l q_3, {0} chevron.r}\
  &"QCB"(4) &&= {chevron.l q_0, {0} chevron.r, chevron.l q_1, {0, 1} chevron.r, chevron.l q_2, {0} chevron.r, chevron.l q_3, {0, 2} chevron.r}\
  &"QCB"(3) &&= {chevron.l q_0, {0, 1} chevron.r, chevron.l q_1, {0, 1, 3} chevron.r, chevron.l q_2, {0, 1} chevron.r, chevron.l q_3, {0, 2} chevron.r}\
  &"QCB"(2) &&= {chevron.l q_0, {0, 1, 3} chevron.r, chevron.l q_1, {0, 1, 2, 3} chevron.r, chevron.l q_2, {0, 1, 3} chevron.r, chevron.l q_3, {0, 1, 2, 3} chevron.r}\
  &"QCB"(1) &&= {chevron.l q_0, {0, 1, 2, 3} chevron.r, chevron.l q_1, {0, 1, 2, 3, 4} chevron.r, chevron.l q_2, {0, 1, 2, 3} chevron.r, chevron.l q_3, {0, 1, 2, 3, 5} chevron.r}\
$
]

Propagation on the bounds of $italic("count")$ can be implemented as:
$
italic("count") gt.eq &italic("min")(c) &| chevron.l q, c chevron.r in underline("QCF")(n)\

italic("count") lt.eq &italic("max")(c) &| chevron.l q, c chevron.r in overline("QCF")(n)\
$

#example[
  We will show a propagation on the upper bound of $italic("count")$.
  Consider the cDFA with $K={2, 3, 4}$ in @cdfa-for-propagation. Given an arbitrary sequence $X$ of $n=4$ variables with $Sigma$ as domain, we have:
  + $overline("QCF")(4) &&= {chevron.l q_0, {3} chevron.r, chevron.l q_1, {3} chevron.r, chevron.l q_2, {3} chevron.r, chevron.l q_3, {2} chevron.r}$
  + $italic("max")(c) = 3$
  + $italic("count") lt.eq 3$
  + $italic("dom")(italic("count")) = {2, 3}$
]

To implement propagation for variables in $X$, a value $cal(l)$ is removed from the domain of $x_i$ iff:\

$
forall q cases(delim: "|", vec(delim: "[",
chevron.l q\, underline(c) chevron.r in underline("QCF")(i - 1),
chevron.l q\, overline(c) chevron.r in overline("QCF")(i - 1),
chevron.l q'\, italic("inc") chevron.r = delta""(q, cal(l)),
chevron.l q'\, underline(c') chevron.r in underline("QCB")(i + 1),
chevron.l q'\, overline(c') chevron.r in overline("QCB")(i + 1)
))
:[underline(c) + italic("inc") + underline(c'), overline(c) + italic("inc") + overline(c')] inter italic("dom")(italic("count")) = emptyset\
$

#example[
  We will show how to derive the propagation $x_3 eq.not 2$.
  Consider the cDFA in @cdfa-for-propagation, but now with  with $K={4, 5, 6}$. For each state we have listed the ranges\
  $[underline(c) + italic("inc") + underline(c'), overline(c) + italic("inc") + overline(c')]$:
  $
  q_0:[0 + 0 + 0, 0 + 0 + 0] = [0, 0]\
  q_1:[0 + 1 + 0, 0 + 1 + 2] = [1, 3]\
  q_2:[0 + 0 + 0, 1 + 0 + 1] = [0, 2]\
  q_3:[1 + 2 + 0, 1 + 2 + 0] = [3, 3]\
  $
  The intersection of each range with $italic("dom")(italic("count"))$ is $emptyset$, thus $x_3 eq.not 2$.
  ]

// = Methodology, Background, Problem Description
/*
Choose one that fits your research best:
== Methodology and/or background
Typically in general research articles, the second section contains a description of the research methodology, explaining what you, the researcher, is doing to answer the research question(s), and why you have chosen this method.
For purely analytical work this is a description of the data collection or experimental setup on how to test the hypothesis, with a motivation.

In any case this section includes references to necessary background information.
For a survey paper this includes the method of how you arrived at the set of papers included in the survey.

== Formal Problem Description
For some types of work in computer science the methodology is standard: analyze the problem (e.g., make assumptions and derive properties), present a new algorithm and its theoretical background, proving its correctness, and evaluate unproven aspects in simulation.
Then an explanation of the methodology is often omitted, and the setup of the evaluation is part of a later section on the evaluation of the ideas.#footnote[This already shows that there is no single outline to be given for all papers.]
In this case, explain relevant (background) concepts, theory and models in this section (with references) and relate them to your research question.
Also this section then typically contains a more precise, formal description of the problem.

Do not forget to give this section another name, for example after the problem you are solving.
*/

= Related work <related_work>

// Constraint solving was originally proposed by Lauriere@lauriere_language_1978, as an approach to solve combinatorial problems. Later, Jaffar and Lassez@jaffar_constraint_1987 coined constraint logic programming as an extension. One of its capabilities was finite domain (FD) constraint solving. It improved the ease of modeling combinatorial problems.
//
// Lazy clause generation (LCG) was proposed by Ohrimenko et al.@ohrimenko_propagation_2007. It implemented FD propagation in a SAT-solver, effectively combining the advantages of FD constraint solving and SAT-solving. LCG was then re-engineered by Feydy and Stuckey@feydy_lazy_2009, by implementing a SAT-solver as a propagator inside a FD solver and having other propagators generate explanations to populate it with. It proved more efficient for large search spaces and boosted the performance of decomposition into global constraints, as FD constraint solvers extended with LCG can make use of conflict-learning.

The DFA based regular constraint and an accompanying domain consistent propagator were originally proposed by Pesant@pesant_regular_2004. Gvosdiovas et al.@gvozdiovas_nfa_2025 recently created a version of Pesant's propagator with explanations for LCG and extended it to work with non-deterministic finite automata (NFA). As we also extend a propagator with explanations for LCG, this research was influential in how we approached our research. A comparison between their NFA-based constraint and our cDFA-based constraint does not seem useful to us, as we can't think of ways that non-determinism provides significant advantages for regular counting.

Using cDFAs for regular counting was originally proposed by Beldiceanu et al.@beldiceanu_deriving_2004, as the use of a counter allows for a simpler representation to count regular patterns opposed to normal DFAs. Later, Beldiceanu et al.@beldiceanu_propagating_2013 proposed propagators for "at least", "at most" and "exact" counting of regular patterns using cDFAs, that are domain consistent on the input sequence. Their "at most" and "at least" propagators were shown to also be domain consistent on the count, whereas their "exact" propagator only provides bounds consistency. They further proved that computing satisfiability for their "exact" constraint is NP-Hard.

Although they show that their propagators prune more than decomposition of a DFA-based regular constraint, they only show this for FD constraint solving _without_ LCG. This poses the question if that is still the case when implemented _with_ LCG, which can benefit from decomposition. Another question left unanswered is for what sizes of cDFA it offers an significant advantage to model problems with them. Our research answers these questions.

Martin and Pearson@martin_when_2022 provided an algorithm that decides when bounds consistency implies domain consistency for a given cDFA. This also analyzes when cDFAs are more efficient, but does so by analyzing their structure in stead of their size and provides no comparison with DFAs.

The cost-regular constraint proposed by Demassey et al.@demassey_cost-regular_2006 has many similarities---both accumulate values when taking transitions in finite automata and compare the accumulation to a variable---to the regular counting constraint proposed by Beldiceanu et al.@beldiceanu_propagating_2013, but propagates less and has asymptotically worse space complexity. No comparison of these two propagators extended with explanations for LCG has also not been done as well, but due to the limited scope of our research, we left this untouched.

= Propagating regular_cDFA with explanations <contributions>
This section showcases our contributions. @explanations showcases our explanations for propagating and the accompanying inference checker, and @benchmarks describes the approach to compare the constraints.

== Explanations <explanations>
These explanations are directly based on the propagations from Beldiceanu et al.@beldiceanu_propagating_2013. As such, they are trivial, but lay the groundwork for future improvements.

=== The count
The propagation clause for _count_ is always an update to the bounds of the domain:\
$
[italic("count") gt.eq italic("value")] "or" [italic("count") lt.eq italic("value")]
$
The clauses making up the reason for propagating on _count_ represent the domains of the variables in $X$. All $c in italic("dom")(italic("count"))$ are independent from each other.

=== The input sequence
The propagation clauses for the variables in $X$ are unit clauses for each value that is impossible:\
$
[x_i eq.not italic("value")]
$ 
The clauses making up the reason for propagating on $x_i$ represent the domains of the variables in $X$ and the set of clauses for _count_ that describe
$
union.big {italic("dom")(italic("count")) inter [underline(c) + italic("inc") + underline(c'), overline(c) + italic("inc") + overline(c')] |
cases(delim: "|", forall q cases(delim: "|", vec(delim: "[",
chevron.l q\, underline(c) chevron.r in underline("QCF")(i - 1),
chevron.l q\, overline(c) chevron.r in overline("QCF")(i - 1),
chevron.l q'\, italic("inc") chevron.r = delta""(q, cal(l)),
chevron.l q'\, underline(c') chevron.r in underline("QCB")(i + 1),
chevron.l q'\, overline(c') chevron.r in overline("QCB")(i + 1)
)))}
$

=== Inference checker
When implementing an inference checker for $"regular_cDFA"(X, A, italic("count"))$, there is one unfortunate fact; computing satisfaction for regular_cDFA is an NP-Hard problem, as Beldiceanu et al.@beldiceanu_propagating_2013 have proven by reduction from SAT. This means that it is hard to calculate if the constraint is still satisfied. We have nonetheless implemented an algorithm and were able to verify our explanation for small instances using it. Bigger instances quickly lead to the program not completing.

Our inference checker first computes the set of all possible counts after consuming $X$, $"QCF"(n)$, given the explanation. It then checks if there exists a $c in italic("dom")(italic("count"))$, such that $c in "QCF"(n)$. If that is the case, the constraint is still satisfied.

== Benchmarks <benchmarks>
In an attempt to show when our cDFA-based propagator offers advantages over DFA based ones, we considered two benchmarks. Our initial plan was based on modelling nonograms, but this proved impractical. We decided to elaborate on why nonograms are a poor problem to model with cDFAs, to helps future research avoid this approach and give insight into what types of problems are unlikely to benefit from being modeled with cDFA. We also explain why generating random cDFAs and equivalent DFAs is a good benchmark.
//The performance of the regular_cDFA constraint, the DFA-based regular constraint and its decomposition were benchmarked.
// Performance was assessed based on runtime, conflicts, propagations and amount of states of the finite automata.

=== Nonograms
Nonograms are well-known puzzles. See @nonogram for an example. They consist of an empty grid, where each row and column has a "hint"---a list of numbers---that corresponds to what squares in the row or column can be filled. Each number $n$ in the hint corresponds to a subsequence of $n$ filled in squares; the subsequences occur in order; subsequences are separated by at least one empty square.

#figure(
  [WIP],
  caption: [An example of a nonogram]
)<nonogram>

As this problem relies on patterns that count, it seems like a good fit to model with cDFAs. And yes, it is possible to model the hints for the rows and columns with regular counting; a given hint $[k, m, n]$ can be modeled by the regular expression "$0^* 1{k} 0⁺ 1{m} 0^+ 1{n} 0^*$". There are two problems when modeling with cDFAs however.

First of all, the count of a subsequence is always a fixed value, whereas regular_cDFA is able to propagate on the count. This means modeling nonograms does not exploit an advantage of cDFA.

Second of all, there are multiple patterns that are counted. This poses the biggest problem. cDFAs only have one counter. As such, nonograms can not be trivially modeled using cDFAs in a way that results in a smaller encoding than when modeled with a DFA.

There is one approach however. If a cDFA increments by at most one, the maximum count after consuming a sequence of $n$ values is $n$. To implement a second counter, whose count can be distinguished from the first, edges incrementing by $n+1$ can thus be used. An accepting count can then be encoded as:
$
1 dot italic("count"_1)+(n+1) dot italic("count"_2)
$
This can be generalized for $k$ counters as:
$
sum_(i=1)^k (n+1)^(i-1) dot italic("count"_i)
$
Note that this essentially represents each count as a digit in a base $n+1$ number. See @nonogram-automata for examples of each approach.

#figure(
  grid(columns: 3, row-gutter: 2mm, column-gutter: 1mm,

    block[WIP], block[WIP], block[WIP],

  "a) Trivial cDFA", "b) Encoded cDFA", "c) DFA"),
  caption: [Three ways to represent the hint [2, 3]]
)<nonogram-automata>

This introduces a new problem however: The accepting count grows exponentially proportional to the amount of encoded counts. For small nonograms, this is no issue, as they have small sequences and consequently a small amount of numbers per hint. As nonograms grow in size however, so do their sequences and consequently the amount of numbers per hint. For a 30x30 nonogram, that thus has sequences of length 30, it is not uncommon to see hints with seven or more numbers. As $31^7 gt 2^32$, the accepting counts used to model larger nonograms are unable to be represented by either signed or unsigned 32-bit integers.

These two factors---having a single count per sequence and exponential blowup of the accepted count---make it impractical to pursue this problem as a benchmark.
// _
// Figured out that the way I was doing this resulted in counts bigger than what can be stored in a i32, so it will not work. I will have to create other benchmarks.
// _

=== Random equivalent constraints
We decided to use randomly generated equivalent DFA and cDFA to benchmark. This will allow us to benchmark cDFAs in general in stead of ones used to model a specific problem.
Additionally, this tackles both issues with the nonogram approach by generating finite automata (FA) that count only one pattern and have multiple accepting counts. We achieve this in the following three steps:
+ We first construct a random intermediate FA.
+ We convert the intermediate FA to a cDFA.
+ We use the intermediate FA to construct a DFA that is equivalent to the generated cDFA, that is then minimized.

To work with the DFA and to minimize the equivalent DFA, the python library FAdo#footnote[https://fado.dcc.fc.up.pt/]<fado> was used.

==== Constructing the intermediate finite automaton
A finite automaton with $n+1$ states and only one accepting state---where $n$ is the amount of states our resulting cDFA will end up with---is generated randomly. See @intermediate-fa.
This is done in a way that a random Hamiltonian path---marked with red for illustration---from the starting state to the accept state exists, to guarantee that the resulting automata accept some sequences. The accept state is incomplete; it does not have any outgoing edges. A set of accepting counts $K$ is defined.

#figure(
  automaton(
    (
      q0: (q1: 1, q2: 0),
      q1: (q2: 0, q0: 1),
      q2: (),
    ),
    initial: "q0",
    final: ("q2"),
    layout: (
      q0: (0, 0),
      q1: (rel: (2, 2)),
      q2: (rel: (2, -2)),
    ),
    style: (
      q0: (initial: (label: "")),
      q0-q2: (curve: 0),
      q0-q1: (curve: .3, stroke: red),
      q1-q0: (curve: .3),
      q1-q2: (curve: .3, stroke: red),
    ),
  ),
  caption: [Intermediate finite automaton, $K={1, 3}$],
) <intermediate-fa>

==== Constructing the cDFA
The ingoing edges to the accept state of the intermediate DFA are marked as incrementing by one. The accept state is merged with the starting state. All states are made accepting.

#figure(
  automaton(
    (
      q2: (),
      q0: (q1: 1, q2: "0{k\u{2190}k+1}"),
      q1: (q2: "0{k\u{2190}k+1}", q0: 1),
    ),
    initial: "q0",
    final: ("q0", "q1","q2"),
    layout: (
      q2: (0, 0),
      q0: (0, 0),
      q1: (rel: (4, 0)),
    ),
    style: (
      q0: (initial: (label: "{k\u{2190}0}")),
      q0-q2: (curve: 0),
      q0-q1: (curve: 1, stroke: red),
      q1-q0: (curve: 0),
      q1-q2: (curve: 1, stroke: red),
    ),
  ),
  caption: [Constructed cDFA, $K={1, 3}$],
) <constructed-cdfa>

==== Constructing the equivalent DFA
From the intermediate DFA $italic("max")(K) + 1$ copies are made.
$
{ italic("copy"_i) | i in 0, 1, ..., italic("max")(K)}
$
Each accepting state of $italic("copy"_i)$ is merged with the starting state of $italic("copy"_(i+1))$ , essentially concatenating the pattern $italic("max")(K) + 1$ times.
The final incomplete state is made into a rejecting trap-state. States corresponding to the rejecting states of $italic("copy"_i)$ are accepting iff $i in K$. See @equivalent-dfa. The resulting DFA is then minimized with Hopcroft's method using FAdo@fado.

#figure(
  automaton(
    (
      q00: (q01: 1, q02: 0),
      q01: (q02: 0, q00: 1),
      q02: (),
      q10: (q11: 1, q12: 0),
      q11: (q12: 0, q10: 1),
      q12: (),
      q20: (q21: 1, q22: 0),
      q21: (q22: 0, q20: 1),
      q22: (),
      q30: (q31: 1, q32: 0),
      q31: (q32: 0, q30: 1),
      q32: (q32: (0, 1)),

    ),
    initial: "q00",
    final: ("q10", "q11", "q30", "q31"),
    layout: (
      q00: (0, 0),
      q01: (rel: (2, 2)),
      q02: (rel: (2, -2)),
      q10: (rel: (0, 0)),
      q11: (rel: (2, 2)),
      q12: (rel: (2, -2)),
      q20: (rel: (0, 0)),
      q21: (rel: (2, 2)),
      q22: (rel: (2, -2)),
      q30: (rel: (0, 0)),
      q31: (rel: (2, 2)),
      q32: (rel: (2, -2)),
    ),
    style: (
      q00: (initial: (label: "")),
      q32-q32: (anchor: top+right),
      q00-q02: (curve: 0),
      q00-q01: (curve: .3, stroke: red),
      q01-q00: (curve: .3),
      q01-q02: (curve: .3, stroke: red),
      q10-q12: (curve: 0),
      q10-q11: (curve: .3, stroke: red),
      q11-q10: (curve: .3),
      q11-q12: (curve: .3, stroke: red),
      q20-q22: (curve: 0),
      q20-q21: (curve: .3, stroke: red),
      q21-q20: (curve: .3),
      q21-q22: (curve: .3, stroke: red),
      q30-q32: (curve: 0),
      q30-q31: (curve: .3, stroke: red),
      q31-q30: (curve: .3),
      q31-q32: (curve: .3, stroke: red),
    ),
  ),
  caption: [Equivalent DFA],
) <equivalent-dfa>


/*
In computer science typically the third section contains an exposition of the main ideas, for example the development of a theory, the analysis of the problem (some proofs), a new algorithm, and potentially some theoretical analysis of the properties of the algorithm.

Do not forget to give this section another name, for example after the method or idea you are presenting.

Some more detailed suggestions for typical types of contributions in computer science are described in the following subsections.

== Experimental work
In this case, this section will mostly contain a description of the methods/algorithms you will be comparing. Although not all methods need to be described in detail (providing appropriate references are available), make sure that you reveal sufficient details to a reader not familiar with these methods to: a) obtain a high-level understanding of the method and differences between them, and b) understand your explanation of the results/conclusions.

== Improvement of an idea
In this case, you would need to explain in detail how the improvement works. If it is based on some observation that can be proven, this is a good place to provide that proof (e.g., of the correctness of your approach).

== Literature survey
If your contribution is a literature survey, then the organization of these "middle" sections very much depends on the way you want to present/organize the literature you are discussing.
First try to cluster papers that are similar in some aspect. Then think of how these clusters are related, from that you can think of a good order to discuss these clusters; this is sometimes called a bottom-up approach to writing a paper.

In addition, you may try to think about the organization of the literature from a top-down perspective: try to "take a step back" and think about the field and what important questions/variants are and build a hierarchical categorization of the field.

Make clear what your contribution is here: a new organization of the literature, identification of open problems/challenges, new parallels/generalizations, a table with pros/cons of different methods, etc.
*/

= Experimental Setup and Results <results>
Our results show that for cDFAs with [insert qualities of cDFAs], it is more effective to use the regular_cDFA constraint with our propagator than a regular constraint with Gvosdiovas et al.$quote.r.single$s@gvozdiovas_nfa_2025 propagator.

Our results show that for cDFAs with [insert qualities of cDFAs], it is more effective to use the regular_cDFA constraint with our propagator than a decomposed regular constraint with Gvosdiovas.

[Insert additional relevant result summary]
/*
As discussed earlier, in many sciences the methodology is explained in section 2 and this section only discusses the results.
However, in computer science, most often the details of the evaluation setup are described here first (simulation environment, etc.).
Very important is that any skilled reader would be able to reproduce this setup and then obtain the same results.

Then, results are reported in an accessible manner through figures (preferably with captions that allow them to be understood without going through the whole text), observations are made that clearly follow from the presented results.
Conclusions are drawn that follow logically from the previous material.
Sometimes the conclusions are in fact hypotheses, which in turn may give rise to new experiments to be validated.

You may want to give this section another name.
*/
== Setup
The regular_cDFA constraint and the DFA-based regular constraint were implemented in Pumpkin@flippo_multi-stage_2024 using Rust. The DFA-based regular constraint was adapted from the code of Gvosdiovas et al.@gvozdiovas_nfa_2025. The decomposition of the DFA-based regular constraint uses the decomposition built into Pumpkin. Minizinc[insert reference or footnote] was used to model our benchmarks using the constraints. Those models were then provided with json files describing individual instances to run, which were generated by Python scripts. Shell scripts were used to generate many instances at once. A python script was used to run all instances of a benchmark and store the results. A python script was used to aggregate, analyse and graph the data.

This approach was inspired by Gvosdivas et al.. An important change is that we opted to not parallelize the running of the instances of our benchmarks, to make sure that their solve speed was impacted as little as possible by random variables.

The benchmarks were run on a laptop with [Insert specs] running NixOS without a graphical user interface, to minimize background processes.

#figure(
  table(),
  caption: [TODO]
)<configurations>

Five randomly generated instances of our benchmark were run for 60 seconds, for each configuration of counts, alphabet size and amount of states. The different configurations can be found in @configurations. The length of the sequence of an instance equals the amount of states times the maximum count plus one. This way, there exists a sequence which counts past the maximum count.

For each configuration the following metrics were compared:
- Number of solutions;
- Average propagation per solution;
- Average nogoods per solution;
- Average learned nogood length;

== Results
[Some of my graphs, they need to be made smaller. I also still have to write for this part.]

#figure(
  image("../results_regular_counting_60s/graphs/num_solutions_vs_states_boxplot_alphabet_3_counts_1_4.png"),
  caption: []
)

#figure(
  image("../results_regular_counting_60s/graphs/avg_propagations_vs_states_boxplot_alphabet_3_counts_1_16.png"),
  caption: []
)

#figure(
  image("../results_regular_counting_60s/graphs/avg_nogoods_vs_states_boxplot_alphabet_3_counts_1_2.png"),
  caption: []
)

#figure(
  image("../results_regular_counting_60s/graphs/avg_LearnedNogoodLength_vs_states_boxplot_alphabet_3_counts_1_2.png"),
  caption: []
)


== Limitations
[TODO]

= Responsible Research <responsible_research>
/*
Reflect on the ethical aspects of your research and discuss the reproducibility of your methods.
Note that although in many published works there is no such a section (it may be part of some meta-information collected by the journal, or part of the discussion section), we require you to think (and report) about this as part of this course.
*/
== Data generation
The data we used for benchmarking was all synthetically generated by scripts. As such, its usage is unrestricted by ethical considerations. One important detail to mention however, is that FAdo@fado#[]---a python library for manipulating finite automata---falls under the GNU General Public License. As such, the python script using it to generate a random equivalent DFA and cDFA also falls under this license. The rest of our contributions fall under the MIT license.

== AI usage
LLM's---and other generative AI---have become prevalent not only in everyday life, but also in academia. However, we have opted to not use any generative AI during the course of this research, as it makes it easy to outsource thinking, which can lead to research that is less critical. This paper and our contributions have been human generated.

== Reproducibility
All our experiments and code have been version controlled since the beginning using git, and are available in our _experiment suite_#footnote[https://github.com/ICorvidusI/experiment-suite-RP-2026]<repo>.
This was done not only to allow others to check our work, but also in an effort to make any material that might be of interest for future research readily available.
Our experiment suite includes the following:
- A fork of Pumpkin, extended with the constraints used;
- Scripts to generate and run the benchmarks;
- Results of the benchmarks;
- A script to process and visualise the results.
In addition to this, all randomly generated instances were seeded and labeled with the used seed.

By using _devenv_
#footnote[https://devenv.sh/\, a tool for declarative development environments that isolates and version locks packages, based on the _nix package manager_#footnote[https://nixos.org/]]
we have tried to prevent additional setup and dependency conflicts that might otherwise have occurred when running the experiments on other machines.

= Conclusion <conclusion>
In this paper we have presented the first ever extension with explanations for lazy clause generation (LCG) of Beldiceanu et al.$quote.r.single$s@beldiceanu_propagating_2013 propagator for the exact regular counting constraint. We have shown that when [insert conditions of cDFA], our propagator provides an advantage over an equivalent DFA based regular constraint propagated with Gvosdiovas et al.$quote.r.single$s@gvozdiovas_nfa_2025 extension with explanations for lcg of Pesant's@pesant_regular_2004 propagator, and that when [insert conditions of cDFA], it provides an advantage over an equivalent DFA based regular constraint decomposed into global constraints. This informs researchers on how to solve finite domain combinatorial problems involving regular counting more effectively. [insert additional important take-aways].

In addition, we have documented two ways we have attempted to compare the aforementioned constraints. For comparing cDFAs with DFAs, we have shown the short-comings of modeling nonograms with cDFAs and the effectiveness of generating random equivalent finite automata.

//== Discussion
/*
Results can be compared to known results and placed in a broader context.
Provide a reflection on what has been concluded and how this was done.
Then give a further possible explanation of results.

You may give this section another name, or merge it with the one before or the one hereafter.
*/
//As the explanations of our propagator are trivially based on the propagation, we believe there is room to shorten them.

== Future Work
/*
Briefly summarize the (main) research question(s).
Provide your conclusions, the answers to the research question(s).
Make statements.
Highlight interesting elements, contributions.

Discuss open issues, possible improvements, and new questions that arise from this work; formulate recommendations for further research.

Ideally, this section can stand on its own: it should be readable without having read the earlier sections and accessible to anyone with a bachelor degree in Computer Science.

*/

There are multiple opportunities for future research that we would like to see explored:
- As LCG is known to learn more from simpler propagation@feydy_lazy_2009, how does decomposing exact regular counting into at-most and at-least regular counting@beldiceanu_propagating_2013#[]---extended with explanations for LCG---compare to our propagator?#footnote[A non-verified propagation for the at-most regular counting constraint can be found---commented out---in the methods of our regular_cdfa propagator.@repo]
- Similarly, how can cDFA based regular counting be decomposed into global constraints? How does this compare to other constraints?
- how does our propagator compare to the similar, but more widely used cost_regular constraint---decomposed or propagated with an extension to Demassey et al.$quote.r.single$s@demassey_cost-regular_2006 propagator---with explanations for LCG?
- Can Martin and Pearson's@martin_when_2022 algorithm---to compute when bounds consistency implies domain consistency for cDFA-based regular counting---be used to improve our propagator's speed or explanations?
- As our explanations for LCG are trivially based on the propagation, can they be shortened to provide better conflict-learning?
- Can our inference checker be optimized in any way? One approach we could see working is to prune counts of $"QCF"(i)$---see @cdfa_constraint#[]---that exceed the upper bound of the domain of $italic("count")$.

#appendix[
/*

  = Some further guidelines that go without saying (right?)

  + Read the manual for the Research Project. (See e.g.\ the instructions on the maximum length: less is more!)

  == Reference use
  + use a system for generating the bibliographic information automatically from your database, e.g., use BibTex and/or Mendeley, EndNote, Papers, or ...
  + all ideas, fragments, figures and data that have been quoted from other work have correct references
  + literal quotations have quotation marks and page numbers
  + paraphrases are not too close to the original
  + the references and bibliography meet the requirements
  + every reference in the text corresponds to an item in the bibliography and vice versa

  == Structure
  Paragraphs

  + are well-constructed
  + are not too long: each paragraph discusses one topic
  + start with clear topic sentences
  + are divided into a clear paragraph structure
  + there is a clear line of argumentation from research question to conclusions
  + scientific literature is reviewed critically

  == Style
  + correct use of English: understandable, no spelling errors, acceptable grammar, no lexical mistakes
  + the style used is objective
  + clarity: sentences are not too complicated (not too long), there is no ambiguity
  + attractiveness: sentence length is varied, active voice and passive voice are mixed

  == Tables and figures
  + all have a number and a caption
  + all are referred to at least once in the text
  + if copied, they contain a reference
  + can be interpreted on their own (e.g. by means of a legend)
*/
  #pagebreak()
= Mathematical definitions <math-definitions>
Using the following two functions to respectively keep only the tuples with the minimum and maximum cost for a given state:

$
&"trimMin"(S) &= { chevron.l q, c chevron.r in S | exists.not chevron.l q, c' chevron.r in S : c' < c}\
&"trimMax"(S) &= { chevron.l q, c chevron.r in S | exists.not chevron.l q, c' chevron.r in S : c' > c}
$
$underline("QCF")(i)$, $overline("QCF")(i)$, $underline("QCB")(i)$ and $overline("QCB")(i)$ can be implemented inductively:
$
underline("QCF")(i) &= cases(
  {chevron.l q_0, 0 chevron.r} &&&"if" i = 0,
  "trimMin"(&{ chevron.l delta_Q""(q, cal(l)), c + delta_NN""(q, cal(l)) chevron.r &| chevron.l q, c chevron.r in underline("QCF")(i - 1), cal(l) in italic("dom")(x_i)}) &"if" i in [1,n],
)\

overline("QCF")(i) &= cases(
  {chevron.l q_0, 0 chevron.r} &&&"if" i = 0,
  "trimMax"(&{ chevron.l delta_Q""(q, cal(l)), c + delta_NN""(q, cal(l)) chevron.r &| chevron.l q, c chevron.r in overline("QCF")(i - 1), cal(l) in italic("dom")(x_i)}) &"if" i in [1,n],
)\

underline("QCB")(i) &= cases(
  {chevron.l q, 0 chevron.r &&| exists c in NN : chevron.l q, c chevron.r in underline("QCB")(i) } &"if" i = n + 1,
  "trimMin"(&{ chevron.l q, c' + italic("inc") chevron.r &| chevron.l q', c' chevron.r in underline("QCB")(i + 1), cal(l) in italic("dom")(x_i), delta(q, cal(l)) = chevron.l q', italic("inc") chevron.r}) &"if" i in [1,n],
)\

overline("QCB")(i) &= cases(
  {chevron.l q, 0 chevron.r &&| exists c in NN : chevron.l q, c chevron.r in overline("QCB")(i) } &"if" i = n + 1,
  "trimMax"(&{ chevron.l q, c' + italic("inc") chevron.r &| chevron.l q', c' chevron.r in overline("QCB")(i + 1), cal(l) in italic("dom")(x_i), delta(q, cal(l)) = chevron.l q', italic("inc") chevron.r}) &"if" i in [1,n],
)\
$

]


#bibliography("./bibliography.bib", style: "ieee", title: "References")
/*
A rule of thumb for dealing with the literature is the following: scan about 10--20 contributions: read title, abstract, part of introduction and conclusions; categorize contribution; some of these are studied in more depth: completely read about 5 conference papers or equivalent (summarize contribution in own words); of which studied in-depth about 2 conference papers (the student is able to explain in detail and criticize contributions). This may result in 5--20 references, possibly even more if the project is a literature study.
*/
