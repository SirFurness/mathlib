/-
Copyright (c) 2022 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/
import tactic.move_add
import data.polynomial.degree.lemmas

/-! # `compute_degree` a tactic for compute `nat_degree`s of polynomials

This file defines two main tactics `compute_degree` and `compute_degree_le`.
Applied when the goal is of the form `f.nat_degree = d` or `f.nat_degree ≤ d`, they try to solve it.

See the corresponding doc-strings for more details.

##  Future work

* Add functionality to deal with exponents that are not necessarily natural numbers.
  It may not be hard to allow an option argument to be passed to `compute_degree` that would
  let the tactic know which one is the term of highest degree.  This would bypass the step
  where the exponents get sorted and may make it accessible to continue with the rest of the
  argument with minimal change.
* Add functionality to close `monic` goals and compute `leading_coeff`s.
* Add support for proving goals of the from `f.nat_degree ≠ 0`.
* Add support for `degree` (as opposed to just `nat_degree`).

##  Implementation details

We start with a goal of the form `f.nat_degree = d` (the case `f.nat_degree ≤ d` follows a similar,
easier pattern).

First, we focus on an elementary term of the polynomial `f` and we extract the degree in easy cases:
if `f` is
* `monomial n r`, then we guess `n`,
* `C a`, then we guess `0`,
* `polynomial.X`, then we guess `1`,
* `X ^ n`, then we guess `n`,
* everything else, then we guess `f.nat_degree`.
This happens in `extract_deg_single_term`.

Second, with input a product, we sum the guesses made above on each factor and add them up.
This happens in `extract_deg_single_summand`.

Third, we scan the summands of `f`, searching for one with highest guessed degree.  Here, if a
guess is not a closed term of type `ℕ`, the tactic fails.  This could be improved, but is not
currently in scope.  We return the first term with highest degree and the guessed degree.
This happens in `extract_top_degree_term_and_deg`.

Now, `compute_degree_le` chains together a few lemmas to conclude.  It guesses that the degree of a
sum of terms is at most the degree of each individual term.

_Heuristic:_ there is no cancellation among the terms, at least the ones of highest degree.

Finally, `compute_degree` takes one extra step.  It isolates the term of highest guessed degree
and assumes that all remaining terms have smaller degree.  It checks that the degree of the highest
term is what it is claimed (and further assumes that the highest term is a pure `X`-power, `X ^ n`,
a pure `X` term or a product of one of these by `C a` and checks that the assumption `a ≠ 0` is in
context).
`compute_degree` then outsources the rest of the computation to `compute_degree_le`, once the goal
has been appropriately replaced.

###  Error reporting
The tactics report that
* naturals involving variables are not allowed in exponents for `compute_deg`;
* when a simple lemma application would have sufficed (via a `Try this: ...`);
* when the guessed degree is incompatible with the goal, suggesting a sharper value.
-/

namespace polynomial
/-- Useful to expose easy hypotheses:
* `df` should be dealt with by `single_term_resolve`,
* `dg` should be dealt with by `compute_degree_le`.
-/
lemma nat_degree_add_left_succ {R : Type*} [semiring R] (n : ℕ) (f g : polynomial R)
  (df : f.nat_degree = n + 1) (dg : g.nat_degree ≤ n) :
  (g + f).nat_degree = n + 1 :=
by rwa nat_degree_add_eq_right_of_nat_degree_lt (dg.trans_lt (nat.lt_of_succ_le df.ge))

lemma nat_degree_bit0 {R : Type*} [semiring R] (a : polynomial R) :
  (bit0 a).nat_degree ≤ a.nat_degree :=
(nat_degree_add_le _ _).trans (by simp)

lemma nat_degree_bit1 {R : Type*} [semiring R] (a : polynomial R) :
  (bit1 a).nat_degree ≤ a.nat_degree :=
(nat_degree_add_le _ _).trans (by simp [nat_degree_bit0])

end polynomial

namespace tactic
namespace compute_degree
open expr

/--  If an expression `e` is an iterated suquence of `bit0` and `bit1` starting from `0` or `1`,
then `num_to_nat e` returns `some n`, where `n` is the natural number obtained from the same
sequence of `bit0` and `bit1` applied to `0` or `1`.  Otherwise, `num_to_nat e = none`. -/
-- for the application, the line `| `(has_zero.zero) := some 0` step is unnecessary: the standard
-- assumption is that the coefficient of the term of highest-looking term is non-zero.
meta def num_to_nat : expr → option ℕ
| `(has_zero.zero) := some 0
| `(has_one.one) := some 1
| `(bit0 %%a) := match num_to_nat a with
  | some an := some (bit0 an)
  | none := none
  end
