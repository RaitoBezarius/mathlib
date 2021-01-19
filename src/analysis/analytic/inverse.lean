/-
Copyright (c) 2021 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel
-/
import analysis.analytic.composition

/-!

# Inverse of analytic functions

We construct the left and right inverse of a formal multilinear series with invertible linear term,
and we prove that they coincide.
-/

open_locale big_operators classical
open finset

namespace formal_multilinear_series

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{F : Type*} [normed_group F] [normed_space 𝕜 F]

/-- The left inverse of a formal multilinear series, where the `n`-th term is defined inductively
in terms of the previous ones to make sure that `(left_inv p i) ∘ p = id`. For this, the linear term
`p₁` in `p` should be invertible. In the definition, `i` is a linear isomorphism that should
coincide with `p₁`, so that one can use its inverse in the construction. The definition does not
use that `i = p₁`, but proofs that the definition is well-behaved do.

The `n`-th term in `q ∘ p` is `∑ qₖ (p_{j₁}, ..., p_{jₖ})` over `j₁ + ... + jₖ = n`. In this
expression, `qₙ` appears only once, in `qₙ (p₁, ..., p₁)`. We adjust the definition so that this
term compensates the rest of the sum, using `i⁻¹` as an inverse to `p₁`.
-/

noncomputable def left_inv (p : formal_multilinear_series 𝕜 E F) (i : E ≃L[𝕜] F) :
  formal_multilinear_series 𝕜 F E
