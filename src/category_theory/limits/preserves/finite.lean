/-
Copyright (c) 2021 Andrew Yang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang
-/
import category_theory.limits.preserves.basic
import category_theory.fin_category

/-!
# Preservation of finite (co)limits.

These functors are also known as left exact (flat) or right exact functors when the categories
involved are abelian, or more generally, finitely (co)complete.

## Related results
* `category_theory.limits.preserves_finite_limits_of_preserves_equalizers_and_finite_products` :
  see `category_theory/limits/constructions/limits_of_products_and_equalizers.lean`. Also provides
  the dual version.
* `category_theory.limits.preserves_finite_limits_iff_flat` :
  see `category_theory/flat_functors.lean`.

-/

open category_theory

namespace category_theory.limits

-- declare the `v`'s first; see `category_theory.category` for an explanation
universes w w₂ v₁ v₂ v₃ u₁ u₂ u₃

variables {C : Type u₁} [category.{v₁} C]
variables {D : Type u₂} [category.{v₂} D]
variables {E : Type u₃} [category.{v₃} E]

variables {J : Type w} [small_category J] {K : J ⥤ C}

/--
A functor is said to preserve finite limits of size `w`, if it preserves all limits of shape `J`,
where `J : Type w` is a finite category.
-/
class preserves_finite_limits_of_size (F : C ⥤ D) :=
(preserves_finite_limits : Π (J : Type w) [small_category J] [fin_category J],
  preserves_limits_of_shape J F . tactic.apply_instance)

/-- Preserving finite limits means preserving finite limits of size `0`. -/
abbreviation preserves_finite_limits (F : C ⥤ D) := preserves_finite_limits_of_size.{0} F

attribute [instance] preserves_finite_limits_of_size.preserves_finite_limits

/--
`preserves_finite_limits_of_size_shrink.{w} F` tries to obtain
`preserves_finite_limits_of_size.{w} F` from some other `preserves_finite_limits_of_size F`.
-/
def preserves_finite_limits_of_size_shrink (F : C ⥤ D)
  [hpres : preserves_finite_limits_of_size.{(max w w₂)} F] :
  preserves_finite_limits_of_size.{w} F :=
⟨λ (J : Type w) hJ fJ, by {
    resetI,
    letI : small_category (ulift_hom.{w₂} (ulift.{w₂} J)),
    { exact (@ulift_hom.category (ulift.{w₂ w} J) (@category_theory.ulift_category J _)) },
    haveI := preserves_finite_limits_of_size.preserves_finite_limits
      (ulift_hom.{w₂ (max w w₂)} (ulift.{w₂ w} J)),
    apply preserves_limits_of_shape_of_equiv (ulift_hom_ulift_category.equiv.{w₂ w₂} J).symm F,
    rotate, rotate, rotate, rotate, rotate, exact hpres,
  }⟩

def preserves_finite_limits_of_preserve_finite_limits_of_size
  (F : C ⥤ D) [preserves_finite_limits_of_size.{w} F] : preserves_finite_limits F :=
preserves_finite_limits_of_size_shrink F

@[priority 100]
instance preserves_limits.preserves_finite_limits (F : C ⥤ D) [preserves_limits_of_size.{w w} F] :
  preserves_finite_limits_of_size.{w} F := {}

instance id_preserves_finite_limits :
  preserves_finite_limits_of_size (𝟭 C) := {}

/-- The composition of two left exact functors is left exact. -/
def comp_preserves_finite_limits (F : C ⥤ D) (G : D ⥤ E)
  [preserves_finite_limits_of_size.{w} F] [preserves_finite_limits_of_size.{w} G] :
  preserves_finite_limits_of_size.{w} (F ⋙ G) :=
⟨λ _ _ _, by { resetI, apply_instance }⟩

/--
A functor is said to preserve finite colimits of size `w`, if it preserves all colimits of 
shape `J`, where `J : Type w` is a finite category.
-/
class preserves_finite_colimits_of_size (F : C ⥤ D) :=
(preserves_finite_colimits : Π (J : Type w) [small_category J] [fin_category J],
  preserves_colimits_of_shape J F . tactic.apply_instance)

  /-- Preserving finite colimits means preserving finite colimits of size `0`. -/
abbreviation preserves_finite_colimits (F : C ⥤ D) := preserves_finite_colimits_of_size.{0} F

attribute [instance] preserves_finite_colimits_of_size.preserves_finite_colimits

/--
`preserves_finite_colimits_of_size_shrink.{w} F` tries to obtain
`preserves_finite_colimits_of_size.{w} F` from some other `preserves_finite_colimits_of_size F`.
-/
def preserves_finite_colimits_of_size_shrink (F : C ⥤ D)
  [hpres : preserves_finite_colimits_of_size.{(max w w₂)} F] :
  preserves_finite_colimits_of_size.{w} F :=
⟨λ (J : Type w) hJ fJ, by {
    resetI,
    letI : small_category (ulift_hom.{w₂} (ulift.{w₂} J)),
    { exact (@ulift_hom.category (ulift.{w₂ w} J) (@category_theory.ulift_category J _)) },
    haveI := preserves_finite_colimits_of_size.preserves_finite_colimits
      (ulift_hom.{w₂ (max w w₂)} (ulift.{w₂ w} J)),
    apply preserves_colimits_of_shape_of_equiv (ulift_hom_ulift_category.equiv.{w₂ w₂} J).symm F,
    rotate, rotate, rotate, rotate, rotate, exact hpres,
  }⟩

set_option pp.universes true
def preserves_finite_colimits_of_preserve_finite_colimits_of_size
  (F : C ⥤ D) [preserves_finite_colimits_of_size.{w} F] : preserves_finite_colimits F :=
preserves_finite_colimits_of_size_shrink F

@[priority 100]
instance preserves_colimits.preserves_finite_colimits (F : C ⥤ D)
  [preserves_colimits_of_size.{w w} F] : preserves_finite_colimits_of_size.{w} F := {}

instance id_preserves_finite_colimits :
  preserves_finite_colimits_of_size (𝟭 C) := {}

/-- The composition of two right exact functors is right exact. -/
def comp_preserves_finite_colimits (F : C ⥤ D) (G : D ⥤ E)
  [preserves_finite_colimits_of_size.{w} F] [preserves_finite_colimits_of_size.{w} G] :
  preserves_finite_colimits_of_size.{w} (F ⋙ G) :=
⟨λ _ _ _, by { resetI, apply_instance }⟩

end category_theory.limits
