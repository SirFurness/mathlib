/-
Copyright (c) 2022 Andrew Yang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang
-/
import algebraic_geometry.AffineScheme
import algebraic_geometry.pullbacks

/-!
# Properties of morphisms

We provide the basic framework for talking about properties of morphisms.
The following meta-properties are defined

* `respects_iso`: `P` respects isomorphisms if `P f → P (e ≫ f)` and `P f → P (f ≫ e)`, where
  `e` is an isomorphism.
* `stable_under_composition`: `P` is stable under composition if `P f → P g → P (f ≫ g)`.
* `stable_under_base_change`: `P` is stable under base change if `P (Y ⟶ S) → P (X ×[S] Y ⟶ X)`.

-/

universe u

open topological_space category_theory category_theory.limits opposite

noncomputable theory

namespace algebraic_geometry

/-- A `morphism_property` is a class of morphisms between schemes. -/
def morphism_property := ∀ ⦃X Y : Scheme⦄ (f : X ⟶ Y), Prop

/-- An `affine_target_morphism_property` is a class of morphisms from an arbitrary scheme into an
affine scheme. -/
def affine_target_morphism_property := ∀ ⦃X Y : Scheme⦄ (f : X ⟶ Y) [is_affine Y], Prop

/-- `is_iso` as an `morphism_property`. -/
protected def is_iso : morphism_property := @is_iso Scheme

/-- `is_iso` as an `morphism_property`. -/
protected def affine_target_is_iso : affine_target_morphism_property :=
λ X Y f H, is_iso f

instance : lattice morphism_property :=
{ le := λ P₁ P₂, ∀ ⦃X Y : Scheme⦄ (f : X ⟶ Y), P₁ f → P₂ f,
  le_refl := λ P X Y f H, H,
  le_trans := λ P₁ P₂ P₃ h₁ h₂ X Y f, h₂ f ∘ h₁ f,
  le_antisymm := λ P₁ P₂ h₁ h₂, funext $ λ _, funext $ λ _, funext $ λ f, propext ⟨h₁ f, h₂ f⟩,

  sup := λ P₁ P₂ X Y f, P₁ f ∨ P₂ f,
  le_sup_left  := λ P₁ P₂ X Y f H, or.inl H,
  le_sup_right := λ P₁ P₂ X Y f H, or.inr H,
  sup_le := λ P₁ P₂ P₃ h₁ h₂ X Y f H, or.cases_on H (h₁ f) (h₂ f),

  inf := λ P₁ P₂ X Y f, P₁ f ∧ P₂ f,
  inf_le_left  := λ P₁ P₂ X Y f H, H.1,
  inf_le_right := λ P₁ P₂ X Y f H, H.2,
  le_inf := λ P₁ P₂ P₃ h₁ h₂ X Y f H, ⟨h₁ f H, h₂ f H⟩ }

/-- A `affine_target_morphism_property` can be extended to a `morphism_property` such that it
*never* holds when the target is not affine -/
def affine_target_morphism_property.to_property (P : affine_target_morphism_property) :
  morphism_property :=
λ X Y f, ∃ h, @@P f h

lemma affine_target_morphism_property.to_property_apply (P : affine_target_morphism_property)
  {X Y : Scheme} (f : X ⟶ Y) [is_affine Y] :
  P.to_property f ↔ P f := by { delta affine_target_morphism_property.to_property, simp [*] }

/-- A morphism property `respects_iso` if it still holds when composed with an isomorphism -/
def respects_iso (P : morphism_property) :=
  (∀ {X Y Z} (e : X ≅ Y) (f : Y ⟶ Z), P f → P (e.hom ≫ f)) ∧
  (∀ {X Y Z} (e : Y ≅ Z) (f : X ⟶ Y), P f → P (f ≫ e.hom))

/-- A morphism property is `stable_under_composition` if the composition of two such morphisms
still falls in the class. -/
def stable_under_composition (P : morphism_property) :=
  ∀ ⦃X Y Z⦄ (f : X ⟶ Y) (g : Y ⟶ Z), P f → P g → P (f ≫ g)

/-- A morphism property is `stable_under_composition` if the base change of such a morphism
still falls in the class. -/
def stable_under_base_change
  (P : morphism_property) : Prop :=
∀ ⦃X Y S : Scheme⦄ (f : X ⟶ S) (g : Y ⟶ S), P g → P (pullback.fst : pullback f g ⟶ X)

