core = ExaCore(concrete = Val(true))
@add_var(core, x, N)
@add_obj(core,
    100*(x[i-1]^2 - x[i])^2 + (x[i-1] - 1)^2
    for i = 2:N)
em = ExaModel(core)
