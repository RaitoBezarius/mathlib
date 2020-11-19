/-
Copyright (c) 2020 Thomas Browning and Patrick Lutz. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Thomas Browning and Patrick Lutz
-/

import field_theory.normal
import field_theory.primitive_element
import field_theory.fixed
import ring_theory.power_basis

/-!
# Galois Extensions

In this file we define Galois extensions as extensions which are both separable and normal.

## Main definitions

- `is_galois F E` where `E` is an extension of `F`
- `fixed_field H` where `H : subgroup (E ≃ₐ[F] E)`
- `fixing_subgroup K` where `K : intermediate_field F E`
- `galois_correspondence` where `E/F` is finite dimensional and Galois

## Main results

- `fixing_subgroup_of_fixed_field` : If `E/F` is finite dimensional (but not necessarily Galois)
  then `fixing_subgroup (fixed_field H) = H`
- `fixed_field_of_fixing_subgroup`: If `E/F` is finite dimensional and Galois
  then `fixed_field (fixing_subgroup K) = K`
Together, these two result prove the Galois correspondence
-/

noncomputable theory
open_locale classical

open finite_dimensional alg_equiv

namespace galois

section

variables (F : Type*) [field F] (E : Type*) [field E] [algebra F E]

/-- A field extension E/F is galois if it is both separable and normal -/
@[class] def is_galois : Prop := is_separable F E ∧ normal F E

instance of_fixed_field (G : Type*) [group G] [fintype G] [mul_semiring_action G E] :
  is_galois (mul_action.fixed_points G E) E :=
⟨fixed_points.separable G E, fixed_points.normal G E⟩

instance self : is_galois F F :=
⟨is_separable_self F, normal.self F⟩

instance aut : group (E ≃ₐ[F] E) :=
{ mul := λ ϕ ψ, ψ.trans ϕ,
  mul_assoc := λ ϕ ψ χ, rfl,
  one := 1,
  one_mul := λ ϕ, by {ext, refl},
  mul_one := λ ϕ, by {ext, refl},
  inv := symm,
  mul_left_inv := λ ϕ, by {ext, exact symm_apply_apply ϕ a} }

lemma is_galois_implies_card_aut_eq_findim [finite_dimensional F E] [h : is_galois F E] :
  fintype.card (E ≃ₐ[F] E) = findim F E :=
