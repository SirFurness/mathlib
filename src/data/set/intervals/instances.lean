import data.set.intervals.basic
import algebra.order.ring
import algebra.group_power.order

open set

/-- Instances for `(Icc 0 1)` -/

instance {α : Type*} [ordered_semiring α] : monoid (Icc (0:α) 1) := {
  mul := λ p q, ⟨p*q, ⟨mul_nonneg p.2.1 q.2.1, mul_le_one p.2.2 q.2.1 q.2.2⟩⟩,
  mul_assoc := λ p q r, subtype.mk_eq_mk.2 (mul_assoc p q r),
  one := ⟨1, right_mem_Icc.2 zero_le_one⟩,
  one_mul := λ p, (by simp only [subtype.coe_mk, one_mul, subtype.coe_eta]),
  mul_one := λ p, (by simp only [subtype.coe_mk, mul_one, subtype.coe_eta]),
  npow := λ n p, ⟨p.1 ^ n, ⟨pow_nonneg p.2.1 n, pow_le_one n p.2.1 p.2.2⟩⟩,
  npow_zero' := λ p, (by simp [has_one.one]),
  npow_succ' := λ n p, (by {simp only [pow_succ p.val n], refl}) }

instance {α : Type*} [ordered_comm_semiring α] : comm_monoid_with_zero (Icc (0:α) 1) :=
{ mul_comm :=
  begin
    exact λ p q, subtype.mk_eq_mk.2 (mul_comm _ _),
  end,
  zero := ⟨0, left_mem_Icc.2 zero_le_one⟩,
  zero_mul :=
  begin
    rintros ⟨p1, ⟨_,_⟩⟩,
    have : (⟨0 * p1, _⟩ : (Icc (0:α) 1)) = ⟨0, _⟩ * ⟨p1, _⟩, { refl },
    rw ←this,
    simp only [zero_mul],
  end,
  mul_zero :=
  begin
    rintros ⟨p1, ⟨_,_⟩⟩,
    have : (⟨p1 * 0, _⟩ : (Icc (0:α) 1)) = ⟨p1, _⟩ * ⟨0, _⟩, { refl },
    rw ←this,
    simp only [mul_zero],
  end,
  ..(show monoid (Icc (0:α) 1), by apply_instance) }


/-- Instances for `(Ico 0 1)` -/

instance {α : Type*} [ordered_semiring α] : semigroup (Ico (0:α) 1) := {
  mul :=
  begin
    refine λ p q, ⟨p*q, ⟨mul_nonneg p.2.1 q.2.1, _⟩⟩,
    rcases p with ⟨p1, ⟨_,_⟩⟩,
    rcases q with ⟨q1, ⟨_,_⟩⟩,
    apply mul_lt_one_of_nonneg_of_lt_one_right,
    exact le_of_lt p_property_right,
    repeat {assumption},
  end,

  mul_assoc := λ p q r, (by exact subtype.mk_eq_mk.2 (mul_assoc p q r)),
}

instance {α : Type*} [ordered_comm_semiring α] : comm_semigroup (Ico (0:α) 1) := {
  mul_comm :=
  begin
    refine λ p q, _,
    rcases p with ⟨p1, ⟨_,_⟩⟩,
    rcases q with ⟨q1, ⟨_,_⟩⟩,
    apply subtype.mk_eq_mk.2,
    simp only [subtype.coe_mk],
    exact mul_comm p1 q1,
  end,
  ..(show semigroup (Ico (0:α) 1), by apply_instance)
}


/-- Instances for `(Ioc 0 1)` -/

instance {α : Type*} [ordered_comm_semiring α] : comm_monoid (Ioc (0:α) 1) := {
  mul :=
begin
  refine λ p q, _,
  rcases p with ⟨p1, ⟨p21,p22⟩⟩,
  rcases q with ⟨q1, ⟨q21,q22⟩⟩,
  use p1*q1,
  simp only [mem_Ioc, canonically_ordered_comm_semiring.mul_pos],


  sorry,
end ,
  mul_assoc := sorry,
  one := sorry,
  one_mul := sorry,
  mul_one := sorry,
  npow := sorry,
  npow_zero' := sorry,
  npow_succ' := sorry,
  mul_comm := sorry }



/-- Instances for `(Ioo 0 1)` : `comm_semigroup (Ioo 0 1)` -/

instance {α : Type*} [ordered_comm_semiring α] : comm_semigroup (Ioo (0:α) 1) := {
  mul := sorry,
  mul_assoc := sorry,
  mul_comm := sorry }



/-- Instances for `(Icc (-1) 1)`: `comm_monoid_with_zero (Icc (-1) 1)` -/
instance {α : Type*} [ordered_comm_semiring α] :
  comm_monoid_with_zero (Icc (-1:α) 1) := {
  mul := sorry,
  mul_assoc := sorry,
  one := sorry,
  one_mul := sorry,
  mul_one := sorry,
  npow := sorry,
  npow_zero' := sorry,
  npow_succ' := sorry,
  mul_comm := sorry,
  zero := sorry,
  zero_mul := sorry,
  mul_zero := sorry }


/-- Instances for `(Ioc (-1) 1`: `comm_monoid_with_zero (Ioc (-1) 1` -/
instance {α : Type*} [ordered_comm_semiring α] [has_neg α] :
  comm_monoid_with_zero (Ioc (-1:α) 1) := {
  mul := sorry,
  mul_assoc := sorry,
  one := sorry,
  one_mul := sorry,
  mul_one := sorry,
  npow := sorry,
  npow_zero' := sorry,
  npow_succ' := sorry,
  mul_comm := sorry,
  zero := sorry,
  zero_mul := sorry,
  mul_zero := sorry }


/-- Instances for `(Ioo (-1) 1)`: `comm_semigroup_with_zero (Ioo (-1) 1)` -/
instance {α : Type*} [ordered_comm_semiring α] [has_neg α] :
  comm_semigroup (Ioo (-1:α) 1) := {
  mul := sorry,
  mul_assoc := sorry,
  mul_comm := sorry }



-- Yaël Dillies: What you really should do is provide `comm_monoid_with_zero (Icc 0 1)`. Then you'll get powers for free.  You can also do
-- `comm_semigroup_with_zero (Ico 0 1)`,
-- `comm_monoid (Ioc 0 1)`,
-- `comm_semigroup (Ioo 0 1)`,
-- `comm_monoid_with_zero (Icc (-1) 1)`,
-- `comm_monoid_with_zero (Ioc (-1) 1`,
-- `comm_semigroup_with_zero (Ioo (-1) 1)`,
-- and also provide `has_distrib_neg` instances where applicable.