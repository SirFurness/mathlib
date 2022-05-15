/-
Copyright (c) 2019 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Scott Morrison, Violeta Hernández Palacios
-/
import set_theory.game.basic
import set_theory.game.birthday

/-!
# Surreal numbers

The basic theory of surreal numbers, built on top of the theory of combinatorial (pre-)games.

A pregame is `numeric` if all the Left options are strictly smaller than all the Right options, and
all those options are themselves numeric. In terms of combinatorial games, the numeric games have
"frozen"; you can only make your position worse by playing, and Left is some definite "number" of
moves ahead (or behind) Right.

A surreal number is an equivalence class of numeric pregames.

In fact, the surreals form a complete ordered field, containing a copy of the reals (and much else
besides!) but we do not yet have a complete development.

## Order properties
Surreal numbers inherit the relations `≤` and `<` from games, and these relations satisfy the axioms
of a partial order (recall that `x < y ↔ x ≤ y ∧ ¬ y ≤ x` did not hold for games).

## Algebraic operations
We show that the surreals form a linear ordered commutative group.

One can also map all the ordinals into the surreals!

## References
* [Conway, *On numbers and games*][conway2001]
* [Schleicher, Stoll, *An introduction to Conway's games and numbers*][schleicher_stoll]
-/

universes u

local infix ` ≈ ` := pgame.equiv
local infix ` ⧏ `:50 := pgame.lf

namespace pgame

/-- A pre-game is numeric if everything in the L set is less than everything in the R set,
and all the elements of L and R are also numeric. -/
def numeric : pgame → Prop
| ⟨l, r, L, R⟩ :=
  (∀ i j, L i < R j) ∧ (∀ i, numeric (L i)) ∧ (∀ i, numeric (R i))

lemma numeric_def (x : pgame) : numeric x ↔ (∀ i j, x.move_left i < x.move_right j) ∧
  (∀ i, numeric (x.move_left i)) ∧ (∀ i, numeric (x.move_right i)) :=
by { cases x, refl }

lemma numeric.left_lt_right {x : pgame} (o : numeric x) (i : x.left_moves) (j : x.right_moves) :
  x.move_left i < x.move_right j :=
by { cases x with xl xr xL xR, exact o.1 i j }
lemma numeric.move_left {x : pgame} (o : numeric x) (i : x.left_moves) :
  numeric (x.move_left i) :=
by { cases x with xl xr xL xR, exact o.2.1 i }
lemma numeric.move_right {x : pgame} (o : numeric x) (j : x.right_moves) :
  numeric (x.move_right j) :=
by { cases x with xl xr xL xR, exact o.2.2 j }

@[elab_as_eliminator]
theorem numeric_rec {C : pgame → Prop}
  (H : ∀ l r (L : l → pgame) (R : r → pgame),
    (∀ i j, L i < R j) → (∀ i, numeric (L i)) → (∀ i, numeric (R i)) →
    (∀ i, C (L i)) → (∀ i, C (R i)) → C ⟨l, r, L, R⟩) :
  ∀ x, numeric x → C x
| ⟨l, r, L, R⟩ ⟨h, hl, hr⟩ :=
  H _ _ _ _ h hl hr (λ i, numeric_rec _ (hl i)) (λ i, numeric_rec _ (hr i))

theorem lf_asymm {x y : pgame} (ox : numeric x) (oy : numeric y) : x ⧏ y → ¬ y ⧏ x :=
begin
  refine numeric_rec (λ xl xr xL xR hx oxl oxr IHxl IHxr, _) x ox y oy,
  refine numeric_rec (λ yl yr yL yR hy oyl oyr IHyl IHyr, _),
  rw [mk_lf_mk, mk_lf_mk], rintro (⟨i, h₁⟩ | ⟨j, h₁⟩) (⟨i, h₂⟩ | ⟨j, h₂⟩),
  { exact IHxl _ _ (oyl _) (move_left_lf_of_le _ h₁) (move_left_lf_of_le _ h₂) },
  { exact not_lf.2 (le_trans h₂ h₁) (lf_of_lt (hy _ _)) },
  { exact not_lf.2 (le_trans h₁ h₂) (lf_of_lt (hx _ _)) },
  { exact IHxr _ _ (oyr _) (lf_move_right_of_le _ h₁) (lf_move_right_of_le _ h₂) },
end

theorem le_of_lf {x y : pgame} (ox : numeric x) (oy : numeric y) (h : x ⧏ y) : x ≤ y :=
not_lf.1 (lf_asymm ox oy h)

theorem lt_of_lf {x y : pgame} (ox : numeric x) (oy : numeric y) (h : x ⧏ y) : x < y :=
(lt_or_fuzzy_of_lf h).resolve_right (not_fuzzy_of_le (le_of_lf ox oy h))

theorem lf_iff_lt {x y : pgame} (ox : numeric x) (oy : numeric y) : x ⧏ y ↔ x < y :=
⟨lt_of_lf ox oy, lf_of_lt⟩

theorem not_fuzzy {x y : pgame} (ox : numeric x) (oy : numeric y) : ¬ fuzzy x y :=
λ h, not_lf.2 (le_of_lf ox oy (lf_of_fuzzy h)) h.2

theorem numeric_zero : numeric 0 :=
⟨by rintros ⟨⟩ ⟨⟩, ⟨by rintros ⟨⟩, by rintros ⟨⟩⟩⟩
theorem numeric_one : numeric 1 :=
⟨by rintros ⟨⟩ ⟨⟩, ⟨λ x, numeric_zero, by rintros ⟨⟩⟩⟩

theorem numeric.neg : Π {x : pgame} (o : numeric x), numeric (-x)
| ⟨l, r, L, R⟩ o := ⟨λ j i, neg_lt_iff.2 (o.1 i j), λ j, (o.2.2 j).neg, λ i, (o.2.1 i).neg⟩

theorem numeric.move_left_lt {x : pgame} (o : numeric x) (i) : x.move_left i < x :=
lt_of_lf (o.move_left i) o (pgame.move_left_lf i)
theorem numeric.move_left_le {x : pgame} (o : numeric x) (i) : x.move_left i ≤ x :=
(o.move_left_lt i).le

theorem numeric.lt_move_right {x : pgame} (o : numeric x) (j) : x < x.move_right j :=
lt_of_lf o (o.move_right j) (pgame.lf_move_right j)
theorem numeric.le_move_right {x : pgame} (o : numeric x) (j) : x ≤ x.move_right j :=
(o.lt_move_right j).le

-- TODO: this can be generalized to `add_lf_add_of_lf_of_lt`, which doesn't depend on any `numeric`
-- hypotheses.
theorem add_lf_add
  {w x y z : pgame.{u}} (oy : numeric y) (oz : numeric z)
  (hwx : w ⧏ x) (hyz : y ⧏ z) : w + y ⧏ x + z :=
begin
  rw lf_def_le at *,
  rcases hwx with ⟨ix, hix⟩|⟨jw, hjw⟩;
  rcases hyz with ⟨iz, hiz⟩|⟨jy, hjy⟩,
  { left,
    use (left_moves_add x z).symm (sum.inl ix),
    simp only [add_move_left_inl],
    calc w + y ≤ move_left x ix + y : add_le_add_right hix _
            ... ≤ move_left x ix + move_left z iz : add_le_add_left hiz _
            ... ≤ move_left x ix + z : add_le_add_left (oz.move_left_le iz) _ },
  { left,
    use (left_moves_add x z).symm (sum.inl ix),
    simp only [add_move_left_inl],
    calc w + y ≤ move_left x ix + y : add_le_add_right hix _
            ... ≤ move_left x ix + move_right y jy : add_le_add_left (oy.le_move_right jy) _
            ... ≤ move_left x ix + z : add_le_add_left hjy _ },
  { right,
    use (right_moves_add w y).symm (sum.inl jw),
    simp only [add_move_right_inl],
    calc move_right w jw + y ≤ x + y : add_le_add_right hjw _
            ... ≤ x + move_left z iz : add_le_add_left hiz _
            ... ≤ x + z : add_le_add_left (oz.move_left_le iz) _ },
  { right,
    use (right_moves_add w y).symm (sum.inl jw),
    simp only [add_move_right_inl],
    calc move_right w jw + y ≤ x + y : add_le_add_right hjw _
            ... ≤ x + move_right y jy : add_le_add_left (oy.le_move_right jy) _
            ... ≤ x + z : add_le_add_left hjy _ },
end

theorem numeric.add : Π {x y : pgame} (ox : numeric x) (oy : numeric y), numeric (x + y)
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ox oy :=
⟨begin
   rintros (ix|iy) (jx|jy),
   { exact add_lt_add_right (ox.1 ix jx) _ },
   { apply lt_of_lf ((ox.move_left ix).add oy) (ox.add (oy.move_right jy))
      (add_lf_add oy (oy.move_right jy) (pgame.move_left_lf ix) (pgame.lf_move_right jy)) },
   { apply lt_of_lf (ox.add (oy.move_left iy)) ((ox.move_right jx).add oy)
      (add_lf_add (oy.move_left iy) oy (pgame.lf_move_right jx) (pgame.move_left_lf iy)) },
   { exact add_lt_add_left (oy.1 iy jy) ⟨xl, xr, xL, xR⟩ }
 end,
 begin
   split,
   { rintros (ix|iy),
     { exact (ox.move_left ix).add oy },
     { exact ox.add (oy.move_left iy) } },
   { rintros (jx|jy),
     { apply (ox.move_right jx).add oy },
     { apply ox.add (oy.move_right jy) } }
 end⟩
using_well_founded { dec_tac := pgame_wf_tac }

lemma numeric.sub {x y : pgame} (ox : numeric x) (oy : numeric y) : numeric (x - y) := ox.add oy.neg

/-- Pre-games defined by natural numbers are numeric. -/
theorem numeric_nat : Π (n : ℕ), numeric n
| 0 := numeric_zero
| (n + 1) := (numeric_nat n).add numeric_one

/-- The pre-game `half` is numeric. -/
theorem numeric_half : numeric half :=
begin
  split,
  { rintros ⟨ ⟩ ⟨ ⟩,
    exact zero_lt_one },
  split; rintro ⟨ ⟩,
  { exact numeric_zero },
  { exact numeric_one }
end

end pgame

/-- The equivalence on numeric pre-games. -/
def surreal.equiv (x y : {x // pgame.numeric x}) : Prop := x.1.equiv y.1

open pgame

instance surreal.setoid : setoid {x // pgame.numeric x} :=
⟨λ x y, x.1 ≈ y.1,
 λ x, equiv_refl x.1,
 λ x y, pgame.equiv_symm,
 λ x y z, pgame.equiv_trans⟩

/-- The type of surreal numbers. These are the numeric pre-games quotiented
by the equivalence relation `x ≈ y ↔ x ≤ y ∧ y ≤ x`. In the quotient,
the order becomes a total order. -/
def surreal := quotient surreal.setoid

namespace surreal

/-- Construct a surreal number from a numeric pre-game. -/
def mk (x : pgame) (h : x.numeric) : surreal := quotient.mk ⟨x, h⟩

instance : has_zero surreal :=
{ zero := ⟦⟨0, numeric_zero⟩⟧ }
instance : has_one surreal :=
{ one := ⟦⟨1, numeric_one⟩⟧ }

instance : inhabited surreal := ⟨0⟩

/-- Lift an equivalence-respecting function on pre-games to surreals. -/
def lift {α} (f : ∀ x, numeric x → α)
  (H : ∀ {x y} (hx : numeric x) (hy : numeric y), x.equiv y → f x hx = f y hy) : surreal → α :=
quotient.lift (λ x : {x // numeric x}, f x.1 x.2) (λ x y, H x.2 y.2)

/-- Lift a binary equivalence-respecting function on pre-games to surreals. -/
def lift₂ {α} (f : ∀ x y, numeric x → numeric y → α)
  (H : ∀ {x₁ y₁ x₂ y₂} (ox₁ : numeric x₁) (oy₁ : numeric y₁) (ox₂ : numeric x₂) (oy₂ : numeric y₂),
    x₁.equiv x₂ → y₁.equiv y₂ → f x₁ y₁ ox₁ oy₁ = f x₂ y₂ ox₂ oy₂) : surreal → surreal → α :=
lift (λ x ox, lift (λ y oy, f x y ox oy) (λ y₁ y₂ oy₁ oy₂ h, H _ _ _ _ equiv_rfl h))
  (λ x₁ x₂ ox₁ ox₂ h, funext $ quotient.ind $ by exact λ ⟨y, oy⟩, H _ _ _ _ h equiv_rfl)

instance : has_le surreal :=
⟨lift₂ (λ x y _ _, x ≤ y) (λ x₁ y₁ x₂ y₂ _ _ _ _ hx hy, propext (le_congr hx hy))⟩

instance : has_lt surreal :=
⟨lift₂ (λ x y _ _, x < y) (λ x₁ y₁ x₂ y₂ _ _ _ _ hx hy, propext (lt_congr hx hy))⟩

/-- Addition on surreals is inherited from pre-game addition:
the sum of `x = {xL | xR}` and `y = {yL | yR}` is `{xL + y, x + yL | xR + y, x + yR}`. -/
instance : has_add surreal  :=
⟨surreal.lift₂
  (λ (x y : pgame) (ox) (oy), ⟦⟨x + y, ox.add oy⟩⟧)
  (λ x₁ y₁ x₂ y₂ _ _ _ _ hx hy, quotient.sound (pgame.add_congr hx hy))⟩

/-- Negation for surreal numbers is inherited from pre-game negation:
the negation of `{L | R}` is `{-R | -L}`. -/
instance : has_neg surreal  :=
⟨surreal.lift
  (λ x ox, ⟦⟨-x, ox.neg⟩⟧)
  (λ _ _ _ _ a, quotient.sound (pgame.neg_congr a))⟩

instance : ordered_add_comm_group surreal :=
{ add               := (+),
  add_assoc         := by { rintros ⟨_⟩ ⟨_⟩ ⟨_⟩, exact quotient.sound add_assoc_equiv },
  zero              := 0,
  zero_add          := by { rintros ⟨_⟩, exact quotient.sound (pgame.zero_add_equiv a) },
  add_zero          := by { rintros ⟨_⟩, exact quotient.sound (pgame.add_zero_equiv a) },
  neg               := has_neg.neg,
  add_left_neg      := by { rintros ⟨_⟩, exact quotient.sound (pgame.add_left_neg_equiv a) },
  add_comm          := by { rintros ⟨_⟩ ⟨_⟩, exact quotient.sound pgame.add_comm_equiv },
  le                := (≤),
  lt                := (<),
  le_refl           := by { rintros ⟨_⟩, apply @le_rfl pgame },
  le_trans          := by { rintros ⟨_⟩ ⟨_⟩ ⟨_⟩, apply @le_trans pgame },
  lt_iff_le_not_le  := by { rintros ⟨_, ox⟩ ⟨_, oy⟩, exact lt_iff_le_not_le },
  le_antisymm       := by { rintros ⟨_⟩ ⟨_⟩ h₁ h₂, exact quotient.sound ⟨h₁, h₂⟩ },
  add_le_add_left   := by { rintros ⟨_⟩ ⟨_⟩ hx ⟨_⟩, exact @add_le_add_left pgame _ _ _ _ _ hx _ } }

noncomputable instance : linear_ordered_add_comm_group surreal :=
{ le_total := by rintro ⟨⟨x, ox⟩⟩ ⟨⟨y, oy⟩⟩; classical; exact
    or_iff_not_imp_left.2 (λ h, le_of_lf oy ox (pgame.not_le.1 h)),
  decidable_le := classical.dec_rel _,
  ..surreal.ordered_add_comm_group }

end surreal

namespace pgame

/-- To prove that surreal multiplication is well-defined, we use a modified argument by Schleicher.
We simultaneously prove two assertions on numeric pre-games:

- `P1 x y` means `x * y` is numeric.
- `P2 x₁ x₂ y` means all of the following hold:
- - If `x₁ ≈ x₂` then `x₁ * y ≈ x₂ * y`,
- - If `x₁ < x₂`, then
- - - For every left move `yL`, `x₂ * yL + x₁ * y < x₁ * yL + x₂ * y`,
- - - For every right move `yR`, `x₂ * y + x₁ * yR < x₁ * y + x₂ * yR`.

We prove this by defining a well-founded "depth" on `P1` and `P2`, and showing that each statement
follows from statements of lesser depth. This auxiliary type represents either the assertion `P1` on
two games, or the assertion `P2` on three games. -/
inductive mul_args : Type (u+1)
| P1 (x y : pgame.{u}) : mul_args
| P2 (x₁ x₂ y : pgame.{u}) : mul_args

end pgame

section comm_lemmas

variables {a b c d e f g h : game.{u}}

/-! A few auxiliary results for the surreal multiplication proof. -/

private theorem add_add_lt_cancel_left : a + b + c < a + d + e ↔ b + c < d + e :=
by rw [add_assoc, add_assoc, add_lt_add_iff_left]

private theorem add_add_lt_cancel_mid : a + b + c < d + b + e ↔ a + c < d + e :=
by rw [add_comm a, add_comm d, add_add_lt_cancel_left]

private theorem add_comm₂ : a + b < c + d ↔ b + a < d + c :=
by abel

end comm_lemmas

namespace pgame

private theorem quot_mul_comm₂ {a b c d : pgame} :
  ⟦a * b⟧ = ⟦c * d⟧ ↔ ⟦b * a⟧ = ⟦d * c⟧ :=
by rw [quot_mul_comm a, quot_mul_comm c]

private theorem quot_mul_comm₄ {a b c d e f g h : pgame} :
  ⟦a * b⟧ + ⟦c * d⟧ < ⟦e * f⟧ + ⟦g * h⟧ ↔ ⟦b * a⟧ + ⟦d * c⟧ < ⟦f * e⟧ + ⟦h * g⟧ :=
by rw [quot_mul_comm a, quot_mul_comm c, quot_mul_comm e, quot_mul_comm g]

namespace mul_args

/-- The depth function on the type. See the docstring for `mul_args`. -/
noncomputable def depth : mul_args → ordinal ×ₗ ordinal
| (P1 x y) := ((x + y).birthday, 0)
| (P2 x₁ x₂ y) := (max ((x₁ + y).birthday) ((x₂ + y).birthday),
                    (min x₁.birthday x₂.birthday).succ)

/-- This is the statement we wish to prove. -/
def hypothesis : mul_args → Prop
| (P1 x y)     := numeric x  → numeric y  → numeric (x * y)
| (P2 x₁ x₂ y) := numeric x₁ → numeric x₂ → numeric y →
                    (x₁ ≈ x₂ → x₁ * y ≈ x₂ * y) ∧
                    (x₁ < x₂ →
                      (∀ i, x₂ * y.move_left i + x₁ * y  < x₁ * y.move_left i + x₂ * y) ∧
                       ∀ j, x₂ * y + x₁ * y.move_right j < x₁ * y + x₂ * y.move_right j)

instance : has_lt mul_args := ⟨λ x y, x.depth < y.depth⟩

instance : has_well_founded mul_args :=
{ r := (<),
  wf := inv_image.wf _ (prod.lex_wf ordinal.wf ordinal.wf) }

/-- The hypothesis is true for any arguments. -/
theorem result : ∀ x : mul_args, x.hypothesis
| (P1 ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩) := begin
  intros ox oy,
  rw numeric_def,

  let x : pgame := ⟨xl, xr, xL, xR⟩,
  let y : pgame := ⟨yl, yr, yL, yR⟩,

  -- Deduce numeric games from inductive hypothesis.
  have HN₁ : ∀ {ix iy}, (xL ix * y + x * yL iy - xL ix * yL iy).numeric :=
  λ ix iy, ((result (P1 _ _) (ox.move_left ix) oy).add (result (P1 _ _) ox (oy.move_left iy))).sub
    (result (P1 _ _) (ox.move_left ix) (oy.move_left iy)),
  have HN₂ : ∀ {jx jy}, (xR jx * y + x * yR jy - xR jx * yR jy).numeric :=
  λ jx jy, ((result (P1 _ _) (ox.move_right jx) oy).add (result (P1 _ _) ox (oy.move_right jy))).sub
    (result (P1 _ _) (ox.move_right jx) (oy.move_right jy)),
  have HN₃ : ∀ {ix jy}, (xL ix * y + x * yR jy - xL ix * yR jy).numeric :=
  λ ix jy, ((result (P1 _ _) (ox.move_left ix) oy).add (result (P1 _ _) ox (oy.move_right jy))).sub
    (result (P1 _ _) (ox.move_left ix) (oy.move_right jy)),
  have HN₄ : ∀ {jx iy}, (xR jx * y + x * yL iy - xR jx * yL iy).numeric :=
  λ jx iy, ((result (P1 _ _) (ox.move_right jx) oy).add (result (P1 _ _) ox (oy.move_left iy))).sub
    (result (P1 _ _) (ox.move_right jx) (oy.move_left iy)),

  -- Other applications of the inductive hypothesis.
  have HR₁ := λ {ix ix'}, result (P2 _ _ _) (ox.move_left ix)  (ox.move_left ix')  oy,
  have HR₂ := λ {iy iy'}, result (P2 _ _ _) (oy.move_left iy)  (oy.move_left iy')  ox,
  have HR₃ := λ {jx jx'}, result (P2 _ _ _) (ox.move_right jx) (ox.move_right jx') oy,
  have HR₄ := λ {jy jy'}, result (P2 _ _ _) (oy.move_right jy) (oy.move_right jy') ox,

  have HS₁ := λ {ix jx}, (result (P2 _ _ _) (ox.move_left ix) (ox.move_right jx) oy).2
    (ox.left_lt_right ix jx),
  have HS₂ := λ {iy jy}, (result (P2 _ _ _) (oy.move_left iy) (oy.move_right jy) ox).2
    (oy.left_lt_right iy jy),

  refine ⟨_, _, _⟩,

  -- Prove all left options of `x * y` are less than the right options.
  { rintro (⟨ix, iy⟩ | ⟨jx, jy⟩) (⟨ix', jy'⟩ | ⟨jx', iy'⟩),
    { rcases lt_or_equiv_or_gt (xL ix) (xL ix') with h | h | h,
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix' * yL iy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply (HR₁.2 h).1 },
        have H₂ : ⟦xL ix' * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix' * yL iy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply HS₂.1 },
        exact lt_trans HN₁ HN₁ H₁ H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦xL ix * _⟧ = ⟦xL ix' * _⟧ := quot.sound (HR₁.1 h),
        have H₂ : ⟦xL ix * yR jy'⟧ = ⟦xL ix' * yR jy'⟧ := quot.sound
          ((result (P2 _ _ _) (ox.move_left ix) (ox.move_left ix') (oy.move_right jy')).1 h),
        rw [H₁, ←H₂, sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
        apply HS₂.1 },
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xL ix * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply HS₂.1 },
        have H₂ : ⟦xL ix * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix * yR jy'⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply (HR₁.2 h).2 },
        exact lt_trans HN₁ HN₃ H₁ H₂ } },
    { rcases lt_or_equiv_or_gt (yL iy) (yL iy') with h | h | h,
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xL ix * y⟧ + ⟦x * yL iy'⟧ - ⟦xL ix * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply (HR₂.2 h).1 },
        have H₂ : ⟦xL ix * y⟧ + ⟦x * yL iy'⟧ - ⟦xL ix * yL iy'⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply HS₁.1 },
        exact lt_trans HN₁ HN₁ H₁ H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦x * yL iy⟧ = ⟦x * yL iy'⟧,
        { rw quot_mul_comm₂,
          exact quot.sound (HR₂.1 h) },
        have H₂ : ⟦xR jx' * yL iy⟧ = ⟦xR jx' * yL iy'⟧,
        { rw quot_mul_comm₂,
          exact quot.sound
            ((result (P2 _ _ _) (oy.move_left iy) (oy.move_left iy') (ox.move_right jx')).1 h) },
        rw [H₁, ←H₂, sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
        apply HS₁.1 },
      { have H₁ : ⟦xL ix * y⟧ + ⟦x * yL iy⟧ - ⟦xL ix * yL iy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy⟧ - ⟦xR jx' * yL iy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply HS₁.1 },
        have H₂ : ⟦xR jx' * y⟧ + ⟦x * yL iy⟧ - ⟦xR jx' * yL iy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply (HR₂.2 h).2 },
        exact lt_trans HN₁ HN₄ H₁ H₂ } },
    -- These are pretty similar to the previous cases in inverse, just changing `L` with `R`.
    { rcases lt_or_equiv_or_gt (yR jy') (yR jy) with h | h | h,
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xR jx * y⟧ + ⟦x * yR jy'⟧ - ⟦xR jx * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply (HR₄.2 h).2 },
        have H₂ : ⟦xR jx * y⟧ + ⟦x * yR jy'⟧ - ⟦xR jx * yR jy'⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply HS₁.2 },
        exact lt_trans HN₂ HN₂ H₁ H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦x * yR jy'⟧ = ⟦x * yR jy⟧,
        { rw quot_mul_comm₂,
          exact quot.sound (HR₄.1 h) },
        have H₂ : ⟦xL ix' * yR jy'⟧ = ⟦xL ix' * yR jy⟧,
        { rw quot_mul_comm₂,
          exact quot.sound
            ((result (P2 _ _ _) (oy.move_right jy') (oy.move_right jy) (ox.move_left ix')).1 h) },
        rw [H₁, H₂, sub_lt_sub_iff, add_add_lt_cancel_mid],
        apply HS₁.2 },
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy⟧ - ⟦xL ix' * yR jy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply HS₁.2 },
        have H₂ : ⟦xL ix' * y⟧ + ⟦x * yR jy⟧ - ⟦xL ix' * yR jy⟧ <
          ⟦xL ix' * y⟧ + ⟦x * yR jy'⟧ - ⟦xL ix' * yR jy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, add_comm₂, quot_mul_comm₄],
          apply (HR₄.2 h).1 },
        exact lt_trans HN₂ HN₃ H₁ H₂ } },
    { rcases lt_or_equiv_or_gt (xR jx') (xR jx) with h | h | h,
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx' * yR jy⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid],
          apply (HR₃.2 h).2 },
        have H₂ : ⟦xR jx' * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx' * yR jy⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply HS₂.2 },
        exact lt_trans HN₂ HN₂ H₁ H₂ },
      { change (⟦_⟧ : game) < ⟦_⟧, dsimp,
        have H₁ : ⟦xR jx' * _⟧ = ⟦xR jx * _⟧ := quot.sound (HR₃.1 h),
        have H₂ : ⟦xR jx' * yL iy'⟧ = ⟦xR jx * yL iy'⟧ := quot.sound
          ((result (P2 _ _ _) (ox.move_right jx') (ox.move_right jx) (oy.move_left iy')).1 h),
        rw [H₁, H₂, sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
        apply HS₂.2 },
      { have H₁ : ⟦xR jx * y⟧ + ⟦x * yR jy⟧ - ⟦xR jx * yR jy⟧ <
          ⟦xR jx * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_left, quot_mul_comm₄],
          apply HS₂.2 },
        have H₂ : ⟦xR jx * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx * yL iy'⟧ <
          ⟦xR jx' * y⟧ + ⟦x * yL iy'⟧ - ⟦xR jx' * yL iy'⟧,
        { rw [sub_lt_sub_iff, add_add_lt_cancel_mid, add_comm₂],
          apply (HR₃.2 h).1 },
        exact lt_trans HN₂ HN₄ H₁ H₂ } } },

  -- Prove that all options of `x * y` are numeric.
  { rintro (⟨ix, iy⟩ | ⟨jx, jy⟩),
    { exact HN₁ },
    { exact HN₂ } },
  { rintro (⟨ix, jy⟩ | ⟨jx, iy⟩),
    { exact HN₃ },
    { exact HN₄ } }
