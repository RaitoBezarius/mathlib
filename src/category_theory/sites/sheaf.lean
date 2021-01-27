/-
Copyright (c) 2020 Kevin Buzzard, Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Buzzard, Bhavik Mehta
-/

import category_theory.sites.sheaf_of_types
import category_theory.limits.yoneda
import category_theory.limits.preserves.shapes.equalizers
import category_theory.limits.preserves.shapes.products
import category_theory.concrete_category

/-!
# Sheaves taking values in a category

If C is a category with a Grothendieck topology, we define the notion of a sheaf taking values in
an arbitrary category `A`. We follow the definition in https://stacks.math.columbia.edu/tag/00VR,
noting that the presheaf of sets "defined above" can be seen in the comments between tags 00VQ and
00VR on the page https://stacks.math.columbia.edu/tag/00VL. The advantage of this definition is
that we need no assumptions whatsoever on `A` other than the assumption that the morphisms in `C`
and `A` live in the same universe.
-/

universes v v' u' u

noncomputable theory

namespace category_theory

open opposite category_theory category limits sieve classical

namespace presheaf

variables {C : Type u} [category.{v} C]
variables {A : Type u'} [category.{v} A]
variables (J : grothendieck_topology C)

-- We follow https://stacks.math.columbia.edu/tag/00VL definition 00VR

/--
A sheaf of A is a presheaf P : C^op => A such that for every X : A, the
presheaf of types given by sending U : C to Hom_{A}(X, P U) is a sheaf of types.

https://stacks.math.columbia.edu/tag/00VR
-/
def is_sheaf (P : Cᵒᵖ ⥤ A) : Prop :=
∀ X : A, presieve.is_sheaf J (P ⋙ coyoneda.obj (op X))

end presheaf

variables {C : Type u} [category.{v} C]
variables (J : grothendieck_topology C)
variables (A : Type u') [category.{v} A]

/-- The category of sheaves taking values in `A` on a grothendieck topology. -/
@[derive category]
def Sheaf : Type* :=
{P : Cᵒᵖ ⥤ A // presheaf.is_sheaf J P}

/-- The inclusion functor from sheaves to presheaves. -/
@[simps {rhs_md := semireducible}, derive [full, faithful]]
def Sheaf_to_presheaf : Sheaf J A ⥤ (Cᵒᵖ ⥤ A) :=
full_subcategory_inclusion (presheaf.is_sheaf J)

theorem Sheaf_is_SheafOfTypes (P : Cᵒᵖ ⥤ Type v) (hP : presheaf.is_sheaf J P) :
  presieve.is_sheaf J P :=
begin
  specialize hP punit,
  apply presieve.is_sheaf_iso J _ hP,
  apply coyoneda.iso_comp_punit,
end

theorem SheafOfTypes_is_Sheaf (P : Cᵒᵖ ⥤ Type v) (hP : presieve.is_sheaf J P) :
  presheaf.is_sheaf J P :=
begin
  intros X Y S hS z hz,
  change ∃! (t : X ⟶ _), _,
  refine ⟨λ x, (hP S hS).amalgamate (λ Z f hf, z f hf x) _, _, _⟩,
  { intros Y₁ Y₂ Z g₁ g₂ f₁ f₂ hf₁ hf₂ h,
    exact congr_fun (hz g₁ g₂ hf₁ hf₂ h) x },
  { intros Z f hf,
    ext x,
    apply presieve.is_sheaf_for.valid_glue },
  { intros y hy,
    ext x,
    apply (hP S hS).is_separated_for.ext,
    intros Y' f hf,
    rw presieve.is_sheaf_for.valid_glue _ _ _ hf,
    rw ← hy _ hf,
    refl }
end

/--
The category of sheaves taking values in Type is the same as the category of set-valued sheaves.
-/
@[simps]
def Sheaf_equiv_SheafOfTypes : Sheaf J (Type v) ≌ SheafOfTypes J :=
{ functor :=
  { obj := λ S, ⟨S.1, Sheaf_is_SheafOfTypes _ _ S.2⟩,
    map := λ S₁ S₂ f, f },
  inverse :=
  { obj := λ S, ⟨S.1, SheafOfTypes_is_Sheaf _ _ S.2⟩,
    map := λ S₁ S₂ f, f },
  unit_iso := nat_iso.of_components (λ X, ⟨𝟙 _, 𝟙 _, by tidy, by tidy⟩) (by tidy),
  counit_iso := nat_iso.of_components (λ X, ⟨𝟙 _, 𝟙 _, by tidy, by tidy⟩) (by tidy) }

instance : inhabited (Sheaf (⊥ : grothendieck_topology C) (Type v)) :=
⟨(Sheaf_equiv_SheafOfTypes _).inverse.obj (default _)⟩

end category_theory

namespace category_theory

open opposite category_theory category limits sieve classical

namespace presheaf

-- under here is the equalizer story, which is equivalent if A has products (and doesn't
-- make sense otherwise). It's described between 00VQ and 00VR in stacks.
-- we need [category.{u} A] possibly

variables {C : Type v} [small_category C]

variables {A : Type u} [category.{v} A] [has_products A]

variables (J : grothendieck_topology C)

variables {U : C} (R : presieve U)

variables (P : Cᵒᵖ ⥤ A)

def first_obj : A :=
∏ (λ (f : Σ V, {f : V ⟶ U // R f}), P.obj (op f.1))

variables [has_pullbacks C]

/--
The rightmost object of the fork diagram of https://stacks.math.columbia.edu/tag/00VM, which
contains the data used to check a family of elements for a presieve is compatible.
-/
def second_obj : A :=
∏ (λ (fg : (Σ V, {f : V ⟶ U // R f}) × (Σ W, {g : W ⟶ U // R g})),
  P.obj (op (pullback fg.1.2.1 fg.2.2.1)))

/-- The map `pr₀*` of https://stacks.math.columbia.edu/tag/00VL. -/
def first_map : first_obj R P ⟶ second_obj R P :=
pi.lift (λ fg, pi.π _ _ ≫ P.map pullback.fst.op)

/-- The map `pr₁*` of https://stacks.math.columbia.edu/tag/00VL. -/
def second_map : first_obj R P ⟶ second_obj R P :=
pi.lift (λ fg, pi.π _ _ ≫ P.map pullback.snd.op)

/--
The left morphism of the fork diagram given in Equation (3) of [MM92], as well as the fork diagram
of https://stacks.math.columbia.edu/tag/00VM.
-/
def fork_map : P.obj (op U) ⟶ first_obj R P :=
pi.lift (λ f, P.map f.2.1.op)

lemma w : fork_map R P ≫ first_map R P = fork_map R P ≫ second_map R P :=
begin
  apply limit.hom_ext,
  rintro ⟨⟨Y, f, hf⟩, ⟨Z, g, hg⟩⟩,
  simp only [first_map, second_map, fork_map, limit.lift_π, limit.lift_π_assoc, assoc,
    fan.mk_π_app, subtype.coe_mk, subtype.val_eq_coe],
  rw [← P.map_comp, ← op_comp, pullback.condition],
  simp,
end

def is_sheaf' (P : Cᵒᵖ ⥤ A) : Prop := ∀ (U : C) (R : presieve U) (hR : generate R ∈ J U),
nonempty (is_limit (fork.of_ι _ (w R P)))

def is_sheaf_for_is_sheaf_for' (P : Cᵒᵖ ⥤ A) (X) (U : C) (R : presieve U) :
  is_limit ((coyoneda.obj X).map_cone (fork.of_ι _ (w R P))) ≃
    is_limit (fork.of_ι _ (equalizer.presieve.w (P ⋙ coyoneda.obj X) R)) :=
begin
  apply equiv.trans (is_limit_map_cone_fork_equiv _ _) _,
  apply (is_limit.postcompose_hom_equiv _ _).symm.trans (is_limit.equiv_iso_limit _),
  { apply nat_iso.of_components _ _,
    { rintro (_ | _),
      { apply preserves_product.iso (coyoneda.obj X) },
      { apply preserves_product.iso (coyoneda.obj X) } },
    { rintro _ _ (_ | _),
      { ext : 1,
        dsimp [equalizer.presieve.first_map, first_map],
        simp only [limit.lift_π, map_lift_pi_comparison, assoc, fan.mk_π_app, functor.map_comp],
        erw limit.lift_π,
        erw pi_comparison_comp_π_assoc,
        simp },
      { ext : 1,
        dsimp [equalizer.presieve.second_map, second_map],
        simp only [limit.lift_π, map_lift_pi_comparison, assoc, fan.mk_π_app, functor.map_comp],
        erw limit.lift_π,
        erw pi_comparison_comp_π_assoc,
        simp },
      { dsimp,
        simp } } },
  { refine fork.ext (iso.refl _) _,
    dsimp [equalizer.fork_map, fork_map],
    simp }

end

theorem is_sheaf_iff_is_sheaf' (P : Cᵒᵖ ⥤ A) :
  is_sheaf J P ↔ is_sheaf' J P :=
begin
  split,
  { intros h U R hR,
    refine ⟨_⟩,
    apply coyoneda_jointly_reflects_limits,
    intro X,
    have q : presieve.is_sheaf_for (P ⋙ coyoneda.obj X) _ := h X.unop _ hR,
    rw ←presieve.is_sheaf_for_iff_generate at q,
    rw equalizer.presieve.sheaf_condition at q,
    replace q := classical.choice q,
    apply (is_sheaf_for_is_sheaf_for' _ _ _ _).symm q },
  { intros h U X S hS,
    rw equalizer.presieve.sheaf_condition,
    refine ⟨_⟩,
    refine is_sheaf_for_is_sheaf_for' _ _ _ _ _,
    apply is_limit_of_preserves,
    apply classical.choice (h _ S _),
    simpa }
end

end presheaf

end category_theory
