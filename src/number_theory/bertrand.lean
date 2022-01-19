/-
Copyright (c) 2020 Patrick Stevens. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Patrick Stevens, Bolton Bailey
-/

import data.nat.multiplicity
import data.nat.choose.central
import number_theory.padics.padic_norm
import data.complex.exponential_bounds
import number_theory.primorial
import analysis.special_functions.pow

/-!
# Bertrand's Postulate

This file contains a proof of Bertrand's postulate: That between any positive number and its
double there is a prime

-- TODO File Docstring
-- TODO Cite "Proofs From THE BOOK"
-- TODO Cite Tochiori's paper
-- TODO edit 100.yml
-/

open_locale big_operators

/-- The multiplicity of p in the nth central binomial coefficient-/
private def α (n p : nat) [hp : fact p.prime] : nat :=
padic_val_nat p (nat.central_binom n)

lemma nat.self_le_mul {m : ℕ} : ∀ {n : ℕ} (n0 : 0 < n), m ≤ n * m
| 0     h := (lt_irrefl _ h).elim
| 1     h := (one_mul m).symm.le
| (n+2) h := trans (nat.self_le_mul n.succ_pos) $ mul_le_mul_right' n.succ.le_succ _

lemma nat.le_two_mul_self (n : ℕ) : n ≤ 2 * n :=
nat.self_le_mul zero_lt_two

lemma claim_1
  (p : nat)
  [hp : fact p.prime]
  (n : nat)
  (n_big : 3 ≤ n)
  : p ^ (α n p) ≤ 2 * n
  :=
begin
  unfold α,
  rw @padic_val_nat_def p hp (nat.central_binom n) (nat.central_binom_ne_zero n),
  simp only [nat.central_binom_eq_two_mul_choose n,
    nat.prime.multiplicity_choose hp.out n.le_two_mul_self (lt_add_one (p.log (2 * n)))],
  have r : 2 * n - n = n,
    calc
    2 * n - n
        = n + n - n : congr_arg (flip (has_sub.sub) n) (two_mul n)
    ... = n : nat.add_sub_cancel n n,
  simp [r, ←two_mul],
  apply trans (pow_le_pow (trans one_le_two hp.out.two_le) _) (_ : p ^ p.log (2 * n) ≤ 2 * n),
  { calc _
        ≤ (finset.Ico 1 (nat.log p (2 * n) + 1)).card : finset.card_filter_le _ _
    ... = (p.log (2 * n) + 1) - 1                     : nat.card_Ico _ _ },
  { apply nat.pow_log_le_self,
    exact hp.out.one_lt,
    linarith, }
end

lemma twice_nat_small (n : nat) (h : 2 * n < 2) : n = 0 :=
nat.le_zero_iff.mp $ nat.le_of_lt_succ $
  lt_of_mul_lt_mul_left (h.trans_le (mul_one _).symm.le) (nat.zero_le _)

lemma claim_4
  (p : nat)
  [hp : fact p.prime]
  (n : nat)
  (multiplicity_pos : 0 < α n p)
  : p ≤ 2 * n
  :=
