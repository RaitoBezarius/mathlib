/-
Copyright (c) 2020 Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta
-/

import category_theory.sites.pretopology
import category_theory.limits.shapes.types
import category_theory.full_subcategory

/-!
# Sheaves of types on a Grothendieck topology

Defines the notion of a sheaf of types (usually called a sheaf of sets by mathematicians)
on a category equipped with a Grothendieck topology, as well as a range of equivalent
conditions useful in different situations.

First define what it means for a presheaf `P : Cᵒᵖ ⥤ Type v` to be a sheaf *for* a particular
presieve `R` on `X`:
* A *family of elements* `x` for `P` at `R` is an element `x_f` of `P Y` for every `f : Y ⟶ X` in
  `R`. See `family_of_elements`.
* The family `x` is *compatible* if, for any `f₁ : Y₁ ⟶ X` and `f₂ : Y₂ ⟶ X` both in `R`,
  and any `g₁ : Z ⟶ Y₁` and `g₂ : Z ⟶ Y₂` such that `g₁ ≫ f₁ = g₂ ≫ f₂`, the restriction of
  `x_f₁` along `g₁` agrees with the restriction of `x_f₂` along `g₂`.
  See `family_of_elements.compatible`.
* An *amalgamation* `t` for the family is an element of `P X` such that for every `f : Y ⟶ X` in
  `R`, the restriction of `t` on `f` is `x_f`.
  See `family_of_elements.is_amalgamation`.
We then say `P` is *separated* for `R` if every compatible family has at most one amalgamation,
and it is a *sheaf* for `R` if every compatible family has a unique amalgamation.
See `is_separated_for` and `is_sheaf_for`.

In the special case where `R` is a sieve, the compatibility condition can be simplified:
* The family `x` is *compatible* if, for any `f : Y ⟶ X` in `R` and `g : Z ⟶ Y`, the restriction of
  `x_f` along `g` agrees with `x_(g ≫ f)` (which is well defined since `g ≫ f` is in `R`).
See `family_of_elements.sieve_compatible` and `compatible_iff_sieve_compatible`.

In the special case where `C` has pullbacks, the compatibility condition can be simplified:
* The family `x` is *compatible* if, for any `f : Y ⟶ X` and `g : Z ⟶ X` both in `R`,
  the restriction of `x_f` along `π₁ : pullback f g ⟶ Y` agrees with the restriction of `x_g`
  along `π₂ : pullback f g ⟶ Z`.
See `family_of_elements.pullback_compatible` and `pullback_compatible_iff`.

Now given a Grothendieck topology `J`, `P` is a sheaf if it is a sheaf for every sieve in the
topology. See `is_sheaf`.

In the case where the topology is generated by a basis, it suffices to check `P` is a sheaf for
every sieve in the pretopology. See `is_sheaf_pretopology`.

We also provide equivalent conditions to satisfy alternate definitions given in the literature.

* Stacks: In `equalizer.presieve.sheaf_condition`, the sheaf condition at a presieve is shown to be
  equivalent to that of https://stacks.math.columbia.edu/tag/00VM (and combined with
  `is_sheaf_pretopology`, this shows the notions of `is_sheaf` are exactly equivalent.)

  The condition of https://stacks.math.columbia.edu/tag/00Z8 is virtually identical to the
  statement of `yoneda_condition_iff_sheaf_condition` (since the bijection described there carries
  the same information as the unique existence.)

* Maclane-Moerdijk [MM92]: Using `compatible_iff_sieve_compatible`, the definitions of `is_sheaf`
  are equivalent. There are also alternate definitions given:
  - Yoneda condition: Defined in `yoneda_sheaf_condition` and equivalence in
    `yoneda_condition_iff_sheaf_condition`.
  - Equalizer condition (Equation 3): Defined in the `equalizer.sieve` namespace, and equivalence
    in `equalizer.sieve.sheaf_condition`.
  - Matching family for presieves with pullback: `pullback_compatible_iff`.
  - Sheaf for a pretopology (Prop 1): `is_sheaf_pretopology` combined with the previous.
  - Sheaf for a pretopology as equalizer (Prop 1, bis): `equalizer.presieve.sheaf_condition`
    combined with the previous.

## Implementation

The sheaf condition is given as a proposition, rather than a subsingleton in `Type (max u v)`.
This doesn't seem to make a big difference, other than making a couple of definitions noncomputable,
but it means that equivalent conditions can be given as `↔` statements rather than `≃` statements,
which can be convenient.

## References

* [MM92]: *Sheaves in geometry and logic*, Saunders MacLane, and Ieke Moerdijk:
  Chapter III, Section 4.
* [Elephant]: *Sketches of an Elephant*, P. T. Johnstone: C2.1.
* https://stacks.math.columbia.edu/tag/00VL (sheaves on a pretopology or site)
* https://stacks.math.columbia.edu/tag/00ZB (sheaves on a topology)

-/

universes v u
namespace category_theory

open opposite category_theory category limits sieve classical

namespace presieve

variables {C : Type u} [category.{v} C]

variables {P : Cᵒᵖ ⥤ Type v}
variables {X Y : C} {S : sieve X} {R : presieve X}
variables (J J₂ : grothendieck_topology C)

/--
A family of elements for a presheaf `P` given a collection of arrows `R` with fixed codomain `X`
consists of an element of `P Y` for every `f : Y ⟶ X` in `R`.
A presheaf is a sheaf (resp, separated) if every *compatible* family of elements has exactly one
(resp, at most one) amalgamation.

