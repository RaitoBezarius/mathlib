/-
Copyright (c) 2018 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl
-/
import algebra.big_operators.order
import group_theory.coset
import data.nat.totient
import data.int.gcd
import data.set.finite

open function
open_locale big_operators

variables {α : Type*} {s : set α} {a a₁ a₂ b c: α}

-- TODO mem_range_iff_mem_finset_range_of_mod_eq should be moved elsewhere.
namespace finset
open finset

lemma mem_range_iff_mem_finset_range_of_mod_eq [decidable_eq α] {f : ℤ → α} {a : α} {n : ℕ}
  (hn : 0 < n) (h : ∀i, f (i % n) = f i) :
  a ∈ set.range f ↔ a ∈ (finset.range n).image (λi, f i) :=
suffices (∃i, f (i % n) = a) ↔ ∃i, i < n ∧ f ↑i = a, by simpa [h],
have hn' : 0 < (n : ℤ), from int.coe_nat_lt.mpr hn,
iff.intro
  (assume ⟨i, hi⟩,
    have 0 ≤ i % ↑n, from int.mod_nonneg _ (ne_of_gt hn'),
    ⟨int.to_nat (i % n),
      by rw [←int.coe_nat_lt, int.to_nat_of_nonneg this]; exact ⟨int.mod_lt_of_pos i hn', hi⟩⟩)
  (assume ⟨i, hi, ha⟩,
    ⟨i, by rw [int.mod_eq_of_lt (int.coe_zero_le _) (int.coe_nat_lt_coe_nat_of_lt hi), ha]⟩)

end finset

lemma mem_normalizer_fintype [group α] {s : set α} [fintype s] {x : α}
  (h : ∀ n, n ∈ s → x * n * x⁻¹ ∈ s) : x ∈ subgroup.set_normalizer s :=
by haveI := classical.prop_decidable;
haveI := set.fintype_image s (λ n, x * n * x⁻¹); exact
λ n, ⟨h n, λ h₁,
have heq : (λ n, x * n * x⁻¹) '' s = s := set.eq_of_subset_of_card_le
  (λ n ⟨y, hy⟩, hy.2 ▸ h y hy.1) (by rw set.card_image_of_injective s conj_injective),
have x * n * x⁻¹ ∈ (λ n, x * n * x⁻¹) '' s := heq.symm ▸ h₁,
let ⟨y, hy⟩ := this in conj_injective hy.2 ▸ hy.1⟩

section order_of
variable [group α]
open quotient_group set

instance fintype_bot : fintype (⊥ : subgroup α) := ⟨{1},
by {rintro ⟨x, ⟨hx⟩⟩, exact finset.mem_singleton_self _}⟩

@[simp] lemma card_trivial :
  fintype.card (⊥ : subgroup α) = 1 :=
fintype.card_eq_one_iff.2
  ⟨⟨(1 : α), set.mem_singleton 1⟩, λ ⟨y, hy⟩, subtype.eq $ subgroup.mem_bot.1 hy⟩

variables [fintype α] [dec : decidable_eq α]

lemma card_eq_card_quotient_mul_card_subgroup (s : subgroup α) [fintype s]
  [decidable_pred (λ a, a ∈ s)] : fintype.card α = fintype.card (quotient s) * fintype.card s :=
by rw ← fintype.card_prod;
  exact fintype.card_congr (subgroup.group_equiv_quotient_times_subgroup)

lemma card_subgroup_dvd_card (s : subgroup α) [fintype s] :
  fintype.card s ∣ fintype.card α :=
by haveI := classical.prop_decidable; simp [card_eq_card_quotient_mul_card_subgroup s]

lemma card_quotient_dvd_card (s : subgroup α) [decidable_pred (λ a, a ∈ s)] [fintype s] :
  fintype.card (quotient s) ∣ fintype.card α :=
by simp [card_eq_card_quotient_mul_card_subgroup s]

lemma exists_gpow_eq_one (a : α) : ∃i≠0, a ^ (i:ℤ) = 1 :=
have ¬ injective (λi:ℤ, a ^ i),
  from not_injective_infinite_fintype _,
let ⟨i, j, a_eq, ne⟩ := show ∃(i j : ℤ), a ^ i = a ^ j ∧ i ≠ j,
  by rw [injective] at this; simpa [not_forall] in
have a ^ (i - j) = 1,
  by simp [sub_eq_add_neg, gpow_add, gpow_neg, a_eq],
⟨i - j, sub_ne_zero.mpr ne, this⟩

lemma exists_pow_eq_one (a : α) : ∃i > 0, a ^ i = 1 :=
let ⟨i, hi, eq⟩ := exists_gpow_eq_one a in
begin
  cases i,
  { exact ⟨i, nat.pos_of_ne_zero (by simp [int.of_nat_eq_coe, *] at *), eq⟩ },
  { exact ⟨i + 1, dec_trivial, inv_eq_one.1 eq⟩ }
end

include dec

/-- `order_of a` is the order of the element `a`, i.e. the `n ≥ 1`, s.t. `a ^ n = 1` -/
def order_of (a : α) : ℕ := nat.find (exists_pow_eq_one a)

lemma pow_order_of_eq_one (a : α) : a ^ order_of a = 1 :=
let ⟨h₁, h₂⟩ := nat.find_spec (exists_pow_eq_one a) in h₂

lemma order_of_pos (a : α) : 0 < order_of a :=
let ⟨h₁, h₂⟩ := nat.find_spec (exists_pow_eq_one a) in h₁

private lemma pow_injective_aux {n m : ℕ} (a : α) (h : n ≤ m)
  (hn : n < order_of a) (hm : m < order_of a) (eq : a ^ n = a ^ m) : n = m :=
decidable.by_contradiction $ assume ne : n ≠ m,
  have h₁ : m - n > 0, from nat.pos_of_ne_zero (by simp [nat.sub_eq_iff_eq_add h, ne.symm]),
  have h₂ : a ^ (m - n) = 1, by simp [pow_sub _ h, eq],
  have le : order_of a ≤ m - n, from nat.find_min' (exists_pow_eq_one a) ⟨h₁, h₂⟩,
  have lt : m - n < order_of a,
    from (nat.sub_lt_left_iff_lt_add h).mpr $ nat.lt_add_left _ _ _ hm,
  lt_irrefl _ (lt_of_le_of_lt le lt)

lemma pow_injective_of_lt_order_of {n m : ℕ} (a : α)
  (hn : n < order_of a) (hm : m < order_of a) (eq : a ^ n = a ^ m) : n = m :=
(le_total n m).elim
  (assume h, pow_injective_aux a h hn hm eq)
  (assume h, (pow_injective_aux a h hm hn eq.symm).symm)

lemma order_of_le_card_univ : order_of a ≤ fintype.card α :=
finset.card_le_of_inj_on ((^) a)
  (assume n _, fintype.complete _)
  (assume i j, pow_injective_of_lt_order_of a)

lemma pow_eq_mod_order_of {n : ℕ} : a ^ n = a ^ (n % order_of a) :=
calc a ^ n = a ^ (n % order_of a + order_of a * (n / order_of a)) :
    by rw [nat.mod_add_div]
  ... = a ^ (n % order_of a) :
    by simp [pow_add, pow_mul, pow_order_of_eq_one]

lemma gpow_eq_mod_order_of {i : ℤ} : a ^ i = a ^ (i % order_of a) :=
calc a ^ i = a ^ (i % order_of a + order_of a * (i / order_of a)) :
    by rw [int.mod_add_div]
  ... = a ^ (i % order_of a) :
    by simp [gpow_add, gpow_mul, pow_order_of_eq_one]

lemma mem_gpowers_iff_mem_range_order_of {a a' : α} :
  a' ∈ subgroup.gpowers a ↔ a' ∈ (finset.range (order_of a)).image ((^) a : ℕ → α) :=
finset.mem_range_iff_mem_finset_range_of_mod_eq
  (order_of_pos a)
  (assume i, gpow_eq_mod_order_of.symm)

instance decidable_gpowers : decidable_pred (subgroup.gpowers a : set α) :=
assume a', decidable_of_iff'
  (a' ∈ (finset.range (order_of a)).image ((^) a))
  mem_gpowers_iff_mem_range_order_of

lemma order_of_dvd_of_pow_eq_one {n : ℕ} (h : a ^ n = 1) : order_of a ∣ n :=
by_contradiction
  (λ h₁, nat.find_min _ (show n % order_of a < order_of a,
    from nat.mod_lt _ (order_of_pos _))
      ⟨nat.pos_of_ne_zero (mt nat.dvd_of_mod_eq_zero h₁), by rwa ← pow_eq_mod_order_of⟩)

lemma order_of_dvd_iff_pow_eq_one {n : ℕ} : order_of a ∣ n ↔ a ^ n = 1 :=
⟨λ h, by rw [pow_eq_mod_order_of, nat.mod_eq_zero_of_dvd h, pow_zero], order_of_dvd_of_pow_eq_one⟩

lemma order_of_le_of_pow_eq_one {n : ℕ} (hn : 0 < n) (h : a ^ n = 1) : order_of a ≤ n :=
nat.find_min' (exists_pow_eq_one a) ⟨hn, h⟩

lemma sum_card_order_of_eq_card_pow_eq_one {n : ℕ} (hn : 0 < n) :
  ∑ m in (finset.range n.succ).filter (∣ n), (finset.univ.filter (λ a : α, order_of a = m)).card
  = (finset.univ.filter (λ a : α, a ^ n = 1)).card :=
calc ∑ m in (finset.range n.succ).filter (∣ n), (finset.univ.filter (λ a : α, order_of a = m)).card
    = _ : (finset.card_bUnion (by { intros, apply finset.disjoint_filter.2, cc })).symm
... = _ : congr_arg finset.card (finset.ext (begin
  assume a,
  suffices : order_of a ≤ n ∧ order_of a ∣ n ↔ a ^ n = 1,
  { simpa [nat.lt_succ_iff], },
  exact ⟨λ h, let ⟨m, hm⟩ := h.2 in by rw [hm, pow_mul, pow_order_of_eq_one, one_pow],
    λ h, ⟨order_of_le_of_pow_eq_one hn h, order_of_dvd_of_pow_eq_one h⟩⟩
end))

section
local attribute [instance] set_fintype

lemma order_eq_card_gpowers : order_of a = fintype.card (subgroup.gpowers a : set α) :=
begin
  refine (finset.card_eq_of_bijective _ _ _ _).symm,
  { exact λn hn, ⟨gpow a n, ⟨n, rfl⟩⟩ },
  { exact assume ⟨_, i, rfl⟩ _,
    have pos: (0:int) < order_of a,
      from int.coe_nat_lt.mpr $ order_of_pos a,
    have 0 ≤ i % (order_of a),
      from int.mod_nonneg _ $ ne_of_gt pos,
    ⟨int.to_nat (i % order_of a),
      by rw [← int.coe_nat_lt, int.to_nat_of_nonneg this];
        exact ⟨int.mod_lt_of_pos _ pos, subtype.eq gpow_eq_mod_order_of.symm⟩⟩ },
  { intros, exact finset.mem_univ _ },
  { exact assume i j hi hj eq, pow_injective_of_lt_order_of a hi hj $ by simpa using eq }
end

@[simp] lemma order_of_one : order_of (1 : α) = 1 :=
by rw [order_eq_card_gpowers, fintype.card_eq_one_iff];
  exact ⟨⟨1, 0, rfl⟩, λ ⟨a, i, ha⟩, by simp [ha.symm]⟩

@[simp] lemma order_of_eq_one_iff : order_of a = 1 ↔ a = 1 :=
⟨λ h, by conv { to_lhs, rw [← pow_one a, ← h, pow_order_of_eq_one] }, λ h, by simp [h]⟩

lemma order_of_eq_prime {p : ℕ} [hp : fact p.prime]
  (hg : a^p = 1) (hg1 : a ≠ 1) : order_of a = p :=
(hp.2 _ (order_of_dvd_of_pow_eq_one hg)).resolve_left (mt order_of_eq_one_iff.1 hg1)

section classical
open_locale classical
open quotient_group subgroup

/- TODO: use cardinal theory, introduce `card : set α → ℕ`, or setup decidability for cosets -/
lemma order_of_dvd_card_univ : order_of a ∣ fintype.card α :=
have ft_prod : fintype (quotient (gpowers a) × (gpowers a)),
  from fintype.of_equiv α group_equiv_quotient_times_subgroup,
have ft_s : fintype (gpowers a),
  from @fintype.fintype_prod_right _ _ _ ft_prod _,
have ft_cosets : fintype (quotient (gpowers a)),
  from @fintype.fintype_prod_left _ _ _ ft_prod ⟨⟨1, (gpowers a).one_mem⟩⟩,
have eq₁ : fintype.card α = @fintype.card _ ft_cosets * @fintype.card _ ft_s,
  from calc fintype.card α = @fintype.card _ ft_prod :
      @fintype.card_congr _ _ _ ft_prod group_equiv_quotient_times_subgroup
    ... = @fintype.card _ (@prod.fintype _ _ ft_cosets ft_s) :
      congr_arg (@fintype.card _) $ subsingleton.elim _ _
    ... = @fintype.card _ ft_cosets * @fintype.card _ ft_s :
      @fintype.card_prod _ _ ft_cosets ft_s,
have eq₂ : order_of a = @fintype.card _ ft_s,
  from calc order_of a = _ : order_eq_card_gpowers
    ... = _ : congr_arg (@fintype.card _) $ subsingleton.elim _ _,
dvd.intro (@fintype.card (quotient (subgroup.gpowers a)) ft_cosets) $
  by rw [eq₁, eq₂, mul_comm]

omit dec

@[simp] lemma pow_card_eq_one (a : α) : a ^ fintype.card α = 1 :=
let ⟨m, hm⟩ := @order_of_dvd_card_univ _ a _ _ _ in
by simp [hm, pow_mul, pow_order_of_eq_one]

lemma mem_powers_iff_mem_gpowers {a x : α} : x ∈ submonoid.powers a ↔ x ∈ gpowers a :=
⟨λ ⟨n, hn⟩, ⟨n, by simp * at *⟩,
λ ⟨i, hi⟩, ⟨(i % order_of a).nat_abs,
  by rwa [← gpow_coe_nat, int.nat_abs_of_nonneg (int.mod_nonneg _
    (int.coe_nat_ne_zero_iff_pos.2 (order_of_pos _))), ← gpow_eq_mod_order_of]⟩⟩

lemma powers_eq_gpowers (a : α) : (submonoid.powers a : set α) = gpowers a :=
set.ext $ λ x, mem_powers_iff_mem_gpowers

end classical

open nat subgroup

lemma order_of_pow (a : α) (n : ℕ) : order_of (a ^ n) = order_of a / gcd (order_of a) n :=
dvd_antisymm
  (order_of_dvd_of_pow_eq_one
    (by rw [← pow_mul, ← nat.mul_div_assoc _ (gcd_dvd_left _ _), mul_comm,
      nat.mul_div_assoc _ (gcd_dvd_right _ _), pow_mul, pow_order_of_eq_one, one_pow]))
  (have gcd_pos : 0 < gcd (order_of a) n, from gcd_pos_of_pos_left n (order_of_pos a),
    have hdvd : order_of a ∣ n * order_of (a ^ n),
      from order_of_dvd_of_pow_eq_one (by rw [pow_mul, pow_order_of_eq_one]),
    coprime.dvd_of_dvd_mul_right (coprime_div_gcd_div_gcd gcd_pos)
      (dvd_of_mul_dvd_mul_right gcd_pos
        (by rwa [nat.div_mul_cancel (gcd_dvd_left _ _), mul_assoc,
            nat.div_mul_cancel (gcd_dvd_right _ _), mul_comm])))

lemma image_range_order_of (a : α) :
  finset.image (λ i, a ^ i) (finset.range (order_of a)) = (gpowers a : set α).to_finset :=
by { ext x, rw [set.mem_to_finset, mem_coe, mem_gpowers_iff_mem_range_order_of] }

omit dec
open_locale classical

lemma pow_gcd_card_eq_one_iff {n : ℕ} {a : α} :
  a ^ n = 1 ↔ a ^ (gcd n (fintype.card α)) = 1 :=
⟨λ h, pow_gcd_eq_one _ h $ pow_card_eq_one _,
  λ h, let ⟨m, hm⟩ := gcd_dvd_left n (fintype.card α) in
    by rw [hm, pow_mul, h, one_pow]⟩

end

end order_of

section cyclic

local attribute [instance] set_fintype

open subgroup

/-- A group is called *cyclic* if it is generated by a single element. -/
class is_cyclic (α : Type*) [group α] : Prop :=
(exists_generator [] : ∃ g : α, ∀ x, x ∈ gpowers g)

/-- A cyclic group is always commutative. This is not an `instance` because often we have a better
proof of `comm_group`. -/
def is_cyclic.comm_group [hg : group α] [is_cyclic α] : comm_group α :=
{ mul_comm := λ x y, show x * y = y * x,
    from let ⟨g, hg⟩ := is_cyclic.exists_generator α in
    let ⟨n, hn⟩ := hg x in let ⟨m, hm⟩ := hg y in
    hm ▸ hn ▸ gpow_mul_comm _ _ _,
  ..hg }

lemma is_cyclic_of_order_of_eq_card [group α] [decidable_eq α] [fintype α]
  (x : α) (hx : order_of x = fintype.card α) : is_cyclic α :=
⟨⟨x, set.eq_univ_iff_forall.1 $ set.eq_of_subset_of_card_le
  (set.subset_univ _)
  (by {rw [fintype.card_congr (equiv.set.univ α), ← hx, order_eq_card_gpowers], refl})⟩⟩

lemma is_cyclic_of_prime_card [group α] [fintype α] {p : ℕ} [hp : fact p.prime]
  (h : fintype.card α = p) : is_cyclic α :=
⟨begin
  obtain ⟨g, hg⟩ : ∃ g : α, g ≠ 1,
  from fintype.exists_ne_of_one_lt_card (by { rw h, exact nat.prime.one_lt hp }) 1,
  classical, -- for fintype (subgroup.gpowers g)
  have : fintype.card (subgroup.gpowers g) ∣ p,
  { rw ←h,
    apply card_subgroup_dvd_card },
  rw nat.dvd_prime hp at this,
  cases this,
  { rw fintype.card_eq_one_iff at this,
    cases this with t ht,
    suffices : g = 1,
    { contradiction },
    have hgt := ht ⟨g, by { change g ∈ subgroup.gpowers g, exact subgroup.mem_gpowers g }⟩,
    rw [←ht 1] at hgt,
    change (⟨_, _⟩ : subgroup.gpowers g) = ⟨_, _⟩ at hgt,
    simpa using hgt },
  { use g,
    intro x,
    rw [←h] at this,
    rw subgroup.eq_top_of_card_eq _ this,
    exact subgroup.mem_top _ }
end⟩

lemma order_of_eq_card_of_forall_mem_gpowers [group α] [decidable_eq α] [fintype α]
  {g : α} (hx : ∀ x, x ∈ gpowers g) : order_of g = fintype.card α :=
by {rw [← fintype.card_congr (equiv.set.univ α), order_eq_card_gpowers],
  simp [hx], apply fintype.card_of_finset', simp, intro x, exact hx x}

instance bot.is_cyclic [group α] : is_cyclic (⊥ : subgroup α) :=
⟨⟨1, λ x, ⟨0, subtype.eq $ eq.symm (subgroup.mem_bot.1 x.2)⟩⟩⟩

instance subgroup.is_cyclic [group α] [is_cyclic α] (H : subgroup α) : is_cyclic H :=
by haveI := classical.prop_decidable; exact
let ⟨g, hg⟩ := is_cyclic.exists_generator α in
if hx : ∃ (x : α), x ∈ H ∧ x ≠ (1 : α) then
  let ⟨x, hx₁, hx₂⟩ := hx in
  let ⟨k, hk⟩ := hg x in
  have hex : ∃ n : ℕ, 0 < n ∧ g ^ n ∈ H,
    from ⟨k.nat_abs, nat.pos_of_ne_zero
      (λ h, hx₂ $ by rw [← hk, int.eq_zero_of_nat_abs_eq_zero h, gpow_zero]),
        match k, hk with
        | (k : ℕ), hk := by rw [int.nat_abs_of_nat, ← gpow_coe_nat, hk]; exact hx₁
        | -[1+ k], hk := by rw [int.nat_abs_of_neg_succ_of_nat,
          ← subgroup.inv_mem_iff H]; simp * at *
        end⟩,
  ⟨⟨⟨g ^ nat.find hex, (nat.find_spec hex).2⟩,
    λ ⟨x, hx⟩, let ⟨k, hk⟩ := hg x in
      have hk₁ : g ^ ((nat.find hex : ℤ) * (k / nat.find hex)) ∈ gpowers (g ^ nat.find hex),
        from ⟨k / nat.find hex, eq.symm $ gpow_mul _ _ _⟩,
      have hk₂ : g ^ ((nat.find hex : ℤ) * (k / nat.find hex)) ∈ H,
        by rw gpow_mul; exact H.gpow_mem (nat.find_spec hex).2 _,
      have hk₃ : g ^ (k % nat.find hex) ∈ H,
        from (subgroup.mul_mem_cancel_right H hk₂).1 $
          by rw [← gpow_add, int.mod_add_div, hk]; exact hx,
      have hk₄ : k % nat.find hex = (k % nat.find hex).nat_abs,
        by rw int.nat_abs_of_nonneg (int.mod_nonneg _
          (int.coe_nat_ne_zero_iff_pos.2 (nat.find_spec hex).1)),
      have hk₅ : g ^ (k % nat.find hex ).nat_abs ∈ H,
        by rwa [← gpow_coe_nat, ← hk₄],
      have hk₆ : (k % (nat.find hex : ℤ)).nat_abs = 0,
        from by_contradiction (λ h,
          nat.find_min hex (int.coe_nat_lt.1 $ by rw [← hk₄];
            exact int.mod_lt_of_pos _ (int.coe_nat_pos.2 (nat.find_spec hex).1))
          ⟨nat.pos_of_ne_zero h, hk₅⟩),
      ⟨k / (nat.find hex : ℤ), subtype.ext_iff_val.2 begin
        suffices : g ^ ((nat.find hex : ℤ) * (k / nat.find hex)) = x,
        { simpa [gpow_mul] },
        rw [int.mul_div_cancel' (int.dvd_of_mod_eq_zero (int.eq_zero_of_nat_abs_eq_zero hk₆)), hk]
      end⟩⟩⟩
else
  have H = (⊥ : subgroup α), from subgroup.ext $ λ x, ⟨λ h, by simp at *; tauto,
    λ h, by rw [subgroup.mem_bot.1 h]; exact H.one_mem⟩,
  by clear _let_match; substI this; apply_instance

open finset nat
lemma is_cyclic.card_pow_eq_one_le [group α] [decidable_eq α] [fintype α] [is_cyclic α] {n : ℕ}
  (hn0 : 0 < n) : (univ.filter (λ a : α, a ^ n = 1)).card ≤ n :=
let ⟨g, hg⟩ := is_cyclic.exists_generator α in
calc (univ.filter (λ a : α, a ^ n = 1)).card
  ≤ ((gpowers (g ^ (fintype.card α / (gcd n (fintype.card α))))) : set α).to_finset.card :
  card_le_of_subset (λ x hx, let ⟨m, hm⟩ := show x ∈ submonoid.powers g,
    from mem_powers_iff_mem_gpowers.2 $ hg x in
    set.mem_to_finset.2 ⟨(m / (fintype.card α / (gcd n (fintype.card α))) : ℕ),
      have hgmn : g ^ (m * gcd n (fintype.card α)) = 1,
        by rw [pow_mul, hm, ← pow_gcd_card_eq_one_iff]; exact (mem_filter.1 hx).2,
      begin
        rw [gpow_coe_nat, ← pow_mul, nat.mul_div_cancel_left', hm],
        refine dvd_of_mul_dvd_mul_right (gcd_pos_of_pos_left (fintype.card α) hn0) _,
        conv {to_lhs, rw [nat.div_mul_cancel (gcd_dvd_right _ _), ← order_of_eq_card_of_forall_mem_gpowers hg]},
        exact order_of_dvd_of_pow_eq_one hgmn
      end⟩)
... ≤ n :
  let ⟨m, hm⟩ := gcd_dvd_right n (fintype.card α) in
  have hm0 : 0 < m, from nat.pos_of_ne_zero
    (λ hm0, (by rw [hm0, mul_zero, fintype.card_eq_zero_iff] at hm; exact hm 1)),
  begin
    rw [← fintype.card_of_finset' _ (λ _, set.mem_to_finset), ← order_eq_card_gpowers,
      order_of_pow, order_of_eq_card_of_forall_mem_gpowers hg],
    rw [hm] {occs := occurrences.pos [2,3]},
    rw [nat.mul_div_cancel_left _  (gcd_pos_of_pos_left _ hn0), gcd_mul_left_left,
      hm, nat.mul_div_cancel _ hm0],
    exact le_of_dvd hn0 (gcd_dvd_left _ _)
  end

lemma is_cyclic.exists_monoid_generator (α : Type*) [group α] [fintype α] [is_cyclic α] :
  ∃ x : α, ∀ y : α, y ∈ submonoid.powers x :=
by { simp only [mem_powers_iff_mem_gpowers], exact is_cyclic.exists_generator α }

section

variables [group α] [decidable_eq α] [fintype α]

lemma is_cyclic.image_range_order_of (ha : ∀ x : α, x ∈ gpowers a) :
  finset.image (λ i, a ^ i) (range (order_of a)) = univ :=
begin
  simp_rw [←subgroup.mem_coe] at ha,
  simp only [image_range_order_of, set.eq_univ_iff_forall.mpr ha],
  convert set.to_finset_univ
end

lemma is_cyclic.image_range_card (ha : ∀ x : α, x ∈ gpowers a) :
  finset.image (λ i, a ^ i) (range (fintype.card α)) = univ :=
by rw [← order_of_eq_card_of_forall_mem_gpowers ha, is_cyclic.image_range_order_of ha]

end

section totient

variables [group α] [decidable_eq α] [fintype α] (hn : ∀ n : ℕ, 0 < n → (univ.filter (λ a : α, a ^ n = 1)).card ≤ n)
include hn

lemma card_pow_eq_one_eq_order_of_aux (a : α) :
  (finset.univ.filter (λ b : α, b ^ order_of a = 1)).card = order_of a :=
le_antisymm
  (hn _ (order_of_pos _))
  (calc order_of a = @fintype.card (gpowers a) (id _) : order_eq_card_gpowers
    ... ≤ @fintype.card (↑(univ.filter (λ b : α, b ^ order_of a = 1)) : set α)
    (fintype.of_finset _ (λ _, iff.rfl)) :
      @fintype.card_le_of_injective (gpowers a) (↑(univ.filter (λ b : α, b ^ order_of a = 1)) : set α)
        (id _) (id _) (λ b, ⟨b.1, mem_filter.2 ⟨mem_univ _,
          let ⟨i, hi⟩ := b.2 in
          by rw [← hi, ← gpow_coe_nat, ← gpow_mul, mul_comm, gpow_mul, gpow_coe_nat,
            pow_order_of_eq_one, one_gpow]⟩⟩) (λ _ _ h, subtype.eq (subtype.mk.inj h))
    ... = (univ.filter (λ b : α, b ^ order_of a = 1)).card : fintype.card_of_finset _ _)

open_locale nat -- use φ for nat.totient

private lemma card_order_of_eq_totient_aux₁ :
  ∀ {d : ℕ}, d ∣ fintype.card α → 0 < (univ.filter (λ a : α, order_of a = d)).card →
  (univ.filter (λ a : α, order_of a = d)).card = φ d
| 0     := λ hd hd0,
let ⟨a, ha⟩ := card_pos.1 hd0 in absurd (mem_filter.1 ha).2 $ ne_of_gt $ order_of_pos a
| (d+1) := λ hd hd0,
let ⟨a, ha⟩ := card_pos.1 hd0 in
have ha : order_of a = d.succ, from (mem_filter.1 ha).2,
have h : ∑ m in (range d.succ).filter (∣ d.succ),
    (univ.filter (λ a : α, order_of a = m)).card =
    ∑ m in (range d.succ).filter (∣ d.succ), φ m, from
  finset.sum_congr rfl
    (λ m hm, have hmd : m < d.succ, from mem_range.1 (mem_filter.1 hm).1,
      have hm : m ∣ d.succ, from (mem_filter.1 hm).2,
      card_order_of_eq_totient_aux₁ (dvd.trans hm hd) (finset.card_pos.2
        ⟨a ^ (d.succ / m), mem_filter.2 ⟨mem_univ _,
          by rw [order_of_pow, ha, gcd_eq_right (div_dvd_of_dvd hm),
            nat.div_div_self hm (succ_pos _)]⟩⟩)),
have hinsert : insert d.succ ((range d.succ).filter (∣ d.succ))
    = (range d.succ.succ).filter (∣ d.succ),
  from (finset.ext $ λ x, ⟨λ h, (mem_insert.1 h).elim (λ h, by simp [h, range_succ])
    (by clear _let_match; simp [range_succ]; tauto), by clear _let_match; simp [range_succ] {contextual := tt}; tauto⟩),
have hinsert₁ : d.succ ∉ (range d.succ).filter (∣ d.succ),
  by simp [mem_range, zero_le_one, le_succ],
(add_left_inj (∑ m in (range d.succ).filter (∣ d.succ),
  (univ.filter (λ a : α, order_of a = m)).card)).1
  (calc _ = ∑ m in insert d.succ (filter (∣ d.succ) (range d.succ)),
        (univ.filter (λ a : α, order_of a = m)).card :
    eq.symm (finset.sum_insert (by simp [mem_range, zero_le_one, le_succ]))
  ... = ∑ m in (range d.succ.succ).filter (∣ d.succ),
      (univ.filter (λ a : α, order_of a = m)).card :
    sum_congr hinsert (λ _ _, rfl)
  ... = (univ.filter (λ a : α, a ^ d.succ = 1)).card :
    sum_card_order_of_eq_card_pow_eq_one (succ_pos d)
  ... = ∑ m in (range d.succ.succ).filter (∣ d.succ), φ m :
    ha ▸ (card_pow_eq_one_eq_order_of_aux hn a).symm ▸ (sum_totient _).symm
  ... = _ : by rw [h, ← sum_insert hinsert₁];
      exact finset.sum_congr hinsert.symm (λ _ _, rfl))

lemma card_order_of_eq_totient_aux₂ {d : ℕ} (hd : d ∣ fintype.card α) :
  (univ.filter (λ a : α, order_of a = d)).card = φ d :=
by_contradiction $ λ h,
have h0 : (univ.filter (λ a : α , order_of a = d)).card = 0 :=
  not_not.1 (mt pos_iff_ne_zero.2 (mt (card_order_of_eq_totient_aux₁ hn hd) h)),
let c := fintype.card α in
have hc0 : 0 < c, from fintype.card_pos_iff.2 ⟨1⟩,
lt_irrefl c $
  calc c = (univ.filter (λ a : α, a ^ c = 1)).card :
    congr_arg card $ by simp [finset.ext_iff, c]
  ... = ∑ m in (range c.succ).filter (∣ c),
      (univ.filter (λ a : α, order_of a = m)).card :
    (sum_card_order_of_eq_card_pow_eq_one hc0).symm
  ... = ∑ m in ((range c.succ).filter (∣ c)).erase d,
      (univ.filter (λ a : α, order_of a = m)).card :
    eq.symm (sum_subset (erase_subset _ _) (λ m hm₁ hm₂,
      have m = d, by simp at *; cc,
      by simp [*, finset.ext_iff] at *; exact h0))
  ... ≤ ∑ m in ((range c.succ).filter (∣ c)).erase d, φ m :
    sum_le_sum (λ m hm,
      have hmc : m ∣ c, by simp at hm; tauto,
      (imp_iff_not_or.1 (card_order_of_eq_totient_aux₁ hn hmc)).elim
        (λ h, by simp [nat.le_zero_iff.1 (le_of_not_gt h), nat.zero_le])
        (λ h, by rw h))
  ... < φ d + ∑ m in ((range c.succ).filter (∣ c)).erase d, φ m :
    lt_add_of_pos_left _ (totient_pos (nat.pos_of_ne_zero
      (λ h, pos_iff_ne_zero.1 hc0 (eq_zero_of_zero_dvd $ h ▸ hd))))
  ... = ∑ m in insert d (((range c.succ).filter (∣ c)).erase d), φ m : eq.symm (sum_insert (by simp))
  ... = ∑ m in (range c.succ).filter (∣ c), φ m : finset.sum_congr
      (finset.insert_erase (mem_filter.2 ⟨mem_range.2 (lt_succ_of_le (le_of_dvd hc0 hd)), hd⟩)) (λ _ _, rfl)
  ... = c : sum_totient _

lemma is_cyclic_of_card_pow_eq_one_le : is_cyclic α :=
have (univ.filter (λ a : α, order_of a = fintype.card α)).nonempty,
from (card_pos.1 $
  by rw [card_order_of_eq_totient_aux₂ hn (dvd_refl _)];
  exact totient_pos (fintype.card_pos_iff.2 ⟨1⟩)),
let ⟨x, hx⟩ := this in
is_cyclic_of_order_of_eq_card x (finset.mem_filter.1 hx).2

end totient

lemma is_cyclic.card_order_of_eq_totient [group α] [is_cyclic α] [decidable_eq α] [fintype α]
  {d : ℕ} (hd : d ∣ fintype.card α) : (univ.filter (λ a : α, order_of a = d)).card = totient d :=
card_order_of_eq_totient_aux₂ (λ n, is_cyclic.card_pow_eq_one_le) hd

end cyclic