lemma stable_under_composition.respects_iso {P : morphism_property}
  (hP : stable_under_composition P) (hP' : ∀ {X Y} (e : X ≅ Y), P e.hom) : respects_iso P :=
⟨λ X Y Z e f hf, hP _ _ (hP' e) hf, λ X Y Z e f hf, hP _ _ hf (hP' e)⟩

lemma respects_iso.cancel_left_is_iso {P : morphism_property}
  (hP : respects_iso P) {X Y Z : Scheme} (f : X ⟶ Y) (g : Y ⟶ Z) [is_iso f] :
    P (f ≫ g) ↔ P g :=
⟨λ h, by simpa using hP.1 (as_iso f).symm (f ≫ g) h, hP.1 (as_iso f) g⟩

lemma respects_iso.cancel_right_is_iso {P : morphism_property}
  (hP : respects_iso P) {X Y Z : Scheme} (f : X ⟶ Y) (g : Y ⟶ Z) [is_iso g] :
    P (f ≫ g) ↔ P f :=
⟨λ h, by simpa using hP.2 (as_iso g).symm (f ≫ g) h, hP.2 (as_iso g) f⟩

lemma respects_iso.affine_cancel_left_is_iso {P : affine_target_morphism_property}
  (hP : respects_iso P.to_property) {X Y Z : Scheme} (f : X ⟶ Y) (g : Y ⟶ Z) [is_iso f]
    [is_affine Z] : P (f ≫ g) ↔ P g :=
by convert hP.cancel_left_is_iso f g; rw P.to_property_apply

lemma respects_iso.affine_cancel_right_is_iso {P : affine_target_morphism_property}
  (hP : respects_iso P.to_property) {X Y Z : Scheme} (f : X ⟶ Y) (g : Y ⟶ Z) [is_iso g]
  [is_affine Y] [is_affine Z] : P (f ≫ g) ↔ P f :=
by convert hP.cancel_right_is_iso f g; rw P.to_property_apply

/-- This is here to mirror `stable_under_base_change.snd`. -/
@[nolint unused_arguments]
lemma stable_under_base_change.fst {P : morphism_property}
  (hP : stable_under_base_change P) (hP' : respects_iso P) {X Y S : Scheme} (f : X ⟶ S)
  (g : Y ⟶ S) (H : P g) : P (pullback.fst : pullback f g ⟶ X) :=
hP f g H

lemma stable_under_base_change.snd {P : morphism_property}
  (hP : stable_under_base_change P) (hP' : respects_iso P) {X Y S : Scheme} (f : X ⟶ S)
  (g : Y ⟶ S) (H : P f) : P (pullback.snd : pullback f g ⟶ Y) :=
begin
  rw [← pullback_symmetry_hom_comp_fst, hP'.cancel_left_is_iso],
  exact hP g f H
end

lemma stable_under_base_change.base_change_obj {P : morphism_property}
  (hP : stable_under_base_change P) (hP' : respects_iso P) {S S' : Scheme} (f : S' ⟶ S)
  (X : over S) (H : P X.hom) : P ((base_change f).obj X).hom :=
hP.snd hP' X.hom f H

lemma stable_under_base_change.base_change_map {P : morphism_property}
  (hP : stable_under_base_change P) (hP' : respects_iso P) {S S' : Scheme} (f : S' ⟶ S)
  {X Y : over S} (g : X ⟶ Y) (H : P g.left) : P ((base_change f).map g).left :=
begin
  let e := pullback_right_pullback_fst_iso Y.hom f g.left ≪≫
    pullback.congr_hom (g.w.trans (category.comp_id _)) rfl,
  have : e.inv ≫ pullback.snd = ((base_change f).map g).left,
  { apply pullback.hom_ext; dsimp; simp },
  rw [← this, hP'.cancel_left_is_iso],
  apply hP.snd hP',
  exact H
end

lemma stable_under_base_change.pullback_map {P : morphism_property}
  (hP : stable_under_base_change P) (hP' : respects_iso P)
  (hP'' : stable_under_composition P) {S X X' Y Y' : Scheme}
  {f : X ⟶ S} {g : Y ⟶ S} {f' : X' ⟶ S} {g' : Y' ⟶ S} {i₁ : X ⟶ X'} {i₂ : Y ⟶ Y'}
  (h₁ : P i₁) (h₂ : P i₂) (e₁ : f = i₁ ≫ f') (e₂ : g = i₂ ≫ g') :
    P (pullback.map f g f' g' i₁ i₂ (𝟙 _)
      ((category.comp_id _).trans e₁) ((category.comp_id _).trans e₂)) :=
begin
  have : pullback.map f g f' g' i₁ i₂ (𝟙 _)
    ((category.comp_id _).trans e₁) ((category.comp_id _).trans e₂) =
      ((pullback_symmetry _ _).hom ≫
      ((base_change _).map (over.hom_mk _ e₂.symm : over.mk g ⟶ over.mk g')).left) ≫
      (pullback_symmetry _ _).hom ≫
      ((base_change g').map (over.hom_mk _ e₁.symm : over.mk f ⟶ over.mk f')).left,
  { apply pullback.hom_ext; dsimp; simp },
  rw this,
  apply hP''; rw hP'.cancel_left_is_iso,
  exacts [hP.base_change_map hP' _ (over.hom_mk _ e₂.symm : over.mk g ⟶ over.mk g') h₂,
    hP.base_change_map hP' _ (over.hom_mk _ e₁.symm : over.mk f ⟶ over.mk f') h₁],
end

end algebraic_geometry
#lint
