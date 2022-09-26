### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ e59c636e-a55e-11ec-3285-459cd28c671e
begin
	import Pkg
	Pkg.activate()
	using Xtal
	using Plots; using Plots.PlotMeasures
	using PlutoUI
end;

# ╔═╡ fe6abf26-caf8-459d-b166-78a0647bda21
md"""
# Plotting band structures and fatbands in Pluto v.0.3

This pluto notebook uses Xtal.jl, Pluto.jl, and Plots.jl to plot band structures.
"""

# ╔═╡ 5e7f361a-d6b6-418f-b6db-59ca0f1bb162
md"""
## Backend

Choose a backend.
* Plotlyjs is good for interactivity but may be more performance-heavy.
* GR is noninteractive.
"""

# ╔═╡ 2d0aac83-ecee-413b-b7ee-eaf6108faf8b
begin
	@bind backend confirm(Select(["PlotlyJS", "GR"]))
end

# ╔═╡ ea49ad8f-3f1f-4a4d-8ae8-4d20a2b1f416
md"""
## Files you'll need

* PROCAR - contains band structure information. For now, this must be *lm-decomposed*.
* KPOINTS - must contain your path through k-space

Change the parameters below to point to the appropriate files.
"""

# ╔═╡ ebe294f7-a773-4e8d-a045-e1ffa3415b80
begin
	@bind inputfiles PlutoUI.combine() do Child
		md"""
		#### Input files
		KPOINTS file:
		$(
			Child(TextField(default = "./KPOINTS"))
		)
		
		PROCAR file:
		$(
			Child(TextField(default = "./PROCAR"))
		)
		"""
	end
end

# ╔═╡ 223f16fa-8fab-4182-9fa1-8cbd20c63980
md"""
## Basic plotting options
You will need to manually enter the energy range you'd like to plot (`emin` and `emax`).
"""

# ╔═╡ cbdd35ae-0cf9-407b-866c-30f561364ae1
begin
	emin = -12
	emax = -5
	fermi = 6.2222
	a_b = -12.0410
end;

# ╔═╡ d3cd057b-540d-4dc2-a7d7-53aaf2e69515
begin
	plotfatbands_ui = @bind pfb Select(["true" => "fatbands ON", "false" => "fatbands OFF"], default="false")

	md"""
	## Fatband plotting functions (optional)
	You can skip this section if you do not plan to plot fatbands.
	Option to plot fatbands: 	$plotfatbands_ui
	"""
end

# ╔═╡ 889642bd-8aa3-4a4b-bdb3-6e5986ca8ee4
begin
	num_ion_ui = @bind num_ion NumberField(1:1000, default = 1)
	md"""
	Enter the number of ions from your POSCAR.
	$num_ion_ui
	"""
end

# ╔═╡ 3831fd52-f63f-4fb0-8668-e5ba788fe3ef
md"""
If you want to plot the fatband of ion 1, set `fat_ion = 1`. You can also plot multiple ions, for example, if you want to plot fatbands of ion 1 through ion 6 because they are the same type, set `fat_ion = 1:6`.

"""

# ╔═╡ 395f5720-f43f-4a46-b424-5f85c1d75ccb
fat_ion = 1:6;

# ╔═╡ 515db34f-bae9-424c-937f-daba2f4a3568
md"""
Lastly, you need to specify which type of band to plot.

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

You can plot one type or even sums of these. For example, if you want to plot all of the *d*-bands, set `fat_type = 5:9`
"""

# ╔═╡ af954634-433e-48ff-8f53-36cf979f7873
begin
	#fat_type = 5:9
	
	@bind orbs confirm(MultiCheckBox((1:9)))
end

# ╔═╡ a17a222b-a830-4bdb-bd16-ff58cbd1ed83
begin
	#fatband_color = RGB(1,0,1)
	fatband_color_ui = @bind fb_c ColorStringPicker(default = "#ff00ff")
	md"""
	Set the color of the fatband.
	$fatband_color_ui
	"""
end

# ╔═╡ a4c3da32-1824-4f62-bacc-c9f1933f03f8
begin
	marker_size_ui = @bind marker_size NumberField(1:1000, default = 10)
	md"""
	Enter the size of the marker.
	$marker_size_ui
	"""
end

# ╔═╡ ff811725-2c40-4902-9007-c4dac0942876
begin
	# Notebook input processing
	if backend == "PlotlyJS"
		plotlyjs()
	else
		gr()
	end
	kpointfile = inputfiles[1]
	procarfile = inputfiles[2]
	plotfatbands = parse(Bool,pfb)
	fat_type = orbs;
	fatband_color = parse(Colorant,fb_c);