This data is referred to as a `family` in [MM92], Chapter III, Section 4. It is also a concrete
version of the elements of the middle object in https://stacks.math.columbia.edu/tag/00VM which is
more useful for direct calculations. It is also used implicitly in Definition C2.1.2 in [Elephant].
-/
def family_of_elements (P : Cᵒᵖ ⥤ Type v) (R : presieve X) :=
Π ⦃Y : C⦄ (f : Y ⟶ X), R f → P.obj (op Y)

instance : inhabited (family_of_elements P (⊥ : presieve X)) := ⟨λ Y f, false.elim⟩

/--
A family of elements for a presheaf on the presieve `R₂` can be restricted to a smaller presieve
`R₁`.
-/
def family_of_elements.restrict {R₁ R₂ : presieve X} (h : R₁ ≤ R₂) :
  family_of_elements P R₂ → family_of_elements P R₁ :=
λ x Y f hf, x f (h _ hf)

/--
A family of elements for the arrow set `R` is *compatible* if for any `f₁ : Y₁ ⟶ X` and
`f₂ : Y₂ ⟶ X` in `R`, and any `g₁ : Z ⟶ Y₁` and `g₂ : Z ⟶ Y₂`, if the square `g₁ ≫ f₁ = g₂ ≫ f₂`
commutes then the elements of `P Z` obtained by restricting the element of `P Y₁` along `g₁` and
restricting the element of `P Y₂` along `g₂` are the same.

In special cases, this condition can be simplified, see `pullback_compatible_iff` and
`compatible_iff_sieve_compatible`.

This is referred to as a "compatible family" in Definition C2.1.2 of [Elephant], and on nlab:
https://ncatlab.org/nlab/show/sheaf#GeneralDefinitionInComponents
-/
def family_of_elements.compatible (x : family_of_elements P R) : Prop :=
∀ ⦃Y₁ Y₂ Z⦄ (g₁ : Z ⟶ Y₁) (g₂ : Z ⟶ Y₂) ⦃f₁ : Y₁ ⟶ X⦄ ⦃f₂ : Y₂ ⟶ X⦄
  (h₁ : R f₁) (h₂ : R f₂), g₁ ≫ f₁ = g₂ ≫ f₂ → P.map g₁.op (x f₁ h₁) = P.map g₂.op (x f₂ h₂)

/--
If the category `C` has pullbacks, this is an alternative condition for a family of elements to be
compatible: For any `f : Y ⟶ X` and `g : Z ⟶ X` in the presieve `R`, the restriction of the
given elements for `f` and `g` to the pullback agree.
This is equivalent to being compatible (provided `C` has pullbacks), shown in
`pullback_compatible_iff`.

This is the definition for a "matching" family given in [MM92], Chapter III, Section 4,
Equation (5). Viewing the type `family_of_elements` as the middle object of the fork in
https://stacks.math.columbia.edu/tag/00VM, this condition expresses that `pr₀* (x) = pr₁* (x)`,
using the notation defined there.
-/
def family_of_elements.pullback_compatible (x : family_of_elements P R) [has_pullbacks C] : Prop :=
∀ ⦃Y₁ Y₂⦄ ⦃f₁ : Y₁ ⟶ X⦄ ⦃f₂ : Y₂ ⟶ X⦄ (h₁ : R f₁) (h₂ : R f₂),
  P.map (pullback.fst : pullback f₁ f₂ ⟶ _).op (x f₁ h₁) = P.map pullback.snd.op (x f₂ h₂)

lemma pullback_compatible_iff (x : family_of_elements P R) [has_pullbacks C] :
  x.compatible ↔ x.pullback_compatible :=
begin
  split,
  { intros t Y₁ Y₂ f₁ f₂ hf₁ hf₂,
    apply t,
    apply pullback.condition },
  { intros t Y₁ Y₂ Z g₁ g₂ f₁ f₂ hf₁ hf₂ comm,
    rw [←pullback.lift_fst _ _ comm, op_comp, functor_to_types.map_comp_apply, t hf₁ hf₂,
        ←functor_to_types.map_comp_apply, ←op_comp, pullback.lift_snd] }
end

/-- The restriction of a compatible family is compatible. -/
lemma family_of_elements.compatible.restrict {R₁ R₂ : presieve X} (h : R₁ ≤ R₂)
  {x : family_of_elements P R₂} : x.compatible → (x.restrict h).compatible :=
λ q Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ comm, q g₁ g₂ (h _ h₁) (h _ h₂) comm

/--
Extend a family of elements to the sieve generated by an arrow set.
This is the construction described as "easy" in Lemma C2.1.3 of [Elephant].
-/
noncomputable def family_of_elements.sieve_extend (x : family_of_elements P R) :
  family_of_elements P (generate R) :=
λ Z f hf, P.map (some (some_spec hf)).op (x _ (some_spec (some_spec (some_spec hf))).1)

/-- The extension of a compatible family to the generated sieve is compatible. -/
lemma family_of_elements.compatible.sieve_extend (x : family_of_elements P R) (hx : x.compatible) :
  x.sieve_extend.compatible :=
begin
  intros Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ comm,
  rw [←(some_spec (some_spec (some_spec h₁))).2, ←(some_spec (some_spec (some_spec h₂))).2,
      ←assoc, ←assoc] at comm,
  dsimp [family_of_elements.sieve_extend],
  rw [← functor_to_types.map_comp_apply, ← functor_to_types.map_comp_apply],
  apply hx _ _ _ _ comm,
end

/-- The extension of a family agrees with the original family. -/
lemma extend_agrees {x : family_of_elements P R} (t : x.compatible) {f : Y ⟶ X} (hf : R f) :
  x.sieve_extend f ⟨_, 𝟙 _, f, hf, id_comp _⟩ = x f hf :=
