import group_theory.congruence
import algebra.module.basic
import algebra.free_monoid

/-!
# Tensor product of modules over semirings.

This file constructs the tensor product of modules over semirings. Given a semiring
`R` and modules over it `M` and `N`, the standard construction of the tensor product is
`tensor_product R M N`. It is also a module over `R`.

It comes with a canonical bilinear map `M → N → tensor_product R M N`.

Given any bilinear map `M → N → P`, there is a unique linear map `tensor_product R M N → P` whose
composition with the canonical bilinear map `M → N → tensor_product R M N` is the given bilinear
map `M → N → P`.

We start by proving basic lemmas about bilinear maps.

## Notations

This file uses the localized notation `M ⊗ N` and `M ⊗[R] N` for `tensor_product R M N`, as well
as `m ⊗ₜ n` and `m ⊗ₜ[R] n` for `tensor_product.tmul R m n`.

## Tags

bilinear, tensor, tensor product
-/

variables {R M N : Type*} [semiring R]
variables [add_comm_monoid M] [add_comm_monoid N]
variables [module Rᵒᵖ M] [module R N]

include R

variables (M N)

namespace tensor_product

section
-- open free_add_monoid
variables (R)

/-- The relation on `free_add_monoid (M × N)` that generates a congruence whose quotient is
the tensor product. -/
inductive eqv : free_add_monoid (M × N) → free_add_monoid (M × N) → Prop
| of_zero_left : ∀ n : N, eqv (free_add_monoid.of (0, n)) 0
| of_zero_right : ∀ m : M, eqv (free_add_monoid.of (m, 0)) 0
| of_add_left : ∀ (m₁ m₂ : M) (n : N), eqv
    (free_add_monoid.of (m₁, n) + free_add_monoid.of (m₂, n)) (free_add_monoid.of (m₁ + m₂, n))
| of_add_right : ∀ (m : M) (n₁ n₂ : N), eqv
    (free_add_monoid.of (m, n₁) + free_add_monoid.of (m, n₂)) (free_add_monoid.of (m, n₁ + n₂))
| of_smul : ∀ (r : R) (m : M) (n : N), eqv
    (free_add_monoid.of (m <• r, n)) (free_add_monoid.of (m, r • n))
| add_comm : ∀ x y, eqv (x + y) (y + x)
end

end tensor_product

variables (R)

/-- The tensor product of two modules `M` and `N` over the same commutative semiring `R`.
The localized notations are `M ⊗ N` and `M ⊗[R] N`, accessed by `open_locale tensor_product`. -/
def tensor_product : Type* :=
(add_con_gen (tensor_product.eqv R M N)).quotient

variables {R}

localized "infix ` ⊗ `:100 := tensor_product _" in tensor_product
localized "notation M ` ⊗[`:100 R `] `:0 N:100 := tensor_product R M N" in tensor_product