begin
  unfold α at multiplicity_pos,
  rw nat.central_binom_eq_two_mul_choose at multiplicity_pos,
  rw @padic_val_nat_def p hp ((2 * n).choose n) (nat.central_binom_ne_zero n) at multiplicity_pos,
  simp only [nat.prime.multiplicity_choose hp.out n.le_two_mul_self (lt_add_one (p.log (2 * n)))] at multiplicity_pos,
  have r : 2 * n - n = n,
    calc
    2 * n - n
        = n + n - n : congr_arg (flip (has_sub.sub) n) (two_mul n)
    ... = n         : nat.add_sub_cancel n n,
  simp only [r, ←two_mul, gt_iff_lt, enat.get_coe', finset.filter_congr_decidable]
    at multiplicity_pos,
  clear r,
  rw finset.card_pos at multiplicity_pos,
  cases multiplicity_pos with m hm,
  simp only [finset.mem_Ico, finset.mem_filter] at hm,
  calc
  p   = p ^ 1 : (pow_one _).symm
  ... ≤ p ^ m : nat.pow_le_pow_of_le_right
                  (show 0 < p, from trans zero_lt_one hp.out.one_lt) hm.left.left
  ... ≤ 2 * (n % p ^ m) : hm.right
  ... ≤ 2 * n : nat.mul_le_mul_left _ (nat.mod_le n _),
end

/-
Then:
4^n ≤ 2nCn * (2 * n + 1) (by choose_halfway_is_big)
= prod (primes ≤ 2n) p^(α n p) * (2n+1)
= prod (primes ≤ n) p^(α n p) * prod (primes n < p <= 2n) p^α * (2n+1)
= prod (primes ≤ 2n/3) p^α * prod (primes 2n/3 to n) p^α * prod (primes n < p ≤ 2n) p^α * (2n+1)
= prod (primes ≤ 2n/3) p^α * prod (primes 2n/3 to n) 1 * prod (primes n < p ≤ 2n) p^α * (2n+1)
  (by claim 3)
= prod (primes ≤ 2n/3) p^α * prod (primes n < p ≤ 2n) p^α * (2n+1)
= prod (primes ≤ sqrt(2n)) p^α * prod(primes sqrt(2n)..2n/3) p^α
  * prod (primes n < p ≤ 2n) p^α * (2n+1)
≤ prod (primes ≤ sqrt(2n)) p^α * prod(primes sqrt(2n)..2n/3) p
  * prod (primes n < p ≤ 2n) p^α * (2n+1)
  (by claim 2)
≤ prod (primes ≤ sqrt(2n)) p^α * 4 ^ (2n / 3) * prod (primes n < p ≤ 2n) p^α * (2n+1)
  (by a general bound on the primorial)
≤ prod (primes ≤ sqrt(2n)) (2n) * 4 ^ (2n / 3) * prod (primes n < p ≤ 2n) p^α * (2n+1)
  (by claim 1)
= (2n)^π (sqrt 2n) * 4 ^ (2n/3) * prod (primes n < p ≤ 2n) p^α * (2n+1)
≤ (2n)^(sqrt 2n) * 4 ^ (2n/3) * prod (primes n < p ≤ 2n) p^α * (2n+1)
  (by "prime count of x is less than x")

For sufficiently large n, that last product term is > 1.
Indeed, suppose for contradiction it's equal to 1.
Then 4^n ≤ (2n)^(sqrt 2n) * 4^(2n/3) * (2n+1)
so 4^(n/3) ≤ (2n)^(sqrt 2n) (2n+1)
and this is Clearly False for sufficiently large n.
-/

lemma two_n_div_3_le_central_binom (n : ℕ) : 2 * n / 3 < nat.central_binom n :=
begin
  cases n,
  { simp only [nat.succ_pos', nat.choose_self, nat.zero_div, mul_zero, nat.central_binom_zero], },
  calc
  2 * (n + 1) / 3
      < 2 * (n + 1)                           : nat.div_lt_self (by norm_num) (by norm_num)
  ... = (2 * (n + 1)).choose(1)               : by norm_num
  ... ≤ (2 * (n + 1)).choose(2 * (n + 1) / 2) : nat.choose_le_middle 1 (2 * (n + 1))
  ... = (2 * (n + 1)).choose(n + 1)           : by simp only [nat.succ_pos', nat.mul_div_right]
end

lemma central_binom_factorization (n : ℕ) :
      ∏ p in finset.filter nat.prime (finset.range (nat.central_binom n + 1)),
        p ^ (padic_val_nat p (nat.central_binom n))
      = nat.central_binom n :=
  prod_pow_prime_padic_val_nat _ (nat.central_binom_ne_zero n) _ (lt_add_one _)

lemma intervening_sqrt {a n : ℕ} (small : (nat.sqrt n) ^ 2 ≤ a ^ 2) (big : a ^ 2 ≤ n)
  : a = nat.sqrt n :=
begin
  rcases lt_trichotomy a (nat.sqrt n) with H|rfl|H,
  { refine (lt_irrefl (a ^ 2) _).elim,
    calc
    _   = a * a            : sq _
    ... < n.sqrt * n.sqrt  : nat.mul_self_lt_mul_self H
    ... = (nat.sqrt n) ^ 2 : (sq _).symm
    ... ≤ a ^ 2            : small, },
  { refl, },
  { refine (lt_irrefl (a ^ 2) _).elim,
    calc
    _   ≤ n     : big
    ... < a * a : nat.sqrt_lt.1 H
    ... = a ^ 2 : (sq _).symm, },
end


lemma even_prime_is_two {p : ℕ} (pr: p.prime) (div: 2 ∣ p) : p = 2 :=
((nat.prime_dvd_prime_iff_eq nat.prime_two pr).mp div).symm

lemma even_prime_is_small {a n : ℕ} (a_prime : nat.prime a) (n_big : 2 < n)
(small : a ≤ nat.sqrt(2 * n))
: a ^ 2 < 2 * n :=
begin
  cases lt_or_ge (a ^ 2) (2 * n),
  { exact h, },
  { have small' : a^2 ≤ (2 * n), exact nat.le_sqrt'.mp small,
    have t : a * a = 2 * n := (sq _).symm.trans (small'.antisymm h),
    have a_even : 2 ∣ a := (or_self _).mp ((nat.prime.dvd_mul nat.prime_two).mp ⟨n, t⟩),
    have a_two : a = 2 := even_prime_is_two a_prime a_even,
    rw [a_two, sq],
    exact (mul_lt_mul_left zero_lt_two).mpr n_big },
end

open real

lemma one_lt_four : (1 : ℝ) < 4 := by linarith

lemma log_four_pos : 0 < log 4 := log_pos one_lt_four

lemma log_four_nonzero : log 4 ≠ 0 := by linarith [log_four_pos]

lemma log_1024_div_log_4 : log 1024 / log 4 = 5 :=
begin
  rw div_eq_iff,
  have h : (1024 : ℝ) = 4 ^ (5 : ℝ), norm_num,
  rw h,
  rw log_rpow,
  linarith,
  linarith [log_four_pos],
end

lemma inequality1 {x : ℝ} (n_large : 1024 < x) : log (x) / (x * log 4) ≤ 1/30 :=
begin
  have h4 : 0 < x,
    linarith only [n_large],
  have x_ne_zero := ne_of_gt h4,
  calc
  log x / (x * log 4)
      = (log x / x) / log 4 : by field_simp
  ... ≤ log 1024 / 1024 / log 4 :
          begin
            rw div_le_div_right,
            apply log_div_self_antitone_on,
            simp only [set.mem_set_of_eq],
            linarith only [exp_one_lt_d9],
            simp only [set.mem_set_of_eq],
            linarith only [exp_one_lt_d9, n_large],
            exact le_of_lt n_large,
            exact log_four_pos,
          end
  ... ≤ 1 / 30 :
          begin
            rw div_div_eq_div_mul,
            rw mul_comm,
            rw <-div_div_eq_div_mul,
            rw log_1024_div_log_4,
            norm_num,
          end,
end

lemma four_eq_two_rpow_two : (4 : ℝ) = 2 ^ (2 : ℝ) :=
calc
(4 : ℝ)
    = 2 ^ (2 : ℕ) : by {norm_num,}
... = 2 ^ (2 : ℝ) : by {rw <-real.rpow_nat_cast, congr, exact nat.cast_two,}


lemma inequality2 {x : ℝ} (n_large : 1024 < x) : sqrt 2 * sqrt x * log 2 / (x * log 4) ≤ 0.04 :=
begin
  rw div_le_iff,
  rw <-mul_assoc,
  rw four_eq_two_rpow_two,
  rw log_rpow,
  rw <-mul_assoc,
  rw mul_le_mul_right,
  rw <-le_div_iff,
  rw mul_comm _ x,
  rw mul_assoc,
  rw mul_comm x,
  rw mul_div_assoc,
  rw div_sqrt,
  rw mul_comm,
  rw <-div_le_iff,
  rw le_sqrt,
  rw div_pow,
  rw real.sq_sqrt,
  field_simp,
  repeat {apply mul_pos},
  repeat {apply log_pos},
  repeat {apply div_nonneg},
  repeat {norm_num,},
  repeat {linarith,},
  apply sqrt_nonneg,
end

lemma inequality3' {x : ℝ} (n_large : 1024 < x) :
  sqrt 2 * sqrt x * log x / (x * log 4) = (sqrt 2 / log 4) * log x / sqrt x :=
begin
  have h : x ≠ 0,
  { apply ne_of_gt,
    linarith, },
  have h4 : 0 < x,
    linarith,
  have h2: log 4 * sqrt x ≠ 0, apply mul_ne_zero log_four_nonzero, exact sqrt_ne_zero'.mpr h4,
  field_simp,
  ring_nf,
  apply eq.symm,
  rw @sq_sqrt x,
  field_simp [log_four_nonzero],
  ring,
  linarith,
end

lemma log_div_sqrt_decreasing {x y : ℝ} (hex : real.exp 2 ≤ x) (hxy : x ≤ y) :
  log y / sqrt y ≤ log x / sqrt x :=
begin
  have hltx : 0 < x, exact lt_of_lt_of_le ( (exp_pos 2)) hex,
  have hlty : 0 < y, linarith,
  have hx : 0 ≤ x, exact le_trans (le_of_lt (exp_pos 2)) hex,
  have hy : 0 ≤ y, linarith,
  conv_lhs
  begin
    congr,
    rw <-sq_sqrt hy,
  end,
  conv_rhs
  begin
    congr,
    rw <-sq_sqrt hx,
  end,
  rw <-real.rpow_nat_cast,
  rw <-real.rpow_nat_cast,
  rw log_rpow,
  rw log_rpow,
  rw mul_div_assoc,
  rw mul_div_assoc,
  rw mul_le_mul_left,
  apply log_div_self_antitone_on,
  simp only [set.mem_set_of_eq],
  rw le_sqrt,
  rw <-exp_nat_mul,
  simp [hex],
  swap 3,
  simp only [set.mem_set_of_eq],
  rw le_sqrt,
  rw <-exp_nat_mul,
  simp only [mul_one, nat.cast_bit0, nat.cast_one],
  exact le_trans hex hxy,
  exact le_of_lt (exp_pos 1),
  exact hy,
  exact le_of_lt (exp_pos 1),
  exact hx,
  exact sqrt_le_sqrt hxy,
  norm_num,

  exact sqrt_pos.mpr hltx,
  rw sqrt_pos,
  exact hlty,
end

lemma inequality3 {x : ℝ} (n_large : 1024 < x) : sqrt 2 * sqrt x * log x / (x * log 4) ≤ 1/4 :=
begin
  rw [inequality3' n_large],
  -- Get the log x in the second term to be 2 log sqrt x. and split the 1/x i n that term to
  calc
  sqrt 2 / log 4 * log x / sqrt x
       = sqrt 2 / log 4 * (log x / sqrt x) : by rw mul_div_assoc
  ...  ≤ sqrt 2 / log 4 * (log 1024 / sqrt 1024) :
          begin
            rw mul_le_mul_left,
            have n_larger := le_of_lt n_large,
            apply log_div_sqrt_decreasing,
            calc
            exp 2 = (exp 1) ^ 2 :
              begin
                rw <-exp_nat_mul,
                simp,
              end
            ... ≤ 2.7182818286 ^ 2 :
              begin
                apply pow_le_pow_of_le_left,
                apply le_of_lt,
                exact exp_pos 1,
                apply le_of_lt,
                exact exp_one_lt_d9,
              end
            ... ≤ 1024 : by norm_num,
            exact n_larger,
            apply div_pos,
            rw sqrt_pos,
            linarith,
            exact log_four_pos,
          end
  ...  = log 1024 / log 4 * sqrt 2 / sqrt 1024 :
          begin
            ring,
          end
  ...  = 5 * sqrt 2 / sqrt 1024 :
          begin
            congr,
            rw log_1024_div_log_4,
          end
  ... ≤ 1 / 4 :
          begin
            rw mul_div_assoc,
            rw <-sqrt_div,
            rw mul_comm,
            rw <-le_div_iff,
            rw sqrt_le_iff,
            split,
            norm_num,
            norm_num,
            linarith,
            linarith,
          end,

end

lemma equality4 {x : ℝ} (n_large : 1024 < x) : 2 * x / 3 * log 4 / (x * log 4) = 2 / 3 :=
begin
  have h : x ≠ 0,
  { apply ne_of_gt,
    linarith, },
  field_simp [log_four_nonzero],
  ring,
end

/--
A reified version of the `bertrand_inequality` below.
-/
lemma real_bertrand_inequality {x : ℝ} (n_large : (1024 : ℝ) < x)
  : x * (2 * x) ^ (real.sqrt (2 * x)) * 4 ^ (2 * x / 3) < 4 ^ x :=
begin
  apply (log_lt_log_iff _ _).1,
  rw [log_mul, log_mul, log_rpow, log_rpow, log_rpow, log_mul],
  rw <-div_lt_one,
  simp only [add_div, mul_add, add_mul, add_div, <-add_assoc],
  simp only [zero_le_one, sqrt_mul, zero_le_bit0],
  { rw [equality4 n_large],
    linarith only [inequality1 n_large, inequality2 n_large, inequality3 n_large], },
  repeat {apply ne_of_gt},
  repeat {apply mul_pos},
  repeat {apply rpow_pos_of_pos},
  repeat {norm_num,},
  repeat {linarith,},
  apply log_pos,
  norm_num,
end

/--
The inequality which contradicts Bertrand's postulate, for large enough `n`.
-/
lemma bertrand_inequality {n : ℕ} (n_large : 1024 < n)
  : n * (2 * n) ^ (nat.sqrt (2 * n)) * 4 ^ (2 * n / 3) ≤ 4 ^ n :=
begin
  rw <-@nat.cast_le ℝ,
  have fact1 : 0 < (n : ℝ),
  { rw <-nat.cast_zero,
    rw nat.cast_lt,
    linarith, },
  have fact2 : 0 < 2 * (n : ℝ),
  { linarith, },
  simp only [nat.cast_bit0, nat.cast_add, nat.cast_one, nat.cast_mul, nat.cast_pow],
  simp only [<-rpow_nat_cast],
  apply le_of_lt,
  calc
  (n : ℝ) * (2 * (n : ℝ)) ^ (nat.sqrt (2 * n) : ℝ) * 4 ^ (((2 * n / 3) : ℕ) : ℝ)
      ≤ (n : ℝ) * (2 * n : ℝ) ^ (real.sqrt (2 * (n : ℝ))) * 4 ^ (((2 * n / 3) : ℕ) : ℝ) :
          begin
            rw mul_le_mul_right,
            rw mul_le_mul_left,
            apply rpow_le_rpow_of_exponent_le,
            rw <-@nat.cast_lt ℝ at n_large,
            have h : (1024) < (n : ℝ), {convert n_large, simp},
            linarith,
            rw le_sqrt,
            rw <-nat.cast_pow,
            conv
            begin
              to_rhs,
              rw <-nat.cast_two,
            end,
            rw <-nat.cast_mul,
            rw nat.cast_le,
            exact (2 * n).sqrt_le',
            exact (nat.sqrt (2 * n)).cast_nonneg,
            rw <-nat.cast_two,
            rw <-nat.cast_mul,
            exact (2 * n).cast_nonneg,
            exact fact1,
            apply rpow_pos_of_pos,
            norm_num,
          end
  ... ≤ (n : ℝ) * (2 * n : ℝ) ^ (real.sqrt (2 * (n : ℝ))) * 4 ^ (2 * (n : ℝ) / 3) :
          begin
            rw mul_le_mul_left,
            apply rpow_le_rpow_of_exponent_le,
            linarith,
            apply trans nat.cast_div_le,
            apply le_of_eq,
            congr,
            simp only [nat.cast_bit0, nat.cast_one, nat.cast_mul],
            simp only [nat.cast_bit1, nat.cast_one],
            exact is_trans.swap (λ (x y : ℝ), y ≤ x),
            apply mul_pos,
            exact fact1,
            apply rpow_pos_of_pos,
            exact fact2,
          end
  ... < 4 ^ (n : ℝ) :
          begin
            apply real_bertrand_inequality,
            rw <-@nat.cast_lt ℝ at n_large,
            have h : (1024) < (n : ℝ), {convert n_large, simp},
            linarith,
          end,
end

/--
A lemma that tells us that, in the case where Bertrand's postulate does not hold, the prime
factorization of the central binomial coefficent only has factors at most `2 * n / 3 + 1`.
-/
lemma central_binom_factorization_small (n : nat) (n_big : 1024 < n)
  (no_prime: ¬∃ (p : ℕ), p.prime ∧ n < p ∧ p ≤ 2 * n) :
  ∏ p in (finset.range (2 * n / 3 + 1)).filter nat.prime,
    p ^ (padic_val_nat p (nat.central_binom n))
  =
  ∏ p in (finset.range ((nat.central_binom n + 1))).filter nat.prime,
    p ^ (padic_val_nat p (nat.central_binom n)) :=
begin
  apply finset.prod_subset,
  { apply finset.filter_subset_filter,
    rw finset.range_subset,
    rw [add_le_add_iff_right],
    exact le_of_lt (two_n_div_3_le_central_binom n), },
  intro x,
  rw [finset.mem_filter, finset.mem_filter, finset.mem_range, finset.mem_range],
  intros hx h2x,
  simp only [hx.right, and_true, not_lt] at h2x,
  by_contradiction,
  have x_le_two_mul_n : x ≤ 2 * n, by
    { apply (@claim_4 x ⟨hx.right⟩ n),
      unfold α,
      by_contradiction h1,
      rw [not_lt, le_zero_iff] at h1,
      rw h1 at h,
      rw pow_zero at h,
      simp only [eq_self_iff_true, not_true] at h,
      exact h, },
  apply no_prime,
  use x,
  split,
  { exact hx.right, },
  { split,
    { by_contradiction neg_n_le_x,
      simp only [not_lt] at neg_n_le_x,
      rw [nat.add_one, nat.succ_le_iff, nat.div_lt_iff_lt_mul', mul_comm x] at h2x,
      have claim := @nat.multiplicity_central_binom_of_large_eq_zero x hx.right n (by linarith) (by linarith) h2x,
      rw [claim, pow_zero] at h,
      simp only [eq_self_iff_true, not_true] at h,
      exact h,
      dec_trivial, },
    exact x_le_two_mul_n, },
end

/--
An upper bound on the central binomial coefficient used in the proof of Bertrand's postulate.
The bound splits the prime factors of `central_binom n` into those
1. At most `sqrt (2 * n)`, which contribute at most `2 * n` for each such prime.
2. Between `sqrt (2 * n)` and `2 * n / 3`, which contribute at most `4^(2 * n / 3)` in total.
3. Between `2 * n / 3` and `n`, which do not exist.
4. Above `n`, which do not exist in the case where Bertrand's postulate is false.
-/
lemma bertrand_central_binomial_upper_bound (n : ℕ) (n_big : 1024 < n)
  (no_prime : ¬∃ (p : ℕ), nat.prime p ∧ n < p ∧ p ≤ 2 * n) :
  nat.central_binom n
    ≤ (2 * n) ^ (nat.sqrt (2 * n))
      * 4 ^ (2 * n / 3) :=
calc
nat.central_binom n
    = (∏ p in (finset.range (2 * n / 3 + 1)).filter nat.prime,
          p ^ (padic_val_nat p (nat.central_binom n))) :
          by rw [(central_binom_factorization_small n n_big no_prime), central_binom_factorization]
... = (∏ p in (finset.range (2 * n / 3 + 1)).filter nat.prime,
          if p ≤ nat.sqrt (2 * n)
          then p ^ (padic_val_nat p (nat.central_binom n))
          else p ^ (padic_val_nat p (nat.central_binom n))) : by simp only [if_t_t]
... = (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (≤ nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n)))
        *
      (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (λ p, ¬p ≤ nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n))) : finset.prod_ite _ _
... = (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (≤ nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n)))
        *
      (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (> nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n))) :
        by simp only [not_le, finset.filter_congr_decidable]
... ≤ (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (≤ nat.sqrt (2 * n)), 2 * n)
        *
      (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (> nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n))) :
        begin
          refine (nat.mul_le_mul_right _ _),
          refine finset.prod_le_prod'' _,
          intros i hyp,
          simp only [finset.mem_filter, finset.mem_range] at hyp,
          exact @claim_1 i (fact_iff.2 hyp.1.2) n (by linarith),
        end
... = (2 * n) ^ (((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (≤ nat.sqrt (2 * n))).card
      *
      (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (> nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n))) : by simp only [finset.prod_const]
... = (2 * n) ^ (((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (λ p, p ^ 2 < 2 * n)).card
      *
      (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (> nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n))) :
        begin
          congr' 3,
          ext1,
          simp only [and_imp, finset.mem_filter, finset.mem_range, and.congr_right_iff],
          intros h pa,
          split,
          { exact even_prime_is_small pa (by linarith), },
          { rw nat.le_sqrt', exact le_of_lt, },
        end
... ≤ (2 * n) ^ (nat.sqrt (2 * n))
        *
      (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (> nat.sqrt (2 * n)),
          p ^ (padic_val_nat p (nat.central_binom n))) :
        begin
          refine (nat.mul_le_mul_right _ _),
          refine pow_le_pow (by linarith) _,
          have : (finset.Ico 1 (nat.sqrt (2 * n) + 1)).card = nat.sqrt (2 * n),
          { simp, },
          rw <-this,
          clear this,
          apply finset.card_mono,
          rw [finset.le_eq_subset, finset.subset_iff],
          simp only [and_imp, finset.mem_filter, finset.mem_range, finset.mem_Ico],
          intros x _ px h,
          split,
          { exact le_of_lt (nat.prime.one_lt px), },
          { rw nat.lt_succ_iff,
            rw nat.le_sqrt',
            exact le_of_lt h, },
        end
... ≤ (2 * n) ^ (nat.sqrt (2 * n))
        *
      (∏ p in ((finset.range (2 * n / 3 + 1)).filter nat.prime).filter (> nat.sqrt (2 * n)),
          p ^ 1) :
      begin
        refine nat.mul_le_mul_left _ _,
        { refine finset.prod_le_prod'' _,
          intros i hyp,
          simp only [finset.mem_filter, finset.mem_range] at hyp,
          cases hyp with i_facts sqrt_two_n_lt_i,
          refine pow_le_pow _ _,
          { cases le_or_gt 1 i,
            { exact h, },
            { have i_zero : i = 0, by linarith,
              rw i_zero at i_facts,
              exfalso,
              exact nat.not_prime_zero i_facts.2, }, },
          { apply @nat.multiplicity_central_binom_of_large_le_one i i_facts.2 n,
            exact (@nat.sqrt_lt' (2 * n) i).1 sqrt_two_n_lt_i, }, },
      end
... ≤ (2 * n) ^ (nat.sqrt (2 * n))
        *
      (∏ p in (finset.range (2 * n / 3 + 1)).filter nat.prime,
          p ^ 1) :
        begin
          refine nat.mul_le_mul_left _ _,
          refine finset.prod_le_prod_of_subset_of_one_le' (finset.filter_subset _ _) _,
          { intros i hyp1 hyp2,
          cases le_or_gt 1 i,
          { ring_nf, exact h, },
          { have i_zero : i = 0, by linarith,
            simp only [i_zero, true_and, nat.succ_pos',
                        finset.mem_filter, finset.mem_range] at hyp1,
            exfalso, exact nat.not_prime_zero hyp1, }, }
        end
... = (2 * n) ^ (nat.sqrt (2 * n))
        *
      (∏ p in (finset.range (2 * n / 3 + 1)).filter nat.prime,
          p) : by simp only [pow_one]
... = (2 * n) ^ (nat.sqrt (2 * n))
      *
      (primorial (2 * n / 3)) : by unfold primorial
... ≤ (2 * n) ^ (nat.sqrt (2 * n))
        *
      4 ^ (2 * n / 3) : nat.mul_le_mul_left _ (primorial_le_4_pow (2 * n / 3))

/--
Proves that Bertrand's postulate holds for all sufficiently large `n`.
-/
lemma bertrand_eventually (n : nat) (n_big : 1024 < n) : ∃ (p : ℕ), p.prime ∧ n < p ∧ p ≤ 2 * n :=
begin
  -- Assume there is no prime in the range
  by_contradiction no_prime,
  -- If not, then we have the above upper bound on the size of this central binomial coefficient.
  -- We now couple this bound with a lower bound on the central binomial coefficient, yielding an
  -- inequality which we have seen is false for large enough n.
  have false_inequality
    : 4 ^ n < n * (2 * n) ^ (nat.sqrt (2 * n)) * 4 ^ (2 * n / 3), by
    calc
    4 ^ n
        < n * nat.central_binom n : nat.four_pow_lt_mul_central_binom n (by linarith)
    ... ≤ n * ((2 * n) ^ (nat.sqrt (2 * n)) * 4 ^ (2 * n / 3)) :
            nat.mul_le_mul_of_nonneg_left (bertrand_central_binomial_upper_bound n n_big no_prime)
    ... = n * (2 * n) ^ (nat.sqrt (2 * n)) * 4 ^ (2 * n / 3) : by ring,
  exact not_le_of_lt false_inequality (bertrand_inequality n_big),
end

/--
Proves that Bertrand's postulate holds over all positive naturals less than n by identifying a
descending list of primes, each no more than twice the next, such that the list contains a witness
for each number ≤ n.
-/
lemma bertrand_initial (n : ℕ) (hn0 : 0 < n) (plist : list ℕ)
  (primeplist : ∀ p ∈ plist, nat.prime p)
  (covering : ∀ a b, (a, b) ∈ list.zip plist (list.tail (plist ++ [2])) →
        a ≤ 2 * b)
   (hn : n < (plist ++ [2]).head) :
  ∃ (p : ℕ), p.prime ∧ n < p ∧ p ≤ 2 * n :=
begin
  tactic.unfreeze_local_instances,
  induction plist,
  { simp * at *,
    interval_cases n,
    { use 2,
      norm_num, }, },
  { simp * at *,
    by_cases plist_hd ≤ 2 * n,
    { use plist_hd,
      exact ⟨primeplist.left, hn, h⟩, },
    { apply plist_ih,
      { exact primeplist.right, },
      { intros a b hmem,
        apply covering,
        cases plist_tl,
        { simp * at *, },
        { simp at hmem,
          simp only [list.mem_cons_iff, list.cons_append, prod.mk.inj_iff, list.zip_cons_cons],
          right,
          assumption, }, },
      { cases plist_tl,
        { simp * at *,
          have h_hd := covering plist_hd 2 rfl rfl,
          have hn2 : 2 * n < 2 * 2, exact gt_of_ge_of_gt h_hd h,
          exact lt_of_mul_lt_mul_left' hn2, },
        { simp * at *,
          have h_hd := covering plist_hd plist_tl_hd,
          simp at h_hd,
          have hn2 : 2 * n < 2 * plist_tl_hd, exact gt_of_ge_of_gt h_hd h,
          exact lt_of_mul_lt_mul_left' hn2, }, }, }, },
end


/--
Bertrand's Postulate: For any positive natural number, there is a prime which is greater than
it, but no more than twice as large.
-/
theorem bertrand (n : nat) (n_pos : 0 < n) : ∃ p, nat.prime p ∧ n < p ∧ p ≤ 2 * n :=
begin
  -- Split into cases whether `n` is large or small
  cases lt_or_le 1024 n,
  -- If `n` is large, apply the theorem derived from the inequalities on the central binomial
  -- coefficient.
  { exact bertrand_eventually n h },
  -- For small `n`, supply a list of primes to cover the initial cases.
  apply bertrand_initial n n_pos [1031, 631, 317, 163, 83, 43, 23, 13, 7, 5, 3],
  -- Prove the list has the properties needed:
  { -- The list consists of primes
    intros p hp,
    simp only [list.mem_cons_iff, list.mem_singleton] at hp,
    iterate {cases hp <|> rw hp <|> norm_num}, },
  { -- Each element of the list is at least half the previous.
    intros a b hab,
    simp only [list.zip_nil_right, list.mem_cons_iff, list.cons_append, prod.mk.inj_iff,
               list.zip_cons_cons, list.tail, list.mem_singleton, list.singleton_append,
               list.tail_cons] at hab,
    iterate {cases hab <|> rw [hab.left, hab.right] <|> linarith}, },
  { -- The first element of the list is large enough.
    simp only [list.head, list.cons_append],
    linarith, },
end
