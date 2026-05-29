# Best-effort multi-backend OPF speedup plot for the JuMP-dev slide.
# Reads per-host result CSVs directly (device/hostname parsed from companion
# _hw.toml), computes ExaModels per-callback speedup of each backend vs the
# CPU (1-thread, shin-compute-001) reference, and renders a faceted log-log
# scaling figure. NOT the canonical paper figure (see notes posted to Sungho).

using CSV, DataFrames, CairoMakie

const RESDIR = joinpath(@__DIR__, "results")  # overridden below

function hw_device(csvfile)
    toml = replace(csvfile, r"\.csv$" => "_hw.toml")
    dev = host = "unknown"
    if isfile(toml)
        for ln in readlines(toml)
            m = match(r"^\s*device\s*=\s*\"(.*)\"", ln);   m !== nothing && (dev = m.captures[1])
            m2 = match(r"^\s*hostname\s*=\s*\"(.*)\"", ln); m2 !== nothing && (host = m2.captures[1])
        end
    end
    # disambiguate oneAPI fp32 vs fp64 by filename suffix
    if occursin("oneAPI", dev)
        occursin("fp32", basename(csvfile)) ? (dev *= " (fp32)") : (dev *= " (fp64)")
    end
    return dev, host
end

function load(resdir)
    dfs = DataFrame[]
    for f in readdir(resdir; join=true)
        (endswith(f, ".csv") && !startswith(basename(f), "combined")) || continue
        df = CSV.read(f, DataFrame)
        nrow(df) == 0 && continue
        dev, host = hw_device(f)
        df.device .= dev; df.hostname .= host
        push!(dfs, df)
    end
    vcat(dfs...; cols=:union)
end

const CB = [:tobj=>"obj", :tcon=>"cons", :tgrad=>"grad", :tjac=>"jac", :thess=>"hess"]

function main(resdir, outstem)
    df = load(resdir)
    df = filter(r -> r.suite == "OPF-polar" && r.ams == "ExaModels", df)
    ref = filter(r -> r.device == "CPU" && r.hostname == "shin-compute-001", df)
    refmap = Dict(r.nvar => r for r in eachrow(ref))   # nvar -> reference row

    backends = sort(unique(filter(d -> !(d == "CPU"), df.device)))
    colors = Makie.wong_colors()
    markers = [:circle, :rect, :utriangle, :diamond, :dtriangle, :star5, :cross]

    fig = Figure(size = (1500, 360))
    for (j, (cb, lbl)) in enumerate(CB)
        ax = Axis(fig[1, j]; xscale=log10, yscale=log10, title=lbl,
                  xlabel="nvar", ylabel = j==1 ? "speedup vs CPU" : "")
        for (k, be) in enumerate(backends)
            sub = filter(r -> r.device == be, df)
            xs = Float64[]; ys = Float64[]
            for r in eachrow(sub)
                haskey(refmap, r.nvar) || continue
                tb = getproperty(r, cb); tr = getproperty(refmap[r.nvar], cb)
                (tb > 0 && tr > 0) || continue
                push!(xs, r.nvar); push!(ys, tr/tb)
            end
            isempty(xs) && continue
            o = sortperm(xs)
            scatterlines!(ax, xs[o], ys[o]; color=colors[mod1(k,7)],
                          marker=markers[mod1(k,7)], markersize=9,
                          label = j==1 ? be : nothing)
        end
        hlines!(ax, [1.0]; color=:gray, linestyle=:dash)
    end
    Legend(fig[1, length(CB)+1], fig.content[1]; framevisible=false)
    save(outstem*".pdf", fig); save(outstem*".png", fig; px_per_unit=2)
    println("backends plotted: ", backends)
    println("wrote ", outstem, ".pdf / .png")
end

main(ARGS[1], ARGS[2])
