# my_solve.jl
using ExaModels, NLPModelsIpoptLite

Base.@ccallable function main()::Cint
    core = ExaCore(concrete = Val(true))
    @add_var(core, x, 100)
    @add_obj(core, x[i]^2 + sin(x[i]) for i = 1:100)
    ipopt(ExaModel(core))
    return 0
end
