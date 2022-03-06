/-
Copyright (c) 2020 Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta
-/
import category_theory.limits.presheaf
import category_theory.limits.preserves.functor_category
import category_theory.limits.shapes.types
import category_theory.closed.cartesian
import category_theory.monoidal.types

/-!
# Cartesian closure of Type

Show that `Type u₁` is cartesian closed, and `C ⥤ Type u₁` is cartesian closed for `C` a small
category in `Type u₁`.
Note this implies that the category of presheaves on a small category `C` is cartesian closed.
-/

namespace category_theory

noncomputable theory

open category limits
universes v₁ v₂ u₁ u₂

variables {C : Type v₂} [category.{v₁} C]

section cartesian_closed

open opposite

/--
Auxiliary definition for the `has_internal_homs` instance on `Type v₁`.
(This is only a separate definition in order to speed up typechecking. )
-/
@[simps]
def has_internal_homs_hom_equiv (X Y Z : Type v₁) :
  ((monoidal_category.tensor_left X).obj Y ⟶ Z) ≃
    (Y ⟶ (coyoneda.obj (op X)).obj Z) :=
{ to_fun := λ f y x, f (x, y),
  inv_fun := λ f ⟨x,y⟩, f y x,
  left_inv := λ f, by tidy,
  right_inv := λ f, by tidy, }

instance : has_internal_homs (Type v₁) :=
{ has_internal_hom := λ X,
  { ihom := coyoneda.obj (op X),
    adj := adjunction.mk_of_hom_equiv
    { hom_equiv := λ Y Z, has_internal_homs_hom_equiv X Y Z, } } }

instance (X : Type v₁) : is_left_adjoint (types.binary_product_functor.obj X) :=
{ right :=
  { obj := λ Y, X ⟶ Y,
    map := λ Y₁ Y₂ f g, g ≫ f },
  adj := adjunction.mk_of_unit_counit
  { unit := { app := λ Z (z : Z) x, ⟨x, z⟩ },
    counit := { app := λ Z xf, xf.2 xf.1 } } }

instance : has_finite_products (Type v₁) := has_finite_products_of_has_products _

/-
Note that we can't just use the `has_internal_homs` instance above,
because it uses the `category_theory.types_monoidal` instance,
which is not definitionally equal to the
`category_theory.monoidal_of_has_finite_products` instance baked into `cartesian_closed`.

As a consequence, while the internal hom `X ⟶[Type v₁] Y` will just be the usual
function type `X → Y`, the `X ⟹ Y` type coming from the `cartesian_closed` instance
will be "opaque".
-/
instance : cartesian_closed (Type v₁) :=
{ closed' := λ X,
  { is_adj := adjunction.left_adjoint_of_nat_iso (types.binary_product_iso_prod.app X) } }

instance {C : Type u₁} [category.{v₁} C] : has_finite_products (C ⥤ Type u₁) :=
has_finite_products_of_has_products _

instance {C : Type v₁} [small_category C] : cartesian_closed (C ⥤ Type v₁) :=
{ closed' := λ F,
  { is_adj :=
    begin
      letI := functor_category.prod_preserves_colimits F,
      apply is_left_adjoint_of_preserves_colimits (prod.functor.obj F),
    end } }

end cartesian_closed

end category_theory
