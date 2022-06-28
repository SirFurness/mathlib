/-
Copyright (c) 2020 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/

import algebra.big_operators.fin
import algebra.geom_sum
import group_theory.perm.fin
import linear_algebra.matrix.determinant
import linear_algebra.matrix.nondegenerate

/-!
# Vandermonde matrix

This file defines the `vandermonde` matrix and gives its determinant.

## Main definitions

 - `vandermonde v`: a square matrix with the `i, j`th entry equal to `v i ^ j`.

## Main results

 - `det_vandermonde`: `det (vandermonde v)` is the product of `v i - v j`, where
   `(i, j)` ranges over the unordered pairs.
-/

variables {R : Type*} [comm_ring R]

open equiv finset
open_locale big_operators matrix

namespace matrix

/-- `vandermonde v` is the square matrix with `i`th row equal to `1, v i, v i ^ 2, v i ^ 3, ...`.
-/
def vandermonde {n : ℕ} (v : fin n → R) : matrix (fin n) (fin n) R :=
λ i j, v i ^ (j : ℕ)

@[simp] lemma vandermonde_apply {n : ℕ} (v : fin n → R) (i j) :
  vandermonde v i j = v i ^ (j : ℕ) :=
rfl

@[simp] lemma vandermonde_cons {n : ℕ} (v0 : R) (v : fin n → R) :
  vandermonde (fin.cons v0 v : fin n.succ → R) =
    fin.cons (λ j, v0 ^ (j : ℕ)) (λ i, fin.cons 1 (λ j, v i * vandermonde v i j)) :=
begin
  ext i j,
  refine fin.cases (by simp) (λ i, _) i,
  refine fin.cases (by simp) (λ j, _) j,
  simp [pow_succ]
end

lemma vandermonde_succ {n : ℕ} (v : fin n.succ → R) :
  vandermonde v =
    fin.cons (λ j, v 0 ^ (j : ℕ))
      (λ i, fin.cons 1 (λ j, v i.succ * vandermonde (fin.tail v) i j)) :=
begin
  conv_lhs { rw [← fin.cons_self_tail v, vandermonde_cons] },
  simp only [fin.tail]
end

lemma vandermonde_mul_vandermonde_transpose {n : ℕ} (v w : fin n → R) (i j) :
  (vandermonde v ⬝ (vandermonde w)ᵀ) i j = ∑ (k : fin n), (v i * w j) ^ (k : ℕ) :=
by simp only [vandermonde_apply, matrix.mul_apply, matrix.transpose_apply, mul_pow]

lemma vandermonde_transpose_mul_vandermonde {n : ℕ} (v : fin n → R) (i j) :
  ((vandermonde v)ᵀ ⬝ vandermonde v) i j = ∑ (k : fin n), v k ^ (i + j : ℕ) :=
by simp only [vandermonde_apply, matrix.mul_apply, matrix.transpose_apply, pow_add]

lemma det_vandermonde {n : ℕ} (v : fin n → R) :
  det (vandermonde v) = ∏ i : fin n, ∏ j in Ioi i, (v j - v i) :=
