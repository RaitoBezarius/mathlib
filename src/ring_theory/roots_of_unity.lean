/-
Copyright (c) 2020 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/

import data.nat.parity
import data.polynomial.ring_division
import group_theory.order_of_element
import ring_theory.integral_domain
import number_theory.divisors
import data.zmod.basic
import tactic.zify
import field_theory.separable
import field_theory.finite.basic

/-!
# Roots of unity and primitive roots of unity

We define roots of unity in the context of an arbitrary commutative monoid,
as a subgroup of the group of units. We also define a predicate `is_primitive_root` on commutative
monoids, expressing that an element is a primitive root of unity.

## Main definitions

* `roots_of_unity n M`, for `n : ℕ+` is the subgroup of the units of a commutative monoid `M`
  consisting of elements `x` that satisfy `x ^ n = 1`.
* `is_primitive_root ζ k`: an element `ζ` is a primitive `k`-th root of unity if `ζ ^ k = 1`,
  and if `l` satisfies `ζ ^ l = 1` then `k ∣ l`.
* `primitive_roots k R`: the finset of primitive `k`-th roots of unity in an integral domain `R`.

## Main results

* `roots_of_unity.is_cyclic`: the roots of unity in an integral domain form a cyclic group.
* `is_primitive_root.zmod_equiv_gpowers`: `zmod k` is equivalent to
  the subgroup generated by a primitive `k`-th root of unity.
* `is_primitive_root.gpowers_eq`: in an integral domain, the subgroup generated by
  a primitive `k`-th root of unity is equal to the `k`-th roots of unity.
* `is_primitive_root.card_primitive_roots`: if an integral domain
   has a primitive `k`-th root of unity, then it has `φ k` of them.

## Implementation details

It is desirable that `roots_of_unity` is a subgroup,
and it will mainly be applied to rings (e.g. the ring of integers in a number field) and fields.
We therefore implement it as a subgroup of the units of a commutative monoid.

We have chosen to define `roots_of_unity n` for `n : ℕ+`, instead of `n : ℕ`,
because almost all lemmas need the positivity assumption,
and in particular the type class instances for `fintype` and `is_cyclic`.

On the other hand, for primitive roots of unity, it is desirable to have a predicate
not just on units, but directly on elements of the ring/field.
For example, we want to say that `exp (2 * pi * I / n)` is a primitive `n`-th root of unity
in the complex numbers, without having to turn that number into a unit first.

This creates a little bit of friction, but lemmas like `is_primitive_root.is_unit` and
`is_primitive_root.coe_units_iff` should provide the necessary glue.

-/

open_locale classical big_operators
noncomputable theory

open polynomial
open finset

variables {M N G G₀ R S : Type*}
variables [comm_monoid M] [comm_monoid N] [comm_group G] [comm_group_with_zero G₀]
variables [integral_domain R] [integral_domain S]

section roots_of_unity

variables {k l : ℕ+}

