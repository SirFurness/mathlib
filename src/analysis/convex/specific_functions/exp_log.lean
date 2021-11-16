/-
Copyright (c) 2020 Yury Kudryashov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yury Kudryashov, Sébastien Gouëzel, Rémy Degenne
-/
import analysis.special_functions.complex.log
import analysis.special_functions.exponential
import analysis.convex.function

/-!
# Convexity of the exponential and logarithm

In this file we prove that the following functions are convex:
* `convex_on_exp` : the exponential function is convex on $(-∞, +∞)$;
* `concave_on_log_Ioi` and `concave_on_log_Iio`: log is concave on `Ioi 0` and `Iio 0` respectively.

This file uses direct proofs instead of using the sign of the second derivative in order to avoid
importing derivatives.

-/

open real set
open_locale big_operators nat

/-- TODO: move this -/
lemma const_add_tsum {ι β} [add_comm_monoid β] [topological_space β] [t2_space β]
  [has_continuous_add β]
  {f : ι → β} (hf : summable f) {c : β} (i : ι) [decidable_pred (λ n, n = i)] :
  c + ∑' n, f n = ∑' n, ite (n = i) (c + f i) (f n) :=
begin
  have h_const_eq_tsum : c = ∑' n, ite (n=i) c 0, from (tsum_ite_eq i c).symm,
  nth_rewrite 0 h_const_eq_tsum,
  rw ← tsum_add _ hf,
  { congr' with n,
    by_cases hni : n = i; simp [hni], },
  { refine summable_of_ne_finset_zero _,
    { exact {i}, },
    { intros n hni,
      rw finset.mem_singleton at hni,
      rw if_neg hni, }, },
end

lemma pow_lt_pow_of_pos_of_lt_one {α} [ordered_semiring α] {x : α} (hx_pos : 0 < x) (hx_lt : x < 1)
  {n m : ℕ} (hmn : m < n) :
  x ^ n < x ^ m :=
begin
  suffices : x ^ (n-m) < 1,
  { have hn_eq : n = (n - m) + m, from (nat.sub_add_cancel hmn.le).symm,
    rw [hn_eq, pow_add],
    nth_rewrite 1 ← one_mul (x ^ m),
    refine mul_lt_mul this le_rfl _ zero_le_one,
    simp [hx_pos], },
  refine pow_lt_one hx_pos.le hx_lt _,
  simp only [tsub_eq_zero_iff_le, not_le, ne.def, hmn],
end

lemma pow_lt_self {α} [ordered_semiring α] {x : α} (hx_pos : 0 < x) (hx_lt : x < 1)
  {n : ℕ} (hn : 2 ≤ n) :
  x ^ n < x :=
begin
  nth_rewrite 1 ← pow_one x,
  exact pow_lt_pow_of_pos_of_lt_one hx_pos hx_lt (one_lt_two.trans_le hn),
end

/-- Auxiliary lemma for `strict_convex_on_exp` -/
lemma exp_mul_lt_sub_add_mul_exp {x : ℝ} (hx : 0 < x) {b : ℝ} (hb_pos : 0 < b) (hb_lt : b < 1) :
  exp (b * x) < 1 - b + b * exp x :=
