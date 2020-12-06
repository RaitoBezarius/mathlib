/-
Copyright © 2020 Nicolò Cavalleri. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Nicolò Cavalleri.
-/

import topology.topological_fiber_bundle
import analysis.calculus.deriv
import linear_algebra.dual

/-!
# Topological vector bundles

In this file we define topological vector bundles.

The most important idea here is that vector bundles are named through their fibers.
Let `B` be the base space. The collection of the fibers is a function `E : B → Type*` for which
there is an appropriate instance on each `E x` and an instance of topological space over `Σ x, E x`.
Naming conventions are essential to work with vector bundles this way.

## Definitions

* `nc_topological_vector_bundle R E F`  : topological vector bundle with non constant fiber. Here
                                          `F` is a function `I → Type*` and `I` is an index type.
* `topological_vector_bundle R E F`     : topological vector bundle constant fiber `F : Type*`.

-/

noncomputable theory

variables {B : Type*}

/--
`total_space E` is the total space of the bundle `Σ x, E x`. This type synonym is used to avoid
conflicts with general sigma types.
-/
def bundle.total_space (E : B → Type*) := Σ x, E x

instance {E : B → Type*} [inhabited B] [inhabited (E (default B))] :
  inhabited (bundle.total_space E) := ⟨⟨default B, default (E (default B))⟩⟩

/-- `bundle.proj E` is the canonical projection `total_space E → B` on the base space. -/
def bundle.proj (E : B → Type*) : bundle.total_space E → B := λ y : (bundle.total_space E), y.1

open bundle

variables (R : Type*) (E : B → Type*) (F : Type*)
[comm_semiring R] [∀ x, add_comm_monoid (E x)] [∀ x, semimodule R (E x)]
[∀ x, topological_space (E x)]

/-- `bundle.dual R E` is the dual bundle. -/
@[reducible] def bundle.dual := (λ x, module.dual R (E x))

localized "notation E `ᵛ` R := bundle.dual R E" in bundle.dual

section

variables [topological_space B] [topological_space F] [topological_space (total_space E)]
[add_comm_monoid F] [semimodule R F]

@[nolint unused_arguments]
instance {x : B} : has_coe_t (E x) (total_space E) := ⟨λ y, (⟨x, y⟩ : total_space E)⟩

/-- Local trivialization for vector bunlde. -/
@[nolint has_inhabited_instance]
structure vector_bundle_trivialization extends bundle_trivialization F (proj E) :=
(linear : ∀ x ∈ base_set, is_linear_map R (λ y : (E x), (to_fun y).2))

instance : has_coe (vector_bundle_trivialization R E F) (bundle_trivialization F (proj E)) :=
⟨vector_bundle_trivialization.to_bundle_trivialization⟩

instance : has_coe_to_fun (vector_bundle_trivialization R E F) :=
⟨_, λ e, e.to_bundle_trivialization⟩

@[simp] lemma coe_eq_coe_coe {e : vector_bundle_trivialization R E F} :
  (⇑e : (total_space E) → B × F) = ((e : bundle_trivialization F (proj E)) : (total_space E) → B × F) :=
rfl

section

def vector_bundle_trivialization.at (e : vector_bundle_trivialization R E F) (b : B)
  (hb : b ∈ e.base_set):
  continuous_linear_equiv R (E b) F :=
{
  to_fun := λ y, (e.to_fun y).2,
  inv_fun := λ z, begin let g := (e.to_local_homeomorph.symm ⟨b, z⟩).2,
    have h : ((e.to_bundle_trivialization.to_local_homeomorph.symm) (b, z)).fst = b := sorry,
    rw h at g,
    exact g,
  end,
  left_inv := begin
    intro x,
    dsimp at *, simp at *,
    unfold eq.mp,
  end,
}

end

variables {I : Type*} (F' : I → Type*) [∀ i, topological_space (F' i)]
[∀ i, add_comm_monoid (F' i)] [∀ i, semimodule R (F' i)]