/-- `roots_of_unity k M` is the subgroup of elements `m : units M` that satisfy `m ^ k = 1` -/
def roots_of_unity (k : ℕ+) (M : Type*) [comm_monoid M] : subgroup (units M) :=
{ carrier := { ζ | ζ ^ (k : ℕ) = 1 },
  one_mem' := one_pow _,
  mul_mem' := λ ζ ξ hζ hξ, by simp only [*, set.mem_set_of_eq, mul_pow, one_mul] at *,
  inv_mem' := λ ζ hζ, by simp only [*, set.mem_set_of_eq, inv_pow, one_inv] at * }

@[simp] lemma mem_roots_of_unity (k : ℕ+) (ζ : units M) :
  ζ ∈ roots_of_unity k M ↔ ζ ^ (k : ℕ) = 1 := iff.rfl

lemma roots_of_unity_le_of_dvd (h : k ∣ l) : roots_of_unity k M ≤ roots_of_unity l M :=
begin
  obtain ⟨d, rfl⟩ := h,
  intros ζ h,
  simp only [mem_roots_of_unity, pnat.mul_coe, pow_mul, one_pow, *] at *,
end

lemma map_roots_of_unity (f : units M →* units N) (k : ℕ+) :
  (roots_of_unity k M).map f ≤ roots_of_unity k N :=
begin
  rintros _ ⟨ζ, h, rfl⟩,
  simp only [←monoid_hom.map_pow, *, mem_roots_of_unity, subgroup.mem_coe, monoid_hom.map_one] at *
end

lemma mem_roots_of_unity_iff_mem_nth_roots {ζ : units R} :
  ζ ∈ roots_of_unity k R ↔ (ζ : R) ∈ nth_roots k (1 : R) :=
by simp only [mem_roots_of_unity, mem_nth_roots k.pos, units.ext_iff, units.coe_one, units.coe_pow]

variables (k R)

/-- Equivalence between the `k`-th roots of unity in `R` and the `k`-th roots of `1`.

This is implemented as equivalence of subtypes,
because `roots_of_unity` is a subgroup of the group of units,
whereas `nth_roots` is a multiset. -/
def roots_of_unity_equiv_nth_roots :
  roots_of_unity k R ≃ {x // x ∈ nth_roots k (1 : R)} :=
begin
  refine
  { to_fun := λ x, ⟨x, mem_roots_of_unity_iff_mem_nth_roots.mp x.2⟩,
    inv_fun := λ x, ⟨⟨x, x ^ (k - 1 : ℕ), _, _⟩, _⟩,
    left_inv := _,
    right_inv := _ },
  swap 4, { rintro ⟨x, hx⟩, ext, refl },
  swap 4, { rintro ⟨x, hx⟩, ext, refl },
  all_goals
  { rcases x with ⟨x, hx⟩, rw [mem_nth_roots k.pos] at hx,
    simp only [subtype.coe_mk, ← pow_succ, ← pow_succ', hx,
      nat.sub_add_cancel (show 1 ≤ (k : ℕ), from k.one_le)] },
  { show (_ : units R) ^ (k : ℕ) = 1,
    simp only [units.ext_iff, hx, units.coe_mk, units.coe_one, subtype.coe_mk, units.coe_pow] }
end

variables {k R}

@[simp] lemma roots_of_unity_equiv_nth_roots_apply (x : roots_of_unity k R) :
  (roots_of_unity_equiv_nth_roots R k x : R) = x :=
rfl

@[simp] lemma roots_of_unity_equiv_nth_roots_symm_apply (x : {x // x ∈ nth_roots k (1 : R)}) :
  ((roots_of_unity_equiv_nth_roots R k).symm x : R) = x :=
rfl

variables (k R)

instance roots_of_unity.fintype : fintype (roots_of_unity k R) :=
fintype.of_equiv {x // x ∈ nth_roots k (1 : R)} $ (roots_of_unity_equiv_nth_roots R k).symm

instance roots_of_unity.is_cyclic : is_cyclic (roots_of_unity k R) :=
is_cyclic_of_subgroup_integral_domain ((units.coe_hom R).comp (roots_of_unity k R).subtype)
  (units.ext.comp subtype.val_injective)

lemma card_roots_of_unity : fintype.card (roots_of_unity k R) ≤ k :=
calc  fintype.card (roots_of_unity k R)
    = fintype.card {x // x ∈ nth_roots k (1 : R)} : fintype.card_congr (roots_of_unity_equiv_nth_roots R k)
... ≤ (nth_roots k (1 : R)).attach.card           : multiset.card_le_of_le (multiset.erase_dup_le _)
... = (nth_roots k (1 : R)).card                  : multiset.card_attach
... ≤ k                                           : card_nth_roots k 1

end roots_of_unity

/-- An element `ζ` is a primitive `k`-th root of unity if `ζ ^ k = 1`,
and if `l` satisfies `ζ ^ l = 1` then `k ∣ l`. -/
structure is_primitive_root (ζ : M) (k : ℕ) : Prop :=
(pow_eq_one : ζ ^ (k : ℕ) = 1)
(dvd_of_pow_eq_one : ∀ l : ℕ, ζ ^ l = 1 → k ∣ l)

section primitive_roots
variables {k : ℕ}

/-- `primitive_roots k R` is the finset of primitive `k`-th roots of unity
in the integral domain `R`. -/
def primitive_roots (k : ℕ) (R : Type*) [integral_domain R] : finset R :=
(nth_roots k (1 : R)).to_finset.filter (λ ζ, is_primitive_root ζ k)

@[simp] lemma mem_primitive_roots {ζ : R} (h0 : 0 < k) :
  ζ ∈ primitive_roots k R ↔ is_primitive_root ζ k :=
begin
  rw [primitive_roots, mem_filter, multiset.mem_to_finset, mem_nth_roots h0, and_iff_right_iff_imp],
  exact is_primitive_root.pow_eq_one
end

end primitive_roots

namespace is_primitive_root

variables {k l : ℕ}

lemma iff_def (ζ : M) (k : ℕ) :
  is_primitive_root ζ k ↔ (ζ ^ k = 1) ∧ (∀ l : ℕ, ζ ^ l = 1 → k ∣ l) :=
⟨λ ⟨h1, h2⟩, ⟨h1, h2⟩, λ ⟨h1, h2⟩, ⟨h1, h2⟩⟩

lemma mk_of_lt (ζ : M) (hk : 0 < k) (h1 : ζ ^ k = 1) (h : ∀ l : ℕ, 0 < l →  l < k → ζ ^ l ≠ 1) :
  is_primitive_root ζ k :=
begin
  refine ⟨h1, _⟩,
  intros l hl,
  apply dvd_trans _ (k.gcd_dvd_right l),
  suffices : k.gcd l = k, { rw this },
  rw eq_iff_le_not_lt,
  refine ⟨nat.le_of_dvd hk (k.gcd_dvd_left l), _⟩,
  intro h', apply h _ (nat.gcd_pos_of_pos_left _ hk) h',
  exact pow_gcd_eq_one _ h1 hl
end

section comm_monoid

variables {ζ : M} (h : is_primitive_root ζ k)

lemma pow_eq_one_iff_dvd (l : ℕ) : ζ ^ l = 1 ↔ k ∣ l :=
⟨h.dvd_of_pow_eq_one l,
by { rintro ⟨i, rfl⟩, simp only [pow_mul, h.pow_eq_one, one_pow, pnat.mul_coe] }⟩

lemma is_unit (h : is_primitive_root ζ k) (h0 : 0 < k) : is_unit ζ :=
begin
  apply is_unit_of_mul_eq_one ζ (ζ ^ (k - 1)),
  rw [← pow_succ, nat.sub_add_cancel h0, h.pow_eq_one]
end

lemma pow_ne_one_of_pos_of_lt (h0 : 0 < l) (hl : l < k) : ζ ^ l ≠ 1 :=
mt (nat.le_of_dvd h0 ∘ h.dvd_of_pow_eq_one _) $ not_le_of_lt hl

lemma pow_inj (h : is_primitive_root ζ k) ⦃i j : ℕ⦄ (hi : i < k) (hj : j < k) (H : ζ ^ i = ζ ^ j) :
  i = j :=
begin
  wlog hij : i ≤ j,
  apply le_antisymm hij,
  rw ← nat.sub_eq_zero_iff_le,
  apply nat.eq_zero_of_dvd_of_lt _ (lt_of_le_of_lt (nat.sub_le_self _ _) hj),
  apply h.dvd_of_pow_eq_one,
  rw [← ((h.is_unit (lt_of_le_of_lt (nat.zero_le _) hi)).pow i).mul_left_inj,
      ← pow_add, nat.sub_add_cancel hij, H, one_mul]
end

lemma one : is_primitive_root (1 : M) 1 :=
{ pow_eq_one := pow_one _,
  dvd_of_pow_eq_one := λ l hl, one_dvd _ }

@[simp] lemma one_right_iff : is_primitive_root ζ 1 ↔ ζ = 1 :=
begin
  split,
  { intro h, rw [← pow_one ζ, h.pow_eq_one] },
  { rintro rfl, exact one }
end

@[simp] lemma coe_units_iff {ζ : units M} :
  is_primitive_root (ζ : M) k ↔ is_primitive_root ζ k :=
by simp only [iff_def, units.ext_iff, units.coe_pow, units.coe_one]

lemma pow_of_coprime (h : is_primitive_root ζ k) (i : ℕ) (hi : i.coprime k) :
  is_primitive_root (ζ ^ i) k :=
begin
  by_cases h0 : k = 0,
  { subst k, simp only [*, pow_one, nat.coprime_zero_right] at * },
  rcases h.is_unit (nat.pos_of_ne_zero h0) with ⟨ζ, rfl⟩,
  rw [← units.coe_pow],
  rw coe_units_iff at h ⊢,
  refine
  { pow_eq_one := by rw [← pow_mul', pow_mul, h.pow_eq_one, one_pow],
    dvd_of_pow_eq_one := _ },
  intros l hl,
  apply h.dvd_of_pow_eq_one,
  rw [← pow_one ζ, ← gpow_coe_nat ζ, ← hi.gcd_eq_one, nat.gcd_eq_gcd_ab, gpow_add,
      mul_pow, ← gpow_coe_nat, ← gpow_mul, mul_right_comm],
  simp only [gpow_mul, hl, h.pow_eq_one, one_gpow, one_pow, one_mul, gpow_coe_nat]
end

lemma pow_of_prime (h : is_primitive_root ζ k) {p : ℕ} (hprime : nat.prime p) (hdiv : ¬ p ∣ k) :
  is_primitive_root (ζ ^ p) k :=
h.pow_of_coprime p (hprime.coprime_iff_not_dvd.2 hdiv)

lemma pow_iff_coprime (h : is_primitive_root ζ k) (h0 : 0 < k) (i : ℕ) :
  is_primitive_root (ζ ^ i) k ↔ i.coprime k :=
begin
  refine ⟨_, h.pow_of_coprime i⟩,
  intro hi,
  obtain ⟨a, ha⟩ := i.gcd_dvd_left k,
  obtain ⟨b, hb⟩ := i.gcd_dvd_right k,
  suffices : b = k,
  { rwa [this, ← one_mul k, nat.mul_left_inj h0, eq_comm] at hb { occs := occurrences.pos [1] } },
  rw [ha] at hi,
  rw [mul_comm] at hb,
  apply nat.dvd_antisymm ⟨i.gcd k, hb⟩ (hi.dvd_of_pow_eq_one b _),
  rw [← pow_mul', ← mul_assoc, ← hb, pow_mul, h.pow_eq_one, one_pow]
end

end comm_monoid

section comm_group

variables {ζ : G} (h : is_primitive_root ζ k)

lemma gpow_eq_one : ζ ^ (k : ℤ) = 1 := h.pow_eq_one

lemma gpow_eq_one_iff_dvd (h : is_primitive_root ζ k) (l : ℤ) :
  ζ ^ l = 1 ↔ (k : ℤ) ∣ l :=
begin
  by_cases h0 : 0 ≤ l,
  { lift l to ℕ using h0, rw [gpow_coe_nat], norm_cast, exact h.pow_eq_one_iff_dvd l },
  { have : 0 ≤ -l, { simp only [not_le, neg_nonneg] at h0 ⊢, exact le_of_lt h0 },
    lift -l to ℕ using this with l' hl',
    rw [← dvd_neg, ← hl'],
    norm_cast,
    rw [← h.pow_eq_one_iff_dvd, ← inv_inj, ← gpow_neg, ← hl', gpow_coe_nat, one_inv] }
end

lemma inv (h : is_primitive_root ζ k) : is_primitive_root ζ⁻¹ k :=
{ pow_eq_one := by simp only [h.pow_eq_one, one_inv, eq_self_iff_true, inv_pow],
  dvd_of_pow_eq_one :=
  begin
    intros l hl,
    apply h.dvd_of_pow_eq_one l,
    rw [← inv_inj, ← inv_pow, hl, one_inv]
  end }

@[simp] lemma inv_iff : is_primitive_root ζ⁻¹ k ↔ is_primitive_root ζ k :=
by { refine ⟨_, λ h, inv h⟩, intro h, rw [← inv_inv ζ], exact inv h }

lemma gpow_of_gcd_eq_one (h : is_primitive_root ζ k) (i : ℤ) (hi : i.gcd k = 1) :
  is_primitive_root (ζ ^ i) k :=
begin
  by_cases h0 : 0 ≤ i,
  { lift i to ℕ using h0, exact h.pow_of_coprime i hi },
  have : 0 ≤ -i, { simp only [not_le, neg_nonneg] at h0 ⊢, exact le_of_lt h0 },
  lift -i to ℕ using this with i' hi',
  rw [← inv_iff, ← gpow_neg, ← hi'],
  apply h.pow_of_coprime,
  rw [int.gcd, ← int.nat_abs_neg, ← hi'] at hi,
  exact hi
end

@[simp] lemma coe_subgroup_iff (H : subgroup G) {ζ : H} :
  is_primitive_root (ζ : G) k ↔ is_primitive_root ζ k :=
by simp only [iff_def, ← subgroup.coe_pow, ← H.coe_one, ← subtype.ext_iff]

end comm_group

section comm_group_with_zero

variables {ζ : G₀} (h : is_primitive_root ζ k)

lemma fpow_eq_one : ζ ^ (k : ℤ) = 1 := h.pow_eq_one

lemma fpow_eq_one_iff_dvd (h : is_primitive_root ζ k) (l : ℤ) :
  ζ ^ l = 1 ↔ (k : ℤ) ∣ l :=
begin
  by_cases h0 : 0 ≤ l,
  { lift l to ℕ using h0, rw [fpow_coe_nat], norm_cast, exact h.pow_eq_one_iff_dvd l },
  { have : 0 ≤ -l, { simp only [not_le, neg_nonneg] at h0 ⊢, exact le_of_lt h0 },
    lift -l to ℕ using this with l' hl',
    rw [← dvd_neg, ← hl'],
    norm_cast,
    rw [← h.pow_eq_one_iff_dvd, ← inv_inj', ← fpow_neg, ← hl', fpow_coe_nat, inv_one] }
end

lemma inv' (h : is_primitive_root ζ k) : is_primitive_root ζ⁻¹ k :=
{ pow_eq_one := by simp only [h.pow_eq_one, inv_one, eq_self_iff_true, inv_pow'],
  dvd_of_pow_eq_one :=
  begin
    intros l hl,
    apply h.dvd_of_pow_eq_one l,
    rw [← inv_inj', ← inv_pow', hl, inv_one]
  end }

@[simp] lemma inv_iff' : is_primitive_root ζ⁻¹ k ↔ is_primitive_root ζ k :=
by { refine ⟨_, λ h, inv' h⟩, intro h, rw [← inv_inv' ζ], exact inv' h }

lemma fpow_of_gcd_eq_one (h : is_primitive_root ζ k) (i : ℤ) (hi : i.gcd k = 1) :
  is_primitive_root (ζ ^ i) k :=
begin
  by_cases h0 : 0 ≤ i,
  { lift i to ℕ using h0, exact h.pow_of_coprime i hi },
  have : 0 ≤ -i, { simp only [not_le, neg_nonneg] at h0 ⊢, exact le_of_lt h0 },
  lift -i to ℕ using this with i' hi',
  rw [← inv_iff', ← fpow_neg, ← hi'],
  apply h.pow_of_coprime,
  rw [int.gcd, ← int.nat_abs_neg, ← hi'] at hi,
  exact hi
end

end comm_group_with_zero

section integral_domain

variables {ζ : R}

@[simp] lemma primitive_roots_zero : primitive_roots 0 R = ∅ :=
begin
  rw [← finset.val_eq_zero, ← multiset.subset_zero, ← nth_roots_zero (1 : R), primitive_roots],
    simp only [finset.not_mem_empty, forall_const, forall_prop_of_false, multiset.to_finset_zero,
    finset.filter_true_of_mem, finset.empty_val, not_false_iff,
    multiset.zero_subset, nth_roots_zero]
end

@[simp] lemma primitive_roots_one : primitive_roots 1 R = {(1 : R)} :=
begin
  apply finset.eq_singleton_iff_unique_mem.2,
  split,
  { simp only [is_primitive_root.one_right_iff, mem_primitive_roots zero_lt_one] },
  { intros x hx,
    rw [mem_primitive_roots zero_lt_one, is_primitive_root.one_right_iff] at hx,
    exact hx }
end

lemma neg_one (p : ℕ) [char_p R p] (hp : p ≠ 2) : is_primitive_root (-1 : R) 2 :=
mk_of_lt (-1 : R) dec_trivial (by simp only [one_pow, neg_square]) $
begin
  intros l hl0 hl2,
  obtain rfl : l = 1,
  { unfreezingI { clear_dependent R p }, dec_trivial! },
  simp only [pow_one, ne.def],
  intro h,
  suffices h2 : p ∣ 2,
  { have := char_p.char_ne_one R p,
    unfreezingI { clear_dependent R },
    have aux := nat.le_of_dvd dec_trivial h2,
    revert this hp h2, revert p, dec_trivial },
  simp only [← char_p.cast_eq_zero_iff R p, nat.cast_bit0, nat.cast_one],
  rw [bit0, ← h, neg_add_self] { occs := occurrences.pos [1] }
end

lemma eq_neg_one_of_two_right (h : is_primitive_root ζ 2) : ζ = -1 :=
begin
  apply (eq_or_eq_neg_of_pow_two_eq_pow_two ζ 1 _).resolve_left,
  { rw [← pow_one ζ], apply h.pow_ne_one_of_pos_of_lt; dec_trivial },
  { simp only [h.pow_eq_one, one_pow] }
end

end integral_domain

section integral_domain

variables {ζ : units R} (h : is_primitive_root ζ k)

protected
lemma mem_roots_of_unity {n : ℕ+} (h : is_primitive_root ζ n) : ζ ∈ roots_of_unity n R :=
h.pow_eq_one

/-- The (additive) monoid equivalence between `zmod k`
and the powers of a primitive root of unity `ζ`. -/
def zmod_equiv_gpowers (h : is_primitive_root ζ k) : zmod k ≃+ additive (subgroup.gpowers ζ) :=
add_equiv.of_bijective
(add_monoid_hom.lift_of_surjective (int.cast_add_hom _)
  zmod.int_cast_surjective
  { to_fun := λ i, additive.of_mul (⟨_, i, rfl⟩ : subgroup.gpowers ζ),
    map_zero' := by { simp only [gpow_zero], refl },
    map_add' := by { intros i j, simp only [gpow_add], refl } }
  (λ i hi,
  begin
    simp only [add_monoid_hom.mem_ker, char_p.int_cast_eq_zero_iff (zmod k) k,
      add_monoid_hom.coe_mk, int.coe_cast_add_hom] at hi ⊢,
    obtain ⟨i, rfl⟩ := hi,
    simp only [gpow_mul, h.pow_eq_one, one_gpow, gpow_coe_nat],
    refl
  end)) $
begin
  split,
  { rw add_monoid_hom.injective_iff,
    intros i hi,
    rw subtype.ext_iff at hi,
    have := (h.gpow_eq_one_iff_dvd _).mp hi,
    rw [← (char_p.int_cast_eq_zero_iff (zmod k) k _).mpr this, eq_comm],
    exact classical.some_spec (zmod.int_cast_surjective i) },
  { rintro ⟨ξ, i, rfl⟩,
    refine ⟨int.cast_add_hom _ i, _⟩,
    rw [add_monoid_hom.lift_of_surjective_comp_apply],
    refl }
end

@[simp] lemma zmod_equiv_gpowers_apply_coe_int (i : ℤ) :
  h.zmod_equiv_gpowers i = additive.of_mul (⟨ζ ^ i, i, rfl⟩ : subgroup.gpowers ζ) :=
begin
  apply add_monoid_hom.lift_of_surjective_comp_apply,
  intros j hj,
  simp only [add_monoid_hom.mem_ker, char_p.int_cast_eq_zero_iff (zmod k) k,
    add_monoid_hom.coe_mk, int.coe_cast_add_hom] at hj ⊢,
  obtain ⟨j, rfl⟩ := hj,
  simp only [gpow_mul, h.pow_eq_one, one_gpow, gpow_coe_nat],
  refl
end

@[simp] lemma zmod_equiv_gpowers_apply_coe_nat (i : ℕ) :
  h.zmod_equiv_gpowers i = additive.of_mul (⟨ζ ^ i, i, rfl⟩ : subgroup.gpowers ζ) :=
begin
  have : (i : zmod k) = (i : ℤ), by norm_cast,
  simp only [this, zmod_equiv_gpowers_apply_coe_int, gpow_coe_nat],
  refl
end

@[simp] lemma zmod_equiv_gpowers_symm_apply_gpow (i : ℤ) :
  h.zmod_equiv_gpowers.symm (additive.of_mul (⟨ζ ^ i, i, rfl⟩ : subgroup.gpowers ζ)) = i :=
by rw [← h.zmod_equiv_gpowers.symm_apply_apply i, zmod_equiv_gpowers_apply_coe_int]

@[simp] lemma zmod_equiv_gpowers_symm_apply_gpow' (i : ℤ) :
  h.zmod_equiv_gpowers.symm ⟨ζ ^ i, i, rfl⟩ = i :=
h.zmod_equiv_gpowers_symm_apply_gpow i

@[simp] lemma zmod_equiv_gpowers_symm_apply_pow (i : ℕ) :
  h.zmod_equiv_gpowers.symm (additive.of_mul (⟨ζ ^ i, i, rfl⟩ : subgroup.gpowers ζ)) = i :=
by rw [← h.zmod_equiv_gpowers.symm_apply_apply i, zmod_equiv_gpowers_apply_coe_nat]

@[simp] lemma zmod_equiv_gpowers_symm_apply_pow' (i : ℕ) :
  h.zmod_equiv_gpowers.symm ⟨ζ ^ i, i, rfl⟩ = i :=
h.zmod_equiv_gpowers_symm_apply_pow i

lemma gpowers_eq {k : ℕ+} {ζ : units R} (h : is_primitive_root ζ k) :
  subgroup.gpowers ζ = roots_of_unity k R :=
begin
  apply subgroup.ext',
  haveI : fact (0 < (k : ℕ)) := k.pos,
  haveI F : fintype (subgroup.gpowers ζ) := fintype.of_equiv _ (h.zmod_equiv_gpowers).to_equiv,
  refine @set.eq_of_subset_of_card_le (units R) (subgroup.gpowers ζ) (roots_of_unity k R)
    F (roots_of_unity.fintype R k)
    (subgroup.gpowers_subset $ show ζ ∈ roots_of_unity k R, from h.pow_eq_one) _,
  calc fintype.card (roots_of_unity k R)
      ≤ k                                 : card_roots_of_unity R k
  ... = fintype.card (zmod k)             : (zmod.card k).symm
  ... = fintype.card (subgroup.gpowers ζ) : fintype.card_congr (h.zmod_equiv_gpowers).to_equiv
end

lemma eq_pow_of_mem_roots_of_unity {k : ℕ+} {ζ ξ : units R}
  (h : is_primitive_root ζ k) (hξ : ξ ∈ roots_of_unity k R) :
  ∃ (i : ℕ) (hi : i < k), ζ ^ i = ξ :=
begin
  obtain ⟨n, rfl⟩ : ∃ n : ℤ, ζ ^ n = ξ, by rwa [← h.gpowers_eq] at hξ,
  have hk0 : (0 : ℤ) < k := by exact_mod_cast k.pos,
  let i := n % k,
  have hi0 : 0 ≤ i := int.mod_nonneg _ (ne_of_gt hk0),
  lift i to ℕ using hi0 with i₀ hi₀,
  refine ⟨i₀, _, _⟩,
  { zify, rw [hi₀], exact int.mod_lt_of_pos _ hk0 },
  { have aux := h.gpow_eq_one, rw [← coe_coe] at aux,
    rw [← gpow_coe_nat, hi₀, ← int.mod_add_div n k, gpow_add, gpow_mul,
        aux, one_gpow, mul_one] }
end

lemma eq_pow_of_pow_eq_one {k : ℕ} {ζ ξ : R}
  (h : is_primitive_root ζ k) (hξ : ξ ^ k = 1) (h0 : 0 < k) :
  ∃ i < k, ζ ^ i = ξ :=
begin
  obtain ⟨ζ, rfl⟩ := h.is_unit h0,
  obtain ⟨ξ, rfl⟩ := is_unit_of_pow_eq_one ξ k hξ h0,
  obtain ⟨k, rfl⟩ : ∃ k' : ℕ+, k = k' := ⟨⟨k, h0⟩, rfl⟩,
  simp only [← units.coe_pow, ← units.ext_iff],
  rw coe_units_iff at h,
  apply h.eq_pow_of_mem_roots_of_unity,
  rw [mem_roots_of_unity, units.ext_iff, units.coe_pow, hξ, units.coe_one]
end

lemma is_primitive_root_iff' {k : ℕ+} {ζ ξ : units R} (h : is_primitive_root ζ k) :
  is_primitive_root ξ k ↔ ∃ (i < (k : ℕ)) (hi : i.coprime k), ζ ^ i = ξ :=
begin
  split,
  { intro hξ,
    obtain ⟨i, hik, rfl⟩ := h.eq_pow_of_mem_roots_of_unity hξ.pow_eq_one,
    rw h.pow_iff_coprime k.pos at hξ,
    exact ⟨i, hik, hξ, rfl⟩ },
  { rintro ⟨i, -, hi, rfl⟩, exact h.pow_of_coprime i hi }
end

lemma is_primitive_root_iff {k : ℕ} {ζ ξ : R} (h : is_primitive_root ζ k) (h0 : 0 < k) :
  is_primitive_root ξ k ↔ ∃ (i < k) (hi : i.coprime k), ζ ^ i = ξ :=
begin
  split,
  { intro hξ,
    obtain ⟨i, hik, rfl⟩ := h.eq_pow_of_pow_eq_one hξ.pow_eq_one h0,
    rw h.pow_iff_coprime h0 at hξ,
    exact ⟨i, hik, hξ, rfl⟩ },
  { rintro ⟨i, -, hi, rfl⟩, exact h.pow_of_coprime i hi }
end

lemma card_roots_of_unity' {n : ℕ+} (h : is_primitive_root ζ n) :
  fintype.card (roots_of_unity n R) = n :=
begin
  haveI : fact (0 < ↑n) := n.pos,
  let e := h.zmod_equiv_gpowers,
  haveI F : fintype (subgroup.gpowers ζ) := fintype.of_equiv _ e.to_equiv,
  calc fintype.card (roots_of_unity n R)
      = fintype.card (subgroup.gpowers ζ) : fintype.card_congr $ by rw h.gpowers_eq
  ... = fintype.card (zmod n)             : fintype.card_congr e.to_equiv.symm
  ... = n                                 : zmod.card n
end

lemma card_roots_of_unity {ζ : R} {n : ℕ+} (h : is_primitive_root ζ n) :
  fintype.card (roots_of_unity n R) = n :=
begin
  obtain ⟨ζ, hζ⟩ := h.is_unit n.pos,
  rw [← hζ, is_primitive_root.coe_units_iff] at h,
  exact h.card_roots_of_unity'
end

/-- The cardinality of the multiset `nth_roots ↑n (1 : R)` is `n`
if there is a primitive root of unity in `R`. -/
lemma card_nth_roots {ζ : R} {n : ℕ} (h : is_primitive_root ζ n) :
  (nth_roots n (1 : R)).card = n :=
begin
  cases nat.eq_zero_or_pos n with hzero hpos,
  { simp only [hzero, multiset.card_zero, nth_roots_zero] },
  rw eq_iff_le_not_lt,
  use card_nth_roots n 1,
  { rw [not_lt],
    have hcard : fintype.card {x // x ∈ nth_roots n (1 : R)}
      ≤ (nth_roots n (1 : R)).attach.card := multiset.card_le_of_le (multiset.erase_dup_le _),
    rw multiset.card_attach at hcard,
    rw ← pnat.to_pnat'_coe hpos at hcard h ⊢,
    set m := nat.to_pnat' n,
    rw [← fintype.card_congr (roots_of_unity_equiv_nth_roots R m), card_roots_of_unity h] at hcard,
    exact hcard }
end

/-- The multiset `nth_roots ↑n (1 : R)` has no repeated elements
if there is a primitive root of unity in `R`. -/
lemma nth_roots_nodup {ζ : R} {n : ℕ} (h : is_primitive_root ζ n) : (nth_roots n (1 : R)).nodup :=
begin
  cases nat.eq_zero_or_pos n with hzero hpos,
  { simp only [hzero, multiset.nodup_zero, nth_roots_zero] },
  apply (@multiset.erase_dup_eq_self R _ _).1,
  rw eq_iff_le_not_lt,
  split,
  { exact multiset.erase_dup_le (nth_roots n (1 : R)) },
  { by_contra ha,
    replace ha := multiset.card_lt_of_lt ha,
    rw card_nth_roots h at ha,
    have hrw : (nth_roots n (1 : R)).erase_dup.card =
      fintype.card {x // x ∈ (nth_roots n (1 : R))},
    { set fs := (⟨(nth_roots n (1 : R)).erase_dup, multiset.nodup_erase_dup _⟩ : finset R),
      rw [← finset.card_mk, ← fintype.card_of_subtype fs _],
      intro x,
      simp only [multiset.mem_erase_dup, finset.mem_mk] },
    rw ← pnat.to_pnat'_coe hpos at h hrw ha,
    set m := nat.to_pnat' n,
    rw [hrw, ← fintype.card_congr (roots_of_unity_equiv_nth_roots R m),
        card_roots_of_unity h] at ha,
    exact nat.lt_asymm ha ha }
end

@[simp] lemma card_nth_roots_finset {ζ : R} {n : ℕ} (h : is_primitive_root ζ n) :
  (nth_roots_finset n R).card = n :=
by rw [nth_roots_finset, ← multiset.to_finset_eq (nth_roots_nodup h), card_mk, h.card_nth_roots]

open_locale nat

/-- If an integral domain has a primitive `k`-th root of unity, then it has `φ k` of them. -/
lemma card_primitive_roots {ζ : R} {k : ℕ} (h : is_primitive_root ζ k) (h0 : 0 < k) :
  (primitive_roots k R).card = φ k :=
begin
  symmetry,
  refine finset.card_congr (λ i _, ζ ^ i) _ _ _,
  { simp only [true_and, and_imp, mem_filter, mem_range, mem_univ],
    rintro i - hi,
    rw mem_primitive_roots h0,
    exact h.pow_of_coprime i hi.symm },
  { simp only [true_and, and_imp, mem_filter, mem_range, mem_univ],
    rintro i j hi - hj - H,
    exact h.pow_inj hi hj H },
  { simp only [exists_prop, true_and, mem_filter, mem_range, mem_univ],
    intros ξ hξ,
    rw [mem_primitive_roots h0, h.is_primitive_root_iff h0] at hξ,
    rcases hξ with ⟨i, hin, hi, H⟩,
    exact ⟨i, ⟨hin, hi.symm⟩, H⟩ }
end

/-- The sets `primitive_roots k R` are pairwise disjoint. -/
lemma disjoint {k l : ℕ} (hk : 0 < k) (hl : 0 < l) (h : k ≠ l) :
  disjoint (primitive_roots k R) (primitive_roots l R) :=
begin
  intro z,
  simp only [finset.inf_eq_inter, finset.mem_inter, mem_primitive_roots, hk, hl, iff_def],
  rintro ⟨⟨hzk, Hzk⟩, ⟨hzl, Hzl⟩⟩,
  apply_rules [h, nat.dvd_antisymm, Hzk, Hzl, hzk, hzl]
end

/-- If there is a `n`-th primitive root of unity in `R` and `b` divides `n`,
then there is a `b`-th primitive root of unity in `R`. -/
lemma pow {ζ : R} {n : ℕ} {a b : ℕ}
  (hn : 0 < n) (h : is_primitive_root ζ n) (hprod : n = a * b) :
  is_primitive_root (ζ ^ a) b :=
begin
  subst n,
  simp only [iff_def, ← pow_mul, h.pow_eq_one, eq_self_iff_true, true_and],
  intros l hl,
  have ha0 : a ≠ 0, { rintro rfl, simpa only [nat.not_lt_zero, zero_mul] using hn },
  rwa ← mul_dvd_mul_iff_left ha0,
  exact h.dvd_of_pow_eq_one _ hl
end

/-- `nth_roots n` as a `finset` is equal to the union of `primitive_roots i R` for `i ∣ n`
if there is a primitive root of unity in `R`. -/
lemma nth_roots_one_eq_bind_primitive_roots' {ζ : R} {n : ℕ+} (h : is_primitive_root ζ n) :
  nth_roots_finset n R = (nat.divisors ↑n).bind (λ i, (primitive_roots i R)) :=
begin
  symmetry,
  apply finset.eq_of_subset_of_card_le,
  { intros x,
    simp only [nth_roots_finset, ← multiset.to_finset_eq (nth_roots_nodup h),
      exists_prop, finset.mem_bind, finset.mem_filter, finset.mem_range, mem_nth_roots,
      finset.mem_mk, nat.mem_divisors, and_true, ne.def, pnat.ne_zero, pnat.pos, not_false_iff],
    rintro ⟨a, ⟨d, hd⟩, ha⟩,
    have hazero : 0 < a,
    { contrapose! hd with ha0,
      simp only [nonpos_iff_eq_zero, zero_mul, *] at *,
      exact n.ne_zero },
    rw mem_primitive_roots hazero at ha,
    rw [hd, pow_mul, ha.pow_eq_one, one_pow] },
  { apply le_of_eq,
    rw [h.card_nth_roots_finset, finset.card_bind],
    { rw [← nat.sum_totient n, nat.filter_dvd_eq_divisors (pnat.ne_zero n), sum_congr rfl]
        { occs := occurrences.pos [1] },
      simp only [finset.mem_filter, finset.mem_range, nat.mem_divisors],
      rintro k ⟨H, hk⟩,
      have hdvd := H,
      rcases H with ⟨d, hd⟩,
      rw mul_comm at hd,
      rw (h.pow n.pos hd).card_primitive_roots (pnat.pos_of_div_pos hdvd) },
    { intros i hi j hj hdiff,
      simp only [nat.mem_divisors, and_true, ne.def, pnat.ne_zero, not_false_iff] at hi hj,
      exact disjoint (pnat.pos_of_div_pos hi) (pnat.pos_of_div_pos hj) hdiff } }
end

/-- `nth_roots n` as a `finset` is equal to the union of `primitive_roots i R` for `i ∣ n`
if there is a primitive root of unity in `R`. -/
lemma nth_roots_one_eq_bind_primitive_roots {ζ : R} {n : ℕ} (hpos : 0 < n)
  (h : is_primitive_root ζ n) :
  nth_roots_finset n R = (nat.divisors n).bind (λ i, (primitive_roots i R)) :=
@nth_roots_one_eq_bind_primitive_roots' _ _ _ ⟨n, hpos⟩ h

end integral_domain

section minimal_polynomial

open minimal_polynomial

variables {n : ℕ} {K : Type*} [field K] {μ : K} (h : is_primitive_root μ n) (hpos : 0 < n)

include n μ h hpos

/--`μ` is integral over `ℤ`. -/
lemma is_integral : is_integral ℤ μ :=
begin
  use (X ^ n - 1),
  split,
  { exact (monic_X_pow_sub_C 1 (ne_of_lt hpos).symm) },
  { simp only [((is_primitive_root.iff_def μ n).mp h).left, eval₂_one, eval₂_X_pow, eval₂_sub,
      sub_self] }
end

variables [char_zero K]

/--The minimal polynomial of a root of unity `μ` divides `X ^ n - 1`. -/
lemma minimal_polynomial_dvd_X_pow_sub_one :
  minimal_polynomial (is_integral h hpos) ∣ X ^ n - 1 :=
begin
  apply integer_dvd (is_integral h hpos) (polynomial.monic.is_primitive
  (monic_X_pow_sub_C 1 (ne_of_lt hpos).symm)),
  simp only [((is_primitive_root.iff_def μ n).mp h).left, aeval_X_pow, ring_hom.eq_int_cast,
  int.cast_one, aeval_one, alg_hom.map_sub, sub_self]
end

/-- The reduction modulo `p` of the minimal polynomial of a root of unity `μ` is separable. -/
lemma separable_minimal_polynomial_mod {p : ℕ} [fact p.prime] (hdiv : ¬p ∣ n) :
  separable (map (int.cast_ring_hom (zmod p)) (minimal_polynomial (is_integral h hpos))) :=
begin
  have hdvd : (map (int.cast_ring_hom (zmod p))
    (minimal_polynomial (is_integral h hpos))) ∣ X ^ n - 1,
  { simpa [map_pow, map_X, map_one, ring_hom.coe_of, map_sub] using
      ring_hom.map_dvd (ring_hom.of (map (int.cast_ring_hom (zmod p))))
        (minimal_polynomial_dvd_X_pow_sub_one h hpos) },
  refine separable.of_dvd (separable_X_pow_sub_C 1 _ one_ne_zero) hdvd,
  by_contra hzero,
  exact hdiv ((zmod.nat_coe_zmod_eq_zero_iff_dvd n p).1 (not_not.1 hzero))
end

/-- The reduction modulo `p` of the minimal polynomial of a root of unity `μ` is squarefree. -/
lemma squarefree_minimal_polynomial_mod {p : ℕ} [fact p.prime] (hdiv : ¬ p ∣ n) :
  squarefree (map (int.cast_ring_hom (zmod p)) (minimal_polynomial (is_integral h hpos))) :=
(separable_minimal_polynomial_mod h hpos hdiv).squarefree

/- Let `P` be the minimal polynomial of a root of unity `μ` and `Q` be the minimal polynomial of
`μ ^ p`, where `p` is a prime that does not divide `n`. Then `P` divides `expand ℤ p Q`. -/
lemma minimal_polynomial_dvd_expand {p : ℕ} (hprime : nat.prime p) (hdiv : ¬ p ∣ n) :
  minimal_polynomial (is_integral h hpos) ∣
  expand ℤ p (minimal_polynomial (is_integral (pow_of_prime h hprime hdiv) hpos)) :=
begin
  apply minimal_polynomial.integer_dvd,
  { apply monic.is_primitive,
    rw [polynomial.monic, leading_coeff, nat_degree_expand, mul_comm, coeff_expand_mul'
        (nat.prime.pos hprime), ← leading_coeff, ← polynomial.monic],
    exact minimal_polynomial.monic (is_integral (pow_of_prime h hprime hdiv) hpos) },
  { rw [aeval_def, coe_expand, ← comp, eval₂_eq_eval_map, map_comp, map_pow, map_X, eval_comp,
      eval_pow, eval_X, ← eval₂_eq_eval_map, ← aeval_def],
    exact minimal_polynomial.aeval (is_integral (pow_of_prime h hprime hdiv) hpos) }
end

/- Let `P` be the minimal polynomial of a root of unity `μ` and `Q` be the minimal polynomial of
`μ ^ p`, where `p` is a prime that does not divide `n`. Then `P` divides `Q ^ p` modulo `p`. -/
lemma minimal_polynomial_dvd_pow_mod {p : ℕ} [hprime : fact p.prime] (hdiv : ¬ p ∣ n) :
  map (int.cast_ring_hom (zmod p)) (minimal_polynomial (is_integral h hpos)) ∣
  map (int.cast_ring_hom (zmod p)) (minimal_polynomial (is_integral
    (pow_of_prime h hprime hdiv) hpos)) ^ p :=
begin
  set Q := minimal_polynomial (is_integral (pow_of_prime h hprime hdiv) hpos),
  have hfrob : map (int.cast_ring_hom (zmod p)) Q ^ p =
    map (int.cast_ring_hom (zmod p)) (expand ℤ p Q),
  by rw [← zmod.expand_card, map_expand (nat.prime.pos hprime)],
  rw [hfrob],
  apply ring_hom.map_dvd (ring_hom.of (map (int.cast_ring_hom (zmod p)))),
  exact minimal_polynomial_dvd_expand h hpos hprime hdiv
end

/- Let `P` be the minimal polynomial of a root of unity `μ` and `Q` be the minimal polynomial of
`μ ^ p`, where `p` is a prime that does not divide `n`. Then `P` divides `Q` modulo `p`. -/
lemma minimal_polynomial_dvd_mod_p {p : ℕ} [hprime : fact p.prime] (hdiv : ¬ p ∣ n) :
  map (int.cast_ring_hom (zmod p)) (minimal_polynomial (is_integral h hpos)) ∣
  map (int.cast_ring_hom (zmod p)) (minimal_polynomial (is_integral
    (pow_of_prime h hprime hdiv) hpos)) :=
(unique_factorization_monoid.dvd_pow_iff_dvd_of_squarefree (squarefree_minimal_polynomial_mod h
  hpos hdiv) (nat.prime.ne_zero hprime)).1 (minimal_polynomial_dvd_pow_mod h hpos hdiv)

/-- If `p` is a prime that does not divide `n`,
then the minimal polynomials of a primitive `n`-th root of unity `μ`
and of `μ ^ p` are the same. -/
lemma minimal_polynomial_eq_pow {p : ℕ} [hprime : fact p.prime] (hdiv : ¬ p ∣ n) :
  minimal_polynomial (is_integral h hpos) =
  minimal_polynomial (is_integral (pow_of_prime h hprime hdiv) hpos) :=
begin
  by_contra hdiff,
  set P := minimal_polynomial (is_integral h hpos),
  set Q := minimal_polynomial (is_integral (pow_of_prime h hprime hdiv) hpos),
  have Pmonic : P.monic := minimal_polynomial.monic _,
  have Qmonic : Q.monic := minimal_polynomial.monic _,
  have Pirr : irreducible P := minimal_polynomial.irreducible _,
  have Qirr : irreducible Q := minimal_polynomial.irreducible _,
  have PQprim : is_primitive (P * Q) := Pmonic.is_primitive.mul Qmonic.is_primitive,
  have prod : P * Q ∣ X ^ n - 1,
  { apply (is_primitive.int.dvd_iff_map_cast_dvd_map_cast (P * Q) (X ^ n - 1) PQprim
      ((monic_X_pow_sub_C 1 (ne_of_lt hpos).symm).is_primitive)).2,
    rw [map_mul],
    refine is_coprime.mul_dvd _ _ _,
    { have aux := is_primitive.int.irreducible_iff_irreducible_map_cast Pmonic.is_primitive,
      refine (dvd_or_coprime _ _ (aux.1 Pirr)).resolve_left _,
      rw map_dvd_map (int.cast_ring_hom ℚ) int.cast_injective Pmonic,
      intro hdiv,
      refine hdiff (eq_of_monic_of_associated Pmonic Qmonic _),
      exact associated_of_dvd_dvd hdiv (dvd_symm_of_irreducible Pirr Qirr hdiv) },
    { apply (map_dvd_map (int.cast_ring_hom ℚ) int.cast_injective Pmonic).2,
      exact minimal_polynomial_dvd_X_pow_sub_one h hpos },
    { apply (map_dvd_map (int.cast_ring_hom ℚ) int.cast_injective Qmonic).2,
      exact minimal_polynomial_dvd_X_pow_sub_one (pow_of_prime h hprime hdiv) hpos } },
  replace prod := ring_hom.map_dvd (ring_hom.of (map (int.cast_ring_hom (zmod p)))) prod,
  rw [ring_hom.coe_of, map_mul, map_sub, map_one, map_pow, map_X] at prod,
  obtain ⟨R, hR⟩ := minimal_polynomial_dvd_mod_p h hpos hdiv,
  rw [hR, ← mul_assoc, ← map_mul, ← pow_two, map_pow] at prod,
  have habs : map (int.cast_ring_hom (zmod p)) P ^ 2 ∣ map (int.cast_ring_hom (zmod p)) P ^ 2 * R,
  { use R },
  replace habs := lt_of_lt_of_le (enat.coe_lt_coe.2 one_lt_two)
    (multiplicity.le_multiplicity_of_pow_dvd (dvd_trans habs prod)),
  have hfree : squarefree (X ^ n - 1 : polynomial (zmod p)),
  { refine squarefree_X_pow_sub_C 1 _ one_ne_zero,
    by_contra hzero,
    exact hdiv ((zmod.nat_coe_zmod_eq_zero_iff_dvd n p).1 (not_not.1 hzero)) },
  cases (multiplicity.squarefree_iff_multiplicity_le_one (X ^ n - 1)).1 hfree
    (map (int.cast_ring_hom (zmod p)) P) with hle hunit,
  { exact not_lt_of_le hle habs },
  { replace hunit := degree_eq_zero_of_is_unit hunit,
    rw degree_map_eq_of_leading_coeff_ne_zero _ _ at hunit,
    { exact (ne_of_lt (minimal_polynomial.degree_pos (is_integral h hpos))).symm hunit },
    simp only [Pmonic, ring_hom.eq_int_cast, monic.leading_coeff, int.cast_one, ne.def,
      not_false_iff, one_ne_zero] }
end

/-- If `m : ℕ` is coprime with `n`,
then the minimal polynomials of a primitive `n`-th root of unity `μ`
and of `μ ^ m` are the same. -/
lemma minimal_polynomial_eq_pow_coprime {m : ℕ} (hcop : nat.coprime m n) :
  minimal_polynomial (is_integral h hpos) = minimal_polynomial
  (is_integral (h.pow_of_coprime m hcop) hpos) :=
begin
  revert n hcop,
  refine unique_factorization_monoid.induction_on_prime m _ _ _,
  { intros n hn h hpos,
    congr,
    simpa [(nat.coprime_zero_left n).mp hn] using h },
  { intros u hunit n hcop h hpos,
    congr,
    simp [nat.is_unit_iff.mp hunit] },
  { intros a p ha hprime hind n hcop h hpos,
    rw hind (nat.coprime.coprime_mul_left hcop) h hpos, clear hind,
    replace hprime := nat.prime_iff_prime.2 hprime,
    have hdiv := (nat.prime.coprime_iff_not_dvd hprime).1 (nat.coprime.coprime_mul_right hcop),
    letI : fact p.prime := hprime,
    rw [minimal_polynomial_eq_pow
      (h.pow_of_coprime a (nat.coprime.coprime_mul_left hcop)) hpos hdiv],
    congr' 1,
    ring_exp }
end

/-- If `m : ℕ` is coprime with `n`,
then the minimal polynomial of a primitive `n`-th root of unity `μ`
has `μ ^ m` as root. -/
lemma pow_is_root_minimal_polynomial {m : ℕ} (hcop : nat.coprime m n) :
  is_root (map (int.cast_ring_hom K) (minimal_polynomial (is_integral h hpos))) (μ ^ m) :=
by simpa [minimal_polynomial_eq_pow_coprime h hpos hcop, eval_map, aeval_def (μ ^ m) _]
  using minimal_polynomial.aeval (is_integral (h.pow_of_coprime m hcop) hpos)

/-- `primitive_roots n K` is a subset of the roots of the minimal polynomial of a primitive
`n`-th root of unity `μ`. -/
lemma is_roots_of_minimal_polynomial : primitive_roots n K ⊆ (map (int.cast_ring_hom K)
  (minimal_polynomial (is_integral h hpos))).roots.to_finset :=
begin
  intros x hx,
  obtain ⟨m, hle, hcop, rfl⟩ := (is_primitive_root_iff h hpos).1 ((mem_primitive_roots hpos).1 hx),
  simpa [multiset.mem_to_finset,
    mem_roots (map_monic_ne_zero $ minimal_polynomial.monic $ is_integral h hpos)]
    using pow_is_root_minimal_polynomial h hpos hcop
end

/-- The degree of the minimal polynomial of `μ` is at least `totient n`. -/
lemma totient_le_degree_minimal_polynomial : nat.totient n ≤ (minimal_polynomial
  (is_integral h hpos)).nat_degree :=
let P : polynomial ℤ := minimal_polynomial (is_integral h hpos),-- minimal polynomial of `μ`
    P_K : polynomial K := map (int.cast_ring_hom K) P -- minimal polynomial of `μ` sent to `K[X]`
in calc
n.totient = (primitive_roots n K).card : (h.card_primitive_roots hpos).symm
... ≤ P_K.roots.to_finset.card : finset.card_le_of_subset (is_roots_of_minimal_polynomial h hpos)
... ≤ P_K.roots.card : multiset.to_finset_card_le _
... ≤ P_K.nat_degree : (card_roots' $ map_monic_ne_zero
        (minimal_polynomial.monic $ is_integral h hpos))
... ≤ P.nat_degree : nat_degree_map_le _

end minimal_polynomial

end is_primitive_root
