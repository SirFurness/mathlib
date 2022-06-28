/-
Copyright (c) 2021 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/
import algebra.big_operators.intervals
import measure_theory.measure.measure_space

/-!
# Independence of sets of sets and measure spaces (σ-algebras)

* A family of sets of sets `π : ι → set (set α)` is independent with respect to a measure `μ` if for
  any finite set of indices `s = {i_1, ..., i_n}`, for any sets `f i_1 ∈ π i_1, ..., f i_n ∈ π i_n`,
  `μ (⋂ i in s, f i) = ∏ i in s, μ (f i) `. It will be used for families of π-systems.
* A family of measurable space structures (i.e. of σ-algebras) is independent with respect to a
  measure `μ` (typically defined on a finer σ-algebra) if the family of sets of measurable sets they
  define is independent. I.e., `m : ι → measurable_space α` is independent with respect to a
  measure `μ` if for any finite set of indices `s = {i_1, ..., i_n}`, for any sets
  `f i_1 ∈ m i_1, ..., f i_n ∈ m i_n`, then `μ (⋂ i in s, f i) = ∏ i in s, μ (f i)`.
* Independence of sets (or events in probabilistic parlance) is defined as independence of the
  measurable space structures they generate: a set `s` generates the measurable space structure with
  measurable sets `∅, s, sᶜ, univ`.
* Independence of functions (or random variables) is also defined as independence of the measurable
  space structures they generate: a function `f` for which we have a measurable space `m` on the
  codomain generates `measurable_space.comap f m`.

## Main statements

* `Indep_sets.Indep`: if π-systems are independent as sets of sets, then the
measurable space structures they generate are independent.
* `indep_sets.indep`: variant with two π-systems.

## Implementation notes

We provide one main definition of independence:
* `Indep_sets`: independence of a family of sets of sets `pi : ι → set (set α)`.
Three other independence notions are defined using `Indep_sets`:
* `Indep`: independence of a family of measurable space structures `m : ι → measurable_space α`,
* `Indep_set`: independence of a family of sets `s : ι → set α`,
* `Indep_fun`: independence of a family of functions. For measurable spaces
  `m : Π (i : ι), measurable_space (β i)`, we consider functions `f : Π (i : ι), α → β i`.

Additionally, we provide four corresponding statements for two measurable space structures (resp.
sets of sets, sets, functions) instead of a family. These properties are denoted by the same names
as for a family, but without a capital letter, for example `indep_fun` is the version of `Indep_fun`
for two functions.

The definition of independence for `Indep_sets` uses finite sets (`finset`). An alternative and
equivalent way of defining independence would have been to use countable sets.
TODO: prove that equivalence.

Most of the definitions and lemma in this file list all variables instead of using the `variables`
keyword at the beginning of a section, for example
`lemma indep.symm {α} {m₁ m₂ : measurable_space α} [measurable_space α] {μ : measure α} ...` .
This is intentional, to be able to control the order of the `measurable_space` variables. Indeed
when defining `μ` in the example above, the measurable space used is the last one defined, here
`[measurable_space α]`, and not `m₁` or `m₂`.

## References

* Williams, David. Probability with martingales. Cambridge university press, 1991.
Part A, Chapter 4.
-/

open measure_theory measurable_space
open_locale big_operators classical measure_theory

namespace probability_theory

section definitions

/-- A family of sets of sets `π : ι → set (set α)` is independent with respect to a measure `μ` if
for any finite set of indices `s = {i_1, ..., i_n}`, for any sets
`f i_1 ∈ π i_1, ..., f i_n ∈ π i_n`, then `μ (⋂ i in s, f i) = ∏ i in s, μ (f i) `.
It will be used for families of pi_systems. -/
def Indep_sets {α ι} [measurable_space α] (π : ι → set (set α)) (μ : measure α . volume_tac) :
  Prop :=
∀ (s : finset ι) {f : ι → set α} (H : ∀ i, i ∈ s → f i ∈ π i), μ (⋂ i ∈ s, f i) = ∏ i in s, μ (f i)

/-- Two sets of sets `s₁, s₂` are independent with respect to a measure `μ` if for any sets
`t₁ ∈ p₁, t₂ ∈ s₂`, then `μ (t₁ ∩ t₂) = μ (t₁) * μ (t₂)` -/
def indep_sets {α} [measurable_space α] (s1 s2 : set (set α)) (μ : measure α . volume_tac) : Prop :=
∀ t1 t2 : set α, t1 ∈ s1 → t2 ∈ s2 → μ (t1 ∩ t2) = μ t1 * μ t2

/-- A family of measurable space structures (i.e. of σ-algebras) is independent with respect to a
measure `μ` (typically defined on a finer σ-algebra) if the family of sets of measurable sets they
define is independent. `m : ι → measurable_space α` is independent with respect to measure `μ` if
for any finite set of indices `s = {i_1, ..., i_n}`, for any sets
`f i_1 ∈ m i_1, ..., f i_n ∈ m i_n`, then `μ (⋂ i in s, f i) = ∏ i in s, μ (f i) `. -/
def Indep {α ι} (m : ι → measurable_space α) [measurable_space α] (μ : measure α . volume_tac) :
  Prop :=
Indep_sets (λ x, {s | measurable_set[m x] s}) μ

/-- Two measurable space structures (or σ-algebras) `m₁, m₂` are independent with respect to a
measure `μ` (defined on a third σ-algebra) if for any sets `t₁ ∈ m₁, t₂ ∈ m₂`,
`μ (t₁ ∩ t₂) = μ (t₁) * μ (t₂)` -/
def indep {α} (m₁ m₂ : measurable_space α) [measurable_space α] (μ : measure α . volume_tac) :
  Prop :=
indep_sets {s | measurable_set[m₁] s} {s | measurable_set[m₂] s} μ

/-- A family of sets is independent if the family of measurable space structures they generate is
independent. For a set `s`, the generated measurable space has measurable sets `∅, s, sᶜ, univ`. -/
def Indep_set {α ι} [measurable_space α] (s : ι → set α) (μ : measure α . volume_tac) : Prop :=
Indep (λ i, generate_from {s i}) μ

