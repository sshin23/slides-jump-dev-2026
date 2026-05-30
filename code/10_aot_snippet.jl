module MySolve
using ExaModels, NLPModelsIpoptLite
function (@main)(ARGS)
    N = 100
    core = ExaCore(concrete = Val(true))
    @add_var(core, x, N; start = (isodd(i) ? -1.2 : 1.0 for i = 1:N))
    @add_obj(core, 100*(x[i+1] - x[i]^2)^2 + (1 - x[i])^2 for i = 1:N-1)
    result = ipopt(ExaModel(core); print_level = 0)
    println(Core.stdout, "status = ", result.status)
    return result.status == 0 ? 0 : 1
end
end # module