begin
  have h : (generate R) f := ⟨_, _, _, hf, id_comp _⟩,
  change P.map (some (some_spec h)).op (x _ _) = x f hf,
  rw t (some (some_spec h)) (𝟙 _) _ hf _,
  { simp },
  simp_rw [id_comp],
  apply (some_spec (some_spec (some_spec h))).2,
end

/-- The restriction of an extension is the original. -/
@[simp]
lemma restrict_extend {x : family_of_elements P R} (t : x.compatible) :
  x.sieve_extend.restrict (le_generate R) = x :=
begin
  ext Y f hf,
  exact extend_agrees t hf,
end

/--
If the arrow set for a family of elements is actually a sieve (i.e. it is downward closed) then the
consistency condition can be simplified.
This is an equivalent condition, see `compatible_iff_sieve_compatible`.

This is the notion of "matching" given for families on sieves given in [MM92], Chapter III,
Section 4, Equation 1, and nlab: https://ncatlab.org/nlab/show/matching+family.
See also the discussion before Lemma C2.1.4 of [Elephant].
-/
def family_of_elements.sieve_compatible (x : family_of_elements P S) : Prop :=
∀ ⦃Y Z⦄ (f : Y ⟶ X) (g : Z ⟶ Y) (hf), x (g ≫ f) (S.downward_closed hf g) = P.map g.op (x f hf)

lemma compatible_iff_sieve_compatible (x : family_of_elements P S) :
  x.compatible ↔ x.sieve_compatible :=
begin
  split,
  { intros h Y Z f g hf,
    simpa using h (𝟙 _) g (S.downward_closed hf g) hf (id_comp _) },
  { intros h Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ k,
    simp_rw [← h f₁ g₁ h₁, k, h f₂ g₂ h₂] }
end

lemma family_of_elements.compatible.to_sieve_compatible {x : family_of_elements P S}
  (t : x.compatible) : x.sieve_compatible :=
(compatible_iff_sieve_compatible x).1 t

/--
Two compatible families on the sieve generated by a presieve `R` are equal if and only if they are
equal when restricted to `R`.
-/
lemma restrict_inj {x₁ x₂ : family_of_elements P (generate R)}
  (t₁ : x₁.compatible) (t₂ : x₂.compatible) :
  x₁.restrict (le_generate R) = x₂.restrict (le_generate R) → x₁ = x₂ :=
begin
  intro h,
  ext Z f ⟨Y, f, g, hg, rfl⟩,
  rw compatible_iff_sieve_compatible at t₁ t₂,
  erw [t₁ g f ⟨_, _, g, hg, id_comp _⟩, t₂ g f ⟨_, _, g, hg, id_comp _⟩],
  congr' 1,
  apply congr_fun (congr_fun (congr_fun h _) g) hg,
end

/--
Given a family of elements `x` for the sieve `S` generated by a presieve `R`, if `x` is restricted
to `R` and then extended back up to `S`, the resulting extension equals `x`.
-/
@[simp]
lemma extend_restrict {x : family_of_elements P (generate R)} (t : x.compatible) :
  (x.restrict (le_generate R)).sieve_extend = x :=
begin
  apply restrict_inj,
  { exact (t.restrict (le_generate R)).sieve_extend _ },
  { exact t },
  rw restrict_extend,
  exact t.restrict (le_generate R),
end

/--
The given element `t` of `P.obj (op X)` is an *amalgamation* for the family of elements `x` if every
restriction `P.map f.op t = x_f` for every arrow `f` in the presieve `R`.

This is the definition given in  https://ncatlab.org/nlab/show/sheaf#GeneralDefinitionInComponents,
and https://ncatlab.org/nlab/show/matching+family, as well as [MM92], Chapter III, Section 4,
equation (2).
-/
def family_of_elements.is_amalgamation (x : family_of_elements P R)
  (t : P.obj (op X)) : Prop :=
∀ ⦃Y : C⦄ (f : Y ⟶ X) (h : R f), P.map f.op t = x f h

lemma is_compatible_of_exists_amalgamation (x : family_of_elements P R)
  (h : ∃ t, x.is_amalgamation t) : x.compatible :=
begin
  cases h with t ht,
  intros Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ comm,
  rw [←ht _ h₁, ←ht _ h₂, ←functor_to_types.map_comp_apply, ←op_comp, comm],
  simp,
end

lemma is_amalgamation_restrict {R₁ R₂ : presieve X} (h : R₁ ≤ R₂)
  (x : family_of_elements P R₂) (t : P.obj (op X)) (ht : x.is_amalgamation t) :
  (x.restrict h).is_amalgamation t :=
λ Y f hf, ht f (h Y hf)

lemma is_amalgamation_sieve_extend {R : presieve X}
  (x : family_of_elements P R) (t : P.obj (op X)) (ht : x.is_amalgamation t) :
  x.sieve_extend.is_amalgamation  t :=
begin
  intros Y f hf,
  dsimp [family_of_elements.sieve_extend],
  rw [←ht _, ←functor_to_types.map_comp_apply, ←op_comp, (some_spec (some_spec (some_spec hf))).2],
end

/-- A presheaf is separated for a presieve if there is at most one amalgamation. -/
def is_separated_for (P : Cᵒᵖ ⥤ Type v) (R : presieve X) : Prop :=
∀ (x : family_of_elements P R) (t₁ t₂),
  x.is_amalgamation t₁ → x.is_amalgamation t₂ → t₁ = t₂

