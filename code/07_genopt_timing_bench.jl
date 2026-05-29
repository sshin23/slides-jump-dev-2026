## GenOpt timing verifier — measure model-build time for the SAME
## Rosenbrock problem used on the Model-build cost slide. Run in an env
## with JuMP + GenOpt + ExaModels + BenchmarkTools.
##
## GenOpt's `lazy_sum` doesn't accept index arithmetic like `x[i+1]`,
## so we pre-slice x into two static arrays x_a = x[1:N-1], x_b = x[2:N]
## and iterate with constant indices.

using JuMP, GenOpt, ExaModels, BenchmarkTools

function build_via_genopt(N)
    model = Model()
    @variable(model, x[i = 1:N], start = isodd(i) ? -1.2 : 1.0)
    x_a = collect(x[1:N-1])
    x_b = collect(x[2:N])
    @objective(model, Min,
        lazy_sum(100*(x_b[i] - x_a[i]^2)^2 + (1 - x_a[i])^2 for i in 1:N-1))
    return ExaModel(model)
end

let
    build_via_genopt(10)
end

println("\njulia> @btime build_via_genopt(10^5);")
@btime build_via_genopt(10^5);
