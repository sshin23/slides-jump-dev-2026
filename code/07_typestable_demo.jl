using JuMP, ExaModels

# JuMP: the same NL expression
jm = Model()
@variable(jm, x);  @variable(jm, y);
f = x^2 + sin(x)*y + cos(y)

@show typeof(f.args)            # ← type-erased; per-iter dispatch
@show eltype(f.args)

# ExaModels: the same expression as a pattern
core = ExaCore(concrete = Val(true))
@add_var(core, z, 2)
@add_obj(core, z[i]^2 + sin(z[i])*z[i+1] + cos(z[i+1]) for i = 1:1)
em = ExaModel(core)

@show typeof(em.objs[1].f.f)    # ← concrete parameterized tree; static dispatch
