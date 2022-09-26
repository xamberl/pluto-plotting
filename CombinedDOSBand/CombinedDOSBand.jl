### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 92d8b958-3608-11ed-3d83-8d102415f0c0
begin
	# Package management
	import Pkg
	Pkg.activate()
	using Xtal
	using Plots
	using Plots.PlotMeasures
	#gr()
	plotlyjs()
end;

# ╔═╡ 1818a8ea-d633-4bc8-a595-0e5733e3dd28
md"""
# Plot a combined DOS and band structure plot in Pluto v.0.1

This pluto notebook uses Xtal.jl, Pluto.jl, and Plots.jl to plot band structures.
"""

# ╔═╡ 208b93e4-c25d-4fa1-9b2a-67ee1359e038
md"""
## Files you'll need

* **KPOINTS** - must contain your path through k-space
* **PROCAR** - contains band structure information. This must be *lm-decomposed* (LORBIT = 11). Phase-decomposed PROCARS (LORBIT = 12) are not currently supported.
* **DOSCAR** - contains DOS information. Can be *l*- or *lm-decomposed*.

Change the parameters below to point to the appropriate files.
"""

# ╔═╡ 70cd1365-b294-4aa7-a582-bef98db98a11
begin
	# PATH TO INPUT FILES
	kpointfile = "KPOINTS"
	procarfile = "PROCAR"
	doscarfile = "DOSCAR_YAl3_Ni3Sn_lm"
end;

# ╔═╡ 1bd09492-77bb-4998-bbb7-ff29307ca0cd
md"""
## Plotting options

* **emin** - Minimum for *y*-axis (energy in eV)
* **emax** - Maximum for *y*-axis (energy in eV)
* **xmax** - Maximum for *x*-axis of the DOS curve
* **alphabeta** - obtain from DOS calculation with `grep fermi OUTCAR`
"""

# ╔═╡ 84015fed-e3e3-4b4d-b485-6ea425fcddeb
begin
	emin = -10
	emax = -5
	xmax = 10
	alphabeta = -13.1527
end;

# ╔═╡ 46f6cd03-b944-405a-8a88-2726b08d46cb
md"""
## Projected DOS plotting options

To plot projected DOS, your DOSCAR must be *l-* or *lm-decomposed*. Set `plotpDOS = true`, otherwise leave it on `false`.

* `num_types_ions` - number of types of ions in your system
* `num_ions_per_type` - an array of ions per type (see POSCAR)
* `ion_type_to_plot` - which ion's pDOS you want to plot based on `num_types_ions`
* `ion_orbital_to_plot` - which ion's orbital to plot.

If *l-decomposed*:

| Number | Orbital  |
| ------ | -------- |
| 1      | ``s``    |
| 2      | ``p``    |
| 3      | ``d``    |

If *lm-decomposed*:

| Number | Orbital      |
| ------ | ------------ |
| 1      | ``s``        |
| 2      | ``p_y``      |
| 3      | ``p_z``      |
| 4      | ``p_x``      |
| 5      | ``d_{xy}``   |
| 6      | ``d_{yz}``   |
| 7      | ``d_{z^2}``  |
| 8      | ``d_{xz}``   |
| 9      | ``d_{x^2-y^2}`` |
"""

# ╔═╡ e1af7e68-e0b1-40cc-8090-2bf5bb26016b
begin

	# Set options for pDOS plotting (l- or lm-decomposed DOSCARS)
	plotpDOS = true # set as true if you want to plot projected DOS
	num_types_ions = 2 # number of types of ions in your system
	num_ions_per_type = [6,2] # array of ions (see POSCAR)
	ion_type_to_plot = 2 # which ion's pDOS you want to plot based on num_types_ions
	ion_orbital_to_plot = 9 # which ion's orbital to plot; see above
end;

# ╔═╡ 84a506bf-3d1d-41d6-8cbc-46f1129b5f52
begin
	# EDIT AT YOUR OWN RISK
	# CREATES DOS CURVES
	
	# Load DOSCAR
	dos = open(doscarfile)
	tdos, pdos = Xtal.readDOSCAR(dos)
	close(dos)

	# Plot total DOS
	dosplot = plot(tdos.dos, tdos.energy.+alphabeta, color =:black, linewidth = 1.5)

    
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
    	plot!(pdos_for_plot[ion_type_to_plot][ion_orbital_to_plot,:], tdos.energy.+alphabeta, color = :black, fill = (0), linewidth = 1.5)
	end

	# Plot the Fermi energy
	hline!([tdos.fermi+alphabeta], linestyle = :dash, color = :black)
	
	plot!(dosplot,
    ylims = (emin,emax),
    xlims = (0,xmax),
    size = (400,800),
    legend = false,
    grid = false,
    fontfamily = "Helvetica",
    ytickfontsize = 12,
    xaxis = nothing,
    framestyle =:grid,
    #margin = 20px
    )

	# Adds extra thick lines for plot borders
	hline!([emin], linewidth = 4, color = :black)
	hline!([emax], linewidth = 4, color = :black)
	vline!([0], linewidth = 4, color = :black)
	vline!([xmax], linewidth = 4, color = :black)
end;

