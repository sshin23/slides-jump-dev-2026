function build_v1(N)
    core = ExaCore(concrete = Val(true))
    @add_var(core, x, N)
    @add_obj(core,
        x[i]^2 for i = 1:N)
    return ExaModel(core)
end
