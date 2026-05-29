## Slide 6 (Model-build cost): the @btime invocation that produced the
## REPL transcript displayed on the slide (code/05_timing_repl.txt).
## Run this in an env with JuMP + ExaModels + BenchmarkTools to reproduce.

using JuMP, ExaModels, BenchmarkTools

# JuMP route: build a JuMP model, then bridge to an ExaModel.
function build_via_jump(N)
    jm = Model()
    @variable(jm, x[i=1:N], start = isodd(i) ? -1.2 : 1.0)
    @objective(jm, Min, sum(100*(x[i+1] - x[i]^2)^2 + (1 - x[i])^2 for i = 1:N-1))
    return ExaModel(jm)
end

# Native ExaModels: build the ExaCore directly.
function build_native(N)
    core = ExaCore(concrete = Val(true))
    @add_var(core, x, N; start = (isodd(i) ? -1.2 : 1.0 for i = 1:N))
    @add_obj(core, 100*(x[i+1] - x[i]^2)^2 + (1 - x[i])^2 for i = 1:(N-1))
    return ExaModel(core)
end

# warmup
let
    build_via_jump(10); build_native(10)
end

println("\njulia> @btime build_via_jump(10^5);")
@btime build_via_jump(10^5);

println("\njulia> @btime build_native(10^5);")
@btime build_native(10^5);
