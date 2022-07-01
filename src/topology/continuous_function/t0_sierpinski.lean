/-
Copyright (c) 2022 Ivan Sadofschi Costa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ivan Sadofschi Costa
-/
import topology.order
import topology.sets.opens
import topology.continuous_function.basic

/-!
# Any T0 space embeds in a product of copies of the Sierpinski space.

We consider `Prop` with the Sierpinski topology. If `X` is a topological space, there is a continuous
map `product_of_mem_opens` from `X` to `opens X → Prop` which is the product of the maps
`X → Prop` given by `x ↦ x ∈ u`.

The map `product_of_mem_opens` is always inducing. Whenever `X` is T0, `product_of_mem_opens` is
also injective and therefore an embedding.
-/

noncomputable theory

namespace topological_space

lemma eq_induced_by_maps_to_sierpinski (X : Type*) [t : topological_space X] :
  t = ⨅ (u : opens X), topological_space.induced (λ x, x ∈ u) sierpinski_space :=
le_antisymm
(le_infi_iff.2 (λ u, continuous.le_induced $ is_open_iff_continuous_mem.1 u.2))
(is_open_implies_is_open_iff.mp $ λ u h,
begin
  apply is_open_implies_is_open_iff.mpr _ u _,
  { exact topological_space.induced (λ (x : X), x ∈ u) sierpinski_space },
  { exact infi_le_of_le ⟨u,h⟩ (le_refl _) },
  { exact is_open_induced_iff'.mpr ⟨{true}, ⟨is_open_singleton_true, by simp [set.preimage]⟩⟩ },
end)

variables (X : Type*) [topological_space X]

/--
The continuous map from `X` to the product of copies of the Sierpinski space, (one copy for each
open subset `u` of `X`). The `u` coordinate of `product_of_mem_opens x` is given by `x ∈ u`.
-/
def product_of_mem_opens : continuous_map X (opens X → Prop) :=
{ to_fun := λ x u, x ∈ u,
  continuous_to_fun := continuous_pi_iff.2 (λ u, continuous_Prop.2 u.property) }

lemma product_of_mem_opens_inducing : inducing (product_of_mem_opens X) :=
begin
  convert inducing_infi_to_pi (λ (u : opens X) (x : X), x ∈ u),
  apply eq_induced_by_maps_to_sierpinski,
end

lemma product_of_mem_opens_injective [t0_space X] : function.injective (product_of_mem_opens X) :=
begin
  intros x1 x2 h,
  apply inseparable.eq,
  rw [←inducing.inseparable_iff (product_of_mem_opens_inducing X), h],
 end

theorem product_of_mem_opens_embedding [t0_space X] : embedding (product_of_mem_opens X) :=
embedding.mk (product_of_mem_opens_inducing X) (product_of_mem_opens_injective X)

end topological_space