| `(bit1 %%a) := match num_to_nat a with
  | some an := some (bit1 an)
  | none := none
  end
| _ := none

/--  `convert_num_to_C_num a` takes an expression `a`, assuming that it is a term in a polynomial
ring `R[X]`.  If `a` is an iterated application of `bit0` and `bit1` to `0` or `1`, then
`convert_num_to_C_num` produces a proof of the equality
`a = C (a : R)` and rewrites the goal with this identity.  Otherwise, the tactic does nothing. -/
meta def convert_num_to_C_num (a : expr) : tactic unit :=
match num_to_nat a with
| some an := do
  `(@polynomial %%R %%inst) ← infer_type a,
  n_eq_Cn ← to_expr ``(%%a = polynomial.C (%%an : %%R)),
  (_, nproof) ← solve_aux n_eq_Cn
    `[ simp only [nat.cast_bit1, nat.cast_bit0, nat.cast_one, C_bit1, C_bit0, map_one] ],
  rewrite_target nproof
| none := skip
end

/--  Let `e` be an expression.  Assume that `e` is
* `C a * X (^ n)`,
* `num * X (^ n)`, where `num` is a sequence of `bit0` and `bit1` applied to `1`,
* `monomial n a`,
* `X (^ n)`,
in a polynomial ring over `R`.
`single_term_resolve e` produces a proof of the goal `e.nat_degree = d`, where `d` is the
exponent of `X`.

Assumptions: the tactic tries to discharge the proof that constant in front of the power of `X` is
non-zero using `assumption <|> ...`.
When it is needed, `single_term_resolve` produces a `nontriviality` assumption using tactic
`nontriviality R` or fails. -/
meta def single_term_resolve : expr → tactic unit
| `(has_mul.mul %%a %%X) := do
  convert_num_to_C_num a,
  refine ``(polynomial.nat_degree_C_mul_X _ _) <|>
    refine ``(polynomial.nat_degree_C_mul_X_pow _ _ _) <|>
    fail "The leading term is not of the form\n`C a * X (^ n)`\n\n",
  assumption <|> interactive.exact ``(one_ne_zero) <|> skip
| (app `(⇑(@polynomial.monomial %%R %%inst %%n)) x) :=
  refine ``(polynomial.nat_degree_monomial_eq %%n _) *>
  assumption <|> interactive.exact ``(one_ne_zero) <|> skip
| (app `(⇑(@polynomial.C %%R %%inst)) x) :=
  interactive.exact ``(polynomial.nat_degree_C _)
--| `(has_pow.pow (@polynomial.X %%R %%inst) %%n) :=
--  (nontriviality_by_assumption R <|>
--    fail format!"could not produce a 'nontrivial {R}' assumption") >>
--  refine ``(polynomial.nat_degree_X_pow %%n)
| `(@has_pow.pow (@polynomial %%R %%nin) ℕ %%inst %%mX %%n) :=
  (nontriviality_by_assumption R <|>
    fail format!"could not produce a 'nontrivial {R}' assumption") >>
  refine ``(polynomial.nat_degree_X_pow %%n)
| `(@polynomial.X %%R %%inst) :=
  (nontriviality_by_assumption R <|>
    fail format!"could not produce a 'nontrivial {R}' assumption") >>
  interactive.exact ``(polynomial.nat_degree_X)
| e := do ppe ← pp e,
  fail format!"'{ppe}' is not a supported term: can you change it to `C a * X (^ n)`?\n
See the docstring of `tactic.compute_degree.single_term_resolve` for more shapes. "

/--
 `guess_degree e` assumes that `e` is a single summand of a polynomial and makes an attempt
 at guessing its degree.  It returns a closed natural number, via `expr.to_nat` or fails.
Currently, `guess_degree` supports:
* `monomial n r`,     guessing `n`,
* `C a`               guessing `0`,
*  `bit0 f, bit1 f`,  guessing `guess_degree f`,
                               (this could give wrong results, e.g. `bit0 f = 0` if the
                                characteristic of the ground ring is `2`),
* `polynomial.X`,     guessing `1`,
* `polynomial.X ^ n`, guessing `n`,
* `f * g`,            guessing `guess_degree f + guess_degree g`,
* on anything else it fails.
 -/
meta def guess_degree : expr → tactic ℕ
| `(has_zero.zero)         := return 0
| `(has_one.one)           := return 0
| `(bit0 %%a)              := guess_degree a
| `(bit1 %%a)              := guess_degree a
| `(has_mul.mul %%a %%b)   := do da ← guess_degree a, db ← guess_degree b,
                                return $ da + db
