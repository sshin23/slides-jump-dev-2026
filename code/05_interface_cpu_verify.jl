## CPU-backend verification of slide 5 (JuMP Interface).
## Slide displays CUDABackend(); this swaps to the CPU backend so we can run
## locally without a GPU. The user-facing API surface is identical.

using JuMP, ExaModels, NLPModelsIpopt, MadNLP

# Build the JuMP model
N = 100
jm = Model()
@variable(jm, x[i=1:N], start = isodd(i) ? -1.2 : 1.0)
@objective(jm, Min, sum(100*(x[i+1] - x[i]^2)^2 + (1 - x[i])^2 for i = 1:N-1))

# Path 1 --- Direct conversion to an ExaModel
em = ExaModel(jm)              # CPU backend (default)
result = madnlp(em)
@info "Path 1 OK" status = result.status iter = result.iter objective = result.objective

# Path 2 --- ExaModels as a JuMP optimizer
jm2 = Model()
@variable(jm2, y[i=1:N], start = isodd(i) ? -1.2 : 1.0)
@objective(jm2, Min, sum(100*(y[i+1] - y[i]^2)^2 + (1 - y[i])^2 for i = 1:N-1))
set_optimizer(jm2, () -> ExaModels.Optimizer(MadNLP.madnlp))
optimize!(jm2)
@info "Path 2 OK" termination_status = termination_status(jm2) objective_value = objective_value(jm2)
