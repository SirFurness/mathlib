import analysis.normed_space.basic

open fintype

def ham {ι : Type*} [fintype ι] (β : ι → Type*) : Type* := Π i, β i

instance {ι : Type*} [fintype ι] (β : ι → Type*) [Π i, inhabited (β i)] : inhabited (ham β) :=
⟨λ i, default⟩

local notation `𝓗[` K`,` n`]` := ham (λ _ : fin n, K)

namespace hamming
variables {α ι : Type*} [fintype ι] {β : ι → Type*}

@[pattern] def of_ham : ham β ≃ Π i, β i := equiv.refl _
@[pattern] def to_ham : (Π i, β i) ≃ ham β := equiv.refl _

@[simp] lemma to_ham_symm_eq                : (@to_ham _ _ β).symm = of_ham := rfl
@[simp] lemma of_ham_symm_eq                : (@of_ham _ _ β).symm = to_ham := rfl
@[simp] lemma to_ham_of_ham (x : ham β)     : to_ham (of_ham x) = x := rfl
@[simp] lemma of_ham_to_ham (x : Π i, β i)  : of_ham (to_ham x) = x := rfl
@[simp] lemma to_ham_inj {x y : Π i, β i}   : to_ham x = to_ham y ↔ x = y := iff.rfl
@[simp] lemma of_ham_inj {x y : ham β}      : of_ham x = of_ham y ↔ x = y := iff.rfl

instance [Π i, has_zero (β i)] : has_zero (ham β) := pi.has_zero
instance [Π i, has_sub (β i)] : has_sub (ham β) := pi.has_sub
instance [Π i, has_scalar α (β i)] : has_scalar α (ham β) := pi.has_scalar
instance [has_zero α] [Π i, has_zero (β i)] [Π i, smul_with_zero α (β i)] :
smul_with_zero α (ham β) := pi.smul_with_zero _

instance [monoid α] [Π i, add_monoid (β i)] [Π i, distrib_mul_action α (β i)] :
distrib_mul_action α (ham β) := pi.distrib_mul_action _

-- This "should" be `add_comm_monoid`. But if one does this,
-- you can get what I think are diamond problems to do with semi_normed_group...
-- This would be solved if we had normed_monoid, maybe?
-- It's possible that it is better to extend things in another way?

instance [semiring α] [Π i, add_comm_group (β i)] [Π i, module α (β i)] :
module α (ham β) := pi.module _ _ _

section decidable_eq

variables {β} [Π i, decidable_eq (β i)]

