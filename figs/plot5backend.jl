# 5-backend LV-suite scaling plot for Vex's SIAM modeling talk.
# Reads the 5 per-host CSVs that have LV ExaModels data, aggregates each
# AD-callback time by geometric mean over the LV problem set at each size
# tier, and renders a faceted log-log time-vs-nvar scaling figure.
# Backends: CUDA (Quadro GV100), AMDGPU (Radeon VII), oneAPI fp32, oneAPI
# fp64 (Intel Arc A770), CPU-8T.

using CSV, DataFrames, CairoMakie, Statistics

const RESDIR = joinpath(homedir(), "git/papers/exa-models-paper/benchmark/results")

# file => backend label  (order = legend/plot order)
const FILES = [
    "shin-compute-002_CPU-8T_fp64.csv"                              => "CPU (8 threads)",
    "shin-compute-001_CUDA-Quadro_GV100_fp64.csv"                   => "CUDA (Quadro GV100)",
    "shin-compute-002_AMDGPU-AMD_Radeon_VII_fp64.csv"               => "AMDGPU (Radeon VII)",
    "shin-compute-002_oneAPI-Intel(R)_Arc(TM)_A770_Graphics_fp64.csv" => "oneAPI fp64 (Arc A770)",
    "shin-compute-002_oneAPI-Intel(R)_Arc(TM)_A770_Graphics_fp32.csv" => "oneAPI fp32 (Arc A770)",
]

# callback column => facet title
const CB = [:tobj=>"obj", :tcon=>"cons", :tgrad=>"grad", :tjac=>"jac", :thess=>"hess"]

# map raw nvar values onto clean size tiers for grouping
sizetier(nv) = nv < 100 ? 20 : (nv < 100000 ? 2000 : 200000)

geomean(v) = isempty(v) ? NaN : exp(mean(log.(v)))

function main(outstem)
    fig = Figure(size = (1500, 340))
    colors = Makie.wong_colors()
    markers = [:rect, :circle, :utriangle, :diamond, :dtriangle]
    legend_handles = nothing

    for (j, (cb, lbl)) in enumerate(CB)
        ax = Axis(fig[1, j]; xscale=log10, yscale=log10, title=lbl,
                  xlabel="number of variables",
                  ylabel = j==1 ? "callback time (s)" : "")
        for (k, (file, be)) in enumerate(FILES)
            df = CSV.read(joinpath(RESDIR, file), DataFrame)
            sub = filter(r -> r.suite == "LV" && r.ams == "ExaModels", df)
            isempty(sub) && continue
            sub.tier = sizetier.(sub.nvar)
            xs = Float64[]; ys = Float64[]
            for tier in sort(unique(sub.tier))
                vals = filter(t -> t > 0, getproperty(sub[sub.tier .== tier, :], cb))
                isempty(vals) && continue
                push!(xs, tier); push!(ys, geomean(vals))
            end
            isempty(xs) && continue
            o = sortperm(xs)
            scatterlines!(ax, xs[o], ys[o]; color=colors[k], marker=markers[k],
                          markersize=10, linewidth=2,
                          label = j==1 ? be : nothing)
        end
    end
    Legend(fig[1, length(CB)+1], fig.content[1]; framevisible=false, labelsize=12)
    save(outstem*".pdf", fig)
    save(outstem*".png", fig; px_per_unit=2)
    println("wrote ", outstem, ".pdf / .png")
end

main(length(ARGS) >= 1 ? ARGS[1] : "/tmp/exa_5backend_scaling")
