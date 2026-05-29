## Slide 5 (The ExaModels JuMP Interface): JuMP Rosenbrock + Path 1 + Path 2.
## Verifies the snippet displayed on the slide actually runs end-to-end.

using JuMP, ExaModels, CUDA, MadNLP, MadNLPGPU

# Build the JuMP model
N = 100
jm = Model()
@variable(jm, x[i=1:N], start = isodd(i) ? -1.2 : 1.0)
@objective(jm, Min, sum(100*(x[i+1] - x[i]^2)^2 + (1 - x[i])^2 for i = 1:N-1))

# Path 1 --- Direct conversion to an ExaModel
em = ExaModel(jm; backend = CUDABackend())
result = madnlp(em)
@info "Path 1 OK" status = result.status iter = result.iter

# Path 2 --- ExaModels as a JuMP optimizer
set_optimizer(jm, () -> ExaModels.Optimizer(MadNLP.madnlp, CUDABackend()))
optimize!(jm)
@info "Path 2 OK" termination_status = termination_status(jm) objective = objective_value(jm)
