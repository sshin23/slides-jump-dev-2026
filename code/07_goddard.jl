## Slide 7 (Goddard rocket in ExaModels): full, runnable version of the snippet.
## The slide elides c2 / c3 / boundary conditions with "...". This file is the
## complete model that the slide is abbreviating.
## Source: paper section 2.4 (~/git/papers/exa-models-paper/sections/modeling.tex).

using ExaModels, NLPModelsIpopt

nh = 200                                   # number of time steps
h_0, v_0, m_0, g_0 = 1.0, 0.0, 1.0, 1.0
T_c, h_c, v_c, m_c  = 3.5, 500.0, 620.0, 0.6
c_e = 0.5*sqrt(g_0*h_0); m_f = m_c*m_0
D_c = 0.5*v_c*(m_0/g_0); T_max = T_c*m_0*g_0

core = ExaCore(minimize = false)           # maximize final altitude
@add_var(core, h, 0:nh; start = 1.0, lvar = 1.0)
@add_var(core, v, 0:nh; start = (i/nh*(1-i/nh) for i=0:nh))
@add_var(core, m, 0:nh;
  start = ((m_f-m_0)*i/nh + m_0 for i=0:nh), lvar = m_f, uvar = m_0)
@add_var(core, T, 0:nh; start = T_max/2, lvar = 0.0, uvar = T_max)
@add_var(core, step, 1; start = 1/nh, lvar = 0.0)

@add_obj(core, h[nh])                      # objective: final altitude
@add_con(core, c1,                         # altitude dynamics
  -h[i]+h[i-1] + 0.5*step[1]*(v[i]+v[i-1]) for i=1:nh)
@add_con(core, c2,                         # velocity dynamics
  -v[i]+v[i-1] + 0.5*step[1]*(
    (T[i] - D_c*v[i]^2*exp(-h_c*(h[i]-h_0))/h_0
      - m[i]*g_0*(h_0/h[i])^2)/m[i]
    + (T[i-1] - D_c*v[i-1]^2*exp(-h_c*(h[i-1]-h_0))/h_0
      - m[i-1]*g_0*(h_0/h[i-1])^2)/m[i-1]) for i=1:nh)
@add_con(core, c3,                         # mass dynamics
  -m[i]+m[i-1] + 0.5*step[1]*(-T[i]/c_e - T[i-1]/c_e) for i=1:nh)
@add_con(core, h[0] - h_0)
@add_con(core, v[0] - v_0)
@add_con(core, m[0] - m_0)
@add_con(core, m[nh] - m_f)

model = ExaModel(core)
result = ipopt(model)
@info "Goddard OK" status = result.status iter = result.iter objective = result.objective