| `(polynomial.X)          := return 1
| (app `(⇑polynomial.C) x) := return 0
| `(polynomial.X ^ %%n)    := n.to_nat <|>
  fail format!"The exponent of 'X ^ {n}' is not a closed natural number"
| (app `(⇑(polynomial.monomial %%n)) x) := n.to_nat <|>
  fail format!"The exponent of 'monomial {n} {x}' is not a closed natural number"
| e                        := do ppe ← pp e, fail format!"cannot guess the degree of '{ppe}'"

/--  Similar to `guess_degree e`, except that it returns an `expr`.  It outputs ``(0)`, when
the heuristic for the guess fails. -/
meta def guess_degree_expr : expr → expr
| `(has_zero.zero)         := `(0)
| `(has_one.one)           := `(0)
| `(bit0 %%a)              := guess_degree_expr a
| `(bit1 %%a)              := guess_degree_expr a
| `(has_mul.mul %%a %%b)   := let da := guess_degree_expr a in let db := guess_degree_expr b in
                              expr.mk_app `(has_add.add : ℕ → ℕ → ℕ) [da, db]
| `(polynomial.X)          := `(1)
| (app `(⇑polynomial.C) x) := `(0)
| `(polynomial.X ^ %%n)    := n
| (app `(⇑(polynomial.monomial %%n)) x) := n
| e                        := `(0)

/--  Similar to `single_term_resolve`, but adapted to `f.nat_degree ≤ d`. -/
meta def single_term_resolve_le : expr → tactic unit
| `(%%a * %%Xp) := do
  let da  := guess_degree_expr a,
  let dXp := guess_degree_expr Xp,
  refine ``(polynomial.nat_degree_mul_le.trans ((add_le_add _ _).trans (_ : %%da + %%dXp ≤ _)))
| `(has_one.one) :=
   refine ``(polynomial.nat_degree_one.le.trans (nat.zero_le _))
| `(has_zero.zero) := refine ``(polynomial.nat_degree_zero.le.trans (nat.zero_le _))
| `(bit0 %%a) := do refine ``((polynomial.nat_degree_bit0 %%a).trans _),
  single_term_resolve_le a
| `(bit1 %%a) := do refine ``((polynomial.nat_degree_bit1 %%a).trans _),
  single_term_resolve_le a
| (app `(⇑(@polynomial.monomial %%R %%inst %%n)) x) :=
  refine ``((polynomial.nat_degree_monomial_le %%x).trans _)
