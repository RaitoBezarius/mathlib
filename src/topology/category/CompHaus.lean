/-
Copyright (c) 2020 Adam Topaz. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Adam Topaz, Bhavik Mehta
-/

import category_theory.adjunction.reflective
import topology.category.Top
import topology.stone_cech

/-!

# The category of Compact Hausdorff Spaces

We construct the category of compact Hausdorff spaces.
The type of compact Hausdorff spaces is denoted `CompHaus`, and it is endowed with a category
instance making it a full subcategory of `Top`.
The fully faithful functor `CompHaus ⥤ Top` is denoted `CompHaus_to_Top`.

**Note:** The file `topology/category/Compactum.lean` provides the equivalence between `Compactum`,
which is defined as the category of algebras for the ultrafilter monad, and `CompHaus`.
`Compactum_to_CompHaus` is the functor from `Compactum` to `CompHaus` which is proven to be an
equivalence of categories in `Compactum_to_CompHaus.is_equivalence`.
See `topology/category/Compactum.lean` for a more detailed discussion where these definitions are
introduced.

-/

open category_theory

/-- The type of Compact Hausdorff topological spaces. -/
structure CompHaus :=
(to_Top : Top)
[is_compact : compact_space to_Top]
[is_hausdorff : t2_space to_Top]

namespace CompHaus

instance : inhabited CompHaus := ⟨{to_Top := { α := pempty }}⟩

instance : has_coe_to_sort CompHaus := ⟨Type*, λ X, X.to_Top⟩
instance {X : CompHaus} : compact_space X := X.is_compact
instance {X : CompHaus} : t2_space X := X.is_hausdorff

instance category : category CompHaus := induced_category.category to_Top

@[simp]
lemma coe_to_Top {X : CompHaus} : (X.to_Top : Type*) = X :=
rfl

end CompHaus

/-- The fully faithful embedding of `CompHaus` in `Top`. -/
@[simps {rhs_md := semireducible}, derive [full, faithful]]
def CompHaus_to_Top : CompHaus ⥤ Top := induced_functor _

@[simps]
def StoneCech_obj (X : Top) : CompHaus :=
{ to_Top := { α := stone_cech X },
  is_compact := stone_cech.compact_space,
  is_hausdorff := @stone_cech.t2_space X _ }

noncomputable def stone_cech_equivalence (X : Top) (Y : CompHaus) :
  (StoneCech_obj X ⟶ Y) ≃ (X ⟶ CompHaus_to_Top.obj Y) :=
{ to_fun := λ f,
  { to_fun := f ∘ stone_cech_unit,
    continuous_to_fun := f.2.comp (@continuous_stone_cech_unit X _) },
  inv_fun := λ f,
  { to_fun := stone_cech_extend f.2,
    continuous_to_fun := continuous_stone_cech_extend f.2 },
  left_inv :=
  begin
    rintro ⟨f : stone_cech X ⟶ Y, hf : continuous f⟩,
    ext (x : stone_cech X),
    refine congr_fun _ x,
    apply continuous.ext_on dense_range_stone_cech_unit (continuous_stone_cech_extend _) hf,
    rintro _ ⟨y, rfl⟩,
    apply congr_fun (stone_cech_extend_extends (hf.comp _)) y,
  end,
  right_inv :=
  begin
    rintro ⟨f : ↥X ⟶ Y, hf : continuous f⟩,
    ext,
    exact congr_fun (stone_cech_extend_extends hf) x,
  end }

noncomputable def Top_to_CompHaus : Top ⥤ CompHaus :=
adjunction.left_adjoint_of_equiv stone_cech_equivalence (by tidy)

noncomputable instance : reflective CompHaus_to_Top :=
{ to_is_right_adjoint := ⟨Top_to_CompHaus, adjunction.adjunction_of_equiv_left _ _⟩ }
