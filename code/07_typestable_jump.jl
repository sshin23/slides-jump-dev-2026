N = 100
jm = Model()
@variable(jm, x[i=1:N], start = isodd(i) ? -1.2 : 1.0)
@objective(jm, Min,
    sum(100*(x[i+1] - x[i]^2)^2 + (1 - x[i])^2 for i = 1:N-1))