/-- Topological vector bundle with varying fiber. `nc` stands for non constant. -/
class nc_topological_vector_bundle : Prop :=
(inducing [] : ∀ b : B, inducing (λ x : (E b), (x : total_space E)))
(locally_trivial [] :
  ∀ b : B, ∃ i : I, ∃ e : vector_bundle_trivialization R E (F' i), b ∈ e.base_set)

namespace nc_topological_vector_bundle

variable [nc_topological_vector_bundle R E F']

def fiber_index_at : B → I := λ b, classical.some (locally_trivial R E F' b)

def trivialization_at : Π b : B, vector_bundle_trivialization R E (F' (fiber_index_at R E F' b)) :=
λ b, classical.some (classical.some_spec (locally_trivial R E F' b))

lemma mem_trivialization_base_set : ∀ b : B, b ∈ (trivialization_at R E F' b).base_set :=
λ b, classical.some_spec (classical.some_spec (locally_trivial R E F' b))

lemma mem_trivialization_source : ∀ z : total_space E, z ∈ (trivialization_at R E F' z.1).source :=
λ z, begin  end

end nc_topological_vector_bundle

/-- Topological vector bundle of fiber `F`. -/
class topological_vector_bundle : Prop :=
(inducing [] : ∀ b : B, inducing (λ x : (E b), (x : total_space E)))
(locally_trivial [] : ∀ b : B, ∃ e : vector_bundle_trivialization R E F, b ∈ e.base_set)

instance topological_vector_bundle.nc_topological_vector_bundle [topological_vector_bundle R E F] :
  nc_topological_vector_bundle R E (λ u : unit, F) :=
{ fiber_index_at := λ x, unit.star,
  trivialization_at := λ b, topological_vector_bundle.trivialization_at R E F b,
  mem_trivialization_source := λ x, topological_vector_bundle.mem_trivialization_source R F x }

end

variable (B)

/-- `trivial_bundle B F` is the trivial bundle over `B` of fiber `F`. -/
@[nolint unused_arguments]
def trivial_bundle : B → Type* := λ x, F

instance [inhabited F] {b : B} : inhabited (trivial_bundle B F b) :=
by { unfold trivial_bundle, exact ⟨default F⟩ }

/-- The trivial bundle, unlike other bundles, has a canonical projection on the fiber. -/
def trivial_bundle.proj_snd : (total_space (trivial_bundle B F)) → F := sigma.snd

instance [I : add_comm_monoid F] : ∀ x : B, add_comm_monoid (trivial_bundle B F x) := λ x, I
instance [add_comm_monoid F] [I : semimodule R F] : ∀ x : B, semimodule R (trivial_bundle B F x) :=
  λ x, I
instance [I : topological_space F] : ∀ x : B, topological_space (trivial_bundle B F x) := λ x, I
instance [t₁ : topological_space B] [t₂ : topological_space F] :
  topological_space (total_space (trivial_bundle B F)) :=
topological_space.induced (proj (trivial_bundle B F)) t₁ ⊓
  topological_space.induced (trivial_bundle.proj_snd B F) t₂

variables [topological_space B] [topological_space F] [topological_space (total_space E)]
[add_comm_monoid F] [semimodule R F]

/-- Local trivialization for trivial bundle. -/
def trivial_bundle_trivialization : vector_bundle_trivialization R (trivial_bundle B F) F :=
{ to_fun := λ x, ⟨x.fst, x.snd⟩,
  inv_fun := λ y, ⟨y.fst, y.snd⟩,
  source := set.univ,
  target := set.univ,
  map_source' := λ x h, set.mem_univ (x.fst, x.snd),
  map_target' :=λ y h,  set.mem_univ ⟨y.fst, y.snd⟩,
  left_inv' := λ x h, sigma.eq rfl rfl,
  right_inv' := λ x h, prod.ext rfl rfl,
  open_source := is_open_univ,
  open_target := is_open_univ,
  continuous_to_fun := by { rw [←continuous_iff_continuous_on_univ, continuous_iff_le_induced],
    simp only [prod.topological_space, induced_inf, induced_compose], exact le_refl _, },
  continuous_inv_fun := by { rw [←continuous_iff_continuous_on_univ, continuous_iff_le_induced],
    simp only [bundle.total_space.topological_space, induced_inf, induced_compose],
    exact le_refl _, },
  base_set := set.univ,
  open_base_set := is_open_univ,
  source_eq := rfl,
  target_eq := by simp only [set.univ_prod_univ],
  proj_to_fun := λ y hy, rfl,
  linear := λ x hx, ⟨λ y z, rfl, λ c y, rfl⟩ }

instance trivial_bundle.topological_vector_bundle :
  topological_vector_bundle R (trivial_bundle B F) F :=
⟨λ x, trivial_bundle_trivialization B R F, λ x, set.mem_univ x⟩

variables {R} {F} {E} {B}

lemma is_topological_vector_bundle_is_topological_fiber_bundle [topological_vector_bundle R E F] :
  is_topological_fiber_bundle F (proj E) :=
λ x, ⟨topological_vector_bundle.trivialization_at R E F x.1,
  topological_vector_bundle.mem_trivialization_source R F x⟩
