using ExaModels, NLPModelsIpopt

core = ExaCore(minimize = false)          # maximize final altitude
@add_var(core, h, 0:nh; start = 1.0, lvar = 1.0)
@add_var(core, v, 0:nh; start = (i/nh*(1-i/nh) for i=0:nh))
@add_var(core, m, 0:nh; start = ..., lvar = m_f, uvar = m_0)
@add_var(core, T, 0:nh; start = T_max/2, lvar = 0.0, uvar = T_max)
@add_var(core, step, 1; start = 1/nh, lvar = 0.0)

@add_obj(core, h[nh])                     # objective: final altitude
@add_con(core, c1, -h[i]+h[i-1] + 0.5*step[1]*(v[i]+v[i-1]) for i=1:nh)
@add_con(core, c2, ...)                   # velocity dynamics
@add_con(core, c3, ...)                   # mass dynamics
@add_con(core, h[0] - h_0); ...           # boundary conditions

result = ipopt(ExaModel(core))
