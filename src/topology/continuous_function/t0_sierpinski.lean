/-
Copyright (c) 2022 Ivan Sadofschi Costa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ivan Sadofschi Costa
-/
import topology.order
import topology.continuous_function.basic

/-!
# Any T0 space embeds in a product of copies of the Sierpinski space

We consider `Prop` with the Sierpinski topology. If `t` is a topology on `X`, there is a continuous
map `product_of_mem_opens : X → Π u ∈ t, Prop` defined as the product of the maps `X → Prop` defined
by `x ↦ x ∈ u`.

The map `product_of_mem_opens` is always inducing. Whenever `X` is T0, `product_of_mem_opens` is
also injective and therefore an embedding.
-/

noncomputable theory

variables {X : Type*} [t : topological_space X] [t0 : t0_space X]

instance : topological_space (Π (u : {s : set X | t.is_open s}), Prop) :=
@Pi.topological_space _ (λ u, Prop) (λ u, sierpinski_space)

/--
  The continuous map from `X` to the product of copies of the Sierpinski space, (one copy for each
  open subset `u` of `X`). The `u` coordinate of  `product_of_mem_opens x` is given by `x ∈ u`.
-/
def product_of_mem_opens (X : Type*) [t : topological_space X] : continuous_map X
  (Π (u : {s : set X | t.is_open s}), Prop) :=
{ to_fun := λ x u, x ∈ (u : set X),
  continuous_to_fun := continuous_pi_iff.2 (λ u, continuous_Prop.2 (by simpa using subtype.mem u)) }

include t0
lemma product_of_mem_opens_injective : function.injective (product_of_mem_opens X) :=
begin
  rw function.injective,
  intros x1 x2 h,
  by_contra' c,
  cases (t0_space_def X).1 t0 x1 x2 c with u hu,
  apply (xor_iff_not_iff _ _).1 hu.2,
  simpa only [eq_iff_iff, subtype.coe_mk] using congr_fun h ⟨u, hu.1⟩
 end
 omit t0

lemma eq_induced_by_maps_to_sierpinski : t = ⨅ (u : {s : set X | t.is_open s}),
   topological_space.induced (λ x, x ∈ (u : set X)) sierpinski_space :=
le_antisymm
(le_infi_iff.2 (λ u, continuous.le_induced $ is_open_iff_continuous_mem.1 u.2))
(is_open_implies_is_open_iff.mp $ λ u h,
begin
  apply is_open_implies_is_open_iff.mpr _ u _,
  { exact topological_space.induced (λ (x : X), x ∈ u) sierpinski_space },
  { exact infi_le_of_le ⟨u,h⟩ (by simp) },
  { exact is_open_induced_iff'.mpr ⟨{true}, ⟨is_open_singleton_true, by simp [set.preimage]⟩⟩},
end)

include t
lemma product_of_mem_opens_inducing : inducing (product_of_mem_opens X).to_fun :=
⟨(eq_induced_by_maps_to_sierpinski).trans begin
  erw induced_infi, -- same steps as in the proof of `inducing_infi_to_pi`
  congr' 1,
  funext,
  erw induced_compose,
  refl
end⟩

theorem product_of_mem_opens_embedding : embedding (product_of_mem_opens X) :=
embedding.mk (product_of_mem_opens_inducing) (@product_of_mem_opens_injective X t t0)