/-- Two sets are independent if the two measurable space structures they generate are independent.
For a set `s`, the generated measurable space structure has measurable sets `∅, s, sᶜ, univ`. -/
def indep_set {α} [measurable_space α] (s t : set α) (μ : measure α . volume_tac) : Prop :=
indep (generate_from {s}) (generate_from {t}) μ

/-- A family of functions defined on the same space `α` and taking values in possibly different
spaces, each with a measurable space structure, is independent if the family of measurable space
structures they generate on `α` is independent. For a function `g` with codomain having measurable
space structure `m`, the generated measurable space structure is `measurable_space.comap g m`. -/
def Indep_fun {α ι} [measurable_space α] {β : ι → Type*} (m : Π (x : ι), measurable_space (β x))
  (f : Π (x : ι), α → β x) (μ : measure α . volume_tac) : Prop :=
Indep (λ x, measurable_space.comap (f x) (m x)) μ

/-- Two functions are independent if the two measurable space structures they generate are
independent. For a function `f` with codomain having measurable space structure `m`, the generated
measurable space structure is `measurable_space.comap f m`. -/
def indep_fun {α β γ} [measurable_space α] [mβ : measurable_space β] [mγ : measurable_space γ]
  (f : α → β) (g : α → γ) (μ : measure α . volume_tac) : Prop :=
indep (measurable_space.comap f mβ) (measurable_space.comap g mγ) μ

end definitions

section indep

lemma indep_sets.symm {α} {s₁ s₂ : set (set α)} [measurable_space α] {μ : measure α}
  (h : indep_sets s₁ s₂ μ) :
  indep_sets s₂ s₁ μ :=
by { intros t1 t2 ht1 ht2, rw [set.inter_comm, mul_comm], exact h t2 t1 ht2 ht1, }

lemma indep.symm {α} {m₁ m₂ : measurable_space α} [measurable_space α] {μ : measure α}
  (h : indep m₁ m₂ μ) :
  indep m₂ m₁ μ :=
indep_sets.symm h

lemma indep_sets_of_indep_sets_of_le_left {α} {s₁ s₂ s₃: set (set α)} [measurable_space α]
  {μ : measure α} (h_indep : indep_sets s₁ s₂ μ) (h31 : s₃ ⊆ s₁) :
  indep_sets s₃ s₂ μ :=
λ t1 t2 ht1 ht2, h_indep t1 t2 (set.mem_of_subset_of_mem h31 ht1) ht2

lemma indep_sets_of_indep_sets_of_le_right {α} {s₁ s₂ s₃: set (set α)} [measurable_space α]
  {μ : measure α} (h_indep : indep_sets s₁ s₂ μ) (h32 : s₃ ⊆ s₂) :
  indep_sets s₁ s₃ μ :=
λ t1 t2 ht1 ht2, h_indep t1 t2 ht1 (set.mem_of_subset_of_mem h32 ht2)

lemma indep_of_indep_of_le_left {α} {m₁ m₂ m₃: measurable_space α} [measurable_space α]
  {μ : measure α} (h_indep : indep m₁ m₂ μ) (h31 : m₃ ≤ m₁) :
  indep m₃ m₂ μ :=
λ t1 t2 ht1 ht2, h_indep t1 t2 (h31 _ ht1) ht2

lemma indep_of_indep_of_le_right {α} {m₁ m₂ m₃: measurable_space α} [measurable_space α]
  {μ : measure α} (h_indep : indep m₁ m₂ μ) (h32 : m₃ ≤ m₂) :
  indep m₁ m₃ μ :=
λ t1 t2 ht1 ht2, h_indep t1 t2 ht1 (h32 _ ht2)

