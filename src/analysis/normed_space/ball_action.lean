/-
Copyright (c) 2022 Yury Kudryashov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yury Kudryashov
-/
import analysis.normed.field.unit_ball
import analysis.normed_space.basic

/-!
# Multiplicative actions of/on balls and spheres
-/
open metric set
variables {𝕜 E : Type*} [normed_field 𝕜] [semi_normed_group E] [normed_space 𝕜 E] {r : ℝ}

section closed_ball

instance mul_action_closed_ball_ball : mul_action (closed_ball (0 : 𝕜) 1) (ball (0 : E) r) :=
{ smul := λ c x, ⟨(c : 𝕜) • x, mem_ball_zero_iff.2 $
    by simpa only [norm_smul, one_mul]
      using mul_lt_mul' (mem_closed_ball_zero_iff.1 c.2) (mem_ball_zero_iff.1 x.2)
        (norm_nonneg _) one_pos⟩,
  one_smul := λ x, subtype.ext $ one_smul 𝕜 _,
  mul_smul := λ c₁ c₂ x, subtype.ext $ mul_smul _ _ _ }

instance mul_action_closed_ball_closed_ball :
  mul_action (closed_ball (0 : 𝕜) 1) (closed_ball (0 : E) r) :=
{ smul := λ c x, ⟨(c : 𝕜) • x, mem_closed_ball_zero_iff.2 $
    by simpa only [norm_smul, one_mul]
      using mul_le_mul (mem_closed_ball_zero_iff.1 c.2) (mem_closed_ball_zero_iff.1 x.2)
        (norm_nonneg _) zero_le_one⟩,
  one_smul := λ x, subtype.ext $ one_smul 𝕜 _,
  mul_smul := λ c₁ c₂ x, subtype.ext $ mul_smul _ _ _ }

end closed_ball

section sphere

instance mul_action_sphere_ball : mul_action (sphere (0 : 𝕜) 1) (ball (0 : E) r) :=
{ smul := λ c x, inclusion sphere_subset_closed_ball c • x,
  one_smul := λ x, subtype.ext $ one_smul _ _,
  mul_smul := λ c₁ c₂ x, subtype.ext $ mul_smul _ _ _ }

instance mul_action_sphere_closed_ball : mul_action (sphere (0 : 𝕜) 1) (closed_ball (0 : E) r) :=
{ smul := λ c x, inclusion sphere_subset_closed_ball c • x,
  one_smul := λ x, subtype.ext $ one_smul _ _,
  mul_smul := λ c₁ c₂ x, subtype.ext $ mul_smul _ _ _ }

instance : mul_action (sphere (0 : 𝕜) 1) (sphere (0 : E) r) :=
{ smul := λ c x, ⟨(c : 𝕜) • x, mem_sphere_zero_iff_norm.2 $
    by rw [norm_smul, mem_sphere_zero_iff_norm.1 c.coe_prop, mem_sphere_zero_iff_norm.1 x.coe_prop,
      one_mul]⟩,
  one_smul := λ x, subtype.ext $ one_smul _ _,
  mul_smul := λ c₁ c₂ x, subtype.ext $ mul_smul _ _ _ }

end sphere

variables (𝕜) [char_zero 𝕜]

lemma ne_neg_of_mem_sphere {r : ℝ} (hr : r ≠ 0) (x : sphere (0:E) r) : x ≠ - x :=
λ h, ne_zero_of_mem_sphere hr x ((self_eq_neg 𝕜 _).mp (by { conv_lhs {rw h}, simp }))

lemma ne_neg_of_mem_unit_sphere (x : sphere (0:E) 1) : x ≠ - x :=
ne_neg_of_mem_sphere 𝕜 one_ne_zero x
