/-
Copyright (c) 2022 Joseph Hua. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison, Bhavik Mehta, Johan Commelin, Reid Barton, Rob Lewis, Joseph Hua
-/
import category_theory.limits.final
import category_theory.functor.reflects_isomorphisms

/-!

# Algebras of endofunctors

This file defines (co)algebras of an endofunctor, and provides the category instance for them.
It also defines the forgetful functor from the category of (co)algebras. It is shown that the
structure map of the initial algebra of an endofunctor is an isomorphism.

## TODO

* Prove the dual result about the structure map of the terminal coalgebra of an endofunctor.
* Prove that if the countable infinite product over the powers of the endofunctor exists, then
  algebras over the endofunctor coincide with algebras over the free monad on the endofunctor.
-/

universes v u

namespace category_theory
namespace endofunctor

variables {C : Type u} [category.{v} C]

/-- An algebra of an endofunctor; `str` stands for "structure morphism" -/
structure algebra (F : C ⥤ C) :=
(A : C)
(str : F.obj A ⟶ A)

instance [inhabited C] : inhabited (algebra (𝟭 C)) := ⟨⟨ default , 𝟙 _ ⟩⟩

namespace algebra

variables {F : C ⥤ C} (A : algebra F) {A₀ A₁ A₂ : algebra F}

