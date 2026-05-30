# Can ExaModels Power JuMP on GPUs?

*Blessing and curse of aggressive typing*

[Sungho Shin](https://shin.mit.edu) (MIT) — **JuMP-dev 2026**, Edinburgh.

## Download

The latest PDF is published automatically from `master`:

**[Download slides (PDF)](https://sshin23.github.io/slides-jump-dev-2026/main.pdf)**

## Building locally

```bash
latexmk -pdf main.tex
```

LaTeX dependencies: TeX Live full, `beamer`, `tikz`, `tcolorbox`, `listings`,
`biblatex` + `biber`.

## Layout

- `main.tex` — the deck.
- `code/` — every code snippet shown on a slide is a runnable `.jl` (or
  `.txt` REPL transcript) here. Benchmark scripts that produced the
  measured timings end in `_bench.jl`.
- `figs/` — figures. The expression-tree and AD-pass diagrams are TikZ;
  source under `*_tikz.tex` with `*_standalone.tex` wrappers.
- `shin.bib` — references.
- `.github/workflows/build.yml` — CI that builds the PDF and publishes it
  to GitHub Pages on every push.

## Talks

- **JuMP-dev 2026** — this deck. Software side of ExaModels.jl: aggressive
  typing of the algebraic expression tree, GPU-native callbacks, AOT
  compilation, and the per-pattern compile-time cost that comes with it.
- **SIAM Optimization 2026** ("The State of ExaModels", MS369, Fri June 5,
  11:10 BST) — a separate deck, sister talk on design principles.

## Related

- [`ExaModels.jl`](https://github.com/exanauts/ExaModels.jl) — the package.
- [`MadNLP.jl`](https://github.com/MadNLP/MadNLP.jl) — primary solver.
- [`GenOpt.jl`](https://github.com/blegat/GenOpt.jl) — Benoît Legat's JuMP
  extension that piggybacks on `ParametrizedArray` + `lazy_sum` to preserve
  algebraic patterns into ExaModels.
