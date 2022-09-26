### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ e59c636e-a55e-11ec-3285-459cd28c671e
begin
	import Pkg
	Pkg.activate()
	using Xtal
	using Plots
	using Plots.PlotMeasures
end

# ╔═╡ fe6abf26-caf8-459d-b166-78a0647bda21
md"""
# Plotting a DOSCAR in Pluto

Here's an example of a notebook that shows the plotting of a DOSCAR with the help of `Plots.jl` and the `Xtal.jl` theory package Brandon has been working on!

## Loading packages

Because `Xtal.jl` is not part of the Julia registry, we'll have to override the built-in package management of Pluto. Make sure you have `Xtal.jl` installed - and if you don't you can do it like this:

```julia-repl
(@v1.6) pkg> add Pluto
```

You can access the package manager by typing the right bracket at an empty REPL.
"""

# ╔═╡ 9c499d41-070b-48d9-9cf7-3d2779d8e9b4
md"""
## Basic plotting options

This is where we're limited by the format of the DOSCAR. It doesn't contain any information about the types of ions or the number of ions of each type. It also doesn't include the E_alpha+beta energy.

If you decide to plot a different DOSCAR, you'll probably want to change some of these parameters.
"""

# ╔═╡ fe1769d2-5617-4c3e-93ec-b7e0f806c159
begin
	# Options
	# Path to DOSCAR as string
	doscarfile = "DOSCAR";
	
	# Plotting options
	emin = -15;
	emax = -5;
	xmax = 25;
	alphabeta = -12.0410;
	
	# Set options for pDOS plotting
	plotpDOS = true;
	num_types_ions = 2;
	num_ions_per_type = [12,4];
	ion_type_to_plot = 2;
	ion_orbital_to_plot = 4;
	nothing
end

# ╔═╡ b874994e-1eb8-43bf-9d21-1c3d6e63ebd9
md"""
## Loading the DOSCAR
This is where the `Xtal.jl` package does its job! You can change the DOSCAR file used to get a different plot.
"""

# ╔═╡ 55a942b0-e150-4f13-a1e1-98b94594472c
# Load DOSCAR
begin
	dos = open(doscarfile)
	tdos, pdos = readDOSCAR(dos)
	close(dos)
end

# ╔═╡ f797399a-2ec6-438c-a747-09b249c1fc81
md"""
## Hypothetical Fermi energy at an electron count
The optional hidden cell below calculates a hypothetical Fermi energy at an electron count. Enable cell if you need this tool.
"""

# ╔═╡ 5ab52382-140c-4526-a1a6-7d279a98a205
# ╠═╡ disabled = true
#=╠═╡
begin
    # This cell calculates a hypothetical fermi energy at an electron count.
	function energy_at_electrons(electron_ct)
    	if electron_ct < tdos.int[1] || electron_ct > tdos.int[length(tdos.int)]
                        error("Electron count invalid")
        end

        i = 1
        while tdos.int[i] < electron_ct
            i += 1
        end
        # Estimate energy at electron count by lineear interpolation
        m = (tdos.int[i]-tdos.int[i-1])/(tdos.energy[i]-tdos.energy[i-1])
        b = tdos.int[i]-m*tdos.energy[i]
        x = (electron_ct - b)/m
        return x
    end

	# Calculate and print fermi energy at electron count with
	# fermi_try = energy_at_electrons(electron_count)
	# Electron count must correspond to the valence electrons as determined in the POTCAR x number of atoms in the unit cell
    fermi_try = energy_at_electrons(72)
    #fermi_try2 = energy_at_electrons(76)
    #fermi_try3 = energy_at_electrons(42)
    println(fermi_try)
    #println(fermi_try2)
    #println(fermi_try3)
end
  ╠═╡ =#

# ╔═╡ 71934996-f2ce-48d3-add6-7bf15346b7d8
md"""
## Plotting the data
The data can be plotted using the `Plots.jl` metapackage. Various options can be changed, including the plotting backend and various parameters of the plot itself.
"""

# ╔═╡ 7b9fb9d4-c318-4216-8d59-8cd0dbdc2f82
begin
    # Plot total DOS
    p = plot(tdos.dos, tdos.energy.+alphabeta, color = :black)
    
    # Processes projected DOS data
    if plotpDOS && !isempty(pdos)
        pdos_for_plot = Matrix{Float64}[]
        ct = 1
        for i in 1:length(num_ions_per_type)
            sum_pdos = zeros(size(pdos[1].dos))
            for j in 1:num_ions_per_type[i]
                sum_pdos += pdos[ct].dos
                global ct += 1
            end
            push!(pdos_for_plot,sum_pdos)
        end
    
    
    # Plots projected DOS
    	plot!(pdos_for_plot[ion_type_to_plot][ion_orbital_to_plot,:],tdos.energy.+alphabeta, color = :black, fill = (0))
	end
    
    # Plot the Fermi energy
    hline!([tdos.fermi+alphabeta], linestyle = :dash, color = :black)
	# Plot hypothetical fermi energy
	#hline!([fermi_try+alphabeta], linestyle = :dash, color = :red)
    
    # Adjusts plot options
    plot!(p,
    ylims = (emin,emax),
    xlims = (0,xmax),
    size = (400,800),
    legend = false,
    grid = false,
    fontfamily = "Helvetica",
    ytickfontsize = 12,
    xaxis = nothing,
    framestyle =:box,
    margin = 20px
    )
end

# ╔═╡ 078171f3-42aa-421d-95d8-881d74f98e67
md"""
## Backend
Here we can check the backend that's being used. By default, it seems to be `GRBackend()`. You can change this if you like in the previous cells.
"""

# ╔═╡ a5eb9b58-117f-47ae-9836-d723f8afc506
Plots.backend()

# ╔═╡ Cell order:
# ╟─fe6abf26-caf8-459d-b166-78a0647bda21
# ╠═e59c636e-a55e-11ec-3285-459cd28c671e
# ╟─9c499d41-070b-48d9-9cf7-3d2779d8e9b4
# ╠═fe1769d2-5617-4c3e-93ec-b7e0f806c159
# ╟─b874994e-1eb8-43bf-9d21-1c3d6e63ebd9
# ╠═55a942b0-e150-4f13-a1e1-98b94594472c
# ╟─f797399a-2ec6-438c-a747-09b249c1fc81
# ╟─5ab52382-140c-4526-a1a6-7d279a98a205
# ╟─71934996-f2ce-48d3-add6-7bf15346b7d8
# ╠═7b9fb9d4-c318-4216-8d59-8cd0dbdc2f82
# ╟─078171f3-42aa-421d-95d8-881d74f98e67
# ╠═a5eb9b58-117f-47ae-9836-d723f8afc506
