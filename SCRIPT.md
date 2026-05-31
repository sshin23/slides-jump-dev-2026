# Speaker script — *Can ExaModels Power JuMP on GPUs?*

Target: ~15 minutes. Short sentences. Conversational.

---

## Slide 1 — Title

Hi everyone. I'm Sungho Shin from MIT. Today I'll talk about ExaModels,
and why aggressive typing is both a blessing and a curse. The question
in the title is: can ExaModels power JuMP on GPUs?

---

## Slide 2 — What is ExaModels?

So, what is ExaModels?

It's an algebraic modeling system, written in Julia. The syntax is
JuMP-inspired, so it should look familiar.

It builds on NLPModels.jl. That means it works with all the standard
JSO-style solvers: Ipopt, MadNLP, KNITRO, Uno.

It ships with its own automatic differentiation system. We compute the
objective, the constraints, the gradient, the Jacobian, and the Hessian
of the Lagrangian.

The killer feature is on the right. ExaModels is **GPU-compatible**. I'll
explain what that means in a minute.

One thing to flag up front: the design philosophy is not ease of use.
The goal is runtime performance. We want this to be the fastest modeling
system you can build optimization problems with.

The example on the right is the Goddard rocket problem. You can see the
syntax — `@add_var`, `@add_obj`, `@add_con`. That's it.

---

## Slide 3 — Why GPU-compatible modeling? (LP / QP / DCP)

Why do we even need a GPU-compatible modeling language?

For LP, QP, and convex programs in general, you don't really need one.

These problems have canonical forms. Just `A`, `b`, `c`, maybe a cone.
You copy that data to the GPU once. The solver runs entirely on the
device. The solution gets copied back once. The data transfer happens
at the boundary, and it's amortized over many solver iterations.

GPU-native solvers in this class already exist and work this way.
CuClarabel for conic. cuPDLP+ for LP. They're great.

So for LP, QP, DCP, a GPU-native modeling language doesn't really add
value.

---

## Slide 4 — Why GPU-compatible modeling? (NLP)

For nonlinear programs, the picture is different.

The solver doesn't just see `A`, `b`, `c`. At every iteration, it asks the
modeling layer to compute callbacks — the objective, the constraints,
their gradients, the Hessian — all at the current iterate.

These queries depend on the iterate. They change every iteration. So
there's no one-shot transfer.

If your callbacks live on the CPU, every iteration pays a CPU↔GPU
round-trip. That overhead is per-iteration. It doesn't amortize.

The point is: we don't need to move all of JuMP onto the GPU. We just
need the callbacks themselves to run on the device. That's the goal.

---

## Slide 5 — The ExaModels JuMP Interface: Status Quo

So how do you use ExaModels from JuMP today?

It's actually pretty simple. You build a JuMP model the normal way. Then
you wrap it: `ExaModel(jm; backend = CUDABackend())`. Or you set
ExaModels as the optimizer and pass it a backend.

This works. But it's an experimental feature, and it comes with caveats.
I'll explain the caveats next.

---

## Slide 6 — The cost is the JuMP → ExaModels conversion layer

Here's the issue. On the left, the JuMP route: build a JuMP Rosenbrock
model, then convert to ExaModel. On the right, native ExaModels.

Look at the timings. Native ExaModels builds in 309 microseconds. The
JuMP route takes 2.2 seconds. That's about 7,200 times slower. The
memory is 350 times worse.

And this gap grows with `N`.

The interesting part is *where* the cost is. ExaModels itself is already
faster than JuMP at modeling. But most of the overhead in `build_via_jump`
is not JuMP — it's the **conversion layer** from JuMP to ExaModels. Let me
show you why.

---

## Slide 7 — Where the gap comes from

When you build an expression in JuMP, it gets unrolled into a flat array.
That array is `Vector{Any}`. The element types are erased.

You can see it on the left. We pull the objective out of the MOI cache,
look at `args`, and the type is just `Vector{Any}`.

The conceptual picture is on the right. The bucket is the array. The
contents are clouds — we don't know what's in there at compile time.

The ExaModels–JuMP extension walks every node, infers its type, and
classifies it into an operator pattern — `x` squared, sine of `x`,
exponential of `x`, and so on. That per-node type inference is the
dominant cost. It's not the tree itself.

---

## Slide 8 — One remedy: piggyback on JuMP (GenOpt.jl)

One remedy is GenOpt.jl by Benoît Legat. The idea: use JuMP's own
extension hooks so the algebraic patterns never get unrolled.

There's a `ParametrizedArray` container for constraints. There's a
`lazy_sum` generator for the objective. With these, the structured
representation survives, and ExaModels reads it directly.

