jm = Model()
@variable(jm, x);  @variable(jm, y);
f = x^2 + sin(x)*y + cos(y)
