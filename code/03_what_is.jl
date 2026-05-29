## Slide 3 (What is ExaModels?): AC OPF active-power balance pattern.
## The slide displays `core = ExaCore(backend = CUDABackend())`; this verifier
## uses the default CPU backend so it runs without a GPU. The user-facing API
## surface (templated @add_con + augmenting @add_con!) is exactly what the
## slide shows --- the data tuples below are a minimal stand-in for the
## PowerModels-parsed `data.bus / data.arc / data.gen` named tuples.

using ExaModels, NLPModelsIpopt

core = ExaCore()

# Toy 2-bus, 2-arc, 1-gen network — minimal data to exercise the pattern.
bus = [(i = 1, pd = 0.0, gs = 0.0), (i = 2, pd = 1.0, gs = 0.0)]
arc = [(i = 1, bus = 1), (i = 2, bus = 2)]
gen = [(i = 1, bus = 1)]

@add_var(core, vm, length(bus); start = 1.0, lvar = 0.9, uvar = 1.1)
@add_var(core, p,  length(arc); start = 0.0, lvar = -2.0, uvar = 2.0)
@add_var(core, pg, length(gen); start = 0.5, lvar = 0.0, uvar = 2.0)

# === The snippet displayed on slide 3 begins here ===========================
@add_con(core, cp,
    b.pd + b.gs*vm[b.i]^2 for b in bus)
@add_con!(core, cp,
    a.bus =>  p[a.i]  for a in arc)
@add_con!(core, cp,
    g.bus => -pg[g.i] for g in gen)

em = ExaModel(core)
result = ipopt(em)
# === end of slide snippet ===================================================

@info "OPF pattern OK" status = result.status iter = result.iter