It's a minimal rewrite of the model. Just two keywords.

It's a really cool proof-of-concept. But I'll spend the next few slides
on a different angle.

---

## Slide 9 — ExaModels: the type IS the tree

Here's the design idea behind ExaModels. The type **is** the tree.

On the left, you see a small model and the REPL output. The type of the
objective is `Node2` of `+`, with nested `Node2`, `Node1`, `Var`,
`DataSource`. Every operator shows up in the type itself.

The picture on the right is the same thing, drawn out.

What this means: ExaModels encodes the algebraic structure directly into
Julia's type system. Just by looking at the type, you can read the
structure of the expression. And at compile time, the structure is fully
known. So model creation, AD, and evaluation can all be specialized for
this exact algebraic expression.

---

## Slide 10 — ExaModels: AD passes (same typed tree)

Both forward and reverse AD passes propagate through the same typed
tree. Forward in green, reverse in red.

Because the type carries the tree, both passes can be **compiled** for
this `Node2` type. At runtime, there's no type inference on the tree.

That's the design. Now let me show you what you get out of it.

---

## Slide 11 — Blessing: Portability and performance

First blessing: portability and performance.

The reason: the complexity of forming the expression tree is decoupled
from the array level. Within each data point, everything is scalar Julia.
Type-inferable. Pure.

The parallelism is just data-level. We hand it to KernelAbstractions.jl,
and the same code runs on `CPU()`, `CUDABackend()`, `ROCBackend()`,
`oneAPIBackend()`, `MetalBackend()`. Same model. Different hardware.

The plot shows AC OPF benchmarks. Jacobian and Hessian on CUDA and
AMDGPU reach over a hundred times speedup at around a million variables.
oneAPI on Arc A770 stays under one — but that's because fp64 is
emulated. Hardware, not software.

More benchmark results at SIAM Optimization 2026.

---

## Slide 12 — Blessing: AOT compile

Second blessing. Because everything is type-inferable at the
modeling-function level, we can compile the whole thing
ahead-of-time.

Here's a tiny module. It builds a Rosenbrock model and calls Ipopt. We
use Julia 1.12's `@main` entry point.

We pass it to `juliac --trim=safe`. We get a standalone executable. No
Julia runtime. Same as a C shared library.

The reason this works at all: the aggressive typing applies at the
whole `ExaModel` level, not just the expression tree.

---

## Slide 13 — Curse: compile-once per algebraic pattern

Now the curse.

On the right, three timed runs. Build `v1`. Build `v1` again, with
different `N`. Build `v2`, which has one extra `sin(x)` term.

First call: 88 milliseconds. About 99% of that is compilation.

Second call: 27 microseconds. The pattern is cached. We changed `N`, but
the algebraic pattern is the same. No recompile.

Third call: 94 milliseconds. Different pattern. Essentially everything
recompiles.

The pattern is the unit of caching. Change one term — recompile.

Why is the compile time so dominated? Aggressive typing plus full
inlining. The LLVM IR is one giant block for the typed `ExaModel`.

---

## Slide 14 — Alternative: ExaModels as a JuMP backend

So what could JuMP do?

Don't ask JuMP to be fully type-stable. That doesn't fit JuMP's broader
audience. The compile-per-pattern cost is too much.

Instead, give it a **small number of buckets**. Each bucket can be large
— but the number of buckets stays small. Inside each bucket, the
contents are fully typed and concrete.

About ten patterns of practical significance: linear, quadratic,
bilinear, polynomial-times-sine, polynomial-times-exp, and so on. Plus a
fallback bucket marked `Any` for anything else.

JuMP authors against these blocks. ExaModels dispatches statically on
the common patterns. The `Any` bucket keeps today's per-element inference
path.

The implication for JuMP: a move from purely interpreted construction
toward more typed-and-compiled. Good and bad. This is just an idea.

---

## Slide 15 — Summary

To wrap up.

ExaModels offers a SIMD abstraction for nonlinear programs. The model is
a pattern plus a data iterator.

Encoding the algebraic structure in the type buys us GPU-native
callbacks, portability across GPU backends, and AOT compilation.

The trade-off: all the burden goes onto the compiler. Great when patterns
are stable. Expensive when they change.

For the discussion: we don't need to move all of JuMP onto the GPU. The
win is GPU-native callbacks, eliminating the per-iteration round-trip. A
slightly more type-stable JuMP tree would make the bridge cheap.

I'll continue this thread at SIAM Optimization 2026 — "The State of
ExaModels", MS369, Friday June 5.

Thank you. Happy to take questions.
