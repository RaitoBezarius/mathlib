/-
Copyright (c) 2020 Anatole Dedecker. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anatole Dedecker
-/
import analysis.asymptotic_equivalent
import data.polynomial.erase_lead

/-!
# Limits related to polynomial and rational functions

This file proves basic facts about limits of polynomial and rationals functions.
The main result is `eval_is_equivalent_at_top_eval_lead`, which states that for
any polynomial `P` of degree `n` with leading coefficient `a`, the corresponding
polynomial function is equivalent to `a * x^n` as `x` goes to +∞.

We can then use this result to prove various limits for polynomial and rational
functions, depending on the degrees and leading coefficients of the considered
polynomials.
-/

open filter finset asymptotics
open_locale asymptotics topological_space

namespace polynomial

variables {α : Type*} [normed_linear_ordered_field α] [order_topology α]

lemma is_equivalent_at_top_lead (P : polynomial α) :
  (λ x, eval x P) ~[at_top] (λ x, P.leading_coeff * x ^ P.nat_degree) :=
begin
  by_cases h : P = 0,
  { simp [h] },
  { conv_lhs
    { funext,
      rw [polynomial.eval_eq_finset_sum, sum_range_succ, add_comm] },
    exact is_equivalent.refl.add_is_o (is_o.sum $ λ i hi, is_o.const_mul_left
      (is_o.const_mul_right (λ hz, h $ leading_coeff_eq_zero.mp hz) $
        is_o_pow_pow_at_top_of_lt (mem_range.mp hi)) _) }
end

lemma tendsto_at_top_of_leading_coeff_nonneg (P : polynomial α) (hdeg : 1 ≤ P.degree)
  (hnng : 0 ≤ P.leading_coeff) : tendsto (λ x, eval x P) at_top at_top :=
P.is_equivalent_at_top_lead.symm.tendsto_at_top
  (tendsto_const_mul_pow_at_top (nat_degree_ge_of_degree_ge_coe hdeg)
    (lt_of_le_of_ne hnng $ ne.symm $ mt leading_coeff_eq_zero.mp $ ne_zero_of_degree_ge_coe hdeg))

lemma tendsto_at_bot_of_leading_coeff_nonpos (P : polynomial α) (hdeg : 1 ≤ P.degree)
  (hnps : P.leading_coeff ≤ 0) : tendsto (λ x, eval x P) at_top at_bot :=
P.is_equivalent_at_top_lead.symm.tendsto_at_bot
  (tendsto_neg_const_mul_pow_at_top (nat_degree_ge_of_degree_ge_coe hdeg)
    (lt_of_le_of_ne hnps $ mt leading_coeff_eq_zero.mp $ ne_zero_of_degree_ge_coe hdeg))

lemma abs_tendsto_at_top (P : polynomial α) (hdeg : 1 ≤ P.degree) :
  tendsto (λ x, abs $ eval x P) at_top at_top :=
begin
  by_cases hP : 0 ≤ P.leading_coeff,
  { exact tendsto_abs_at_top_at_top.comp (P.tendsto_at_top_of_leading_coeff_nonneg hdeg hP)},
  { push_neg at hP,
    exact tendsto_abs_at_bot_at_top.comp (P.tendsto_at_bot_of_leading_coeff_nonpos hdeg hP.le)}
end

lemma is_equivalent_at_top_div {P Q : polynomial α} :
   (λ x, (eval x P)/(eval x Q)) ~[at_top]
     λ x, P.leading_coeff/Q.leading_coeff * x^(P.nat_degree - Q.nat_degree : ℤ) :=
begin
  by_cases hP : P = 0,
  { simp [hP] },
  by_cases hQ : Q = 0,
  { simp [hQ] },
  refine (P.is_equivalent_at_top_lead.symm.div
          Q.is_equivalent_at_top_lead.symm).symm.trans
         (eventually_eq.is_equivalent ((eventually_gt_at_top 0).mono $ λ x hx, _)),
  simp [← div_mul_div, hP, hQ, fpow_sub hx.ne.symm]