begin
  cases field.exists_primitive_element h.1 with α hα,
  cases h.1 α with H1 h_separable,
  cases h.2 α with H2 h_splits,
  have switch : (⊤ : intermediate_field F E).to_subalgebra.to_submodule = ⊤ :=
    by { ext, exact iff_of_true intermediate_field.mem_top submodule.mem_top },
  rw [←findim_top, ←switch],
  change fintype.card (E ≃ₐ[F] E) = findim F (⊤ : intermediate_field F E),
  replace h_splits : polynomial.splits (algebra_map F F⟮α⟯) (minimal_polynomial H2),
  { rw hα,
    let map : E →+* (⊤ : intermediate_field F E) :=
    { to_fun := λ x, ⟨x, intermediate_field.mem_top⟩,
      map_one' := rfl,
      map_mul' := λ _ _, rfl,
      map_zero' := rfl,
      map_add' := λ _ _, rfl },
    rw (show algebra_map F (⊤ : intermediate_field F E) = map.comp (algebra_map F E),
      by { ext, refl }),
    exact polynomial.splits_comp_of_splits (algebra_map F E) map h_splits },
  rw [←hα, intermediate_field.adjoin.findim H2],
  rw ← intermediate_field.card_alg_hom_adjoin_integral F H2 h_separable h_splits,
  apply fintype.card_congr,
  transitivity (F⟮α⟯ ≃ₐ[F] F⟮α⟯),
  { rw hα,
    change (E ≃ₐ[F] E) ≃ ((⊤ : intermediate_field F E).to_subalgebra ≃ₐ[F]
      (⊤ : intermediate_field F E).to_subalgebra),
    rw intermediate_field.top_to_subalgebra,
    exact
    { to_fun := λ ϕ, (algebra.top_equiv).trans (trans ϕ (algebra.top_equiv).symm),
      inv_fun := λ ϕ, (algebra.top_equiv).symm.trans (trans ϕ (algebra.top_equiv)),
      left_inv := λ _, by { ext, simp only [apply_symm_apply, trans_apply] },
      right_inv := λ _, by { ext, simp only [symm_apply_apply, trans_apply] } } },
  { exact alg_equiv_equiv_alg_hom F F⟮α⟯ },
end

end

section galois_correspondence

variables {F : Type*} [field F] {E : Type*} [field E] [algebra F E]
variables {E' : Type*} [field E'] [algebra F E']

lemma is_galois_of_alg_equiv_aux (h : E ≃ₐ[F] E') : is_galois F E → is_galois F E' :=
begin
  intro h_gal,
  split,
  { intro x,
    cases h_gal.1 (h.symm x) with hx hhx,
    have H := is_integral_alg_hom h.to_alg_hom hx,
    simp only [alg_equiv.coe_alg_hom, alg_equiv.to_alg_hom_eq_coe, alg_equiv.apply_symm_apply] at H,
    use H,
    apply polynomial.separable.of_dvd hhx,
    apply minimal_polynomial.dvd H,
    apply ring_hom.injective h.symm.to_alg_hom.to_ring_hom,
    rw ring_hom.map_zero,
    exact eq.trans (polynomial.aeval_alg_hom_apply h.symm.to_alg_hom x
      (minimal_polynomial hx)).symm (minimal_polynomial.aeval hx), },
  { intro x,
    cases h_gal.2 (h.symm x) with hx hhx,
    have H := is_integral_alg_hom h.to_alg_hom hx,
    simp only [alg_equiv.coe_alg_hom, alg_equiv.to_alg_hom_eq_coe, alg_equiv.apply_symm_apply] at H,
    use H,
    apply polynomial.splits_of_splits_of_dvd (algebra_map F E') (minimal_polynomial.ne_zero hx),
    { rw (show (algebra_map F E') = h.to_alg_hom.to_ring_hom.comp (algebra_map F E),
          by exact (alg_hom.comp_algebra_map h.to_alg_hom).symm),
      exact polynomial.splits_comp_of_splits (algebra_map F E) h.to_alg_hom.to_ring_hom hhx },
    { apply minimal_polynomial.dvd H,
      apply ring_hom.injective h.symm.to_alg_hom.to_ring_hom,
      rw ring_hom.map_zero,
      exact eq.trans (polynomial.aeval_alg_hom_apply h.symm.to_alg_hom x
        (minimal_polynomial hx)).symm (minimal_polynomial.aeval hx) } }
end

lemma is_galois_of_alg_equiv (h : E ≃ₐ[F] E') : is_galois F E ↔ is_galois F E' :=
⟨is_galois_of_alg_equiv_aux h, is_galois_of_alg_equiv_aux h.symm⟩

variables (H : subgroup (E ≃ₐ[F] E)) (K : intermediate_field F E)

instance tower_top_of_galois [h : is_galois F E] : is_galois K E :=
⟨is_separable_tower_top_of_is_separable K h.1, normal.tower_top_of_normal F K E h.2⟩

instance algebra_over_intermediate_field_bot : algebra (⊥ : intermediate_field F E) F :=
{ to_fun := intermediate_field.bot_equiv,
  map_zero' := alg_equiv.map_zero _,
  map_one' := alg_equiv.map_one _,
  map_add' := alg_equiv.map_add _,
  map_mul' := alg_equiv.map_mul _,
  smul := λ x y, (intermediate_field.bot_equiv x) * y,
  smul_def' := λ _ _, rfl,
  commutes' := λ _ _, mul_comm _ _ }

instance is_scalar_tower_over_intermediate_field_bot :
  is_scalar_tower (⊥ : intermediate_field F E) F E :=
⟨begin
  intros x y z,
  suffices : (algebra_map F E) (algebra_map (⊥ : intermediate_field F E) F x) = ↑x,
  { simp only [algebra.smul_def, ring_hom.map_mul, this, mul_assoc], refl },
  let ϕ := algebra.of_id F (⊥ : subalgebra F E),
  let ψ := alg_equiv.of_bijective ϕ ((algebra.bot_equiv F E).symm.bijective),
  change ↑(ψ (ψ.symm ⟨x, _⟩)) = (↑x : E),
  rw alg_equiv.apply_symm_apply,
  refl,
end⟩

lemma is_galois_iff_is_galois_bot : is_galois (⊥ : intermediate_field F E) E ↔ is_galois F E :=
begin
  split,
  { intro h,
    exact ⟨is_separable_tower_top_of_is_separable _ h.1, normal.tower_top_of_normal _ F E h.2⟩ },
  { intro h,
    exactI galois.tower_top_of_galois ⊥ },
end

lemma is_galois_iff_is_galois_top : is_galois F (⊤ : intermediate_field F E) ↔ is_galois F E :=
is_galois_of_alg_equiv (intermediate_field.top_equiv)

instance is_galois_bot : is_galois F (⊥ : intermediate_field F E) :=
(is_galois_of_alg_equiv intermediate_field.bot_equiv).mpr (galois.self F)

instance subgroup_action : faithful_mul_semiring_action H E :=
{ smul := λ h x, h x,
  smul_zero := λ _, map_zero _,
  smul_add := λ _, map_add _,
  one_smul := λ _, rfl,
  smul_one := λ _, map_one _,
  mul_smul := λ _ _ _, rfl,
  smul_mul := λ _, map_mul _,
  eq_of_smul_eq_smul' := λ x y z, subtype.ext (ext z) }

/-- The intermediate_field fixed by a subgroup -/
def fixed_field : intermediate_field F E :=
{ carrier := mul_action.fixed_points H E,
  zero_mem' := smul_zero,
  add_mem' := λ _ _ hx hy _, by rw [smul_add, hx, hy],
  neg_mem' := λ _ hx _, by rw [smul_neg, hx],
  one_mem' := smul_one,
  mul_mem' := λ _ _ hx hy _, by rw [smul_mul', hx, hy],
  inv_mem' := λ _ hx _, by rw [smul_inv, hx],
  algebra_map_mem' := λ _ _, commutes _ _ }

lemma findim_fixed_field_eq_card [finite_dimensional F E] :
  findim (fixed_field H) E = fintype.card H :=
fixed_points.findim_eq_card H E

/-- The subgroup fixing an intermediate_field -/
def fixing_subgroup : subgroup (E ≃ₐ[F] E) :=
{ carrier := λ ϕ, ∀ x : K, ϕ x = x,
  one_mem' := λ _, rfl,
  mul_mem' := λ _ _ hx hy _, (congr_arg _ (hy _)).trans (hx _),
  inv_mem' := λ _ hx _, (equiv.symm_apply_eq (to_equiv _)).mpr (hx _).symm }

lemma le_iff_le : K ≤ fixed_field H ↔ H ≤ fixing_subgroup K :=
⟨λ h g hg x, h (subtype.mem x) ⟨g, hg⟩, λ h x hx g, h (subtype.mem g) ⟨x, hx⟩⟩

/-- The fixing_subgroup of `K : intermediate_field F E` is isomorphic to `E ≃ₐ[K] E` -/
def fixing_subgroup_iso : fixing_subgroup K ≃* (E ≃ₐ[K] E) :=
{ to_fun := λ ϕ, of_bijective (alg_hom.mk ϕ (map_one ϕ) (map_mul ϕ)
    (map_zero ϕ) (map_add ϕ) (ϕ.mem)) (bijective ϕ),
  inv_fun := λ ϕ, ⟨of_bijective (alg_hom.mk ϕ (ϕ.map_one) (ϕ.map_mul)
    (ϕ.map_zero) (ϕ.map_add) (λ r, ϕ.commutes (algebra_map F K r)))
      (ϕ.bijective), ϕ.commutes⟩,
  left_inv := λ _, by {ext, refl},
  right_inv := λ _, by {ext, refl},
  map_mul' := λ _ _, by {ext, refl} }

theorem fixing_subgroup_of_fixed_field [finite_dimensional F E] :
  fixing_subgroup (fixed_field H) = H :=
begin
  have H_le : H ≤ (fixing_subgroup (fixed_field H)) := (le_iff_le _ _).mp (le_refl _),
  suffices : fintype.card H = fintype.card (fixing_subgroup (fixed_field H)),
  { exact subgroup.ext' (set.eq_of_inclusion_surjective ((fintype.bijective_iff_injective_and_card
    (set.inclusion H_le)).mpr ⟨set.inclusion_injective H_le, this⟩).2).symm },
  rw fintype.card_congr (fixing_subgroup_iso (fixed_field H)).to_equiv,
  rw fintype.card_congr (fixed_points.to_alg_hom_equiv H E),
  rw fintype.card_congr (alg_equiv_equiv_alg_hom (fixed_field H) E),
  exact fintype.card_congr (by refl),
end

instance alg_instance : algebra K (fixed_field (fixing_subgroup K)) :=
{ smul := λ x y, ⟨x*y, λ ϕ, by rw [smul_mul', (show ϕ • ↑x = ↑x, by exact subtype.mem ϕ x),
    (show ϕ • ↑y = ↑y, by exact subtype.mem y ϕ)]⟩,
  to_fun := λ x, ⟨x, λ ϕ, subtype.mem ϕ x⟩,
  map_zero' := rfl,
  map_add' := λ _ _, rfl,
  map_one' := rfl,
  map_mul' := λ _ _, rfl,
  commutes' := λ _ _, mul_comm _ _,
  smul_def' := λ _ _, rfl }

instance tower_instance : is_scalar_tower K (fixed_field (fixing_subgroup K)) E :=
⟨λ _ _ _, mul_assoc _ _ _⟩

theorem fixed_field_of_fixing_subgroup [finite_dimensional F E] [h : is_galois F E] :
  fixed_field (fixing_subgroup K) = K :=
begin
  have K_le : K ≤ fixed_field (fixing_subgroup K) := (le_iff_le _ _).mpr (le_refl _),
  suffices : findim K E = findim (fixed_field (fixing_subgroup K)) E,
  { exact (intermediate_field.eq_of_le_of_findim_eq' K_le this).symm },
  rw [findim_fixed_field_eq_card, fintype.card_congr (fixing_subgroup_iso K).to_equiv],
  exact (is_galois_implies_card_aut_eq_findim K E).symm,
end

lemma card_fixing_subgroup_eq_findim [finite_dimensional F E] [is_galois F E] :
  fintype.card (fixing_subgroup K) = findim K E :=
by conv { to_rhs, rw [←fixed_field_of_fixing_subgroup K, findim_fixed_field_eq_card] }

/-- The Galois correspondence from intermediate fields to subgroups -/
def galois_correspondence [finite_dimensional F E] [is_galois F E] :
  intermediate_field F E ≃o order_dual (subgroup (E ≃ₐ[F] E)) :=
{ to_fun := fixing_subgroup,
  inv_fun := fixed_field,
  left_inv := λ K, fixed_field_of_fixing_subgroup K,
  right_inv := λ H, fixing_subgroup_of_fixed_field H,
  map_rel_iff' := λ K L, by { rw [←fixed_field_of_fixing_subgroup L, le_iff_le,
                                  fixed_field_of_fixing_subgroup L, ←order_dual.dual_le], refl} }

end galois_correspondence

section galois_equivalent_definitions

variables (F : Type*) [field F] (E : Type*) [field E] [algebra F E]

lemma is_separable_splitting_field_of_is_galois [finite_dimensional F E] [h : is_galois F E] :
  ∃ p : polynomial F, p.separable ∧ p.is_splitting_field F E :=
begin
  cases field.exists_primitive_element h.1 with α h1,
  cases h.1 α with h2 h3,
  cases h.2 α with _ h4,
  use minimal_polynomial h2,
  split,
  { exact h3 },
  { split,
    { exact h4 },
    { rw [eq_top_iff, ←intermediate_field.top_to_subalgebra, ←h1],
      rw intermediate_field.adjoin_simple_to_subalgebra_of_integral F α h2,
      apply algebra.adjoin_mono,
      rw [set.singleton_subset_iff, finset.mem_coe, multiset.mem_to_finset, polynomial.mem_roots],
      { dsimp only [polynomial.is_root],
        rw [polynomial.eval_map, ←polynomial.aeval_def],
        exact minimal_polynomial.aeval h2 },
      { exact polynomial.map_ne_zero (minimal_polynomial.ne_zero h2) } } }
end

lemma is_galois_of_fixed_field_eq_bot [finite_dimensional F E]
  (h : fixed_field (⊤ : subgroup (E ≃ₐ[F] E)) = ⊥) : is_galois F E :=
begin
  rw [←is_galois_iff_is_galois_bot, ←h],
  exact galois.of_fixed_field E (⊤ : subgroup (E ≃ₐ[F] E)),
end

lemma is_galois_of_card_aut_eq_findim [finite_dimensional F E]
  (h : fintype.card (E ≃ₐ[F] E) = findim F E) : is_galois F E :=
begin
  apply is_galois_of_fixed_field_eq_bot,
  rw ← intermediate_field.findim_eq_one_iff,
  have ne : findim (fixed_field (⊤ : subgroup (E ≃ₐ[F] E))) E ≠ 0 := (ne_of_lt findim_pos).symm,
  rw [←mul_left_inj' ne, findim_mul_findim, ←h, one_mul, findim_fixed_field_eq_card],
  apply fintype.card_congr,
  exact { to_fun := λ g, ⟨g, subgroup.mem_top g⟩, inv_fun := coe,
          left_inv := λ g, rfl, right_inv := λ _, by { ext, refl } },
end

end galois_equivalent_definitions

section splitting_field_galois
variables {F : Type*} {E : Type*} [field F] [field E] [algebra F E] {p : polynomial F}

lemma is_galois_of_separable_splitting_field_aux [hFE : finite_dimensional F E]
  (sp : p.is_splitting_field F E) (hp : p.separable) (K : intermediate_field F E) {x : E}
  (hx : x ∈ (p.map (algebra_map F E)).roots) :
fintype.card ((↑K⟮x⟯ : intermediate_field F E) →ₐ[F] E) = fintype.card (K →ₐ[F] E) * findim K K⟮x⟯ :=
begin
  have h : is_integral K x := is_integral_of_is_scalar_tower x (is_integral_of_noetherian hFE x),
  rw intermediate_field.adjoin.findim h,
  have p_ne_zero : p ≠ 0,
  { intro p_eq_zero,
    rw [p_eq_zero, polynomial.map_zero, polynomial.roots_zero] at hx,
    exact multiset.not_mem_zero x hx },
  have p_aeval : polynomial.aeval x (p.map (algebra_map F K)) = 0,
  { rw [polynomial.aeval_def, polynomial.eval₂_map, ←is_scalar_tower.algebra_map_eq F K E,
        ←polynomial.eval_map, ←polynomial.is_root,
        ←polynomial.mem_roots (polynomial.map_ne_zero p_ne_zero)],
    exact hx,
    exact field.to_nontrivial E },
  have h_dvd : (minimal_polynomial h) ∣ p.map (algebra_map F K) :=
    minimal_polynomial.dvd h p_aeval,
  have h_sep : (minimal_polynomial h).separable :=
    polynomial.separable.of_dvd ((polynomial.separable_map (algebra_map F K)).mpr hp) h_dvd,
  have p_map_ne_zero : p.map (algebra_map F K) ≠ 0 := polynomial.map_ne_zero p_ne_zero,
  have p_map_splits : (p.map (algebra_map F K)).splits (algebra_map K E),
  { rw [polynomial.splits_map_iff, ←is_scalar_tower.algebra_map_eq F K E],
    exact sp.splits },
  have h_splits : (minimal_polynomial h).splits (algebra_map K E) :=
    polynomial.splits_of_splits_of_dvd (algebra_map K E) p_map_ne_zero p_map_splits h_dvd,
  rw ← intermediate_field.card_alg_hom_adjoin_integral K h h_sep h_splits,
  have key_equiv' : (K⟮x⟯ →ₐ[F] E) ≃
    (K →ₐ[F] E) × {x // x ∈ ((minimal_polynomial h).map (algebra_map K E)).roots} :=
  { to_fun := λ f, ⟨
    { to_fun := λ k, f k,
      map_zero' := f.map_zero,
      map_one' := f.map_one,
      map_add' := λ k l, f.map_add k l,
      map_mul' := λ k l, f.map_mul k l,
      commutes' := λ k, f.commutes k },
    ⟨f (intermediate_field.adjoin_simple.gen K x), begin
      rw polynomial.mem_roots,
      rw polynomial.is_root,
      rw polynomial.eval_map,
      sorry,
      sorry,
    end⟩⟩,
    inv_fun := sorry,
    left_inv := sorry,
    right_inv := sorry, },
  --alg_hom_adjoin_integral_equiv
  have key_equiv : ((↑K⟮x⟯ : intermediate_field F E) →ₐ[F] E) ≃ (K →ₐ[F] E) × (K⟮x⟯ →ₐ[K] E) :=
  { to_fun := sorry,
    inv_fun := sorry,
    left_inv := sorry,
    right_inv := sorry, },
  rw fintype.card_congr key_equiv,
  rw fintype.card_prod,


  apply congr_arg (has_mul.mul (fintype.card (K →ₐ[F] E))),
  apply fintype.card_congr,
  refl,

  /-have key_equiv : ((↑K⟮x⟯ : intermediate_field F E) →ₐ[F] E) ≃
    Σ (f : K →ₐ[F] E), @alg_hom K K⟮x⟯ E _ _ _ _ (ring_hom.to_algebra f) :=
  { to_fun := λ f, ⟨begin sorry end,begin sorry end⟩,
    inv_fun := sorry,
    left_inv := sorry,
    right_inv := sorry, },
  haveI : Π (f : K →ₐ[F] E), fintype (@alg_hom K K⟮x⟯ E _ _ _ _ (ring_hom.to_algebra f)) := sorry,
  rw fintype.card_congr key_equiv,
  rw fintype.card_sigma,
  apply finset.sum_const_nat,
  intros f hf,
  have h : is_integral K x := is_integral_of_is_scalar_tower x (is_integral_of_noetherian hFE x),
  rw intermediate_field.adjoin.findim h,
  have h_sep : (minimal_polynomial h).separable := sorry,
  have h_splits : (minimal_polynomial h).splits
    (@algebra_map K E _ _ (ring_hom.to_algebra f.to_ring_hom)) := sorry,
  have key := @intermediate_field.card_alg_hom_adjoin_integral
    K _ _ _ _ x E _ (ring_hom.to_algebra f.to_ring_hom) h h_sep h_splits,
  exact key,
  sorry,
  sorry,
  sorry,
  sorry,-/
end

lemma is_galois_of_separable_splitting_field (sp : p.is_splitting_field F E) (hp : p.separable) :
  is_galois F E :=
begin
  haveI hFE : finite_dimensional F E := polynomial.is_splitting_field.finite_dimensional E p,
  let p' := (p.map (algebra_map F E)),
  let s := p'.roots.to_finset,
  have adjoin_root : (intermediate_field.adjoin F ↑s).to_subalgebra =
    (⊤ : intermediate_field F E).to_subalgebra,
  { rw [intermediate_field.top_to_subalgebra, eq_top_iff, ←sp.adjoin_roots],
    exact algebra.adjoin_le (intermediate_field.subset_adjoin F ↑s) },
  replace adjoin_root : intermediate_field.adjoin F ↑s = (⊤ : intermediate_field F E),
  { exact intermediate_field.ext (subalgebra.ext_iff.mp adjoin_root) },
  let P : intermediate_field F E → Prop := λ K, fintype.card (K →ₐ[F] E) = findim F K,
  suffices : P (intermediate_field.adjoin F ↑s),
  { rw adjoin_root at this,
    change fintype.card _ = _ at this,
    apply is_galois_of_card_aut_eq_findim,
    have swap : findim F (⊤ : intermediate_field F E) = findim F E :=
      linear_equiv.findim_eq intermediate_field.top_equiv.to_linear_equiv,
    rw [←swap, ← this],
    apply fintype.card_congr,
    transitivity (⊤ : intermediate_field F E) ≃ₐ[F] E,
    { change (E ≃ₐ[F] E) ≃ ((⊤ : intermediate_field F E).to_subalgebra ≃ₐ[F] E),
      rw intermediate_field.top_to_subalgebra,
      exact
      { to_fun := λ ϕ, (algebra.top_equiv).trans ϕ,
        inv_fun := λ ϕ, (algebra.top_equiv).symm.trans ϕ,
        left_inv := λ _, by { ext, simp only [apply_symm_apply, trans_apply] },
        right_inv := λ _, by { ext, simp only [symm_apply_apply, trans_apply] } } },
    { exact alg_equiv_equiv_alg_hom_of_findim_eq swap } },
  have base : P ⊥,
  { change _ = findim F (⊥ : intermediate_field F E).to_subalgebra,
    rw [intermediate_field.bot_to_subalgebra, subalgebra.findim_bot, fintype.card_eq_one_iff],
    use (⊥ : intermediate_field F E).val,
    intro ϕ,
    ext,
    cases intermediate_field.mem_bot.mp (subtype.mem x) with y hy,
    change ↑(algebra_map F (⊥ : intermediate_field F E) y) = ↑x at hy,
    rw [←subtype.ext_iff.mpr hy, ϕ.commutes y],
    refl },
  apply intermediate_field.induction_on_adjoin' F s P base,
  intros K x hx hK,
  change fintype.card _ = _,
  suffices : fintype.card ((↑K⟮x⟯ : intermediate_field F E) →ₐ[F] E) =
    (fintype.card (K →ₐ[F] E)) * (findim K K⟮x⟯),
  { change fintype.card _ = _ at hK,
    rw [this, hK],
    rw findim_mul_findim F K K⟮x⟯,
    exact (linear_equiv.findim_eq (intermediate_field.lift2_alg_equiv K⟮x⟯).to_linear_equiv).symm },
  exact is_galois_of_separable_splitting_field_aux sp hp K (multiset.mem_to_finset.mp hx),
end

end splitting_field_galois

end galois