# ╔═╡ 5e487d24-bdd2-4069-9626-f71c8b0b590c
begin
	# EDIT AT YOUR OWN RISK
	# CREATES BAND STRUCTURE
	
	# reads the KPOINTS file and returns:
	# intersections - the number of points between high-symmetry k-points
	# num_intersections - the number of high symmetry k-points
	# kpathsets - a vector of strings of the path in k-space (for labeling axes)

function readKpath(kptfile::String)
    f = open(kptfile)
    readline(f)
    intersections = parse(Int, split(readline(f))[1])
    readline(f)
    readline(f)
    kpath = Vector{String}()
    for ln in eachline(f)
        if length(split(ln)) == 5
            push!(kpath,string((split(ln)[5])));
        end
    end
    close(f)
    num_intersections = length(kpath)
    kpathsets = Vector{String}(undef,floor(Int,length(kpath)/2+1))
    kpathsets[1] = kpath[1]
    kpathsets[length(kpathsets)] = kpath[length(kpath)]
    count = 2;
    for i in 2:2:(length(kpath)-2)
        if cmp(kpath[i], kpath[i+1]) == 0
            kpathsets[count] = kpath[i]
        else
            kpathsets[count] = string(kpath[i]," | ",kpath[i+1])
        end
        count += 1
    end
    return intersections, num_intersections, kpathsets
end

# Runs the readKpath function
(intersections, num_intersections, kpathsets) = readKpath(kpointfile)
# Reads the PROCAR according to Xtal
procarinfo = Xtal.readPROCAR(procarfile)

	# Plot the band structure
	bandplot = plot()
	for i in 1:size(procarinfo.bands)[2]
    	global bandplot = plot!((1:size(procarinfo.bands)[1]), procarinfo.bands[:,i] + alphabeta*ones(size(procarinfo.bands[:,i])),
			color = :black,linewidth = 1.5)
	end
	
	# Plot the fermi energy
	hline!([tdos.fermi+alphabeta], linestyle = :dash, color = :black)

	# Plot vertical lines to separate k-paths
	function plotKpathSeparations(num_intersections)
    	vline!([1], color = :black)
    	for i in 1:(num_intersections/2)
        	vline!([i*40], color = :black, linewidth = 1.5)
    	end
	end
	plotKpathSeparations(num_intersections)

	# Adjusts plot options
	plot!(bandplot,
		ylims = (emin,emax),
		xlims = (0.99,size(procarinfo.bands)[1]),
		xticks = ([1;intersections:intersections:size(procarinfo.bands)[1]], kpathsets),
		legend = false,
		grid = false,
		framestyle =:grid,
		margin = 20px,
		yaxis=nothing,
		size = (1000,800),
		fontfamily = "Helvetica",
    	xtickfontsize = 8,
		)

	# Adds extra thick lines for plot borders
	hline!([emin], linewidth = 4, color = :black)
	hline!([emax], linewidth = 4, color = :black)
	vline!([1], linewidth = 4, color = :black)
	vline!([size(procarinfo.bands)[1]], linewidth = 4, color = :black)
end;

# ╔═╡ 1fff35f5-8ccd-4924-b8f4-918abbc67f11
begin
	# EDIT AT YOUR OWN RISK
	# CREATES COMBINED PLOT
	
	p = plot(dosplot, bandplot,
		layout = Plots.grid(1,2, widths=[0.25,0.75]),
		right_margin = 20px,
		left_margin = 0px,
		#size = (1000,800),
		dpi = 500,
	)
end

# ╔═╡ 6c94c0b7-4311-4fd3-a4b7-94d94bed0786
md"""
## Save your figure
You can save your figure as a png by scrolling to the top-right of the figure and clicking the camera icon, or you can uncomment the script below to save it into the working directory.

You may use the following file extensions:
* .svg - best for scaling but not compatible with many photo editors (including Affinity Photo)
* .png - quickest and easiest file format to work with but may be difficult to scale.
* .pdf - can be opened in Affinity Photo for scaling (recommended)
* .eps - can be opened in Affinity Photo for scaling (may have aliasing issues)
* .html - exports as an interactive document
"""

# ╔═╡ 0431d78b-75f8-46fa-bbde-995b884579f4
begin
	#savefig(p,"myplot.pdf")
end

# ╔═╡ Cell order:
# ╟─1818a8ea-d633-4bc8-a595-0e5733e3dd28
# ╟─92d8b958-3608-11ed-3d83-8d102415f0c0
# ╟─208b93e4-c25d-4fa1-9b2a-67ee1359e038
# ╠═70cd1365-b294-4aa7-a582-bef98db98a11
# ╟─1bd09492-77bb-4998-bbb7-ff29307ca0cd
# ╠═84015fed-e3e3-4b4d-b485-6ea425fcddeb
# ╟─46f6cd03-b944-405a-8a88-2726b08d46cb
# ╠═e1af7e68-e0b1-40cc-8090-2bf5bb26016b
# ╟─84a506bf-3d1d-41d6-8cbc-46f1129b5f52
# ╟─5e487d24-bdd2-4069-9626-f71c8b0b590c
# ╟─1fff35f5-8ccd-4924-b8f4-918abbc67f11
# ╟─6c94c0b7-4311-4fd3-a4b7-94d94bed0786
# ╠═0431d78b-75f8-46fa-bbde-995b884579f4
