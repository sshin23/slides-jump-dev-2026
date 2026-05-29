# Slide code: snippets + verifiers

Every code-bearing slide pulls its code text from a `*_snippet.jl`
file via `\lstinputlisting` (single source of truth between slide
and file). A sibling `*.jl` or `*_verify.jl` wraps the snippet with
whatever setup is needed to actually run it.

## Conventions

- `<N>_<slide>_snippet.jl` — exact slide content; what the audience sees.
- `<N>_<slide>.jl` or `<N>_<slide>_verify.jl` — runnable wrapper that
  provides data/setup and calls into the snippet (or duplicates it
  with CPU backend for GPU snippets).
- GPU snippets show `CUDABackend()`; verifiers fall back to the
  default CPU backend on this desktop (no NVIDIA driver). The
  user-facing API surface is identical.

## Index

| Slide | Snippet (on slide via `\lstinputlisting`) | Runnable verifier | Verifier status |
|-------|-------------------------------------------|-------------------|-----------------|
| 3 — *What is ExaModels?* (OPF active-power balance) | `03_what_is_snippet.jl` | `03_what_is.jl` | runs, optimal |
| 5 — *JuMP Interface* (Rosenbrock + Path 1 + Path 2) | `05_interface_snippet.jl` | `05_interface_cpu_verify.jl` | both paths solve (Path 2 returns `OTHER_ERROR` for `termination_status` due to live ExaModels.jl #282, which the status-quo slide already calls out) |
| 7 — *Goddard rocket* (abbreviated showcase) | `07_goddard_snippet.jl` | `07_goddard.jl` (full unabbreviated) | runs, optimal |

The slide 3 and slide 7 snippets are abbreviated and won't run as
standalone files (slide 3 references conceptual `bus / arc / gen`
data; slide 7 elides `c2` / `c3` / boundaries with `...`). Their
verifiers cover the full picture.

## Running a verifier

```bash
cd /tmp/bench-rosenbrock                                       # JuMP+ExaModels+MadNLP+NLPModelsIpopt env
julia --startup-file=no --project=. \
  /home/sushin/git/slides-jump-dev-2026/code/<file>.jl
```

## Workflow for new slides

1. Write the snippet file with the exact slide content.
2. Write the verifier (wrap with setup, run, `@info` results).
3. Run the verifier. Fix until it passes.
4. Add `\lstinputlisting{code/<file>_snippet.jl}` to the slide.
5. Update this README's index.
