import measure_theory.measure.measure_space

/-!
-/

open_locale topological_space
open set function filter

namespace measure_theory

namespace measure

section basic

variables {X Y : Type*} [topological_space X] {m : measurable_space X}
  [topological_space Y] [t2_space Y] (μ : measure X)

class is_open_positive : Prop :=
(open_pos : ∀ (U : set X), is_open U → U.nonempty → μ U ≠ 0)

variables [is_open_positive μ] {s U : set X} {x : X}

lemma _root_.is_open.measure_ne_zero (hU : is_open U) (hne : U.nonempty) : μ U ≠ 0 :=
is_open_positive.open_pos U hU hne

lemma _root_.is_open.measure_pos (hU : is_open U) (hne : U.nonempty) : 0 < μ U :=
(hU.measure_ne_zero μ hne).bot_lt

lemma _root_.is_open.measure_pos_iff (hU : is_open U) : 0 < μ U ↔ U.nonempty :=
⟨λ h, ne_empty_iff_nonempty.1 $ λ he, h.ne' $ he.symm ▸ measure_empty, hU.measure_pos μ⟩

lemma _root_.is_open.measure_eq_zero_iff (hU : is_open U) : μ U = 0 ↔ U = ∅ :=
by simpa only [not_lt, nonpos_iff_eq_zero, not_nonempty_iff_eq_empty]
  using not_congr (hU.measure_pos_iff μ)

lemma measure_pos_of_nonempty_interior (h : (interior s).nonempty) : 0 < μ s :=
(is_open_interior.measure_pos μ h).trans_le (measure_mono interior_subset)

lemma measure_pos_of_mem_nhds (h : s ∈ 𝓝 x) : 0 < μ s :=
measure_pos_of_nonempty_interior _ ⟨x, mem_interior_iff_mem_nhds.2 h⟩

variable {μ}

lemma _root_.is_open.eq_empty_of_measure_zero (hU : is_open U) (h₀ : μ U = 0) :
  U = ∅ :=
(hU.measure_eq_zero_iff μ).mp h₀

lemma interior_eq_empty_of_null (hs : μ s = 0) : interior s = ∅ :=
is_open_interior.eq_empty_of_measure_zero $ measure_mono_null interior_subset hs

/-- If two functions are a.e. equal on an open set and are continuous on this set, then they are
equal on this set. -/
lemma eq_on_open_of_ae_eq {f g : X → Y} (h : f =ᵐ[μ.restrict U] g) (hU : is_open U)
  (hf : continuous_on f U) (hg : continuous_on g U) :
  eq_on f g U :=
begin
  replace h := ae_imp_of_ae_restrict h,
  simp only [eventually_eq, ae_iff, not_imp] at h,
  have : is_open (U ∩ {a | f a ≠ g a}),
  { refine is_open_iff_mem_nhds.mpr (λ a ha, inter_mem (hU.mem_nhds ha.1) _),
    rcases ha with ⟨ha : a ∈ U, ha' : (f a, g a) ∈ (diagonal Y)ᶜ⟩,
    exact (hf.continuous_at (hU.mem_nhds ha)).prod_mk_nhds (hg.continuous_at (hU.mem_nhds ha))
      (is_closed_diagonal.is_open_compl.mem_nhds ha') },
  replace := (this.eq_empty_of_measure_zero h).le,
  exact λ x hx, not_not.1 (λ h, this ⟨hx, h⟩)
end

/-- If two continuous functions are a.e. equal, then they are equal. -/
lemma eq_of_ae_eq {f g : X → Y} (h : f =ᵐ[μ] g) (hf : continuous f) (hg : continuous g) : f = g :=
suffices eq_on f g univ, from funext (λ x, this trivial),
eq_on_open_of_ae_eq (ae_restrict_of_ae h) is_open_univ hf.continuous_on hg.continuous_on

lemma eq_on_of_ae_eq {f g : X → Y} (h : f =ᵐ[μ.restrict s] g) (hf : continuous_on f s)
  (hg : continuous_on g s) (hU : s ⊆ closure (interior s)) :
  eq_on f g s :=
have interior s ⊆ s, from interior_subset,
(eq_on_open_of_ae_eq (ae_restrict_of_ae_restrict_of_subset this h) is_open_interior
  (hf.mono this) (hg.mono this)).of_subset_closure hf hg this hU

end basic

section linear_order

variables {X Y : Type*} [topological_space X] [linear_order X] [order_topology X]
  {m : measurable_space X} [topological_space Y] [t2_space Y] (μ : measure X)
  [is_open_positive μ]

lemma measure_Ioi_pos [no_max_order X] (a : X) : 0 < μ (Ioi a) :=
is_open_Ioi.measure_pos μ nonempty_Ioi

lemma measure_Iio_pos [no_min_order X] (a : X) : 0 < μ (Iio a) :=
is_open_Iio.measure_pos μ nonempty_Iio

lemma measure_Ioo_pos [densely_ordered X] {a b : X} : 0 < μ (Ioo a b) ↔ a < b :=
(is_open_Ioo.measure_pos_iff μ).trans nonempty_Ioo

lemma measure_Ioo_eq_zero [densely_ordered X] {a b : X} : μ (Ioo a b) = 0 ↔ b ≤ a :=
(is_open_Ioo.measure_eq_zero_iff μ).trans (Ioo_eq_empty_iff.trans not_lt)

lemma eq_on_Ioo_of_ae_eq {a b : X} {f g : X → Y} (hfg : f =ᵐ[μ.restrict (Ioo a b)] g)
  (hf : continuous_on f (Ioo a b)) (hg : continuous_on g (Ioo a b)) : eq_on f g (Ioo a b) :=
eq_on_of_ae_eq hfg hf hg Ioo_subset_closure_interior

lemma eq_on_Ioc_of_ae_eq [densely_ordered X] {a b : X} {f g : X → Y}
  (hfg : f =ᵐ[μ.restrict (Ioc a b)] g) (hf : continuous_on f (Ioc a b))
  (hg : continuous_on g (Ioc a b)) : eq_on f g (Ioc a b) :=
eq_on_of_ae_eq hfg hf hg (Ioc_subset_closure_interior _ _)

lemma eq_on_Ico_of_ae_eq [densely_ordered X] {a b : X} {f g : X → Y}
  (hfg : f =ᵐ[μ.restrict (Ico a b)] g) (hf : continuous_on f (Ico a b))
  (hg : continuous_on g (Ico a b)) : eq_on f g (Ico a b) :=
eq_on_of_ae_eq hfg hf hg (Ico_subset_closure_interior _ _)

lemma eq_on_Icc_of_ae_eq [densely_ordered X] {a b : X} (hne : a ≠ b) {f g : X → Y}
  (hfg : f =ᵐ[μ.restrict (Icc a b)] g) (hf : continuous_on f (Icc a b))
  (hg : continuous_on g (Icc a b)) : eq_on f g (Icc a b) :=
eq_on_of_ae_eq hfg hf hg (Icc_subset_closure_interior hne)

end linear_order

end measure

end measure_theory
