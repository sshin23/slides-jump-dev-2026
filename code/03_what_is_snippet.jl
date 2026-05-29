core = ExaCore(backend = CUDABackend())

@add_con(core, cp,
    b.pd + b.gs*vm[b.i]^2 for b in bus)
@add_con!(core, cp,
    a.bus =>  p[a.i]  for a in arc)
@add_con!(core, cp,
    g.bus => -pg[g.i] for g in gen)

em = ExaModel(core)
result = madnlp(em)
