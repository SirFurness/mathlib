/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import algebra.big_operators.basic
import data.zmod.basic

/-!
# Euler's totient function

This file defines [Euler's totient function][https://en.wikipedia.org/wiki/Euler's_totient_function]
`nat.totient n` which counts the number of naturals less than `n` that are coprime with `n`.
We prove the divisor sum formula, namely that `n` equals `φ` summed over the divisors of `n`. See
`sum_totient`.
-/

open finset
open_locale big_operators

namespace nat

/-- Euler's totient function. This counts the number of naturals strictly less than `n` which are
coprime with `n`. -/
def totient (n : ℕ) : ℕ := ((range n).filter (nat.coprime n)).card

localized "notation `φ` := nat.totient" in nat

@[simp] theorem totient_zero : φ 0 = 0 := rfl

lemma totient_le (n : ℕ) : φ n ≤ n :=
calc totient n ≤ (range n).card : card_filter_le _ _
           ... = n              : card_range _

lemma totient_pos : ∀ {n : ℕ}, 0 < n → 0 < φ n
| 0 := dec_trivial
| 1 := by simp [totient]
| (n+2) := λ h, card_pos.2 ⟨1, mem_filter.2 ⟨mem_range.2 dec_trivial, coprime_one_right _⟩⟩

open zmod

@[simp] lemma _root_.zmod.card_units_eq_totient (n : ℕ) [fact (0 < n)] :
  fintype.card (units (zmod n)) = φ n :=
calc fintype.card (units (zmod n)) = fintype.card {x : zmod n // x.val.coprime n} :
  fintype.card_congr zmod.units_equiv_coprime
... = φ n :
begin
  apply finset.card_congr (λ (a : {x : zmod n // x.val.coprime n}) _, a.1.val),
  { intro a, simp [(a : zmod n).val_lt, a.prop.symm] {contextual := tt} },
  { intros _ _ _ _ h, rw subtype.ext_iff_val, apply val_injective, exact h, },
  { intros b hb,
    rw [finset.mem_filter, finset.mem_range] at hb,
    refine ⟨⟨b, _⟩, finset.mem_univ _, _⟩,
    { let u := unit_of_coprime b hb.2.symm,
      exact val_coe_unit_coprime u },
    { show zmod.val (b : zmod n) = b,
      rw [val_nat_cast, nat.mod_eq_of_lt hb.1], } }
end

lemma totient_mul {m n : ℕ} (h : m.coprime n) : φ (m * n) = φ m * φ n :=
if hmn0 : m * n = 0
  then by cases nat.mul_eq_zero.1 hmn0 with h h;
    simp only [totient_zero, mul_zero, zero_mul, h]
  else
  begin
    haveI : fact (0 < (m * n)) := ⟨nat.pos_of_ne_zero hmn0⟩,
    haveI : fact (0 < m) := ⟨nat.pos_of_ne_zero $ left_ne_zero_of_mul hmn0⟩,
    haveI : fact (0 < n) := ⟨nat.pos_of_ne_zero $ right_ne_zero_of_mul hmn0⟩,
    rw [← zmod.card_units_eq_totient, ← zmod.card_units_eq_totient,
      ← zmod.card_units_eq_totient,
      fintype.card_congr (units.map_equiv (chinese_remainder h).to_mul_equiv).to_equiv,
      fintype.card_congr (@mul_equiv.prod_units (zmod m) (zmod n) _ _).to_equiv,
      fintype.card_prod]
  end

lemma sum_totient (n : ℕ) : ∑ m in (range n.succ).filter (∣ n), φ m = n :=
if hn0 : n = 0 then by simp [hn0]
else
calc ∑ m in (range n.succ).filter (∣ n), φ m
    = ∑ d in (range n.succ).filter (∣ n), ((range (n / d)).filter (λ m, gcd (n / d) m = 1)).card :
  eq.symm $ sum_bij (λ d _, n / d)
    (λ d hd, mem_filter.2 ⟨mem_range.2 $ lt_succ_of_le $ nat.div_le_self _ _,
      by conv {to_rhs, rw ← nat.mul_div_cancel' (mem_filter.1 hd).2}; simp⟩)
    (λ _ _, rfl)
    (λ a b ha hb h,
      have ha : a * (n / a) = n, from nat.mul_div_cancel' (mem_filter.1 ha).2,
      have 0 < (n / a), from nat.pos_of_ne_zero (λ h, by simp [*, lt_irrefl] at *),
      by rw [← nat.mul_left_inj this, ha, h, nat.mul_div_cancel' (mem_filter.1 hb).2])
    (λ b hb,
      have hb : b < n.succ ∧ b ∣ n, by simpa [-range_succ] using hb,
      have hbn : (n / b) ∣ n, from ⟨b, by rw nat.div_mul_cancel hb.2⟩,
      have hnb0 : (n / b) ≠ 0, from λ h, by simpa [h, ne.symm hn0] using nat.div_mul_cancel hbn,
      ⟨n / b, mem_filter.2 ⟨mem_range.2 $ lt_succ_of_le $ nat.div_le_self _ _, hbn⟩,
        by rw [← nat.mul_left_inj (nat.pos_of_ne_zero hnb0),
          nat.mul_div_cancel' hb.2, nat.div_mul_cancel hbn]⟩)
... = ∑ d in (range n.succ).filter (∣ n), ((range n).filter (λ m, gcd n m = d)).card :
  sum_congr rfl (λ d hd,
    have hd : d ∣ n, from (mem_filter.1 hd).2,
    have hd0 : 0 < d, from nat.pos_of_ne_zero (λ h, hn0 (eq_zero_of_zero_dvd $ h ▸ hd)),
    card_congr (λ m hm, d * m)
      (λ m hm, have hm : m < n / d ∧ gcd (n / d) m = 1, by simpa using hm,
        mem_filter.2 ⟨mem_range.2 $ nat.mul_div_cancel' hd ▸
          (mul_lt_mul_left hd0).2 hm.1,
          by rw [← nat.mul_div_cancel' hd, gcd_mul_left, hm.2, mul_one]⟩)
      (λ a b ha hb h, (nat.mul_right_inj hd0).1 h)
      (λ b hb, have hb : b < n ∧ gcd n b = d, by simpa using hb,
        ⟨b / d, mem_filter.2 ⟨mem_range.2
            ((mul_lt_mul_left (show 0 < d, from hb.2 ▸ hb.2.symm ▸ hd0)).1
              (by rw [← hb.2, nat.mul_div_cancel' (gcd_dvd_left _ _),
                nat.mul_div_cancel' (gcd_dvd_right _ _)]; exact hb.1)),
            hb.2 ▸ coprime_div_gcd_div_gcd (hb.2.symm ▸ hd0)⟩,
          hb.2 ▸ nat.mul_div_cancel' (gcd_dvd_right _ _)⟩))
... = ((filter (∣ n) (range n.succ)).bUnion (λ d, (range n).filter (λ m, gcd n m = d))).card :
  (card_bUnion (by intros; apply disjoint_filter.2; cc)).symm
... = (range n).card :
  congr_arg card (finset.ext (λ m, ⟨by finish,
    λ hm, have h : m < n, from mem_range.1 hm,
      mem_bUnion.2 ⟨gcd n m, mem_filter.2
        ⟨mem_range.2 (lt_succ_of_le (le_of_dvd (lt_of_le_of_lt (zero_le _) h)
          (gcd_dvd_left _ _))), gcd_dvd_left _ _⟩, mem_filter.2 ⟨hm, rfl⟩⟩⟩))
... = n : card_range _

end nat
