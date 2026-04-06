### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ 2d87e5fe-26c5-11f1-af9a-e14d0317bfdf
begin
	using Pkg
	Pkg.activate(; temp=true)
	Pkg.add("GeometryBasics")
	Pkg.add("LinearAlgebra")
	Pkg.add(;name="Symbolics", version="7")
	using GeometryBasics
	using Symbolics
	using LinearAlgebra
	Pkg.add("Latexify")
	import Latexify
	Pkg.develop(;name="Tangle", path=@__DIR__)
	using Tangle
end

# ╔═╡ d723ca94-f514-43a6-8416-959cc60fb17e
ONE_CROSSING

# ╔═╡ 16bf84b9-2e7e-49c0-a0b3-0130d9d7a114
ONE_CROSSING.loop.poi

# ╔═╡ 74296462-8416-4a9e-9aa2-1df2d9c6e67f
one_crossing_symbolic = symbolic_cubic_spline(ONE_CROSSING.loop.poi)

# ╔═╡ 2c4c5b82-9396-4d39-87c0-3ba4a2ef183b
ocf = let
	kp = only(Symbolics.get_variables(one_crossing_symbolic))
	build_function(one_crossing_symbolic, kp;
				   expression=build_function_expression_value(false))[1]
end

# ╔═╡ 2f9e36e3-f9fd-4f21-b3f8-629669fcadc9
# Does ocf return the right value for each PointOfInterest?
for poi in ONE_CROSSING.loop.poi
	computed = ocf(float(poi.p.p))
	coord = spatial_coordinates(poi)
	if !isapprox(computed, coord)
		println(computed, "\t", coord)
	end
end

# ╔═╡ f3eababe-999e-451f-b21b-955a12d2f33f
pm = proximity_metric(one_crossing_symbolic)

# ╔═╡ d90999c4-9ca4-4a6d-ac86-bcbcb2554503
plot_metric(metric_to_function(proximity_metric(one_crossing_symbolic)))

# ╔═╡ 459bdabb-bb28-4a75-acf2-b424ad4d9408
build_function(pm, sort(collect(Symbolics.get_variables(pm)); by = x -> string(Symbolics.value(x)))...;
			   expression = build_function_expression_value(false))

# ╔═╡ e4751dad-4983-4cb7-a3a5-27f84009e07b
md"""
## Lets Try Projection
"""

# ╔═╡ 45d8f545-10c0-44f8-9749-937962104d2a
Tangle.project([0, 0, 1], one_crossing_symbolic)

# ╔═╡ f5e1bdcd-e750-4cc4-9b01-635ee8fdb455
[0, 0, 1] .* one_crossing_symbolic

# ╔═╡ 3146b475-288c-4934-9436-c4b7130a7279
one_crossing_symbolic

# ╔═╡ 2c3af49d-e5e9-42b8-a8ba-2ec81606e584
let
	@variables a, b, c
	ifelse(a < 2,
		   Symbolics.Arr([a, b, c]),
		   Symbolics.Arr([c, b, a]))
end

# ╔═╡ Cell order:
# ╠═2d87e5fe-26c5-11f1-af9a-e14d0317bfdf
# ╠═d723ca94-f514-43a6-8416-959cc60fb17e
# ╠═16bf84b9-2e7e-49c0-a0b3-0130d9d7a114
# ╠═74296462-8416-4a9e-9aa2-1df2d9c6e67f
# ╠═2c4c5b82-9396-4d39-87c0-3ba4a2ef183b
# ╠═2f9e36e3-f9fd-4f21-b3f8-629669fcadc9
# ╠═f3eababe-999e-451f-b21b-955a12d2f33f
# ╠═d90999c4-9ca4-4a6d-ac86-bcbcb2554503
# ╠═459bdabb-bb28-4a75-acf2-b424ad4d9408
# ╟─e4751dad-4983-4cb7-a3a5-27f84009e07b
# ╠═45d8f545-10c0-44f8-9749-937962104d2a
# ╠═f5e1bdcd-e750-4cc4-9b01-635ee8fdb455
# ╠═3146b475-288c-4934-9436-c4b7130a7279
# ╠═2c3af49d-e5e9-42b8-a8ba-2ec81606e584
