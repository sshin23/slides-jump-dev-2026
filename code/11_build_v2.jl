function build_v2(N)
    core = ExaCore(concrete = Val(true))
    @add_var(core, x, N)
    @add_obj(core, x[i]^2 |+ sin(x[i])| for i = 1:N)
    return ExaModel(core)
end