end

lemma div_tendsto_zero_of_degree_lt (P Q : polynomial α) (hdeg : P.degree < Q.degree) :
  tendsto (λ x, (eval x P)/(eval x Q)) at_top (𝓝 0) :=
begin
  by_cases hP : P = 0,
  { simp [hP, tendsto_const_nhds] },
  rw ←  nat_degree_lt_nat_degree_iff hP at hdeg,
  refine is_equivalent_at_top_div.symm.tendsto_nhds _,
  rw ← mul_zero,
  refine tendsto.const_mul _ _,
  apply tendsto_fpow_at_top_zero,
  linarith
end

lemma div_tendsto_leading_coeff_div_of_degree_eq (P Q : polynomial α)
  (hdeg : P.degree = Q.degree) :
  tendsto (λ x, (eval x P)/(eval x Q)) at_top (𝓝 $ P.leading_coeff / Q.leading_coeff) :=
begin
  refine is_equivalent_at_top_div.symm.tendsto_nhds _,
  rw show (P.nat_degree : ℤ) = Q.nat_degree, by simp [hdeg, nat_degree],
  simp [tendsto_const_nhds]
end

lemma div_tendsto_at_top_of_degree_gt (P Q : polynomial α) (hdeg : Q.degree < P.degree)
  (hQ : Q ≠ 0) (hnng : 0 ≤ P.leading_coeff/Q.leading_coeff) :
  tendsto (λ x, (eval x P)/(eval x Q)) at_top at_top :=
begin
  have ratio_pos : 0 < P.leading_coeff/Q.leading_coeff :=
    lt_of_le_of_ne hnng (div_ne_zero (λ h, ne_zero_of_degree_gt hdeg $ leading_coeff_eq_zero.mp h)
      (λ h, hQ $ leading_coeff_eq_zero.mp h)).symm,
  rw ← nat_degree_lt_nat_degree_iff hQ at hdeg,
  refine is_equivalent_at_top_div.symm.tendsto_at_top _,
  apply tendsto.const_mul_at_top ratio_pos,
  apply tendsto_fpow_at_top_at_top,
  linarith
end

lemma div_tendsto_at_bot_of_degree_gt (P Q : polynomial α) (hdeg : Q.degree < P.degree)
  (hQ : Q ≠ 0) (hnng : P.leading_coeff/Q.leading_coeff ≤ 0) :
  tendsto (λ x, (eval x P)/(eval x Q)) at_top at_bot :=
begin
  have ratio_neg : P.leading_coeff/Q.leading_coeff < 0 :=
    lt_of_le_of_ne hnng (div_ne_zero (λ h, ne_zero_of_degree_gt hdeg $ leading_coeff_eq_zero.mp h)
      (λ h, hQ $ leading_coeff_eq_zero.mp h)),
  rw ← nat_degree_lt_nat_degree_iff hQ at hdeg,
  refine is_equivalent_at_top_div.symm.tendsto_at_bot _,
  apply tendsto.neg_const_mul_at_top ratio_neg,
  apply tendsto_fpow_at_top_at_top,
  linarith
end

lemma eval_div_tendsto_at_top_of_degree_gt (P Q : polynomial α) (hdeg : Q.degree < P.degree)
  (hQ : Q ≠ 0) :
  tendsto (λ x, abs ((eval x P)/(eval x Q))) at_top at_top :=
begin
  by_cases h : 0 ≤ P.leading_coeff/Q.leading_coeff,
  { exact tendsto_abs_at_top_at_top.comp (P.div_tendsto_at_top_of_degree_gt Q hdeg hQ h) },
  { push_neg at h,
    exact tendsto_abs_at_bot_at_top.comp (P.div_tendsto_at_bot_of_degree_gt Q hdeg hQ h.le) }
end

end polynomial