| (app `(⇑polynomial.C) x) :=
  interactive.exact ``((polynomial.nat_degree_C _).le.trans (nat.zero_le _))
| `(@has_pow.pow (@polynomial %%R %%nin) ℕ %%inst %%mX %%n) :=
  refine ``((polynomial.nat_degree_X_pow_le %%n).trans _)
| `(polynomial.X) :=
  refine ``(polynomial.nat_degree_X_le.trans _)
| e := try `[norm_num] >> try assumption

/-- `extract_top_degree_term_and_deg e` takes an expression `e` looks for summands in `e`
(assuming the Type of `e` is `R[X]`), and produces the pairs `(e',deg)`, where `e'` is
a summand of `e` of maximal guessed degree equal to `deg`.

The tactic fails if `e` contains no summand (this probably means something else went wrong
somewhere else). -/
meta def extract_top_degree_term_and_deg (e : expr) : tactic (expr × ℕ) :=
do summ ← e.list_summands,
  nat_degs ← summ.mmap guess_degree,
  let summ_and_degs := summ.zip nat_degs in
  match summ_and_degs.argmax (λ e : expr × ℕ, e.2) with
  | none := fail
      "'`compute_degree`' could not find summands: something has gone very wrong!\n\n"
  | (some first) := let maxs := summ_and_degs.filter (λ f, f.2 = first.2) in
    if maxs.length ≠ 1 then do
      ppf ← pp $ maxs.map prod.fst,
      fail format!("the maximum degree '{first.2}' is guessed at the {maxs.length} terms\n" ++
      "{ppf}:\n\n" ++
      "'compute_degree' assumes that only one term has the top guessed degree\n")
    else return first
  end

/--  These are the cases in which an easy lemma computes the degree. -/
meta def single_term_suggestions : tactic unit := do
bo ← succeeds $ interactive.exact ``(polynomial.nat_degree_X_pow _),
if bo then fail "Try this: exact polynomial.nat_degree_X_pow _"
else do
bo ← succeeds $ interactive.exact ``(polynomial.nat_degree_C _),
if bo then fail "Try this: exact polynomial.nat_degree_C _"
else do
bo ← succeeds $ interactive.exact ``(polynomial.nat_degree_X),
if bo then fail "Try this: exact polynomial.nat_degree_X"
else do
bo ← succeeds $ interactive.exact ``(polynomial.nat_degree_C_mul_X_pow _ _ ‹_›),
if bo then fail "Try this: exact polynomial.nat_degree_C_mul_X_pow _ _ ‹_›"
else do
bo ← succeeds $ interactive.exact ``(polynomial.nat_degree_C_mul_X _ ‹_›),
if bo then fail "Try this: exact polynomial.nat_degree_C_mul_X _ ‹_›"
else
  fail "'compute_degree' works better with polynomials involving more than one term\n"

/--  `resolve_sum_step e` first checks that `e` is of the form `f.nat_degree ≤ d`,
failing otherwise.  Suppose that `e` has the desired form.
* If `f` is a sum of two terms, then `resolve_sum_step` splits off one summand from `f` using
  `nat_degree_add_le_iff_left`.
* Otherwise, `resolve_sum_step` tries to solve the goal using `single_term_resolve_le`.

In either case, there might be side-goals left of two different shapes:
* `f'.nat_degree ≤ d`, with `f'` having fewer terms than `f`;
* `m ≤ n`, where `m, n` are natural numbers.
-/
meta def resolve_sum_step : expr → tactic unit
| `(polynomial.nat_degree (%%tl1 + %%tl2) ≤ %%tr) := do
    refine ``((polynomial.nat_degree_add_le_iff_left _ _ _).mpr _)
| `(polynomial.nat_degree %%tl ≤ %%tr) := do
  single_term_resolve_le tl
| _ := failed

/--  `norm_assum` simply tries `norm_num` and `assumption`.  It is used to try to discharge as
many as possible of the side-goals of `compute_degree` and `compute_degree_le`, once they have
processed all the goals of the form `f.(nat_)degree ≤/= d`.
Such side-goals are all of the form `m ≤ n`, for natural numbers `m, n` or of the form
`a ≠ 0` with `a` is a coefficient of the polynomial `f` in question.
 -/
meta def norm_assum : tactic unit :=
try `[ norm_num ] >> try assumption

/--  If `check_deg_le tl tr` fails, then either at least one of the expressions `tl, tr` involves
a non-closed natural number, or the expected degree of `tl` is smaller than `tr`.  In either
case, failure means that we can proceed with the checking in `compute_degree_le`. -/
meta def check_deg_le (tl tr : expr) : tactic unit :=
do (_, m') ← extract_top_degree_term_and_deg tl,
  td ← eval_expr ℕ tr,
  if (m' ≤ td) then failed else trace sformat!"should the degree be {m'}?"

end compute_degree

namespace interactive
open compute_degree

/--  `compute_degree_le` tries to solve a goal of the form `f.nat_degree ≤ d`, where `d : ℕ` and `f`
satisfies:
* `f` is a sum of expression of the form
  `C a * X ^ n, C a * X, C a, X ^ n, X, monomial n a, monomial n a * monomial m b`,
* all exponents and the `n` in `monomial n a` are *closed* terms of type `ℕ`.
If the given degree is smaller than the one that the tactic computes,
then the tactic suggests the degree that it computed.

The tactic reports nothing if it is used with non-closed natural numbers as exponents. -/
meta def compute_degree_le : tactic unit :=
do try $ refine ``(polynomial.degree_le_nat_degree.trans (with_bot.coe_le_coe.mpr _)),
  `(polynomial.nat_degree %%tl ≤ %%tr) ← target |
    fail "Goal is not of the form\n`f.nat_degree ≤ d` or `f.degree ≤ d`",
  tactic.success_if_fail $ check_deg_le tl tr,  -- can `success_if_fail` fail with a custom message?
  repeat $ target >>= resolve_sum_step,
  try $ any_goals' norm_assum

/--  `compute_degree.with_lead lead` assumes that `lead` is an expression for the highest degree
term of a polynomial and proceeds to try to close a goal of the form
`f.nat_degree = d` or `f.degree = d`. -/
meta def _root_.tactic.compute_degree.with_lead (lead : expr) : tactic unit := do
move_op.with_errors ``((+)) [(ff, pexpr.of_expr lead)] none,
refine ``(polynomial.nat_degree_add_left_succ _ %%lead _ _ _) <|>
  single_term_suggestions,
single_term_resolve lead,
gs ← get_goals,
gts ← gs.mmap infer_type,
-- `is_ineq` is a list of tactics, one for each goal:
-- * if the goal has the form `f.nat_degree ≤ d`, the tactic is `compute_degree_le`
-- * otherwise, it is the tactic that tries `norm_num` and `assumption`
is_ineq ← gts.mmap (λ t : expr, do match t with
  | `(polynomial.nat_degree %%_ ≤ %%_) := return compute_degree_le
  | _                                  := return norm_assum end),
focus' is_ineq

setup_tactic_parser

/--  `compute_degree` tries to solve a goal of the form `f.nat_degree = d` or  `f.degree = d`,
where `d : ℕ` and `f` satisfies:
* `f` is a sum of expressions of the form
  `C a * X ^ n, C a * X, C a, X ^ n, X, monomial n a, monomial n a * monomial m b`;
* all exponents and the `n` in `monomial n a` are *closed* terms of type `ℕ`;
* the term with largest exponent is `C a * X ^ n, X ^ n, C a * X, X, C a` and is the unique term of
  its degree (repetitions are allowed in terms of smaller degree);
* if the leading term involves a product with `C a`, there must be in context the assumption
  `a ≠ 0`;
* if the goal is computing `degree`, instead of `nat_degree`, then the expected degree `d` should
  not be `⊥`.

If the given degree does not match what the tactic computes,
then the tactic suggests the degree that it computed.

You can also pass an optional argument to `compute_degree`, letting the tactic know which term is
the one of highest degree.  The syntax is `compute_degree [<expression for one term>]`.  The
expression can involve underscore, and Lean will try to unify them with one of the summands in the
goal.  This opens the possibility of working with polynomials whose exponents are not closed natural
numbers, though this is mostly unimplemented still.

The tactic also reports when it is used with non-closed natural numbers as exponents. -/
meta def compute_degree : parse opt_pexpr_list → tactic unit
| [] := do
is_deg ← succeeds $ refine ``((polynomial.degree_eq_iff_nat_degree_eq_of_pos _).mpr _) >>
  interactive.rotate,
`(polynomial.nat_degree %%tl = %%tr) ← target |
  fail "Goal is not of the form\n`f.nat_degree = d` or `f.degree = d`",
(lead,m') ← extract_top_degree_term_and_deg tl,
td ← eval_expr ℕ tr,
if m' ≠ td then do
  pptl ← pp tl, ppm' ← pp m',
  if is_deg then
    fail sformat!"should the degree be '{m'}'?"
  else
   fail sformat!"should the nat_degree be '{m'}'?"
else do tactic.compute_degree.with_lead lead
| [lead] := do `(polynomial.nat_degree %%tl = %%tr) ← target |
    fail "Goal is not of the form\n`f.nat_degree = d` or `f.degree = d`",
  tls ← tl.list_summands,
  lead ← to_expr lead,
  (lead :: hs) ← tls.mfilter $ λ e', succeeds $ unify lead e',
  tactic.compute_degree.with_lead lead
| _  := fail "'compute_degree' only accepts one leading term"

add_tactic_doc
{ name := "compute_degree_le",
  category := doc_category.tactic,
  decl_names := [`tactic.interactive.compute_degree],
  tags := ["arithmetic, finishing"] }

add_tactic_doc
{ name := "compute_degree",
  category := doc_category.tactic,
  decl_names := [`tactic.interactive.compute_degree],
  tags := ["arithmetic, finishing"] }

end interactive

end tactic
