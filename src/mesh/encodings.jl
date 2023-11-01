@enum MeshTopology::UInt8 begin
  MESH_TOPOLOGY_TRIANGLE_LIST = 1
  MESH_TOPOLOGY_TRIANGLE_STRIP = 2
  MESH_TOPOLOGY_TRIANGLE_FAN = 3
end

@struct_hash_equal struct MeshEncoding{T<:Integer}
  topology::MeshTopology
  indices::Vector{T}
end
MeshEncoding(topology::MeshTopology, range::AbstractRange) = MeshEncoding(topology, collect(range))
MeshEncoding(topology::MeshTopology, indices::AbstractVector{T}) where {T} = MeshEncoding(topology, convert(Vector{T}, indices))
MeshEncoding(topology::MeshTopology, indices::AbstractVector{<:Tuple}) = MeshEncoding(topology, convert.(SVector, indices))
MeshEncoding(topology::MeshTopology, indices::AbstractVector{<:SVector{3}}) = MeshEncoding(topology, collect(Iterators.flatten(indices)))

function reencode(encoding::MeshEncoding, topology::MeshTopology)
  encoding.topology === topology && return encoding
  MeshEncoding(topology, reencode_indices(encoding.indices, encoding.topology, topology))
end

function reencode_indices(indices::Vector{T}, from::MeshTopology, to::MeshTopology) where {T}
  n = length(indices)
  if to === MESH_TOPOLOGY_TRIANGLE_LIST
    if from === MESH_TOPOLOGY_TRIANGLE_STRIP
      new_indices = Vector{T}(undef, 3(n - 2))
      for i in eachindex(indices)[3:end]
        j = 3 * (i - 2)
        new_indices[j - 2] = indices[i - 2]
        new_indices[j - 1] = indices[i - i % 2]
        new_indices[j] = indices[i - 1 + i % 2]
      end
      return new_indices
    elseif from === MESH_TOPOLOGY_TRIANGLE_FAN
      new_indices = Vector{T}(undef, 3(n - 2))
      origin = indices[1]
      for i in eachindex(indices)[3:end]
        j = 3 * (i - 2)
        new_indices[j - 2] = origin
        new_indices[j - 1] = indices[i - 1]
        new_indices[j] = indices[i]
      end
      return new_indices
    end
  else
    from === MESH_TOPOLOGY_TRIANGLE_LIST && error("Reencoding into a triangle list from any other topology is not well-defined.")
    error("Only reencoding into a triangle list is supported at the moment.")
  end
end

"""
Mesh represented with indexed vertices using a specific [`IndexEncoding`](@ref).
"""
@struct_hash_equal struct VertexMesh{I,T,VA<:AbstractVector{T}}
  encoding::MeshEncoding{I}
  vertex_attributes::VA
end

VertexMesh(encoding::MeshEncoding, vertices::PointSet) = VertexMesh(encoding, vertices.points)
VertexMesh(indices::AbstractVector{T}, vertices) where {T<:Integer} = VertexMesh(MeshEncoding(MESH_TOPOLOGY_TRIANGLE_LIST), indices)
VertexMesh(vertices) = VertexMesh(MeshEncoding(MESH_TOPOLOGY_TRIANGLE_STRIP, eachindex(vertices)), vertices)

function VertexMesh(mesh::Mesh)
  all(istri, faces(mesh)) || error("The mesh must be triangulated.")
  ishomogeneous(mesh) || error("Only homogeneous meshes are supported.")
  length(mesh.vertex_attributes) == nv(mesh) || error("Vertex data is missing from the mesh")

  # Remap vertex indices into a contiguous range as a triangle list.
  vertex_index_map = Dictionary(index.(vertices(mesh)), 1:nv(mesh))
  indices = Vector{Int64}(undef, 3nf(mesh))
  for (i, face) in enumerate(faces(mesh))
    for (j, (; prev)) in enumerate(edge_cycle(mesh, face))
      @inbounds indices[3(i - 1) + j] = vertex_index_map[index(prev)]
    end
  end

  encoding = MeshEncoding(MESH_TOPOLOGY_TRIANGLE_LIST, indices)
  vertex_attributes = collect(sortkeys(mesh.vertex_attributes))
  VertexMesh(encoding, vertex_attributes)
end

vertices(mesh::VertexMesh) = [location(attr) for attr in mesh.vertex_attributes]