begin
  have hb_n_le : ∀ n : ℕ, 1 ≤ n → b ^ n ≤ b,
  { intros h hn,
    nth_rewrite 1 ← pow_one b,
    exact pow_le_pow_of_le_one hb_pos.le hb_lt.le hn, },
  rw [real.exp_eq_exp_ℝ_ℝ, exp_eq_tsum],
  dsimp only,
  rw [← tsum_mul_left, const_add_tsum _ 0],
  swap, { apply_instance, },
  swap, { apply_instance, },
  swap, { refine summable.mul_left b _, exact exp_series_summable' x, },
  refine tsum_lt_tsum (λ n, _) _ _ _,
  { exact 2, },
  { by_cases hn0 : n = 0,
    { simp [hn0], },
    simp only [hn0, one_div, if_false, smul_eq_mul],
    rw [mul_pow, ← mul_assoc, mul_comm _ (b ^ n), mul_assoc],
    refine mul_le_mul (hb_n_le n _) le_rfl _ hb_pos.le,
    { rw nat.succ_le_iff,
      exact lt_of_le_of_ne zero_le' (ne.symm hn0), },
    { refine mul_nonneg (inv_nonneg.mpr _) (pow_nonneg hx.le n),
      norm_cast,
      exact zero_le', } },
  { simp only [one_div, nat.one_ne_zero, algebra.id.smul_eq_mul, nat.cast_bit0, nat.factorial_two,
      if_false, bit0_eq_zero, nat.cast_one],
    rw mul_pow,
    have hb_sq_lt : b^2 < b, from pow_lt_self hb_pos hb_lt le_rfl,
    rw [mul_comm (2 : ℝ)⁻¹, mul_comm (2 : ℝ)⁻¹, mul_assoc],
    refine mul_lt_mul hb_sq_lt le_rfl _ hb_pos.le,
    simp [hx], },
  { exact exp_series_summable' (b * x), },
  { refine (finset.summable_compl_iff {(0 : ℕ)}).mp _,
    have : (λ (m : {x : ℕ // x ∉ {(0 : ℕ)}}),
        ite ((m : ℕ) = 0) (1 - b + b * (1 / ((0 : ℕ)! : ℝ)) • x ^ 0)
          (b * (1 / ((m : ℕ)! : ℝ)) • x ^ (m : ℕ)))
      = (λ (m : {x : ℕ // x ∉ ({(0 : ℕ)} : finset ℕ)}), (b * (1 / ((m : ℕ)! : ℝ) * x ^ (m : ℕ)))),
    { ext1 m,
      have hm : (m : ℕ) ≠ (0 : ℕ), from mt finset.mem_singleton.mpr m.prop,
      simp only [hm, one_div, mul_eq_mul_left_iff, if_false, smul_eq_mul],
      exact or.inl (or.inl rfl), },
    rw [this, @finset.summable_compl_iff _ _ _ _ _
      (λ m, b * (1 / ((m : ℕ)! : ℝ) * x ^ (m : ℕ))) {(0 : ℕ)}],
    refine summable.mul_left b _,
    convert exp_series_summable' x,
    ext1 n,
    rw smul_eq_mul, },
end

/-- Auxiliary lemma for `strict_convex_on_exp` -/
lemma strict_convex_on_exp_of_lt {x y a b : ℝ} (ha_pos : 0 < a) (hb_pos : 0 < b)
  (hab_add : a + b = 1) (h_lt : x < y) :
  exp (a • x + b • y) < a • exp x + b • exp y :=
begin
  have ha_eq : a = 1 - b, from eq_sub_iff_add_eq.mpr hab_add,
  simp_rw [ha_eq, smul_eq_mul],
  rw [sub_mul, one_mul],
  have hb_lt_one : b < 1, by linarith,
  calc exp (x - b * x + b * y) = exp x * exp (b * (y - x)) :
    by { rw ← real.exp_add, congr' 1, ring, }
  ... < exp x * (1 - b + b * exp (y - x)) : mul_lt_mul' le_rfl
    (exp_mul_lt_sub_add_mul_exp (sub_pos.mpr h_lt) hb_pos hb_lt_one) (exp_pos _).le (exp_pos _)
  ... = (1 - b) * exp x + b * exp y : begin
    rw [mul_add, mul_comm],
    congr' 1,
    rw [mul_comm, mul_assoc, ← real.exp_add, sub_add_cancel],
  end,
end

/-- `exp` is strictly convex on the whole real line -/
lemma strict_convex_on_exp : strict_convex_on ℝ univ exp :=
begin
  refine ⟨convex_univ, λ x y _ _ hxy a b ha_pos hb_pos hab_add, _⟩,
  cases lt_or_gt_of_ne hxy with h_lt h_lt,
  { exact strict_convex_on_exp_of_lt ha_pos hb_pos hab_add h_lt, },
  { rw add_comm at hab_add ⊢,
    rw add_comm (a • exp x),
    exact strict_convex_on_exp_of_lt hb_pos ha_pos hab_add h_lt, },
end

/-- `exp` is convex on the whole real line -/
lemma convex_on_exp : convex_on ℝ univ exp := strict_convex_on_exp.convex_on

/-- `log` is concave on [0, +∞) -/
lemma concave_on_log_Ioi : concave_on ℝ (Ioi 0) log :=
begin
  refine ⟨convex_Ioi 0, λ x y hx hy a b ha_nonneg hb_nonneg hab_add, _⟩,
  have hx_pos : 0 < x, from mem_Ioi.mp hx,
  have hy_pos : 0 < y, from mem_Ioi.mp hy,
  rw ← exp_le_exp,
  by_cases ha0 : a = 0,
  { have hb : b = 1, by rwa [ha0, zero_add] at hab_add,
    simp [ha0, hb], },
  have ha_pos : 0 < a, from lt_of_le_of_ne ha_nonneg (ne.symm ha0),
  rw exp_log,
  swap, { simp_rw smul_eq_mul,
    exact add_pos_of_pos_of_nonneg (mul_pos ha_pos hx_pos) (mul_nonneg hb_nonneg hy_pos.le), },
  refine (convex_on_exp.2 (mem_univ _) (mem_univ _) ha_nonneg hb_nonneg hab_add).trans _,
  rw [exp_log hx_pos, exp_log hy_pos],
end

/-- `log` is concave on (-∞, 0] -/
lemma concave_on_log_Iio : concave_on ℝ (Iio 0) log :=
begin
  refine ⟨convex_Iio 0, λ x y hx hy a b ha_nonneg hb_nonneg hab_add, _⟩,
  have hx_neg : x < 0, from mem_Iio.mp hx,
  have hy_neg : y < 0, from mem_Iio.mp hy,
  rw ← exp_le_exp,
  by_cases ha0 : a = 0,
  { have hb : b = 1, by rwa [ha0, zero_add] at hab_add,
    simp [ha0, hb], },
  have ha_pos : 0 < a, from lt_of_le_of_ne ha_nonneg (ne.symm ha0),
  rw exp_log_of_neg,
  swap, { rw [smul_eq_mul, smul_eq_mul, ← neg_pos, neg_add, neg_mul_eq_mul_neg, neg_mul_eq_mul_neg],
    refine add_pos_of_pos_of_nonneg (mul_pos ha_pos _) (mul_nonneg hb_nonneg _),
    { exact right.neg_pos_iff.mpr hx_neg, },
    { exact (right.neg_pos_iff.mpr hy_neg).le, }, },
  refine (convex_on_exp.2 (mem_univ _) (mem_univ _) ha_nonneg hb_nonneg hab_add).trans _,
  rw [exp_log_of_neg hx_neg, exp_log_of_neg hy_neg],
  simp,
end