end
| (P2 ⟨x₁l, x₁r, x₁L, x₁R⟩ ⟨x₂l, x₂r, x₂L, x₂R⟩ ⟨yl, yr, yL, yR⟩) := begin
  let x₁ : pgame := ⟨x₁l, x₁r, x₁L, x₁R⟩,
  let x₂ : pgame := ⟨x₂l, x₂r, x₂L, x₂R⟩,
  let y  : pgame := ⟨yl, yr, yL, yR⟩,

  -- Prove that if `x₁ ≈ x₂`, then `x₁ * y ≈ x₂ * y`.
  refine λ ox₁ ox₂ oy, ⟨λ h, ⟨le_def_lt.2 ⟨_, _⟩, le_def_lt.2 ⟨_, _⟩⟩, _⟩,
  { rintro (⟨ix₁, iy⟩ | ⟨jx₁, jy⟩);
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yL iy)) ox₁ ox₂ (oy.move_left iy)).1 h),
      rw [sub_lt_iff_lt_add, H, add_comm₂],
      apply ((result (P2 _ _ _) (ox₁.move_left ix₁) ox₂ oy).2
        (lt_of_lt_of_le (move_left_lt ix₁) h.1)).1 },
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yR jy)) ox₁ ox₂ (oy.move_right jy)).1 h),
      rw [sub_lt_iff_lt_add, H],
      apply ((result (P2 _ _ _) ox₂ (ox₁.move_right jx₁) oy).2
        (lt_of_le_of_lt h.2 (lt_move_right jx₁))).2 } },
  { rintro (⟨ix₂, jy⟩ | ⟨jx₂, iy⟩);
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yR jy)) ox₁ ox₂ (oy.move_right jy)).1 h),
      rw [lt_sub_iff_add_lt, ←H],
      apply ((result (P2 _ _ _) (ox₂.move_left ix₂) ox₁ oy).2
        (lt_of_lt_of_le (move_left_lt ix₂) h.2)).2 },
    { have H : ⟦x₁ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yL iy)) ox₁ ox₂ (oy.move_left iy)).1 h),
      rw [lt_sub_iff_add_lt, ←H, add_comm₂],
      apply ((result (P2 _ _ _) ox₁ (ox₂.move_right jx₂) oy).2
        (lt_of_le_of_lt h.1 (lt_move_right jx₂))).1 } },
  -- These are just the same but with `x₁` and `x₂` swapped.
  { rintro (⟨ix₂, iy⟩ | ⟨jx₂, jy⟩);
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yL iy)) ox₂ ox₁ (oy.move_left iy)).1 h.symm),
      rw [sub_lt_iff_lt_add, H, add_comm₂],
      apply ((result (P2 _ _ _) (ox₂.move_left ix₂) ox₁ oy).2
        (lt_of_lt_of_le (move_left_lt ix₂) h.2)).1 },
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yR jy)) ox₂ ox₁ (oy.move_right jy)).1 h.symm),
      rw [sub_lt_iff_lt_add, H],
      apply ((result (P2 _ _ _) ox₁ (ox₂.move_right jx₂) oy).2
        (lt_of_le_of_lt h.1 (lt_move_right jx₂))).2 } },
  { rintro (⟨ix₁, jy⟩ | ⟨jx₁, iy⟩);
    change (⟦_⟧ : game) < ⟦_⟧; dsimp,
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yR jy)) ox₂ ox₁ (oy.move_right jy)).1 h.symm),
      rw [lt_sub_iff_add_lt, ←H],
      apply ((result (P2 _ _ _) (ox₁.move_left ix₁) ox₂ oy).2
        (lt_of_lt_of_le (move_left_lt ix₁) h.1)).2 },
    { have H : ⟦x₂ * _⟧ = ⟦_⟧ :=
        quot.sound ((result (P2 _ _ (yL iy)) ox₂ ox₁ (oy.move_left iy)).1 h.symm),
      rw [lt_sub_iff_add_lt, ←H, add_comm₂],
      apply ((result (P2 _ _ _) ox₂ (ox₁.move_right jx₁) oy).2
        (lt_of_le_of_lt h.2 (lt_move_right jx₁))).1 } },

  -- Deduce numeric games from inductive hypothesis.
  have HN₁ := result (P1 x₁ y) ox₁ oy,
  have HN₂ := result (P1 x₂ y) ox₂ oy,

  intro h;
  rcases lt_def_le.1 h with ⟨ix₂, h⟩ | ⟨j, h⟩;
  cases lt_or_equiv_of_le h with h h,
  { have H₁ := (result (P2 _ _ _) ox₁ (ox₂.move_left ix₂) oy).2 h,
    have H₂ := HN₂.left_lt_right,
  }
