using Graphs: SimpleDiGraph, add_edge!, outneighbors, nv
import Graphs: add_vertex!

struct Polytope{N}
  graphs::Vector{SimpleDiGraph{Int64}}
  function Polytope{N}(graphs::AbstractVector) where {N}
    @assert N == length(graphs)
    new{N}(graphs)
  end
  Polytope{N}(graphs...) where {N} = Polytope{N}(collect(graphs))
end

"""
Build a `Polytope` with `n_verts` from the structure provided in `indices`.

The nth argument passed as `indices` describes connectivity from the (n-1)th face to the nth face.

## Example

`` `julia
julia> Polytope(4,
    [(1, 2), (2, 3), (3, 1), (2, 3), (3, 4), (4, 2)], # edges (segments)
    [(1, 2, 3), (4, 5, 6)] # 2 triangle faces from edges 1, 2, 3 and 4, 5, 6 respectively
)

julia> Polytope(4,
    [(1, 2, 3, 1), (2, 3, 4, 2)], # edges (closed chains)
    [(1,), (2,)]) # faces (made from a closed chain -> PolySurface with no inner chains)
`` `
"""
function Polytope(n_verts, indices::Vararg{<:AbstractVector{<:Tuple}})
  graphs = SimpleDiGraph{Int64}[]
  n_nodes = n_verts
  g = SimpleDiGraph{Int64}(n_nodes)
  for vec in indices
    for (u, vs) in enumerate(vec)
      for v in vs
        add_edge!(g, u, v)
      end
    end
    push!(graphs, g)
    n_nodes = length(vec)
    g = SimpleDiGraph{Int64}(n_nodes)
  end
  Polytope{length(indices)}(graphs)
end

parametric_dimension(::Type{Polytope{N}}) where {N} = N

struct PolytopeElement{N}
  elements::Vector{Int64}
  polytope::Polytope
end

elements(polytope::Polytope, ::Val{N}) where {N} = Polytope{N}(polytope.graphs[1:N])
function elements(polytope::Polytope, ::Val{N}) where {N}
  g = polytope.graphs[N]
  (PolytopeElement{N}(outneighbors(g, i), polytope) for i in 1:nv(g))
end
@inline elements(polytope::Polytope, n::Integer) = elements(polytope, Val(n))

struct Mesh{N,V}
  polytope::Polytope{N}
  vertices::V
  Mesh{N}(vertices::V) where {N,V} = new{N,V}(Polytope(length(vertices)), vertices)
  Mesh{N}(vertices::V, edges) where {N,V} = new{N,V}(Polytope(length(vertices), edges), vertices)
end

elements(mesh::Mesh, ::Val{N}) where {N} = Mesh(elements(mesh.polytope, N), mesh.vertices)
@inline elements(mesh::Mesh, n::Integer) = elements(mesh, Val(n))

function add_element!(mesh::Mesh, element::PolytopeElement{N}) where {N}
  g = mesh.polytope.graphs[N]
  v = add_vertex!(g)
  g_sub = mesh.polytope.graphs[N - 1]
  add_edge!(g_sub)
end

function add_vertex!(mesh::Mesh, v::Point)
  push!(mesh.vertices, v)
  add_vertex!(mesh.polytope.graphs[1])
end