lemma is_separated_for.ext {R : presieve X} (hR : is_separated_for P R)
  {t₁ t₂ : P.obj (op X)} (h : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : R f), P.map f.op t₁ = P.map f.op t₂) :
t₁ = t₂ :=
hR (λ Y f hf, P.map f.op t₂) t₁ t₂ (λ Y f hf, h hf) (λ Y f hf, rfl)

lemma is_separated_for_iff_generate :
  is_separated_for P R ↔ is_separated_for P (generate R) :=
begin
  split,
  { intros h x t₁ t₂ ht₁ ht₂,
    apply h (x.restrict (le_generate R)) t₁ t₂ _ _,
    { exact is_amalgamation_restrict _ x t₁ ht₁ },
    { exact is_amalgamation_restrict _ x t₂ ht₂ } },
  { intros h x t₁ t₂ ht₁ ht₂,
    apply h (x.sieve_extend),
    { exact is_amalgamation_sieve_extend x t₁ ht₁ },
    { exact is_amalgamation_sieve_extend x t₂ ht₂ } }
end

lemma is_separated_for_top (P : Cᵒᵖ ⥤ Type v) : is_separated_for P (⊤ : presieve X) :=
λ x t₁ t₂ h₁ h₂,
begin
  have q₁ := h₁ (𝟙 X) (by simp),
  have q₂ := h₂ (𝟙 X) (by simp),
  simp only [op_id, functor_to_types.map_id_apply] at q₁ q₂,
  rw [q₁, q₂],
end

/--
We define `P` to be a sheaf for the presieve `R` if every compatible family has a unique
amalgamation.

This is the definition of a sheaf for the given presieve given in C2.1.2 of [Elephant], and
https://ncatlab.org/nlab/show/sheaf#GeneralDefinitionInComponents. Using `compatible_iff_sieve_compatible`,
this is equivalent to the definition of a sheaf in [MM92], Chapter III, Section 4.
-/
def is_sheaf_for (P : Cᵒᵖ ⥤ Type v) (R : presieve X) : Prop :=
∀ (x : family_of_elements P R), x.compatible → ∃! t, x.is_amalgamation t

/--
This is an equivalent condition to be a sheaf, which is useful for the abstraction to local
operators on elementary toposes. However this definition is defined only for sieves, not presieves.
The equivalence between this and `is_sheaf_for` is given in `yoneda_condition_iff_sheaf_condition`.
This version is also useful to establish that being a sheaf is preserved under isomorphism of
presheaves.

See the discussion before Equation (3) of [MM92], Chapter III, Section 4. See also C2.1.4 of
[Elephant]. This is also a direct reformulation of https://stacks.math.columbia.edu/tag/00Z8.
-/
def yoneda_sheaf_condition (P : Cᵒᵖ ⥤ Type v) (S : sieve X) : Prop :=
∀ (f : S.functor ⟶ P), ∃! g, S.functor_inclusion ≫ g = f

/--
(Implementation). This is a (primarily internal) equivalence between natural transformations
and compatible families.