lemma indep_sets.union {α} [measurable_space α] {s₁ s₂ s' : set (set α)} {μ : measure α}
  (h₁ : indep_sets s₁ s' μ) (h₂ : indep_sets s₂ s' μ) :
  indep_sets (s₁ ∪ s₂) s' μ :=
begin
  intros t1 t2 ht1 ht2,
  cases (set.mem_union _ _ _).mp ht1 with ht1₁ ht1₂,
  { exact h₁ t1 t2 ht1₁ ht2, },
  { exact h₂ t1 t2 ht1₂ ht2, },
end

@[simp] lemma indep_sets.union_iff {α} [measurable_space α] {s₁ s₂ s' : set (set α)}
  {μ : measure α} :
  indep_sets (s₁ ∪ s₂) s' μ ↔ indep_sets s₁ s' μ ∧ indep_sets s₂ s' μ :=
⟨λ h, ⟨indep_sets_of_indep_sets_of_le_left h (set.subset_union_left s₁ s₂),
    indep_sets_of_indep_sets_of_le_left h (set.subset_union_right s₁ s₂)⟩,
  λ h, indep_sets.union h.left h.right⟩

lemma indep_sets.Union {α ι} [measurable_space α] {s : ι → set (set α)} {s' : set (set α)}
  {μ : measure α} (hyp : ∀ n, indep_sets (s n) s' μ) :
  indep_sets (⋃ n, s n) s' μ :=
begin
  intros t1 t2 ht1 ht2,
  rw set.mem_Union at ht1,
  cases ht1 with n ht1,
  exact hyp n t1 t2 ht1 ht2,
end

lemma indep_sets.inter {α} [measurable_space α] {s₁ s' : set (set α)} (s₂ : set (set α))
  {μ : measure α} (h₁ : indep_sets s₁ s' μ) :
  indep_sets (s₁ ∩ s₂) s' μ :=
λ t1 t2 ht1 ht2, h₁ t1 t2 ((set.mem_inter_iff _ _ _).mp ht1).left ht2

lemma indep_sets.Inter {α ι} [measurable_space α] {s : ι → set (set α)} {s' : set (set α)}
  {μ : measure α} (h : ∃ n, indep_sets (s n) s' μ) :
  indep_sets (⋂ n, s n) s' μ :=
by {intros t1 t2 ht1 ht2, cases h with n h, exact h t1 t2 (set.mem_Inter.mp ht1 n) ht2 }

lemma indep_sets_singleton_iff {α} [measurable_space α] {s t : set α} {μ : measure α} :
  indep_sets {s} {t} μ ↔ μ (s ∩ t) = μ s * μ t :=
⟨λ h, h s t rfl rfl,
  λ h s1 t1 hs1 ht1, by rwa [set.mem_singleton_iff.mp hs1, set.mem_singleton_iff.mp ht1]⟩

end indep

/-! ### Deducing `indep` from `Indep` -/
section from_Indep_to_indep

lemma Indep_sets.indep_sets {α ι} {s : ι → set (set α)} [measurable_space α] {μ : measure α}
  (h_indep : Indep_sets s μ) {i j : ι} (hij : i ≠ j) :
  indep_sets (s i) (s j) μ :=
begin
  intros t₁ t₂ ht₁ ht₂,
  have hf_m : ∀ (x : ι), x ∈ {i, j} → (ite (x=i) t₁ t₂) ∈ s x,
  { intros x hx,
    cases finset.mem_insert.mp hx with hx hx,
    { simp [hx, ht₁], },
    { simp [finset.mem_singleton.mp hx, hij.symm, ht₂], }, },
  have h1 : t₁ = ite (i = i) t₁ t₂, by simp only [if_true, eq_self_iff_true],
  have h2 : t₂ = ite (j = i) t₁ t₂, by simp only [hij.symm, if_false],
  have h_inter : (⋂ (t : ι) (H : t ∈ ({i, j} : finset ι)), ite (t = i) t₁ t₂)
      = (ite (i = i) t₁ t₂) ∩ (ite (j = i) t₁ t₂),
    by simp only [finset.set_bInter_singleton, finset.set_bInter_insert],
  have h_prod : (∏ (t : ι) in ({i, j} : finset ι), μ (ite (t = i) t₁ t₂))
      = μ (ite (i = i) t₁ t₂) * μ (ite (j = i) t₁ t₂),
    by simp only [hij, finset.prod_singleton, finset.prod_insert, not_false_iff,
      finset.mem_singleton],
  rw h1,
  nth_rewrite 1 h2,
  nth_rewrite 3 h2,
  rw [← h_inter, ← h_prod, h_indep {i, j} hf_m],
end

lemma Indep.indep {α ι} {m : ι → measurable_space α} [measurable_space α] {μ : measure α}
  (h_indep : Indep m μ) {i j : ι} (hij : i ≠ j) :
  indep (m i) (m j) μ :=
begin
  change indep_sets ((λ x, measurable_set[m x]) i) ((λ x, measurable_set[m x]) j) μ,
  exact Indep_sets.indep_sets h_indep hij,
end

end from_Indep_to_indep

/-!
## π-system lemma

Independence of measurable spaces is equivalent to independence of generating π-systems.
-/

section from_measurable_spaces_to_sets_of_sets
/-! ### Independence of measurable space structures implies independence of generating π-systems -/

lemma Indep.Indep_sets {α ι} [measurable_space α] {μ : measure α} {m : ι → measurable_space α}
  {s : ι → set (set α)} (hms : ∀ n, m n = generate_from (s n))
  (h_indep : Indep m μ) :
  Indep_sets s μ :=
λ S f hfs, h_indep S $ λ x hxS,
  ((hms x).symm ▸ measurable_set_generate_from (hfs x hxS) : measurable_set[m x] (f x))

lemma indep.indep_sets {α} [measurable_space α] {μ : measure α} {s1 s2 : set (set α)}
  (h_indep : indep (generate_from s1) (generate_from s2) μ) :
  indep_sets s1 s2 μ :=
λ t1 t2 ht1 ht2, h_indep t1 t2 (measurable_set_generate_from ht1) (measurable_set_generate_from ht2)

end from_measurable_spaces_to_sets_of_sets

section from_pi_systems_to_measurable_spaces
/-! ### Independence of generating π-systems implies independence of measurable space structures -/

private lemma indep_sets.indep_aux {α} {m2 : measurable_space α}
  {m : measurable_space α} {μ : measure α} [is_probability_measure μ] {p1 p2 : set (set α)}
  (h2 : m2 ≤ m) (hp2 : is_pi_system p2) (hpm2 : m2 = generate_from p2)
  (hyp : indep_sets p1 p2 μ) {t1 t2 : set α} (ht1 : t1 ∈ p1) (ht2m : measurable_set[m2] t2) :
  μ (t1 ∩ t2) = μ t1 * μ t2 :=
begin
  let μ_inter := μ.restrict t1,
  let ν := (μ t1) • μ,
  have h_univ : μ_inter set.univ = ν set.univ,
  by rw [measure.restrict_apply_univ, measure.smul_apply, smul_eq_mul, measure_univ, mul_one],
  haveI : is_finite_measure μ_inter := @restrict.is_finite_measure α _ t1 μ ⟨measure_lt_top μ t1⟩,
  rw [set.inter_comm, ← measure.restrict_apply (h2 t2 ht2m)],
  refine ext_on_measurable_space_of_generate_finite m p2 (λ t ht, _) h2 hpm2 hp2 h_univ ht2m,
  have ht2 : measurable_set[m] t,
  { refine h2 _ _,
    rw hpm2,
    exact measurable_set_generate_from ht, },
  rw [measure.restrict_apply ht2, measure.smul_apply, set.inter_comm],
  exact hyp t1 t ht1 ht,
end

lemma indep_sets.indep {α} {m1 m2 : measurable_space α} {m : measurable_space α}
  {μ : measure α} [is_probability_measure μ] {p1 p2 : set (set α)} (h1 : m1 ≤ m) (h2 : m2 ≤ m)
  (hp1 : is_pi_system p1) (hp2 : is_pi_system p2) (hpm1 : m1 = generate_from p1)
  (hpm2 : m2 = generate_from p2) (hyp : indep_sets p1 p2 μ) :
  indep m1 m2 μ :=
begin
  intros t1 t2 ht1 ht2,
  let μ_inter := μ.restrict t2,
  let ν := (μ t2) • μ,
  have h_univ : μ_inter set.univ = ν set.univ,
  by rw [measure.restrict_apply_univ, measure.smul_apply, smul_eq_mul, measure_univ, mul_one],
  haveI : is_finite_measure μ_inter := @restrict.is_finite_measure α _ t2 μ ⟨measure_lt_top μ t2⟩,
  rw [mul_comm, ← @measure.restrict_apply α _ μ t2 t1 (h1 t1 ht1)],
  refine ext_on_measurable_space_of_generate_finite m p1 (λ t ht, _) h1 hpm1 hp1 h_univ ht1,
  have ht1 : measurable_set[m] t,
  { refine h1 _ _,
    rw hpm1,
    exact measurable_set_generate_from ht, },
  rw [measure.restrict_apply ht1, measure.smul_apply, smul_eq_mul, mul_comm],
  exact indep_sets.indep_aux h2 hp2 hpm2 hyp ht ht2,
end

variables {α ι : Type*} {m0 : measurable_space α} {μ : measure α}

lemma Indep_sets.pi_Union_Inter_singleton {π : ι → set (set α)} {a : ι} {S : finset ι}
  (hp_ind : Indep_sets π μ) (haS : a ∉ S) :
  indep_sets (pi_Union_Inter π {S}) (π a) μ :=
begin
  rintros t1 t2 ⟨s, hs_mem, ft1, hft1_mem, ht1_eq⟩ ht2_mem_pia,
  rw set.mem_singleton_iff at hs_mem,
  subst hs_mem,
  let f := λ n, ite (n = a) t2 (ite (n ∈ s) (ft1 n) set.univ),
  have h_f_mem : ∀ n ∈ insert a s, f n ∈ π n,
  { intros n hn_mem_insert,
    simp_rw f,
    cases (finset.mem_insert.mp hn_mem_insert) with hn_mem hn_mem,
    { simp [hn_mem, ht2_mem_pia], },
    { have hn_ne_a : n ≠ a, by { rintro rfl, exact haS hn_mem, },
      simp [hn_ne_a, hn_mem, hft1_mem n hn_mem], }, },
  have h_f_mem_pi : ∀ n ∈ s, f n ∈ π n, from λ x hxS, h_f_mem x (by simp [hxS]),
  have h_t1 : t1 = ⋂ n ∈ s, f n,
  { suffices h_forall : ∀ n ∈ s, f n = ft1 n,
    { rw ht1_eq,
      congr' with n x,
      congr' with hns y,
      simp only [(h_forall n hns).symm], },
    intros n hnS,
    have hn_ne_a : n ≠ a, by { rintro rfl, exact haS hnS, },
    simp_rw [f, if_pos hnS, if_neg hn_ne_a], },
  have h_μ_t1 : μ t1 = ∏ n in s, μ (f n), by rw [h_t1, ← hp_ind s h_f_mem_pi],
  have h_t2 : t2 = f a, by { simp_rw [f], simp, },
  have h_μ_inter : μ (t1 ∩ t2) = ∏ n in insert a s, μ (f n),
  { have h_t1_inter_t2 : t1 ∩ t2 = ⋂ n ∈ insert a s, f n,
      by rw [h_t1, h_t2, finset.set_bInter_insert, set.inter_comm],
    rw [h_t1_inter_t2, ← hp_ind (insert a s) h_f_mem], },
  rw [h_μ_inter, finset.prod_insert haS, h_t2, mul_comm, h_μ_t1],
end

/-- Auxiliary lemma for `Indep_sets.Indep`. -/
theorem Indep_sets.Indep_aux [is_probability_measure μ] (m : ι → measurable_space α)
  (h_le : ∀ i, m i ≤ m0) (π : ι → set (set α)) (h_pi : ∀ n, is_pi_system (π n))
  (hp_univ : ∀ i, set.univ ∈ π i) (h_generate : ∀ i, m i = generate_from (π i))
  (h_ind : Indep_sets π μ) :
  Indep m μ :=
begin
  refine finset.induction (by simp [measure_univ]) _,
  intros a S ha_notin_S h_rec f hf_m,
  have hf_m_S : ∀ x ∈ S, measurable_set[m x] (f x) := λ x hx, hf_m x (by simp [hx]),
  rw [finset.set_bInter_insert, finset.prod_insert ha_notin_S, ← h_rec hf_m_S],
  let p := pi_Union_Inter π {S},
  set m_p := generate_from p with hS_eq_generate,
  have h_indep : indep m_p (m a) μ,
  { have hp : is_pi_system p := is_pi_system_pi_Union_Inter π h_pi {S} (sup_closed_singleton S),
    have h_le' : ∀ i, generate_from (π i) ≤ m0 := λ i, (h_generate i).symm.trans_le (h_le i),
    have hm_p : m_p ≤ m0 := generate_from_pi_Union_Inter_le π h_le' {S},
    exact indep_sets.indep hm_p (h_le a) hp (h_pi a) hS_eq_generate (h_generate a)
      (h_ind.pi_Union_Inter_singleton ha_notin_S), },
  refine h_indep.symm (f a) (⋂ n ∈ S, f n) (hf_m a (finset.mem_insert_self a S)) _,
  have h_le_p : ∀ i ∈ S, m i ≤ m_p,
  { intros n hn,
    rw [hS_eq_generate, h_generate n],
    exact le_generate_from_pi_Union_Inter {S} hp_univ (set.mem_singleton _) hn, },
  have h_S_f : ∀ i ∈ S, measurable_set[m_p] (f i) := λ i hi, (h_le_p i hi) (f i) (hf_m_S i hi),
  exact S.measurable_set_bInter h_S_f,
end

/-- The measurable space structures generated by independent pi-systems are independent. -/
theorem Indep_sets.Indep [is_probability_measure μ] (m : ι → measurable_space α)
  (h_le : ∀ i, m i ≤ m0) (π : ι → set (set α)) (h_pi : ∀ n, is_pi_system (π n))
  (h_generate : ∀ i, m i = generate_from (π i)) (h_ind : Indep_sets π μ) :
  Indep m μ :=
begin
  -- We want to apply `Indep_sets.Indep_aux`, but `π i` does not contain `univ`, hence we replace
  -- `π` with a new augmented pi-system `π'`, and prove all hypotheses for that pi-system.
  let π' := λ i, insert set.univ (π i),
  have h_subset : ∀ i, π i ⊆ π' i := λ i, set.subset_insert _ _,
  have h_pi' : ∀ n, is_pi_system (π' n) := λ n, (h_pi n).insert_univ,
  have h_univ' : ∀ i, set.univ ∈ π' i, from λ i, set.mem_insert _ _,
  have h_gen' : ∀ i, m i = generate_from (π' i),
  { intros i,
    rw [h_generate i, generate_from_insert_univ (π i)], },
  have h_ind' : Indep_sets π' μ,
  { intros S f hfπ',
    let S' := finset.filter (λ i, f i ≠ set.univ) S,
    have h_mem : ∀ i ∈ S', f i ∈ π i,
    { intros i hi,
      simp_rw [S', finset.mem_filter] at hi,
      cases hfπ' i hi.1,
      { exact absurd h hi.2, },
      { exact h, }, },
    have h_left : (⋂ i ∈ S, f i) = ⋂ i ∈ S', f i,
    { ext1 x,
      simp only [set.mem_Inter, finset.mem_filter, ne.def, and_imp],
      split,
      { exact λ h i hiS hif, h i hiS, },
      { intros h i hiS,
        by_cases hfi_univ : f i = set.univ,
        { rw hfi_univ, exact set.mem_univ _, },
        { exact h i hiS hfi_univ, }, }, },
    have h_right : ∏ i in S, μ (f i) = ∏ i in S', μ (f i),
    { rw ← finset.prod_filter_mul_prod_filter_not S (λ i, f i ≠ set.univ),
      simp only [ne.def, finset.filter_congr_decidable, not_not],
      suffices : ∏ x in finset.filter (λ x, f x = set.univ) S, μ (f x) = 1,
      { rw [this, mul_one], },
      calc ∏ x in finset.filter (λ x, f x = set.univ) S, μ (f x)
          = ∏ x in finset.filter (λ x, f x = set.univ) S, μ set.univ :
            finset.prod_congr rfl (λ x hx, by { rw finset.mem_filter at hx, rw hx.2, })
      ... = ∏ x in finset.filter (λ x, f x = set.univ) S, 1 :
            finset.prod_congr rfl (λ _ _, measure_univ)
      ... = 1 : finset.prod_const_one, },
    rw [h_left, h_right],
    exact h_ind S' h_mem, },
  exact Indep_sets.Indep_aux m h_le π' h_pi' h_univ' h_gen' h_ind',
end

end from_pi_systems_to_measurable_spaces

section indep_set
/-! ### Independence of measurable sets

We prove the following equivalences on `indep_set`, for measurable sets `s, t`.
* `indep_set s t μ ↔ μ (s ∩ t) = μ s * μ t`,
* `indep_set s t μ ↔ indep_sets {s} {t} μ`.
-/

variables {α : Type*} [measurable_space α] {s t : set α} (S T : set (set α))

lemma indep_set_iff_indep_sets_singleton (hs_meas : measurable_set s) (ht_meas : measurable_set t)
  (μ : measure α . volume_tac) [is_probability_measure μ] :
  indep_set s t μ ↔ indep_sets {s} {t} μ :=
⟨indep.indep_sets,  λ h, indep_sets.indep
  (generate_from_le (λ u hu, by rwa set.mem_singleton_iff.mp hu))
  (generate_from_le (λ u hu, by rwa set.mem_singleton_iff.mp hu)) (is_pi_system.singleton s)
  (is_pi_system.singleton t) rfl rfl h⟩

lemma indep_set_iff_measure_inter_eq_mul (hs_meas : measurable_set s) (ht_meas : measurable_set t)
  (μ : measure α . volume_tac) [is_probability_measure μ] :
  indep_set s t μ ↔ μ (s ∩ t) = μ s * μ t :=
(indep_set_iff_indep_sets_singleton hs_meas ht_meas μ).trans indep_sets_singleton_iff

lemma indep_sets.indep_set_of_mem (hs : s ∈ S) (ht : t ∈ T) (hs_meas : measurable_set s)
  (ht_meas : measurable_set t) (μ : measure α . volume_tac) [is_probability_measure μ]
  (h_indep : indep_sets S T μ) :
  indep_set s t μ :=
(indep_set_iff_measure_inter_eq_mul hs_meas ht_meas μ).mpr (h_indep s t hs ht)

end indep_set

section indep_fun

variables {α β β' γ γ' : Type*} {mα : measurable_space α} {μ : measure α}

lemma indep_fun.ae_eq {mβ : measurable_space β} {f g f' g' : α → β}
  (hfg : indep_fun f g μ) (hf : f =ᵐ[μ] f') (hg : g =ᵐ[μ] g') :
  indep_fun f' g' μ :=
begin
  rintro _ _ ⟨A, hA, rfl⟩ ⟨B, hB, rfl⟩,
  have h1 : f ⁻¹' A =ᵐ[μ] f' ⁻¹' A := hf.fun_comp A,
  have h2 : g ⁻¹' B =ᵐ[μ] g' ⁻¹' B := hg.fun_comp B,
  rw [← measure_congr h1, ← measure_congr h2, ← measure_congr (h1.inter h2)],
  exact hfg _ _ ⟨_, hA, rfl⟩ ⟨_, hB, rfl⟩
end

lemma indep_fun.comp {mβ : measurable_space β} {mβ' : measurable_space β'}
  {mγ : measurable_space γ} {mγ' : measurable_space γ'}
  {f : α → β} {g : α → β'} {φ : β → γ} {ψ : β' → γ'}
  (hfg : indep_fun f g μ) (hφ : measurable φ) (hψ : measurable ψ) :
  indep_fun (φ ∘ f) (ψ ∘ g) μ :=
begin
  rintro _ _ ⟨A, hA, rfl⟩ ⟨B, hB, rfl⟩,
  apply hfg,
  { exact ⟨φ ⁻¹' A, hφ hA, set.preimage_comp.symm⟩ },
  { exact ⟨ψ ⁻¹' B, hψ hB, set.preimage_comp.symm⟩ }
end

end indep_fun


/-! ### Kolmogorov's 0-1 law

In this section, we prove that any event in the tail σ-algebra has probability 0 or 1.
-/

section lattice

variables {α ι : Type*} [preorder ι] {n m : ι} {x : α}

/-- TODO: rename, or find existing equivalent definition -/
def tail [has_Sup α] [has_Inf α] (s : ι → α) : α := ⨅ n, ⨆ i ≥ n, s i

variables [complete_lattice α]

lemma le_head_n (s : ι → α) (hnm : n < m) : s n ≤ ⨆ j < m, s j := le_supr₂ n hnm

lemma head_n_le (s : ι → α) (n : ι) (h_le : ∀ n, s n ≤ x) : (⨆ i < n, s i) ≤ x :=
supr₂_le (λ i hi, h_le i)

lemma head_n_mono (s : ι → α) (h : n ≤ m) : (⨆ i < n, s i) ≤ ⨆ i < m, s i :=
bsupr_mono (λ i hi, hi.trans_le h)

lemma supr_eq_supr_head_n (s : ℕ → α) : (⨆ n, s n) = ⨆ n, ⨆ i < n, s i :=
le_antisymm (supr_le (λ i, le_trans (le_head_n s (nat.lt_succ_self i))
    (le_supr (λ i, (⨆ j < i, s j)) (i+1))))
  (supr_le (λ i, supr₂_le_supr (λ n, n < i) (λ n, s n)))

lemma tail_n_le (s : ι → α) (n : ι) (h_le : ∀ n, s n ≤ x) : (⨆ i ≥ n, s i) ≤ x :=
supr₂_le (λ i hi, h_le i)

lemma tail_n_le_supr (s : ι → α) (n : ι) : (⨆ i ≥ n, s i) ≤ ⨆ n, s n :=
supr₂_le_supr (λ i, i ≥ n) (λ i, (s i))

lemma tail_le_tail_n (s : ι → α) (n : ι) : tail s ≤ ⨆ i ≥ n, s i :=
infi_le (λ n, ⨆ i ≥ n, s i) n

lemma tail_le [h : nonempty ι] {s : ι → α} (h_le : ∀ n, s n ≤ x) : tail s ≤ x :=
(tail_le_tail_n s h.some).trans (tail_n_le s h.some h_le)

end lattice

section zero_one_law

variables {α : Type*} {m m0 : measurable_space α} {μ : measure α}

lemma measure_eq_zero_or_one_or_top_of_indep_self (h_indep : indep m m μ) {t : set α}
  (ht_m : measurable_set[m] t) :
  μ t = 0 ∨ μ t = 1 ∨ μ t = ⊤ :=
begin
  specialize h_indep t t ht_m ht_m,
  by_cases h0 : μ t = 0,
  { exact or.inl h0, },
  by_cases h_top : μ t = ⊤,
  { exact or.inr (or.inr h_top), },
  rw [← one_mul (μ (t ∩ t)), set.inter_self, ennreal.mul_eq_mul_right h0 h_top] at h_indep,
  exact or.inr (or.inl h_indep.symm),
end

lemma measure_eq_zero_or_one_of_indep_self [is_finite_measure μ] (h_indep : indep m m μ) {t : set α}
  (ht_m : measurable_set[m] t) :
  μ t = 0 ∨ μ t = 1 :=
begin
  have h_0_1_top := measure_eq_zero_or_one_or_top_of_indep_self h_indep ht_m,
  simpa [measure_ne_top μ] using h_0_1_top,
end

lemma head_n_eq_generate_from_Union_Inter_range (s : ℕ → measurable_space α) (n : ℕ) :
  (⨆ i < n, s i)
    = generate_from (pi_Union_Inter (λ n, {t | measurable_set[s n] t}) {finset.range n}) :=
by simp [generate_from_pi_Union_Inter_measurable_space s {finset.range n}]

lemma tail_n_eq_generate_from_Union_Inter_Icc (s : ℕ → measurable_space α) (N : ℕ) :
  (⨆ i ≥ N, s i) = generate_from (pi_Union_Inter (λ n, {t | measurable_set[s n] t})
    {p : finset ℕ | ∃ r, p = finset.Icc N (N + r)}) :=
begin
  rw generate_from_pi_Union_Inter_measurable_space s {p : finset ℕ | ∃ r, p = finset.Icc N (N + r)},
  congr,
  ext1 i,
  suffices h_congr : i ≥ N
      ↔ ∃ (p : finset ℕ) (hp : p ∈ {q : finset ℕ | ∃ r, q = finset.Icc N (N + r)}), i ∈ p,
    by simp [h_congr],
  simp_rw [exists_prop, set.mem_set_of_eq],
  split; intro h,
  { refine ⟨finset.Icc N (N + i), ⟨i, rfl⟩, _⟩,
    rw finset.mem_Icc,
    exact ⟨h, le_add_left le_rfl⟩, },
  { rcases h with ⟨p, ⟨r, rfl⟩, hip⟩,
    rw finset.mem_Icc at hip,
    exact hip.left, },
end

lemma prod_range_ite_eq_prod_range [comm_monoid α] (N r : ℕ) (f : ℕ → α) :
  (∏ n in finset.range (N + r), ite (n ∈ finset.range N) (f n) 1) = ∏ n in finset.range N, (f n) :=
begin
  simp_rw [finset.mem_range],
  rw [finset.range_eq_Ico,
    ← finset.prod_Ico_consecutive (λ x, ite (x < N) (f x) 1) (zero_le N) (le_add_right le_rfl)],
  have h_left : (∏ i in finset.Ico 0 N, (λ (x : ℕ), ite (x < N) (f x) 1) i)
      = ∏ i in finset.Ico 0 N, f i,
    from finset.prod_congr rfl (λ n hn, by simp [finset.mem_Ico.mp hn]),
  have h_right : (∏ i in finset.Ico N (N+r), (λ x, ite (x < N) (f x) 1) i) = 1,
  { refine finset.prod_eq_one (λ i hi, _),
    rw finset.mem_Ico at hi,
    dsimp only,
    rw if_neg (not_lt.mpr hi.1), },
  rw [h_left, h_right, mul_one],
end

lemma prod_range_ite_range_le [comm_monoid α] (N r : ℕ) (f : ℕ → α) :
  (∏ n in finset.range (N + r), ite (n ∈ finset.Ico N (N + r)) (f n) 1)
    = ∏ n in finset.Ico N (N + r), f n :=
begin
  simp_rw [finset.mem_Ico, finset.range_eq_Ico,
    ← finset.prod_Ico_consecutive (λ x, ite (N ≤ x ∧ x < N + r) (f x) 1) (zero_le N)
      (le_add_right le_rfl)],
  have h_left : (∏ (x : ℕ) in finset.range N, ite (N ≤ x ∧ x < N +r) (f x) 1) = 1,
  { refine finset.prod_eq_one (λ i hi, _),
    rw finset.mem_range at hi,
    simp [not_le.mpr hi], },
  rw [← finset.range_eq_Ico, h_left, one_mul],
  refine finset.prod_congr rfl (λ x hx, _),
  rw finset.mem_Ico at hx,
  simp [hx],
end

lemma aux_t1_inter_t2 (N r : ℕ) (f1 f2 : ℕ → set α) :
  ((⋂ i ∈ finset.range N, f1 i) ∩ ⋂ i ∈ finset.Icc N (N + r), f2 i)
    = ⋂ i ∈ finset.range (N + r + 1), (ite (i ∈ finset.range N) (f1 i) set.univ
      ∩ ite (i ∈ finset.Icc N (N + r)) (f2 i) set.univ) :=
begin
  ext1 x,
  simp only [set.mem_inter_eq, set.mem_Inter, finset.mem_range, finset.mem_Icc],
  split; intro h,
  { intros i _,
    split_ifs,
    exacts [⟨h.1 i h_1, h.2 i h_2⟩, ⟨h.1 i h_1, set.mem_univ _⟩, ⟨set.mem_univ _, h.2 i h_2⟩,
      ⟨set.mem_univ _, set.mem_univ _⟩], },
  { have h_le : N ≤ N + r + 1,
    { rw add_assoc, exact le_add_right le_rfl, },
    split; intros i hi; specialize h i,
    { specialize h (hi.trans_le h_le),
      rw if_pos hi at h,
      exact h.1, },
    { specialize h (nat.lt_succ_of_le hi.2),
      rw if_pos hi at h,
      exact h.2, }, },
end

lemma measurable_set.ite' {m0 : measurable_space α} {s t : set α} {p : Prop}
  (hs : p → measurable_set s) (ht : ¬ p → measurable_set t)  :
  measurable_set (ite p s t) :=
by { split_ifs, exacts [hs h, ht h], }

lemma indep_sets_head_n_tail_n_pi_systems [is_probability_measure μ] (s : ℕ → measurable_space α)
  (h_indep : Indep s μ) (N : ℕ) :
  indep_sets (pi_Union_Inter (λ n, {t | measurable_set[s n] t}) {finset.range N})
    (pi_Union_Inter (λ n, {t | measurable_set[s n] t})
      {p : finset ℕ | ∃ r : ℕ, p = finset.Icc N (N + r)}) μ :=
begin
  rintros t1 t2 ⟨p1, hp1, f1, ht1_m, ht1_eq⟩ ⟨p2, ⟨r, rfl⟩, f2, ht2_m, ht2_eq⟩,
  rw set.mem_singleton_iff at hp1,
  simp_rw [hp1] at *,
  let g := λ i, ite (i ∈ finset.range N) (f1 i) set.univ
    ∩ ite (i ∈ finset.Icc N (N + r)) (f2 i) set.univ,
  have h_P_inter : μ (t1 ∩ t2) = ∏ n in finset.range (N + r + 1), μ (g n),
  { have hgm : ∀ i, i ∈ finset.range (N + r + 1) → measurable_set[s i] (g i),
    { refine (λ i _, measurable_set.inter _ _),
      { convert measurable_set.ite' (ht1_m i) (λ _, measurable_set.univ), },
      { convert measurable_set.ite' (ht2_m i) (λ _, measurable_set.univ), }, },
    rw [ht1_eq, ht2_eq, aux_t1_inter_t2 N r f1 f2, ← h_indep (finset.range (N+r+1)) hgm], },
  rw h_P_inter,
  have h_μg : ∀ n, μ (g n)
    = (ite (n ∈ finset.range N) (μ (f1 n)) 1) * (ite (n ∈ finset.Icc N (N + r)) (μ (f2 n)) 1),
  { intro n,
    simp_rw g,
    split_ifs,
    { rw finset.mem_range at h,
      rw finset.mem_Icc at h_1,
      exact absurd h_1.1 (not_le.mpr h), },
    all_goals { simp only [measure_univ, one_mul, mul_one, set.inter_univ, set.univ_inter], }, },
  simp_rw h_μg,
  have h1 : (∏ x in finset.range (N + r + 1), ite (x ∈ finset.range N) (μ (f1 x)) 1)
    = ∏ x in finset.range N, μ (f1 x),
  { simp_rw [add_assoc],
    exact prod_range_ite_eq_prod_range N (r + 1) (λ n, μ (f1 n)), },
  have h2 : (∏ x in finset.range (N + r + 1), ite (x ∈ finset.Icc N (N + r)) (μ (f2 x)) 1)
    = ∏ x in finset.Icc N (N + r), μ (f2 x),
  { simp_rw [add_assoc],
    exact prod_range_ite_range_le N (r + 1) (λ n, μ (f2 n)), },
  rw [finset.prod_mul_distrib, h1, h2, ht1_eq, ← h_indep (finset.range N) ht1_m,
    ht2_eq, ← h_indep (finset.Icc N (N + r)) ht2_m],
end

lemma generate_from_Union_measurable_set {ι : Type*} (s : ι → measurable_space α) :
  generate_from (⋃ n, {t | measurable_set[s n] t}) = ⨆ n, s n :=
(@measurable_space.gi_generate_from α).l_supr_u s

lemma supr_eq_generate_from_Union_head_n (s : ℕ → measurable_space α) :
  (⨆ n, s n) = generate_from (⋃ n, {t | measurable_set[⨆ i < n, s i] t}) :=
by rw [supr_eq_supr_head_n, generate_from_Union_measurable_set]

lemma is_pi_system_Union_of_monotone {ι} [linear_order ι] (p : ι → set (set α))
  (hp_pi : ∀ n, is_pi_system (p n)) (hp_mono : ∀ n m : ι, n ≤ m → p n ⊆ p m) :
  is_pi_system (⋃ n, p n) :=
begin
  intros t1 ht1 t2 ht2 h,
  rw set.mem_Union at ht1 ht2 ⊢,
  cases ht1 with n ht1,
  cases ht2 with m ht2,
  cases le_total n m with h_le h_le,
  { exact ⟨m, hp_pi m t1 (set.mem_of_mem_of_subset ht1 (hp_mono n m h_le)) t2 ht2 h⟩, },
  { exact ⟨n, hp_pi n t1 ht1 t2 (set.mem_of_mem_of_subset ht2 (hp_mono m n h_le)) h⟩, },
end

variables [is_probability_measure μ] {s : ℕ → measurable_space α}

lemma sup_closed_finset_Icc_right (N : ℕ) :
  sup_closed {s : finset ℕ | ∃ r : ℕ, s = finset.Icc N (N + r)} :=
begin
  refine sup_closed_of_totally_ordered _ _,
  rintros s1 s2 ⟨r1, rfl⟩ ⟨r2, rfl⟩,
  cases le_total r1 r2,
  { exact or.inr (finset.Icc_subset_Icc le_rfl (by simp [h])), },
  { exact or.inl (finset.Icc_subset_Icc le_rfl (by simp [h])), },
end

lemma head_n_indep_tail_n (h_le : ∀ n, s n ≤ m0) (h_indep : Indep s μ) (N : ℕ) :
  indep (⨆ n < N, s n) (⨆ i ≥ N, s i) μ :=
begin
  -- define a π-system family
  have h_pi : ∀ n, is_pi_system {t | measurable_set[s n] t},
    from (λ n, @is_pi_system_measurable_set α (s n)),
  -- define generating π-systems for head and tail
  let p_head := pi_Union_Inter (λ n, {t | measurable_set[s n] t}) {finset.range N},
  have h_pi_head : is_pi_system p_head,
    from is_pi_system_pi_Union_Inter (λ n, {t | measurable_set[s n] t}) h_pi {finset.range N}
      (by convert sup_closed_singleton (finset.range N)),
  have h_generate_head : (⨆ n < N, s n) = generate_from p_head,
    from head_n_eq_generate_from_Union_Inter_range s N,
  let p_tail := pi_Union_Inter (λ n, {t | measurable_set[s n] t})
    {p : finset ℕ | ∃ r : ℕ, p = finset.Icc N (N + r)},
  have h_pi_tail : is_pi_system p_tail,
    from is_pi_system_pi_Union_Inter (λ n, {t | measurable_set[s n] t}) h_pi
      {p : finset ℕ | ∃ r : ℕ, p = finset.Icc N (N + r)}
      (by convert sup_closed_finset_Icc_right N),
  have h_generate_tail : (⨆ i ≥ N, s i) = generate_from p_tail,
    from tail_n_eq_generate_from_Union_Inter_Icc s N,
  -- if these π-systems are independent, then head and tail are independent
  refine indep_sets.indep (head_n_le s N h_le) (tail_n_le s N h_le)
    h_pi_head h_pi_tail h_generate_head h_generate_tail _,
  exact indep_sets_head_n_tail_n_pi_systems s h_indep N,
end

lemma head_n_indep_tail (h_le : ∀ n, s n ≤ m0) (h_indep : Indep s μ) (n : ℕ) :
  indep (⨆ i < n, s i) (tail s) μ :=
indep_of_indep_of_le_right (head_n_indep_tail_n h_le h_indep n) (tail_le_tail_n s n)

lemma supr_indep_tail (h_le : ∀ n, s n ≤ m0) (h_indep : Indep s μ) :
  indep (⨆ n, s n) (tail s) μ :=
begin
  let p : ℕ → set (set α) := λ n, {t | measurable_set[⨆ i < n, s i] t},
  have hp : ∀ n, is_pi_system (p n),
    from λ n, @is_pi_system_measurable_set α (⨆ i < n, s i),
  have h_generate_n : ∀ n, (⨆ i < n, s i) = generate_from (p n),
    from λ n, (@generate_from_measurable_set α (⨆ i < n, s i)).symm,
  have hp_mono : ∀ n m, n ≤ m → p n ⊆ p m, from (λ n m hnm, head_n_mono s hnm),
  have hp_supr_pi : is_pi_system (⋃ n, p n), from is_pi_system_Union_of_monotone p hp hp_mono,
  let p_tail := {t : set α | measurable_set[tail s] t},
  have hp_tail_pi : is_pi_system p_tail, from @is_pi_system_measurable_set α (tail s),
  have h_generate_tail : tail s = generate_from p_tail,
    from (@generate_from_measurable_set α (tail s)).symm,
  -- the π-systems defined are independent
  have h_indep_n : ∀ n, indep_sets (p n) p_tail μ,
  { intro n,
    have h_sigma_indep : indep (⨆ i < n, s i) (tail s) μ,
      from head_n_indep_tail h_le h_indep n,
    rw [h_generate_n n, h_generate_tail] at h_sigma_indep,
    exact indep.indep_sets h_sigma_indep, },
  have h_pi_system_indep : indep_sets (⋃ n, p n) p_tail μ, from indep_sets.Union h_indep_n,
  -- now go from π-systems to σ-algebras
  exact indep_sets.indep (supr_le h_le) (tail_le h_le) hp_supr_pi hp_tail_pi
    (supr_eq_generate_from_Union_head_n s) h_generate_tail h_pi_system_indep,
end

lemma tail_indep_tail (h_le : ∀ n, s n ≤ m0) (h_indep : Indep s μ) :
  indep (tail s) (tail s) μ :=
indep_of_indep_of_le_left (supr_indep_tail h_le h_indep)
    (le_trans (tail_le_tail_n s 0) (tail_n_le_supr s 0))

/-- **Kolmogorov's 0-1 law** : any event in the tail σ-algebra has probability 0 or 1 -/
theorem zero_or_one_of_tail (h_le : ∀ n, s n ≤ m0) (h_indep : Indep s μ) {t : set α}
  (h_t_tail : measurable_set[tail s] t) :
  (μ t = 0 ∨ μ t = 1) :=
measure_eq_zero_or_one_of_indep_self (tail_indep_tail h_le h_indep) h_t_tail

end zero_one_law

end probability_theory