| 0 := 0
| 1 := (continuous_multilinear_curry_fin1 𝕜 F E).symm i.symm
| (n+2) := - ∑ c : {c : composition (n+2) // c.length < n + 2},
      have (c : composition (n+2)).length < n+2 := c.2,
      (left_inv (c : composition (n+2)).length).comp_along_composition
        (p.comp_continuous_linear_map i.symm) c

/-- The left inverse to a formal multilinear series is indeed a left inverse, provided its linear
term is invertible. -/
lemma left_inv_comp (p : formal_multilinear_series 𝕜 E F) (i : E ≃L[𝕜] F)
  (h : p 1 = (continuous_multilinear_curry_fin1 𝕜 E F).symm i) :
  (left_inv p i).comp p = id 𝕜 E :=
begin
  ext n v,
  cases n,
  { simp only [left_inv, continuous_multilinear_map.zero_apply, id_apply_ne_one, ne.def,
      not_false_iff, zero_ne_one, comp_coeff_zero']},
  cases n,
  { simp only [left_inv, comp_coeff_one, h, id_apply_one, continuous_linear_equiv.coe_apply,
      continuous_linear_equiv.symm_apply_apply, continuous_multilinear_curry_fin1_symm_apply] },
  have A : (finset.univ : finset (composition (n+2)))
    = {c | composition.length c < n + 2}.to_finset ∪ {composition.ones (n+2)},
  { refine subset.antisymm (λ c hc, _) (subset_univ _),
    by_cases h : c.length < n + 2,
    { simp [h] },
    { simp [composition.eq_ones_iff_le_length.2 (not_lt.1 h)] } },
  have B : disjoint ({c | composition.length c < n + 2} : set (composition (n + 2))).to_finset
    {composition.ones (n+2)}, by simp,
  have C : (p.left_inv i (composition.ones (n + 2)).length)
    (λ (j : fin (composition.ones n.succ.succ).length), p 1 (λ k,
      v ((fin.cast_le (composition.length_le _)) j)))
    = p.left_inv i (n+2) (λ (j : fin (n+2)), p 1 (λ k, v j)),
  { apply formal_multilinear_series.congr _ (composition.ones_length _) (λ j hj1 hj2, _),
    exact formal_multilinear_series.congr _ rfl (λ k hk1 hk2, by congr) },
  have D : p.left_inv i (n+2) (λ (j : fin (n+2)), p 1 (λ k, v j)) =
    - ∑ (c : composition (n + 2)) in {c : composition (n + 2) | c.length < n + 2}.to_finset,
        (p.left_inv i c.length) (p.apply_composition c v),
  { simp only [left_inv, continuous_multilinear_map.neg_apply, neg_inj,
      continuous_multilinear_map.sum_apply],
    convert (sum_to_finset_eq_subtype (λ (c : composition (n+2)), c.length < n+2)
      (λ (c : composition (n+2)), (continuous_multilinear_map.comp_along_composition
        (p.comp_continuous_linear_map ↑(i.symm)) c (p.left_inv i c.length))
          (λ (j : fin (n + 2)), p 1 (λ (k : fin 1), v j)))).symm.trans _,
    simp only [comp_continuous_linear_map_apply_composition,
      continuous_multilinear_map.comp_along_composition_apply],
    congr,
    ext c,
    congr,
    ext k,
    simp [h] },
  simp [formal_multilinear_series.comp, show n + 2 ≠ 1, by dec_trivial, A, finset.sum_union B,
    apply_composition_ones, C, D],
end

/-- The right inverse of a formal multilinear series, where the `n`-th term is defined inductively
in terms of the previous ones to make sure that `p ∘ (right_inv p i) = id`. For this, the linear
term `p₁` in `p` should be invertible. In the definition, `i` is a linear isomorphism that should
coincide with `p₁`, so that one can use its inverse in the construction. The definition does not
use that `i = p₁`, but proofs that the definition is well-behaved do.

The `n`-th term in `p ∘ q` is `∑ pₖ (q_{j₁}, ..., q_{jₖ})` over `j₁ + ... + jₖ = n`. In this
expression, `qₙ` appears only once, in `p₁ (qₙ)`. We adjust the definition so that this
term compensates the rest of the sum, using `i⁻¹` as an inverse to `p₁`.
-/
noncomputable def right_inv (p : formal_multilinear_series 𝕜 E F) (i : E ≃L[𝕜] F) :
  formal_multilinear_series 𝕜 F E
| 0 := 0
| 1 := (continuous_multilinear_curry_fin1 𝕜 F E).symm i.symm
| (n+2) :=
    let q : formal_multilinear_series 𝕜 F E := λ k, if h : k < n + 2 then right_inv k else 0 in
    - (i.symm : F →L[𝕜] E).comp_continuous_multilinear_map ((p.comp q) (n+2))

/-- The right inverse to a formal multilinear series is indeed a right inverse, provided its linear
term is invertible and its constant term vanishes. -/
lemma right_inv_comp (p : formal_multilinear_series 𝕜 E F) (i : E ≃L[𝕜] F)
  (h : p 1 = (continuous_multilinear_curry_fin1 𝕜 E F).symm i) (h0 : p 0 = 0) :
  p.comp (right_inv p i) = id 𝕜 F :=
begin
  ext n v,
  cases n,
  { simp only [h0, continuous_multilinear_map.zero_apply, id_apply_ne_one, ne.def, not_false_iff,
      zero_ne_one, comp_coeff_zero']},
  cases n,
  { simp only [comp_coeff_one, h, right_inv, continuous_linear_equiv.apply_symm_apply, id_apply_one,
      continuous_linear_equiv.coe_apply, continuous_multilinear_curry_fin1_symm_apply] },
  have N : 0 < n+2, by dec_trivial,
  have : ∀ q : formal_multilinear_series 𝕜 F E,
    p.comp q (n + 2) v =
    ∑ (c : composition (n + 2)) in {c : composition (n + 2) | 1 < c.length}.to_finset,
      p c.length (q.apply_composition c v)
    + p 1 (λ i, q (n+2) v), sorry,
  /-{ assume q,
    have A : (finset.univ : finset (composition (n+2)))
      = {c | 1 < composition.length c}.to_finset ∪ {composition.single (n+2) N},
    { refine subset.antisymm (λ c hc, _) (subset_univ _),
      by_cases h : 1 < c.length,
      { simp [h] },
      { have : c.length = 1,
          by { refine (eq_iff_le_not_lt.2 ⟨ _, h⟩).symm, exact c.length_pos_of_pos N },
        rw ← composition.eq_single_iff N at this,
        simp [this] } },
    have B : disjoint ({c | 1 < composition.length c} : set (composition (n+2))).to_finset
      {composition.single (n+2) N}, by simp,
    have C : p (composition.single (n + 2) N).length
               (q.apply_composition (composition.single (n + 2) N) v)
             = p 1 (λ (i : fin 1), q (n + 2) v),
    { apply p.congr (composition.single_length N) (λ j hj1 hj2, _),
      simp [apply_composition_single] },
    simp [formal_multilinear_series.comp, show n + 2 ≠ 1, by dec_trivial, A,
          finset.sum_union B, C], } -/
  suffices H : ∑ (c : composition (n + 2)) in {c : composition (n + 2) | 1 < c.length}.to_finset,
        p c.length ((p.right_inv i).apply_composition c v) =
      ∑ (c : composition (n + 2)) in {c : composition (n + 2) | 1 < c.length}.to_finset,
        p c.length (apply_composition (λ (k : ℕ), ite (k < n + 2) (p.right_inv i k) 0) c v), sorry,
    -- by simpa [this, h, right_inv, lt_irrefl n, show n + 2 ≠ 1, by dec_trivial, ← sub_eq_add_neg,
    --  sub_eq_zero],
  refine sum_congr rfl (λ c hc, p.congr rfl (λ j hj1 hj2, _)),
  have : ∀ k, c.blocks_fun k < n + 2, sorry,
  simp [apply_composition, this],

end


end formal_multilinear_series

#exit

∑ (x : composition (n + 2)) in {c : composition (n + 2) | 1 < c.length}.to_finset, ⇑(p x.length)
  ((p.right_inv i).apply_composition x v)

+ ⇑(p (composition.single (n + 2) N).length) ((p.right_inv i).apply_composition (composition.single (n + 2) N) v) = 0
