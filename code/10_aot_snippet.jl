module MySolve

using ExaModels, NLPModelsIpoptLite

Base.@ccallable function julia_main()::Cint
    N = 100
    core = ExaCore(concrete = Val(true))
    @add_var(core, x, N;
        start = (isodd(i) ? -1.2 : 1.0 for i = 1:N))
    @add_obj(core,
        100*(x[i+1] - x[i]^2)^2 + (1 - x[i])^2 for i = 1:N-1)
    ipopt(ExaModel(core))
    return 0
end

end # module