/-
```
        str
   F A₀ -----> A₀
    |          |
F f |          | f
    V          V
   F A₁ -----> A₁
        str
```
-/
/-- A morphism between algebras of endofunctor `F` -/
@[ext] structure hom (A₀ A₁ : algebra F) :=
(f : A₀.1 ⟶ A₁.1)
(h' : F.map f ≫ A₁.str = A₀.str ≫ f . obviously)

restate_axiom hom.h'
attribute [simp, reassoc] hom.h
namespace hom

/-- The identity morphism of an algebra of endofunctor `F` -/
def id : hom A A := { f := 𝟙 _ }

instance : inhabited (hom A A) := ⟨{ f := 𝟙 _ }⟩

/-- The composition of morphisms between algebras of endofunctor `F` -/
def comp (f : hom A₀ A₁) (g : hom A₁ A₂) : hom A₀ A₂ := { f := f.1 ≫ g.1 }

end hom

instance (F : C ⥤ C) : category_struct (algebra F) :=
{ hom := hom,
  id := hom.id,
  comp := @hom.comp _ _ _ }

@[simp] lemma id_eq_id : algebra.hom.id A = 𝟙 A := rfl

@[simp] lemma id_f : (𝟙 _ : A ⟶ A).1 = 𝟙 A.1 := rfl

variables {A₀ A₁ A₂} (f : A₀ ⟶ A₁) (g : A₁ ⟶ A₂)

@[simp] lemma comp_eq_comp : algebra.hom.comp f g = f ≫ g := rfl

@[simp] lemma comp_f : (f ≫ g).1 = f.1 ≫ g.1 := rfl

/-- Algebras of an endofunctor `F` form a category -/
instance (F : C ⥤ C) : category (algebra F) := {}

/--
To construct an isomorphism of algebras, it suffices to give an isomorphism of the As which
commutes with the structure morphisms.
-/
@[simps]
def iso_mk (h : A₀.1 ≅ A₁.1) (w : F.map h.hom ≫ A₁.str = A₀.str ≫ h.hom) : A₀ ≅ A₁ :=
{ hom := { f := h.hom },
  inv :=
  { f := h.inv,
    h' := by { rw [h.eq_comp_inv, category.assoc, ←w, ←functor.map_comp_assoc], simp } } }

/-- The forgetful functor from the category of algebras, forgetting the algebraic structure. -/
@[simps] def forget (F : C ⥤ C) : algebra F ⥤ C :=
{ obj := λ A, A.1,
  map := λ A B f, f.1 }

/-- An algebra morphism with an underlying isomorphism hom in `C` is an algebra isomorphism. -/
lemma iso_of_iso (f : A₀ ⟶ A₁) [is_iso f.1] : is_iso f :=
⟨⟨{ f := inv f.1,
    h' := by { rw [is_iso.eq_comp_inv f.1, category.assoc, ← f.h], simp } }, by tidy⟩⟩

instance forget_reflects_iso : reflects_isomorphisms (forget F) :=
{ reflects := λ A B, iso_of_iso }

instance forget_faithful : faithful (forget F) := {}

/--
From a natural transformation `α : G → F` we get a functor from
algebras of `F` to algebras of `G`.
-/
@[simps]
def functor_of_nat_trans {F G : C ⥤ C} (α : G ⟶ F) : algebra F ⥤ algebra G :=
{ obj := λ A,
  { A := A.1,
    str := α.app A.1 ≫ A.str },
  map := λ A₀ A₁ f,
  { f := f.1 } }

/-- The identity transformation induces the identity endofunctor on the category of algebras. -/
@[simps {rhs_md := semireducible}]
def functor_of_nat_trans_id :
  functor_of_nat_trans (𝟙 F) ≅ 𝟭 _ :=
nat_iso.of_components
  (λ X, iso_mk (iso.refl _) (by { dsimp, simp, }))
  (λ X Y f, by { ext, dsimp, simp })

/-- A composition of natural transformations gives the composition of corresponding functors. -/
@[simps {rhs_md := semireducible}]
def functor_of_nat_trans_comp {F₀ F₁ F₂ : C ⥤ C} (α : F₀ ⟶ F₁) (β : F₁ ⟶ F₂) :
  functor_of_nat_trans (α ≫ β) ≅
    functor_of_nat_trans β ⋙ functor_of_nat_trans α :=
nat_iso.of_components
  (λ X, iso_mk (iso.refl _) (by { dsimp, simp }))
  (λ X Y f, by { ext, dsimp, simp })

/--
If `α` and `β` are two equal natural transformations, then the functors of algebras induced by them
are isomorphic.
We define it like this as opposed to using `eq_to_iso` so that the components are nicer to prove
lemmas about.
-/
@[simps {rhs_md := semireducible}]
def functor_of_nat_trans_eq {F G : C ⥤ C} {α β : F ⟶ G} (h : α = β) :
  functor_of_nat_trans α ≅ functor_of_nat_trans β :=
nat_iso.of_components
  (λ X, iso_mk (iso.refl _) (by { dsimp, simp [h] }))
  (λ X Y f, by { ext, dsimp, simp })

/--
Naturally isomorphic endofunctors give equivalent categories of algebras.
Furthermore, they are equivalent as categories over `C`, that is,
we have `equiv_of_nat_iso h ⋙ forget = forget`.
-/
@[simps]
def equiv_of_nat_iso {F G : C ⥤ C} (α : F ≅ G) :
  algebra F ≌ algebra G :=
{ functor := functor_of_nat_trans α.inv,
  inverse := functor_of_nat_trans α.hom,
  unit_iso :=
    functor_of_nat_trans_id.symm ≪≫
    functor_of_nat_trans_eq (by simp) ≪≫
    functor_of_nat_trans_comp _ _,
  counit_iso :=
    (functor_of_nat_trans_comp _ _).symm ≪≫
    functor_of_nat_trans_eq (by simp) ≪≫
    functor_of_nat_trans_id }.

namespace initial

variables {A} (h : limits.is_initial A)

/-- The inverse of the structure map of an initial algebra -/
@[simp] def str_inv : A.1 ⟶ F.obj A.1 := (h.to ⟨ F.obj A.1 , F.map A.str ⟩).1

lemma left_inv' : (⟨str_inv h ≫ A.str⟩ : A ⟶ A) = 𝟙 A :=
limits.is_initial.hom_ext h _ (𝟙 A)

lemma left_inv : str_inv h ≫ A.str = 𝟙 _ := congr_arg hom.f (left_inv' h)

lemma right_inv : A.str ≫ str_inv h = 𝟙 _ :=
by { rw [str_inv, ← (h.to ⟨ F.obj A.1 , F.map A.str ⟩).h,
  ← F.map_id, ← F.map_comp], congr, exact (left_inv h) }

/--
The structure map of the inital algebra is an isomorphism,
hence endofunctors preserve their initial algebras
-/
lemma str_is_iso (h : limits.is_initial A) : is_iso A.str :=
{ out := ⟨ str_inv h, right_inv _ , left_inv _ ⟩ }

end initial
end algebra

/-- A coalgebra of an endofunctor; `str` stands for "structure morphism" -/
structure coalgebra (F : C ⥤ C) :=
(V : C)
(str : V ⟶ F.obj V)

instance [inhabited C] : inhabited (coalgebra (𝟭 C)) := ⟨⟨ default , 𝟙 _ ⟩⟩

namespace coalgebra

variables {F : C ⥤ C} (V : coalgebra F) {V₀ V₁ V₂ : coalgebra F}

/-
```
        str
    V₀ -----> F V₀
    |          |
  f |          | F f
    V          V
    V₁ -----> F V₁
        str
```
-/
/-- A morphism between coalgebras of an endofunctor `F` -/
@[ext] structure hom (V₀ V₁ : coalgebra F) :=
(f : V₀.1 ⟶ V₁.1)
(h' : V₀.str ≫ F.map f = f ≫ V₁.str . obviously)

restate_axiom hom.h'
attribute [simp, reassoc] hom.h
namespace hom

/-- The identity morphism of an algebra of endofunctor `F` -/
def id : hom V V := { f := 𝟙 _ }

instance : inhabited (hom V V) := ⟨{ f := 𝟙 _ }⟩

/-- The composition of morphisms between algebras of endofunctor `F` -/
def comp (f : hom V₀ V₁) (g : hom V₁ V₂) : hom V₀ V₂ := { f := f.1 ≫ g.1 }

end hom

instance (F : C ⥤ C) : category_struct (coalgebra F) :=
{ hom := hom,
  id := hom.id,
  comp := @hom.comp _ _ _ }

@[simp] lemma id_eq_id : coalgebra.hom.id V = 𝟙 V := rfl

@[simp] lemma id_f : (𝟙 _ : V ⟶ V).1 = 𝟙 V.1 := rfl

variables {V₀ V₁ V₂} (f : V₀ ⟶ V₁) (g : V₁ ⟶ V₂)

@[simp] lemma comp_eq_comp : coalgebra.hom.comp f g = f ≫ g := rfl

@[simp] lemma comp_f : (f ≫ g).1 = f.1 ≫ g.1 := rfl

/-- Coalgebras of an endofunctor `F` form a category -/
instance (F : C ⥤ C) : category (coalgebra F) := {}

/--
To construct an isomorphism of coalgebras, it suffices to give an isomorphism of the Vs which
commutes with the structure morphisms.
-/
@[simps]
def iso_mk (h : V₀.1 ≅ V₁.1) (w : V₀.str ≫ F.map h.hom = h.hom ≫ V₁.str ) : V₀ ≅ V₁ :=
{ hom := { f := h.hom },
  inv :=
  { f := h.inv,
    h' := by { rw [h.eq_inv_comp, ← category.assoc, ←w, category.assoc, ← functor.map_comp],
               simp only [iso.hom_inv_id, functor.map_id, category.comp_id] } } }

/-- The forgetful functor from the category of coalgebras, forgetting the coalgebraic structure. -/
@[simps] def forget (F : C ⥤ C) : coalgebra F ⥤ C :=
{ obj := λ A, A.1,
  map := λ A B f, f.1 }

/-- A coalgebra morphism with an underlying isomorphism hom in `C` is a coalgebra isomorphism. -/
lemma iso_of_iso (f : V₀ ⟶ V₁) [is_iso f.1] : is_iso f :=
⟨⟨{ f := inv f.1,
    h' := by { rw [is_iso.eq_inv_comp f.1, ← category.assoc, ← f.h, category.assoc], simp } },
          by tidy⟩⟩

instance forget_reflects_iso : reflects_isomorphisms (forget F) :=
{ reflects := λ A B, iso_of_iso }

instance forget_faithful : faithful (forget F) := {}

/--
From a natural transformation `α : F → G` we get a functor from
coalgebras of `F` to coalgebras of `G`.
-/
@[simps]
def functor_of_nat_trans {F G : C ⥤ C} (α : F ⟶ G) : coalgebra F ⥤ coalgebra G :=
{ obj := λ V,
  { V := V.1,
    str := V.str ≫ α.app V.1 },
  map := λ V₀ V₁ f,
    { f := f.1,
      h' := begin rw [category.assoc, ← α.naturality, ← category.assoc, f.h, category.assoc] end },
}

/-- The identity transformation induces the identity endofunctor on the category of coalgebras. -/
@[simps {rhs_md := semireducible}]
def functor_of_nat_trans_id :
  functor_of_nat_trans (𝟙 F) ≅ 𝟭 _ :=
nat_iso.of_components
  (λ X, iso_mk (iso.refl _) (by { dsimp, simp, }))
  (λ X Y f, by { ext, dsimp, simp })

/-- A composition of natural transformations gives the composition of corresponding functors. -/
@[simps {rhs_md := semireducible}]
def functor_of_nat_trans_comp {F₀ F₁ F₂ : C ⥤ C} (α : F₀ ⟶ F₁) (β : F₁ ⟶ F₂) :
  functor_of_nat_trans (α ≫ β) ≅
    functor_of_nat_trans α ⋙ functor_of_nat_trans β :=
nat_iso.of_components
  (λ X, iso_mk (iso.refl _) (by { dsimp, simp }))
  (λ X Y f, by { ext, dsimp, simp })

/--
If `α` and `β` are two equal natural transformations, then the functors of coalgebras induced by
them are isomorphic.
We define it like this as opposed to using `eq_to_iso` so that the components are nicer to prove
lemmas about.
-/
@[simps {rhs_md := semireducible}]
def functor_of_nat_trans_eq {F G : C ⥤ C} {α β : F ⟶ G} (h : α = β) :
  functor_of_nat_trans α ≅ functor_of_nat_trans β :=
nat_iso.of_components
  (λ X, iso_mk (iso.refl _) (by { dsimp, simp [h] }))
  (λ X Y f, by { ext, dsimp, simp })

/--
Naturally isomorphic endofunctors give equivalent categories of coalgebras.
Furthermore, they are equivalent as categories over `C`, that is,
we have `equiv_of_nat_iso h ⋙ forget = forget`.
-/
@[simps]
def equiv_of_nat_iso {F G : C ⥤ C} (α : F ≅ G) :
  coalgebra F ≌ coalgebra G :=
{ functor := functor_of_nat_trans α.hom,
  inverse := functor_of_nat_trans α.inv,
  unit_iso :=
    functor_of_nat_trans_id.symm ≪≫
    functor_of_nat_trans_eq (by simp) ≪≫
    functor_of_nat_trans_comp _ _,
  counit_iso :=
    (functor_of_nat_trans_comp _ _).symm ≪≫
    functor_of_nat_trans_eq (by simp) ≪≫
    functor_of_nat_trans_id }.

end coalgebra

namespace adjunction

variables {F : C ⥤ C} {G : C ⥤ C}

def alg_coalg_equiv (adj : F ⊣ G) : algebra F ≌ coalgebra G :=
{ functor :=
    { obj := λ A, { V := A.1,
                    str := (adj.hom_equiv A.1 A.1).to_fun A.2 },
      map := λ A₁ A₂ f, { f := f.1,
                          h' := begin dsimp,
                          simp only [adjunction.hom_equiv_unit, ← category.assoc],
                          erw  adj.unit.naturality,
                          simp only [category.assoc],
                          rw [← G.map_comp, ← f.h, functor.comp_map, G.map_comp], end } },
  inverse :=
    { obj := λ V, { A := V.1,
                    str := (adj.hom_equiv V.1 V.1).inv_fun V.2 },
      map := λ V₁ V₂ f, { f := f.1,
                          h' := begin dsimp,
                                simp only [adjunction.hom_equiv_counit, category.assoc],
                                erw ← adj.counit.naturality,
                                rw [← category.assoc, ← category.assoc, ← F.map_comp, ← f.h],
                                rw [functor.comp_map, F.map_comp], end } },
  unit_iso := { hom := { app := λ A, { f := (𝟙 A.1),
                                       h' := begin dsimp, simp, end },
                         naturality' := λ A₁ A₂ f, begin dsimp, sorry end },
                inv := _,
                hom_inv_id' := _,
                inv_hom_id' := _ },
  counit_iso := { hom := { app := λ V, _,
                           naturality' := _ },
                  inv := _,
                  hom_inv_id' := _,
                  inv_hom_id' := _ },
  functor_unit_iso_comp' := _ }

end adjunction

end endofunctor
end category_theory