end;

# ╔═╡ 55a942b0-e150-4f13-a1e1-98b94594472c
#= Loading KPOINTS, PROCAR

This cell holds the guts of the data processing. Edit this at your own peril! =#

begin
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
	# Reads in fatband information
	if plotfatbands
    	ydz2 = Matrix{Float64}(undef,size(procarinfo.bands))
    	for i in 1:size(procarinfo.bands)[1]
        	for j in 1:size(procarinfo.bands)[2]
            	# sum 7th orb of 7th and 8th ion
            	global ydz2[i,j] = sum(procarinfo.projband[fat_type,fat_ion,j,i])
        	end
    	end
	end
end;

# ╔═╡ 71934996-f2ce-48d3-add6-7bf15346b7d8
md"""
## Plotting the data
The data can be plotted using the `Plots.jl` metapackage. Various options can be changed, including the plotting backend and various parameters of the plot itself.
"""

# ╔═╡ 7b9fb9d4-c318-4216-8d59-8cd0dbdc2f82
begin
	p = plot()
	# Plot the band structure
	for i in 1:size(procarinfo.bands)[2]
    	global p = plot!((1:size(procarinfo.bands)[1]), procarinfo.bands[:,i] + a_b*ones(size(procarinfo.bands[:,i])),
			color = :black)
		# Plot fat bands
    	if plotfatbands
        	scatter!(p, (1:size(procarinfo.bands)[1]), procarinfo.bands[:,i] + a_b*ones(size(procarinfo.bands[:,i])),
				markersize = marker_size*ydz2[:,i],
				markercolor = fatband_color,
				markerstrokecolor = fatband_color)
    	end
	end
	
	# Plot the fermi energy
	hline!([fermi+a_b], linestyle = :dash, color = :black)

	# Plot vertical lines to separate k-paths
	function plotKpathSeparations(num_intersections)
    	vline!([1], color = :black)
    	for i in 1:(num_intersections/2)
        	vline!([i*40], color = :black)
    	end
	end
	plotKpathSeparations(num_intersections)

	# Adjusts plot options
	plot!(p,
		ylims = (emin,emax),
		xlims = (0.99,size(procarinfo.bands)[1]),
		xticks = ([1;intersections:intersections:size(procarinfo.bands)[1]], kpathsets),
		legend = false,
		grid = false,
		framestyle =:box,
		margin = 20px,
		#size = (1000,800),
		)
end

# ╔═╡ 3a6052ce-60f6-42a7-ae41-957249d3836e
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

# ╔═╡ af148c9b-137c-4dc4-acc1-5a0b441877f7
begin
	#savefig(p,"myplot.pdf")
end

# ╔═╡ Cell order:
# ╟─fe6abf26-caf8-459d-b166-78a0647bda21
# ╠═e59c636e-a55e-11ec-3285-459cd28c671e
# ╟─5e7f361a-d6b6-418f-b6db-59ca0f1bb162
# ╟─2d0aac83-ecee-413b-b7ee-eaf6108faf8b
# ╟─ea49ad8f-3f1f-4a4d-8ae8-4d20a2b1f416
# ╟─ebe294f7-a773-4e8d-a045-e1ffa3415b80
# ╟─223f16fa-8fab-4182-9fa1-8cbd20c63980
# ╠═cbdd35ae-0cf9-407b-866c-30f561364ae1
# ╟─d3cd057b-540d-4dc2-a7d7-53aaf2e69515
# ╟─889642bd-8aa3-4a4b-bdb3-6e5986ca8ee4
# ╟─3831fd52-f63f-4fb0-8668-e5ba788fe3ef
# ╠═395f5720-f43f-4a46-b424-5f85c1d75ccb
# ╟─515db34f-bae9-424c-937f-daba2f4a3568
# ╟─af954634-433e-48ff-8f53-36cf979f7873
# ╟─a17a222b-a830-4bdb-bd16-ff58cbd1ed83
# ╟─a4c3da32-1824-4f62-bacc-c9f1933f03f8
# ╟─ff811725-2c40-4902-9007-c4dac0942876
# ╟─55a942b0-e150-4f13-a1e1-98b94594472c
# ╟─71934996-f2ce-48d3-add6-7bf15346b7d8
# ╟─7b9fb9d4-c318-4216-8d59-8cd0dbdc2f82
# ╟─3a6052ce-60f6-42a7-ae41-957249d3836e
# ╠═af148c9b-137c-4dc4-acc1-5a0b441877f7