end
using_well_founded { dec_tac := sorry }

end mul_args

theorem numeric_mul {x y : pgame} : numeric x → numeric y → numeric (x * y) :=
(mul_args.P1 x y).result

theorem mul_congr_left {x₁ x₂ y : pgame} (ox₁ : numeric x₁) (ox₂ : numeric x₂) (oy : numeric y) :
  x₁ ≈ x₂ → x₁ * y ≈ x₂ * y :=
((mul_args.P2 x₁ x₂ y).result ox₁ ox₂ oy).1

theorem mul_congr_right {x y₁ y₂ : pgame} (ox : numeric x) (oy₁ : numeric y₁) (oy₂ : numeric y₂)
  (h : y₁ ≈ y₂) : x * y₁ ≈ x * y₂ :=
pgame.equiv_trans (mul_comm_equiv _ _)
  (pgame.equiv_trans (mul_congr_left oy₁ oy₂ ox h) (mul_comm_equiv _ _))

theorem mul_congr {x₁ x₂ y₁ y₂ : pgame} (ox₁ : numeric x₁) (ox₂ : numeric x₂) (oy₁ : numeric y₁)
  (oy₂ : numeric y₂) (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ * y₁ ≈ x₂ * y₂ :=
pgame.equiv_trans (mul_congr_left ox₁ ox₂ oy₁ hx) (mul_congr_right ox₂ oy₁ oy₂ hy)

end pgame

namespace surreal

/-- Multiplication of surreal numbers is inherited from pre-game multiplication: the product of
`x = {xL | xR}` and `y = {yL | yR}` is
`{xL*y + x*yL - xL*yL, xR*y + x*yR - xR*yR | xL*y + x*yR - xL*yR, x*yL + xR*y - xR*yL }`. -/
def mul : surreal → surreal → surreal :=
surreal.lift₂
  (λ x y ox oy, ⟦⟨x * y, pgame.numeric_mul ox oy⟩⟧)
  (λ _ _ _ _ ox₁ oy₁ ox₂ oy₂ hx hy, quotient.sound (pgame.mul_congr ox₁ ox₂ oy₁ oy₂ hx hy))

instance : has_mul surreal := ⟨mul⟩

end surreal

-- We conclude with some ideas for further work on surreals; these would make fun projects.

-- TODO define the inclusion of groups `surreal → game`
-- TODO define the field structure on the surreals
