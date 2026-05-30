## Slide 11 (Trade-off) timing verifier. Runs the @time sequence shown
## on the slide. The first build is the COLD compile (deps already
## loaded via the warmup), the second build hits the cache, and the
## third build is a DIFFERENT algebraic pattern that triggers a fresh
## compile of similar cost.
##
## Run after the JuMP+ExaModels environment is fully loaded. Paste the
## measured timings into code/11_recompile_repl.txt.

using ExaModels

include("11_build_v1.jl")
include("11_build_v2.jl")

# warmup: load deps + pre-trigger any first-time codegen for the package
build_v1(10); build_v2(10)

println("\njulia> @time em = build_v1(1000);   # 1st call: fresh pattern compile")
@time em = build_v1(1000);

println("\njulia> @time em = build_v1(1000);   # 2nd call: pattern cached, no recompile")
@time em = build_v1(1000);

println("\njulia> @time em = build_v2(1000);   # different pattern: fresh compile")
@time em = build_v2(1000);
