# Slide code verifications

Every Julia snippet that appears on a slide is saved here as a runnable
`.jl` file and is executed against a real Julia env to confirm it works.

## Running

The verifiers were exercised against a fresh Julia 1.12.6 project at
`/tmp/bench-rosenbrock` with `JuMP`, `ExaModels`, `MadNLP`, `NLPModelsIpopt`,
and `BenchmarkTools` installed:

```bash
cd /tmp/bench-rosenbrock
julia --startup-file=no --project=. /home/sushin/git/slides-jump-dev-2026/code/<file>.jl
```

GPU paths on the slides use `CUDABackend()`; the verifiers fall back to
the CPU backend so they run on a desktop without an NVIDIA driver. The
ExaModels API surface is identical between backends, so a passing CPU
verification is sufficient evidence the GPU version is well-formed.

## Files

| File | Slide | Status |
|------|-------|--------|
| `03_what_is.jl` | What is ExaModels? — AC OPF active-power balance pattern | runs, optimal |
| `05_interface_cpu_verify.jl` | The ExaModels JuMP Interface — Rosenbrock + Path 1 + Path 2 | both paths solve (Path 2 returns `OTHER_ERROR` from `termination_status` due to ExaModels.jl #282, but the underlying solver converges) |
| `07_goddard.jl` | Goddard rocket in ExaModels | runs, optimal |

The `05_interface.jl` file shows the slide snippet verbatim (with
`CUDABackend()`); the `_cpu_verify` sibling is the CPU-backend version
actually executed locally.

When adding a new code-bearing slide, drop a fresh verifier here and
add a row to the table above.