begin
  unfold vandermonde,

  induction n with n ih,
  { exact det_eq_one_of_card_eq_zero (fintype.card_fin 0) },

  calc det (λ (i j : fin n.succ), v i ^ (j : ℕ))
      = det (λ (i j : fin n.succ), @fin.cons _ (λ _, R)
               (v 0 ^ (j : ℕ))
               (λ i, v (fin.succ i) ^ (j : ℕ) - v 0 ^ (j : ℕ)) i) :
    det_eq_of_forall_row_eq_smul_add_const (fin.cons 0 1) 0 (fin.cons_zero _ _) _
  ... = det (λ (i j : fin n), @fin.cons _ (λ _, R)
              (v 0 ^ (j.succ : ℕ))
              (λ (i : fin n), v (fin.succ i) ^ (j.succ : ℕ) - v 0 ^ (j.succ : ℕ))
              (fin.succ_above 0 i)) :
    by simp_rw [det_succ_column_zero, fin.sum_univ_succ, fin.cons_zero, minor, fin.cons_succ,
                fin.coe_zero, pow_zero, one_mul, sub_self, mul_zero, zero_mul,
                finset.sum_const_zero, add_zero]
  ... = det (λ (i j : fin n), (v (fin.succ i) - v 0) *
              (∑ k in finset.range (j + 1 : ℕ), v i.succ ^ k * v 0 ^ (j - k : ℕ))) :
    by { congr, ext i j, rw [fin.succ_above_zero, fin.cons_succ, fin.coe_succ, mul_comm],
         exact (geom_sum₂_mul (v i.succ) (v 0) (j + 1 : ℕ)).symm }
  ... = (∏ (i : fin n), (v (fin.succ i) - v 0)) * det (λ (i j : fin n),
    (∑ k in finset.range (j + 1 : ℕ), v i.succ ^ k * v 0 ^ (j - k : ℕ))) :
    det_mul_column (λ i, v (fin.succ i) - v 0) _
  ... = (∏ (i : fin n), (v (fin.succ i) - v 0)) * det (λ (i j : fin n), v (fin.succ i) ^ (j : ℕ)) :
    congr_arg ((*) _) _
  ... = ∏ i : fin n.succ, ∏ j in Ioi i, (v j - v i) :
    by simp_rw [ih (v ∘ fin.succ), fin.prod_univ_succ, fin.prod_Ioi_zero, fin.prod_Ioi_succ],
  { intros i j,
    rw fin.cons_zero,
    refine fin.cases _ (λ i, _) i,
    { simp },
    rw [fin.cons_succ, fin.cons_succ, pi.one_apply],
    ring },
  { cases n,
    { simp only [det_eq_one_of_card_eq_zero (fintype.card_fin 0)] },
    apply det_eq_of_forall_col_eq_smul_add_pred (λ i, v 0),
    { intro j,
      simp },
    { intros i j,
      simp only [smul_eq_mul, pi.add_apply, fin.coe_succ, fin.coe_cast_succ, pi.smul_apply],
      rw [finset.sum_range_succ, add_comm, tsub_self, pow_zero, mul_one, finset.mul_sum],
      congr' 1,
      refine finset.sum_congr rfl (λ i' hi', _),
      rw [mul_left_comm (v 0), nat.succ_sub, pow_succ],
      exact nat.lt_succ_iff.mp (finset.mem_range.mp hi') } }
end

lemma det_vandermonde_eq_zero_iff [is_domain R] {n : ℕ} {v : fin n → R} :
  det (vandermonde v) = 0 ↔ ∃ (i j : fin n), v i = v j ∧ i ≠ j :=
begin
  split,
  { simp only [det_vandermonde v, finset.prod_eq_zero_iff, sub_eq_zero, forall_exists_index],
    exact λ i _ j h₁ h₂, ⟨j, i, h₂, (mem_Ioi.mp h₁).ne'⟩ },
  { simp only [ne.def, forall_exists_index, and_imp],
    refine λ i j h₁ h₂, matrix.det_zero_of_row_eq h₂ (funext $ λ k, _),
    rw [vandermonde_apply, vandermonde_apply, h₁], }
end

lemma det_vandermonde_ne_zero_iff [is_domain R] {n : ℕ} {v : fin n → R} :
  det (vandermonde v) ≠ 0 ↔ function.injective v :=
by simpa only [det_vandermonde_eq_zero_iff, ne.def, not_exists, not_and, not_not]

theorem vandermonde_invertibility' {R : Type*} [comm_ring R]
[is_domain R] {n : ℕ} (v : fin n ↪ R) {f : fin n → R}
(h₂ : ∀ j, ∑ i : fin n, (v j ^ (i : ℕ)) * f i = 0) : f = 0
:= eq_zero_of_mul_vec_eq_zero (det_vandermonde_ne_zero_iff.mpr v.inj') (funext h₂)

theorem vandermonde_invertibility {R : Type*} [comm_ring R]
[is_domain R] {n : ℕ} (v : fin n ↪ R) {f : fin n → R}
(h₂ : ∀ j, ∑ i, f i * (v j ^ (i : ℕ)) = 0) : f = 0
:= by {refine vandermonde_invertibility' v _, simp_rw mul_comm, exact h₂}

theorem vandermonde_invertibility_transposed {R : Type*} [comm_ring R]
[is_domain R] {n : ℕ} (v : fin n ↪ R) {f : fin n → R}
(h₂ : ∀ i : fin n, ∑ j : fin n, f j * (v j ^ (i : ℕ)) = 0) : f = 0
:= eq_zero_of_vec_mul_eq_zero (det_vandermonde_ne_zero_iff.mpr v.inj') (funext h₂)

end matrix

namespace polynomial
open_locale polynomial

theorem eq_zero_iff_degree_lt_equiv_eq_zero {R : Type*} [comm_ring R] {n : ℕ}
  {p : R[X]} (hp : p ∈ degree_lt R n) : p = 0 ↔ degree_lt_equiv _ _ ⟨p, hp⟩ = 0 :=
by {rw [linear_equiv.map_eq_zero_iff, submodule.mk_eq_zero]}

theorem eval_eq_sum_degree_lt_equiv {R : Type*} [comm_ring R] {n : ℕ} {p : R[X]} (hp : p ∈ degree_lt R n)
  (x : R) : p.eval x = ∑ i, degree_lt_equiv _ _ ⟨p, hp⟩ i * (x ^ (i : ℕ)) :=
begin
  simp_rw [eval_eq_sum],
  exact (sum_fin _ (by simp_rw [zero_mul, forall_const]) (mem_degree_lt.mp hp)).symm
end

theorem vandermonde_invertibility {R : Type*} [comm_ring R] [is_domain R] {n : ℕ}
  (v : fin n ↪ R) {p : R[X]} (hp₁ : p ∈ degree_lt R n)
  (hp₂ : ∀ j, eval (v j) p = 0) : p = 0 :=
begin
  simp_rw eval_eq_sum_degree_lt_equiv hp₁ at hp₂, rw eq_zero_iff_degree_lt_equiv_eq_zero hp₁,
  exact matrix.vandermonde_invertibility v (λ j, hp₂ j)
end

theorem vandermonde_invertibility_transposed {R : Type*} [comm_ring R] [is_domain R]
  {n : ℕ} (v : fin n ↪ R) {p : R[X]} (hp₁ : p ∈ degree_lt R n)
  (hp₂ : ∀ i : fin n, ∑ j : fin n, (p : R[X]).coeff j * (v j ^ (i : ℕ)) = 0) : p = 0 :=
begin
  rw eq_zero_iff_degree_lt_equiv_eq_zero hp₁,
  exact matrix.vandermonde_invertibility_transposed v (λ i, hp₂ i)
end

theorem vandermonde_agreement {R : Type*} [comm_ring R] [is_domain R] {n : ℕ}
  (v : fin n ↪ R) {p q : R[X]} (hpq₁ : (p - q) ∈ degree_lt R n)
  (hpq₂ : ∀ j, p.eval (v j) = q.eval (v j)) : p = q :=
begin
  have vi := vandermonde_invertibility v hpq₁, simp_rw [eval_sub, sub_eq_zero] at vi, exact vi hpq₂
end

theorem vandermonde_agreement' {R : Type*} [comm_ring R] [is_domain R] {n : ℕ}
  (v : fin n ↪ R) {p q : R[X]} (hp : p ∈ degree_lt R n) (hq : q ∈ degree_lt R n)
  (hpq : ∀ j, p.eval (v j) = q.eval (v j)) : p = q :=
vandermonde_agreement v (submodule.sub_mem _ hp hq) hpq

end polynomial