Cf the discussion after Lemma 7.47.10 in https://stacks.math.columbia.edu/tag/00YW. See also
the proof of C2.1.4 of [Elephant], and the discussion in [MM92], Chapter III, Section 4.
-/
def nat_trans_equiv_compatible_family :
  (S.functor ⟶ P) ≃ {x : family_of_elements P S // x.compatible} :=
{ to_fun := λ α,
  begin
    refine ⟨λ Y f hf, _, _⟩,
    { apply α.app (op Y) ⟨_, hf⟩ },
    { rw compatible_iff_sieve_compatible,
      intros Y Z f g hf,
      dsimp,
      rw ← functor_to_types.naturality _ _ α g.op,
      refl }
  end,
  inv_fun := λ t,
  { app := λ Y f, t.1 _ f.2,
    naturality' := λ Y Z g,
    begin
      ext ⟨f, hf⟩,
      apply t.2.to_sieve_compatible _,
    end },
  left_inv := λ α,
  begin
    ext X ⟨_, _⟩,
    refl
  end,
  right_inv :=
  begin
    rintro ⟨x, hx⟩,
    refl,
  end }

/-- (Implementation). A lemma useful to prove `yoneda_condition_iff_sheaf_condition`. -/
lemma extension_iff_amalgamation (x : S.functor ⟶ P) (g : yoneda.obj X ⟶ P) :
  S.functor_inclusion ≫ g = x ↔
  (nat_trans_equiv_compatible_family x).1.is_amalgamation (yoneda_equiv g) :=
begin
  change _ ↔ ∀ ⦃Y : C⦄ (f : Y ⟶ X) (h : S f), P.map f.op (yoneda_equiv g) = x.app (op Y) ⟨f, h⟩,
  split,
  { rintro rfl Y f hf,
    rw yoneda_equiv_naturality,
    dsimp,
    simp },  -- See note [dsimp, simp].
  { intro h,
    ext Y ⟨f, hf⟩,
    have : _ = x.app Y _ := h f hf,
    rw yoneda_equiv_naturality at this,
    rw ← this,
    dsimp,
    simp }, -- See note [dsimp, simp].
end

/--
The yoneda version of the sheaf condition is equivalent to the sheaf condition.

C2.1.4 of [Elephant].
-/
lemma is_sheaf_for_iff_yoneda_sheaf_condition :
  is_sheaf_for P S ↔ yoneda_sheaf_condition P S :=
begin
  rw [is_sheaf_for, yoneda_sheaf_condition],
  simp_rw [extension_iff_amalgamation],
  rw equiv.forall_congr_left' nat_trans_equiv_compatible_family,
  rw subtype.forall,
  apply ball_congr,
  intros x hx,
  rw equiv.exists_unique_congr_left _,
  simp,
end

/--
If `P` is a sheaf for the sieve `S` on `X`, a natural transformation from `S` (viewed as a functor)
to `P` can be (uniquely) extended to all of `yoneda.obj X`.

      f
   S  →  P
   ↓  ↗
   yX

-/
noncomputable def is_sheaf_for.extend (h : is_sheaf_for P S) (f : S.functor ⟶ P) :
  yoneda.obj X ⟶ P :=
classical.some (is_sheaf_for_iff_yoneda_sheaf_condition.1 h f).exists

/--
Show that the extension of `f : S.functor ⟶ P` to all of `yoneda.obj X` is in fact an extension, ie
that the triangle below commutes, provided `P` is a sheaf for `S`

      f
   S  →  P
   ↓  ↗
   yX

-/
@[simp, reassoc]
lemma is_sheaf_for.functor_inclusion_comp_extend (h : is_sheaf_for P S) (f : S.functor ⟶ P) :
  S.functor_inclusion ≫ h.extend f = f :=
classical.some_spec (is_sheaf_for_iff_yoneda_sheaf_condition.1 h f).exists

/-- The extension of `f` to `yoneda.obj X` is unique. -/
lemma is_sheaf_for.unique_extend (h : is_sheaf_for P S) {f : S.functor ⟶ P} (t : yoneda.obj X ⟶ P)
  (ht : S.functor_inclusion ≫ t = f) :
  t = h.extend f :=
((is_sheaf_for_iff_yoneda_sheaf_condition.1 h f).unique ht (h.functor_inclusion_comp_extend f))

/--
If `P` is a sheaf for the sieve `S` on `X`, then if two natural transformations from `yoneda.obj X`
to `P` agree when restricted to the subfunctor given by `S`, they are equal.
-/
lemma is_sheaf_for.hom_ext (h : is_sheaf_for P S) (t₁ t₂ : yoneda.obj X ⟶ P)
  (ht : S.functor_inclusion ≫ t₁ = S.functor_inclusion ≫ t₂) :
  t₁ = t₂ :=
(h.unique_extend t₁ ht).trans (h.unique_extend t₂ rfl).symm

/-- `P` is a sheaf for `R` iff it is separated for `R` and there exists an amalgamation. -/
lemma is_separated_for_and_exists_is_amalgamation_iff_sheaf_for :
  is_separated_for P R ∧ (∀ (x : family_of_elements P R), x.compatible → ∃ t, x.is_amalgamation t) ↔
  is_sheaf_for P R :=
begin
  rw [is_separated_for, ←forall_and_distrib],
  apply forall_congr,
  intro x,
  split,
  { intros z hx, exact exists_unique_of_exists_of_unique (z.2 hx) z.1 },
  { intros h,
    refine ⟨_, (exists_of_exists_unique ∘ h)⟩,
    intros t₁ t₂ ht₁ ht₂,
    apply (h _).unique ht₁ ht₂,
    exact is_compatible_of_exists_amalgamation x ⟨_, ht₂⟩ }
end

/--
If `P` is separated for `R` and every family has an amalgamation, then `P` is a sheaf for `R`.
-/
lemma is_separated_for.is_sheaf_for (t : is_separated_for P R) :
  (∀ (x : family_of_elements P R), x.compatible → ∃ t, x.is_amalgamation t) →
  is_sheaf_for P R :=
begin
  rw ← is_separated_for_and_exists_is_amalgamation_iff_sheaf_for,
  exact and.intro t,
end

/-- If `P` is a sheaf for `R`, it is separated for `R`. -/
lemma is_sheaf_for.is_separated_for : is_sheaf_for P R → is_separated_for P R :=
λ q, (is_separated_for_and_exists_is_amalgamation_iff_sheaf_for.2 q).1

/-- Get the amalgamation of the given compatible family, provided we have a sheaf. -/
noncomputable def is_sheaf_for.amalgamate
  (t : is_sheaf_for P R) (x : family_of_elements P R) (hx : x.compatible) :
  P.obj (op X) :=
classical.some (t x hx).exists

lemma is_sheaf_for.is_amalgamation
  (t : is_sheaf_for P R) {x : family_of_elements P R} (hx : x.compatible) :
  x.is_amalgamation (t.amalgamate x hx) :=
classical.some_spec (t x hx).exists

@[simp]
lemma is_sheaf_for.valid_glue
  (t : is_sheaf_for P R) {x : family_of_elements P R} (hx : x.compatible) (f : Y ⟶ X) (Hf : R f) :
  P.map f.op (t.amalgamate x hx) = x f Hf :=
t.is_amalgamation hx f Hf

/-- C2.1.3 in [Elephant] -/
lemma is_sheaf_for_iff_generate (R : presieve X) :
  is_sheaf_for P R ↔ is_sheaf_for P (generate R) :=
begin
  rw ← is_separated_for_and_exists_is_amalgamation_iff_sheaf_for,
  rw ← is_separated_for_and_exists_is_amalgamation_iff_sheaf_for,
  rw ← is_separated_for_iff_generate,
  apply and_congr (iff.refl _),
  split,
  { intros q x hx,
    apply exists_imp_exists _ (q _ (hx.restrict (le_generate R))),
    intros t ht,
    simpa [hx] using is_amalgamation_sieve_extend _ _ ht },
  { intros q x hx,
    apply exists_imp_exists _ (q _ (hx.sieve_extend _)),
    intros t ht,
    simpa [hx] using is_amalgamation_restrict (le_generate R) _ _ ht },
end

/--
Every presheaf is a sheaf for the family {𝟙 X}.

[Elephant] C2.1.5(i)
-/
lemma is_sheaf_for_singleton_iso (P : Cᵒᵖ ⥤ Type v) :
  is_sheaf_for P (presieve.singleton (𝟙 X)) :=
begin
  intros x hx,
  refine ⟨x _ (presieve.singleton_self _), _, _⟩,
  { rintro _ _ ⟨rfl, rfl⟩,
    simp },
  { intros t ht,
    simpa using ht _ (presieve.singleton_self _) }
end

/--
Every presheaf is a sheaf for the maximal sieve.

[Elephant] C2.1.5(ii)
-/
lemma is_sheaf_for_top_sieve (P : Cᵒᵖ ⥤ Type v) :
  is_sheaf_for P ((⊤ : sieve X) : presieve X) :=
begin
  rw ← generate_of_singleton_split_epi (𝟙 X),
  rw ← is_sheaf_for_iff_generate,
  apply is_sheaf_for_singleton_iso,
end

/--
If `P` is a sheaf for `S`, and it is iso to `P'`, then `P'` is a sheaf for `S`. This shows that
"being a sheaf for a presieve" is a mathematical or hygenic property.
-/
lemma is_sheaf_for_iso {P' : Cᵒᵖ ⥤ Type v} (i : P ≅ P') : is_sheaf_for P R → is_sheaf_for P' R :=
begin
  rw [is_sheaf_for_iff_generate R, is_sheaf_for_iff_generate R],
  intro h,
  rw [is_sheaf_for_iff_yoneda_sheaf_condition],
  intro f,
  refine ⟨h.extend (f ≫ i.inv) ≫ i.hom, by simp, _⟩,
  intros g' hg',
  rw [← i.comp_inv_eq, h.unique_extend (g' ≫ i.inv) (by rw reassoc_of hg')],
end

/--
If a presieve `R` on `X` has a subsieve `S` such that:

* `P` is a sheaf for `S`.
* For every `f` in `R`, `P` is separated for the pullback of `S` along `f`,

then `P` is a sheaf for `R`.

This is closely related to [Elephant] C2.1.6(i).
-/
lemma is_sheaf_for_subsieve_aux (P : Cᵒᵖ ⥤ Type v) {S : sieve X} {R : presieve X}
  (h : (S : presieve X) ≤ R)
  (hS : is_sheaf_for P S)
  (trans : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄, R f → is_separated_for P (S.pullback f)) :
  is_sheaf_for P R :=
begin
  rw ← is_separated_for_and_exists_is_amalgamation_iff_sheaf_for,
  split,
  { intros x t₁ t₂ ht₁ ht₂,
    exact hS.is_separated_for _ _ _ (is_amalgamation_restrict h x t₁ ht₁)
                                    (is_amalgamation_restrict h x t₂ ht₂) },
  { intros x hx,
    use hS.amalgamate _ (hx.restrict h),
    intros W j hj,
    apply (trans hj).ext,
    intros Y f hf,
    rw [←functor_to_types.map_comp_apply, ←op_comp,
        hS.valid_glue (hx.restrict h) _ hf, family_of_elements.restrict,
        ←hx (𝟙 _) f _ _ (id_comp _)],
    simp },
end

/--
If `P` is a sheaf for every pullback of the sieve `S`, then `P` is a sheaf for any presieve which
contains `S`.
This is closely related to [Elephant] C2.1.6.
-/
lemma is_sheaf_for_subsieve (P : Cᵒᵖ ⥤ Type v) {S : sieve X} {R : presieve X}
  (h : (S : presieve X) ≤ R)
  (trans : Π ⦃Y⦄ (f : Y ⟶ X), is_sheaf_for P (S.pullback f)) :
  is_sheaf_for P R :=
is_sheaf_for_subsieve_aux P h (by simpa using trans (𝟙 _)) (λ Y f hf, (trans f).is_separated_for)

/-- A presheaf is separated for a topology if it is separated for every sieve in the topology. -/
def is_separated (P : Cᵒᵖ ⥤ Type v) : Prop :=
∀ {X} (S : sieve X), S ∈ J X → is_separated_for P S

/--
A presheaf is a sheaf for a topology if it is a sheaf for every sieve in the topology.

If the given topology is given by a pretopology, `is_sheaf_for_pretopology` shows it suffices to
check the sheaf condition at presieves in the pretopology.
-/
def is_sheaf (P : Cᵒᵖ ⥤ Type v) : Prop :=
∀ ⦃X⦄ (S : sieve X), S ∈ J X → is_sheaf_for P S

lemma is_sheaf.is_sheaf_for {P : Cᵒᵖ ⥤ Type v} (hp : is_sheaf J P)
  (R : presieve X) (hr : generate R ∈ J X) : is_sheaf_for P R :=
(is_sheaf_for_iff_generate R).2 $ hp _ hr

lemma is_sheaf_of_le (P : Cᵒᵖ ⥤ Type v) {J₁ J₂ : grothendieck_topology C} :
  J₁ ≤ J₂ → is_sheaf J₂ P → is_sheaf J₁ P :=
λ h t X S hS, t S (h _ hS)

lemma is_separated_of_is_sheaf (P : Cᵒᵖ ⥤ Type v) (h : is_sheaf J P) : is_separated J P :=
λ X S hS, (h S hS).is_separated_for

/-- The property of being a sheaf is preserved by isomorphism. -/
lemma is_sheaf_iso {P' : Cᵒᵖ ⥤ Type v} (i : P ≅ P') (h : is_sheaf J P) : is_sheaf J P' :=
λ X S hS, is_sheaf_for_iso i (h S hS)

lemma is_sheaf_of_yoneda (h : ∀ {X} (S : sieve X), S ∈ J X → yoneda_sheaf_condition P S) :
  is_sheaf J P :=
λ X S hS, is_sheaf_for_iff_yoneda_sheaf_condition.2 (h _ hS)

/--
For a topology generated by a basis, it suffices to check the sheaf condition on the basis
presieves only.
-/
lemma is_sheaf_pretopology [has_pullbacks C] (K : pretopology C) :
  is_sheaf (K.to_grothendieck C) P ↔ (∀ {X : C} (R : presieve X), R ∈ K X → is_sheaf_for P R) :=
begin
  split,
  { intros PJ X R hR,
    rw is_sheaf_for_iff_generate,
    apply PJ (sieve.generate R) ⟨_, hR, le_generate R⟩ },
  { rintro PK X S ⟨R, hR, RS⟩,
    have gRS : ⇑(generate R) ≤ S,
    { apply gi_generate.gc.monotone_u,
      rwa sets_iff_generate },
    apply is_sheaf_for_subsieve P gRS _,
    intros Y f,
    rw [← pullback_arrows_comm, ← is_sheaf_for_iff_generate],
    exact PK (pullback_arrows f R) (K.pullbacks f R hR) }
end

/-- Any presheaf is a sheaf for the bottom (trivial) grothendieck topology. -/
lemma is_sheaf_bot : is_sheaf (⊥ : grothendieck_topology C) P :=
λ X, by simp [is_sheaf_for_top_sieve]

end presieve

namespace equalizer

variables {C : Type v} [small_category C] (P : Cᵒᵖ ⥤ Type v) {X : C} (R : presieve X) (S : sieve X)

noncomputable theory

/--
The middle object of the fork diagram given in Equation (3) of [MM92], as well as the fork diagram
of https://stacks.math.columbia.edu/tag/00VM.
-/
def first_obj : Type v :=
∏ (λ (f : Σ Y, {f : Y ⟶ X // R f}), P.obj (op f.1))

/-- Show that `first_obj` is isomorphic to `family_of_elements`. -/
@[simps]
def first_obj_eq_family : first_obj P R ≅ R.family_of_elements P :=
{ hom := λ t Y f hf, pi.π (λ (f : Σ Y, {f : Y ⟶ X // R f}), P.obj (op f.1)) ⟨_, _, hf⟩ t,
  inv := pi.lift (λ f x, x _ f.2.2),
  hom_inv_id' :=
  begin
    ext ⟨Y, f, hf⟩ p,
    simpa,
  end,
  inv_hom_id' :=
  begin
    ext x Y f hf,
    apply limits.types.limit.lift_π_apply,
  end }

instance : inhabited (first_obj P (⊥ : presieve X)) :=
((first_obj_eq_family P _).to_equiv).inhabited

/--
The left morphism of the fork diagram given in Equation (3) of [MM92], as well as the fork diagram
of https://stacks.math.columbia.edu/tag/00VM.
-/
def fork_map : P.obj (op X) ⟶ first_obj P R :=
pi.lift (λ f, P.map f.2.1.op)

/-!
This section establishes the equivalence between the sheaf condition of Equation (3) [MM92] and
the definition of `is_sheaf_for`.
-/
namespace sieve

/--
The rightmost object of the fork diagram of Equation (3) [MM92], which contains the data used
to check a family is compatible.
-/
def second_obj : Type v :=
∏ (λ (f : Σ Y Z (g : Z ⟶ Y), {f' : Y ⟶ X // S f'}), P.obj (op f.2.1))

/-- The map `p` of Equations (3,4) [MM92]. -/
def first_map : first_obj P S ⟶ second_obj P S :=
pi.lift (λ fg, pi.π _ (⟨_, _, S.downward_closed fg.2.2.2.2 fg.2.2.1⟩ : Σ Y, {f : Y ⟶ X // S f}))

instance : inhabited (second_obj P (⊥ : sieve X)) := ⟨first_map _ _ (default _)⟩

/-- The map `a` of Equations (3,4) [MM92]. -/
def second_map : first_obj P S ⟶ second_obj P S :=
pi.lift (λ fg, pi.π _ ⟨_, fg.2.2.2⟩ ≫ P.map fg.2.2.1.op)

lemma w : fork_map P S ≫ first_map P S = fork_map P S ≫ second_map P S :=
begin
  apply limit.hom_ext,
  rintro ⟨Y, Z, g, f, hf⟩,
  simp [first_map, second_map, fork_map],
end

/--
The family of elements given by `x : first_obj P S` is compatible iff `first_map` and `second_map`
map it to the same point.
-/
lemma compatible_iff (x : first_obj P S) :
  ((first_obj_eq_family P S).hom x).compatible ↔ first_map P S x = second_map P S x :=
begin
  rw presieve.compatible_iff_sieve_compatible,
  split,
  { intro t,
    ext ⟨Y, Z, g, f, hf⟩,
    simpa [first_map, second_map] using t _ g hf },
  { intros t Y Z f g hf,
    rw types.limit_ext_iff at t,
    simpa [first_map, second_map] using t ⟨Y, Z, g, f, hf⟩ }
end

/-- `P` is a sheaf for `S`, iff the fork given by `w` is an equalizer. -/
lemma equalizer_sheaf_condition :
  presieve.is_sheaf_for P S ↔ nonempty (is_limit (fork.of_ι _ (w P S))) :=
begin
  rw [types.type_equalizer_iff_unique,
      ← equiv.forall_congr_left (first_obj_eq_family P S).to_equiv.symm],
  simp_rw ← compatible_iff,
  simp only [inv_hom_id_apply, iso.to_equiv_symm_fun],
  apply ball_congr,
  intros x tx,
  apply exists_unique_congr,
  intro t,
  rw ← iso.to_equiv_symm_fun,
  rw equiv.eq_symm_apply,
  split,
  { intros q,
    ext Y f hf,
    simpa [first_obj_eq_family, fork_map] using q _ _ },
  { intros q Y f hf,
    rw ← q,
    simp [first_obj_eq_family, fork_map] }
end

end sieve

/-!
This section establishes the equivalence between the sheaf condition of
https://stacks.math.columbia.edu/tag/00VM and the definition of `is_sheaf_for`.
-/
namespace presieve

variables [has_pullbacks C]

/--
The rightmost object of the fork diagram of https://stacks.math.columbia.edu/tag/00VM, which
contains the data used to check a family of elements for a presieve is compatible.
-/
def second_obj : Type v :=
∏ (λ (fg : (Σ Y, {f : Y ⟶ X // R f}) × (Σ Z, {g : Z ⟶ X // R g})),
  P.obj (op (pullback fg.1.2.1 fg.2.2.1)))

/-- The map `pr₀*` of https://stacks.math.columbia.edu/tag/00VL. -/
def first_map : first_obj P R ⟶ second_obj P R :=
pi.lift (λ fg, pi.π _ _ ≫ P.map pullback.fst.op)

instance : inhabited (second_obj P (⊥ : presieve X)) := ⟨first_map _ _ (default _)⟩

/-- The map `pr₁*` of https://stacks.math.columbia.edu/tag/00VL. -/
def second_map : first_obj P R ⟶ second_obj P R :=
pi.lift (λ fg, pi.π _ _ ≫ P.map pullback.snd.op)

lemma w : fork_map P R ≫ first_map P R = fork_map P R ≫ second_map P R :=
begin
  apply limit.hom_ext,
  rintro ⟨⟨Y, f, hf⟩, ⟨Z, g, hg⟩⟩,
  simp only [first_map, second_map, fork_map],
  simp only [limit.lift_π, limit.lift_π_assoc, assoc, fan.mk_π_app, subtype.coe_mk,
             subtype.val_eq_coe],
  rw [← P.map_comp, ← op_comp, pullback.condition],
  simp,
end

/--
The family of elements given by `x : first_obj P S` is compatible iff `first_map` and `second_map`
map it to the same point.
-/
lemma compatible_iff (x : first_obj P R) :
  ((first_obj_eq_family P R).hom x).compatible ↔ first_map P R x = second_map P R x :=
begin
  rw presieve.pullback_compatible_iff,
  split,
  { intro t,
    ext ⟨⟨Y, f, hf⟩, Z, g, hg⟩,
    simpa [first_map, second_map] using t hf hg },
  { intros t Y Z f g hf hg,
    rw types.limit_ext_iff at t,
    simpa [first_map, second_map] using t ⟨⟨Y, f, hf⟩, Z, g, hg⟩ }
end

/--
`P` is a sheaf for `R`, iff the fork given by `w` is an equalizer.
See https://stacks.math.columbia.edu/tag/00VM.
-/
lemma sheaf_condition :
  R.is_sheaf_for P ↔ nonempty (is_limit (fork.of_ι _ (w P R))) :=
begin
  rw types.type_equalizer_iff_unique,
  erw ← equiv.forall_congr_left (first_obj_eq_family P R).to_equiv.symm,
  simp_rw [← compatible_iff, ← iso.to_equiv_fun, equiv.apply_symm_apply],
  apply ball_congr,
  intros x hx,
  apply exists_unique_congr,
  intros t,
  rw equiv.eq_symm_apply,
  split,
  { intros q,
    ext Y f hf,
    simpa [fork_map] using q _ _ },
  { intros q Y f hf,
    rw ← q,
    simp [fork_map] }
end

end presieve
end equalizer

variables {C : Type u} [category.{v} C]
variables (J : grothendieck_topology C)

/-- The category of sheaves on a grothendieck topology. -/
@[derive category]
def SheafOfTypes (J : grothendieck_topology C) : Type (max u (v+1)) :=
{P : Cᵒᵖ ⥤ Type v // presieve.is_sheaf J P}

/-- The inclusion functor from sheaves to presheaves. -/
@[simps, derive [full, faithful]]
def SheafOfTypes_to_presheaf : SheafOfTypes J ⥤ (Cᵒᵖ ⥤ Type v) :=
full_subcategory_inclusion (presieve.is_sheaf J)

/--
The category of sheaves on the bottom (trivial) grothendieck topology is equivalent to the category
of presheaves.
-/
@[simps]
def SheafOfTypes_bot_equiv : SheafOfTypes (⊥ : grothendieck_topology C) ≌ (Cᵒᵖ ⥤ Type v) :=
{ functor := SheafOfTypes_to_presheaf _,
  inverse :=
  { obj := λ P, ⟨P, presieve.is_sheaf_bot⟩,
    map := λ P₁ P₂ f, (SheafOfTypes_to_presheaf _).preimage f },
  unit_iso :=
  { hom := { app := λ _, 𝟙 _ },
    inv := { app := λ _, 𝟙 _ } },
  counit_iso := iso.refl _ }

instance : inhabited (SheafOfTypes (⊥ : grothendieck_topology C)) :=
⟨SheafOfTypes_bot_equiv.inverse.obj ((functor.const _).obj punit)⟩

end category_theory