def ham_dist (x y : ham β) := card {i // x i ≠ y i}

lemma ham_dist_smul_le [Π i, has_scalar α (β i)] (k : α) (x y : ham β) :
ham_dist (k • x) (k • y) ≤ ham_dist x y :=
card_subtype_mono _ _ (λ i h H, h (by rw [pi.smul_apply, pi.smul_apply, H]))

lemma ham_dist_smul [Π i, has_scalar α (β i)] {k : α} (hk : ∀ i, is_smul_regular (β i) k)
(x y : ham β) : ham_dist x y = ham_dist (k • x) (k • y) :=
le_antisymm (card_subtype_mono _ _ (λ _ h H, h (hk _ H))) (ham_dist_smul_le _ _ _)

lemma ham_dist_eq (x y : ham β) : ham_dist x y = card {i // x i ≠ y i} := rfl

lemma ham_dist_comm (x y : ham β) : ham_dist x y = ham_dist y x :=
by simp_rw [ham_dist_eq, ne_comm]

lemma ham_dist_triangle (x y z : ham β) : ham_dist x z ≤ ham_dist x y + ham_dist y z :=
begin
  simp_rw ham_dist_eq, refine le_trans (card_subtype_mono _ _ (λ _ h, _)) (card_subtype_or _ _), by_contra' H, exact h (eq.trans H.1 H.2)
end

lemma ham_dist_eq_zero (x y : ham β) : ham_dist x y = 0 ↔ x = y :=
begin
  rw [function.funext_iff, ham_dist_eq, card_eq_zero_iff],
  exact ⟨ λ h i, imp_of_not_imp_not _ _ (λ H, h.elim' ⟨i, H⟩) h,
          λ h, subtype.is_empty_of_false (λ i H, H (h _))⟩
end

lemma ham_dist_self (x : ham β) : ham_dist x x = 0 := (ham_dist_eq_zero _ _).mpr rfl

lemma eq_of_ham_dist_eq_zero (x y : ham β) : ham_dist x y = 0 → x = y := (ham_dist_eq_zero _ _).mp

lemma ham_dist_ne_zero (x y : ham β) : ham_dist x y ≠ 0 ↔ x ≠ y :=
not_iff_not.mpr (ham_dist_eq_zero _ _)

lemma ham_dist_pos (x y : ham β) : 0 < ham_dist x y ↔ x ≠ y :=
by rw [←ham_dist_ne_zero, iff_not_comm, not_lt, nat.le_zero_iff]

lemma ham_dist_eq_zero_iff_forall_eq (x y : ham β) : ham_dist x y = 0 ↔ ∀ i, x i = y i :=
by rw [ham_dist_eq_zero, function.funext_iff]

lemma ham_dist_ne_zero_iff_exists_ne (x y : ham β) : ham_dist x y ≠ 0 ↔ ∃ i, x i ≠ y i :=
by rw [ham_dist_ne_zero, function.ne_iff]

section has_zero

variable [Π i, has_zero (β i)]

def ham_wt (x : ham β) : ℕ := ham_dist x 0

lemma ham_wt_smul_le [has_zero α] [Π i, smul_with_zero α (β i)] (k : α) (x : ham β) :
ham_wt (k • x) ≤ ham_wt x :=
by rw [ham_wt, ← smul_zero' (ham β) k]; exact ham_dist_smul_le _ _ _

lemma ham_wt_smul [has_zero α] [Π i, smul_with_zero α (β i)] {k : α}
(hk : ∀ i, is_smul_regular (β i) k) (x : ham β) : ham_wt x = ham_wt (k • x) :=
by simp_rw ham_wt; nth_rewrite 1 ← smul_zero' (ham β) k; exact ham_dist_smul hk _ _

lemma ham_wt_eq (x : ham β) : ham_wt x = card {i // x i ≠ 0} := rfl

lemma ham_wt_eq_zero (x : ham β) : ham_wt x = 0 ↔ x = 0 := ham_dist_eq_zero _ _

lemma ham_wt_zero : ham_wt (0 : ham β) = 0 := ham_dist_self _

lemma zero_of_ham_wt_eq_zero (x : ham β) : ham_wt x = 0 → x = 0 := eq_of_ham_dist_eq_zero _ _

lemma ham_wt_ne_zero (x : ham β) : ham_wt x ≠ 0 ↔ x ≠ 0 := ham_dist_ne_zero _ _

lemma ham_wt_pos (x : ham β) : 0 < ham_wt x ↔ x ≠ 0 := ham_dist_pos _ _

lemma ham_wt_zero_iff_forall_zero (x : ham β) : ham_wt x = 0 ↔ ∀ i, x i = 0 :=
ham_dist_eq_zero_iff_forall_eq _ _

lemma ham_wt_pos_iff_exists_nz (x : ham β) : ham_wt x ≠ 0 ↔ ∃ i, x i ≠ 0 :=
ham_dist_ne_zero_iff_exists_ne _ _

end has_zero

lemma ham_dist_eq_ham_wt_sub [Π i, add_group (β i)] (x y : ham β) : ham_dist x y = ham_wt (x - y) :=
by simp_rw [ham_dist_eq, ham_wt_eq, pi.sub_apply, sub_ne_zero]

instance : has_dist (ham β) := ⟨λ x y, ham_dist x y⟩

@[simp, push_cast] lemma dist_eq_ham_dist (x y : ham β) : dist x y = ham_dist x y := rfl

instance : pseudo_metric_space (ham β) :=
{ dist_self           := by push_cast; exact_mod_cast ham_dist_self,
  dist_comm           := by push_cast; exact_mod_cast ham_dist_comm,
  dist_triangle       := by push_cast; exact_mod_cast ham_dist_triangle,
  ..ham.has_dist }

instance : metric_space (ham β) :=
{ eq_of_dist_eq_zero  := by push_cast; exact_mod_cast eq_of_ham_dist_eq_zero,
  ..ham.pseudo_metric_space }

instance [Π i, has_zero (β i)] : has_norm (ham β) := ⟨λ x, ham_wt x⟩

@[simp, push_cast] lemma norm_eq_ham_wt [Π i, has_zero (β i)] (x : ham β) : ∥x∥ = ham_wt x := rfl

instance [Π i, add_comm_group (β i)] : semi_normed_group (ham β) :=
{ dist_eq := by push_cast; exact_mod_cast ham_dist_eq_ham_wt_sub, ..pi.add_comm_group }

instance [Π i, add_comm_group (β i)] : normed_group (ham β) := { ..ham.semi_normed_group }

/-
Want something like this:
instance [Π i, add_comm_group (β i)] {α : Type*} [normed_field α] [Π i, module α (β i)] : normed_space α (ham β) := sorry

But this isn't true. There is no existing structure that captures properties like ham_wt_smul_le.

This is unfortunate - because the module structure ought to combine with the metric structure!
-/

end decidable_eq

end hamming
