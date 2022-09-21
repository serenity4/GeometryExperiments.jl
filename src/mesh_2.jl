struct MeshVertex
  index::Int
  edges::Any
end

struct MeshEdge
  src::MeshVertex
  dst::MeshVertex
  faces::Any
end

struct MeshFace
  edges::Optional{Vector{MeshEdge}}
end

function Base.getproperty(v::MeshVertex, property::Symbol)
  property === :index && return getfield(v, :index)
  property === :edges && return getfield(v, :edges)::Optional{Vector{MeshEdge}}
  error("Type MeshVertex has no property $property")
end

function Base.getproperty(e::MeshEdge, property::Symbol)
  property === :src && return getfield(e, :src)
  property === :dst && return getfield(e, :dst)
  property === :faces && return getfield(e, :faces)::Optional{Vector{MeshFace}}
  error("Type MeshEdge has no property $property")
end

struct Mesh{VT,ET,FT}
  vertices::Vector{MeshVertex}
  edges::Vector{MeshEdge}
  faces::Vector{MeshFace}
  # Use a dictionary to allow holes in vertex indices.
  vertex_attributes::Dict{Int,VT}
  edge_attributes::Dict{Int,ET}
  face_attributes::Dict{Int,FT}
end

function Mesh(vertices = [], edges = [], faces = [])
  mesh = Mesh(MeshFace[], MeshEdge[], MeshVertex[])
  verts_cache = Dict{Int,MeshVertex}()
  remaining_edges = Set(1:length(edges))
  for face in faces
    edges = @view edges[face]
    f = MeshFace(MeshEdge[], mesh)
    push!(mesh.faces, f)
    for edge_index in face
      delete!(remaining_edges, edge_index)
    end
    for edge in edges
      src_index, dst_index = edge
      src = get!(() -> MeshVertex(src_index), verts_cache, src_index)
      dst = get!(() -> MeshVertex(dst_index), verts_cache, dst_index)
      e = MeshEdge(src, dst, f, mesh)
      push!(f.edges, e)
      push!(mesh.edges, e)
      !isdefined(src, :edge) && (src.edge = e)
      !isdefined(dst, :edge) && (dst.edge = e)
    end
  end
  for edge_index in remaining_edges
    edge = edges[edge_index]
    src_index, dst_index = edge
    src = get!(() -> MeshVertex(src_index), verts_cache, src_index)
    dst = get!(() -> MeshVertex(dst_index), verts_cache, dst_index)
    e = MeshEdge(src, dst, nothing, mesh)
    push!(mesh.edges, e)
    !isdefined(src, :edge) && (src.edge = e)
    !isdefined(dst, :edge) && (dst.edge = e)
  end
  for vertex in vertices
    get!(() -> MeshVertex(vertex), verts_cache, vertex)
  end
  append!(mesh.vertices, values(verts_cache))
  mesh
end
