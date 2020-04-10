-- Provide the interactive tactics
import tactic.rewrite_search.interactive

-- We include the shipped library of strategies, metrics, and tracers
import tactic.rewrite_search.strategy
import tactic.rewrite_search.metric
import tactic.rewrite_search.tracer

/-!
# Searching for chains of rewrites

`rewrite_search` is a tactic that attempts to rewrite
the lhs and rhs of an equation or iff so that they become more similar.

In this comment we will provide an overview of the code
and pointers to more specific documentation.

TODO: write this documentation.

-/
