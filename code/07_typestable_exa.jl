core = ExaCore(concrete = Val(true))
@add_var(core, z, 2)
@add_obj(core,
    z[i]^2 + sin(z[i])*z[i+1] + cos(z[i+1]) for i = 1:1)
em = ExaModel(core)
