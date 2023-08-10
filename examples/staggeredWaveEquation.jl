using OrdinaryDiffEq, ModelingToolkit, MethodOfLines, DomainSets, Plots;

@parameters t x
@variables ρ(..) ϕ(..)
Dt = Differential(t);
Dx = Differential(x);

a = 5.0;#1.0/2.0;
L = 8.0;
dx = 0.125;
dt = dx/a;
tmax = 1000.0;

#initialFunction(x) = exp(-(x)^2);
#initialFunction(x) = abs(x-L)/(2*L);
initialFunction(x) = tanh(-x)+1;
eq = [Dt(ρ(t,x)) + Dx(ϕ(t,x)) ~ 0,
      Dt(ϕ(t,x)) + a^2 * Dx(ρ(t,x)) ~ 0]
bcs = [ρ(0,x) ~ initialFunction(x),
       ϕ(0.0,x) ~ 0.0,
       ρ(t,-L) ~ initialFunction(-L),
       ρ(t,L) ~ 0.0,
       ϕ(t,-L) ~ 0.0,
       Dt(ϕ(t,L)) ~ -a^2*Dx(ρ(t,L))];

domains = [t in Interval(0.0, tmax),
           x in Interval(-L, L)];

@named pdesys = PDESystem(eq, bcs, domains, [t,x], [ρ(t,x), ϕ(t,x)]);

discretization = MOLFiniteDifference([x=>dx], t, grid_align=MethodOfLines.StaggeredGrid());

prob = discretize(pdesys, discretization);

function calc_du!(du, u, p, t)
    placeholder = copy(du);
    dynamical_f1(du, u, p, t);
    dynamical_f2(placeholder, [(u[1:len] + dt*du[1:len]); u[len+1:end]], p, t);
    du[len+1:end] .= placeholder[1:len+1];
    return;
end

function update(u, p, t)
    du = zeros(length(u));
    calc_du!(du, u, p, t);
    return u .+ du*dt;
end

sol = zeros(length(u0), length(tsteps));
sol[:,1] .= u0;
for i in 2:length(tsteps)
    sol[:,i] = update(sol[:,i-1], 0, 0);
end

function plot_sol(sol; time_range=1:200:1000)
    p_rho = plot();
    p_phi = plot();
    for i in time_range
        plot!(p_rho, sol[1:len,i], label="t=$(tsteps[i])");
        plot!(p_phi, sol[len+1:end,i], label="t=$(tsteps[i])");
    end
    plot!(p_phi, title="Mass flux: ϕ");
    plot!(p_rho, title="Density: ρ");
    return plot(p_rho, p_phi);
end

plot_sol(sol)
