module GeometryExperimentsGLTFExt

using GeometryExperiments
using StaticArrays: SVector, SMatrix
using Base64: base64decode
using StyledStrings
using PrecompileTools
using LinearAlgebra: diagm
import GLTF

import GeometryExperiments: load_mesh_gltf, VertexMesh, Transform

function component_type(type)
  type === GLTF.BYTE && return Int8
  type === GLTF.UNSIGNED_BYTE && return UInt8
  type === GLTF.SHORT && return Int16
  type === GLTF.UNSIGNED_SHORT && return UInt16
  type === GLTF.UNSIGNED_INT && return UInt32
  type === GLTF.FLOAT && return Float32
  error("Unknown component type $type")
end

function data_type(type, ::Type{T}) where {T}
  type == "SCALAR" && return T
  type == "VEC2" && return SVector{2,T}
  type == "VEC3" && return SVector{3,T}
  type == "VEC4" && return SVector{4,T}
  error("Unknown data type `$type`")
end

function mesh_topology(mode)
  mode === GLTF.TRIANGLES && return MESH_TOPOLOGY_TRIANGLE_LIST
  mode === GLTF.TRIANGLE_STRIP && return MESH_TOPOLOGY_TRIANGLE_STRIP
  mode === GLTF.TRIANGLE_FAN && return MESH_TOPOLOGY_TRIANGLE_FAN
  mode === LINE_LOOP && error("The `LINE_LOOP` primitive topology is not supported.")
  mode === POINTS && error("The `POINTS` primitive topology is not supported.")
  mode in (GLTF.LINES, GLTF.LINE_STRIP) && error("Line topologies are not supported.")
  error("Unknown mode `$mode`")
end

function read_data(buffer::GLTF.Buffer)
  uri = buffer.uri::String
  data_sep = findfirst(==(','), uri)::Int
  header = uri[1:(data_sep - 1)]
  media_type = (match(r"data:(.*);", header)::RegexMatch)[1]
  data = if media_type == "application/octet-stream"
    binary_blob = uri[(data_sep + 1):end]
    encoding = match(r";(.*)$", header)
    if !isnothing(encoding) && encoding[1] == "base64"
      base64decode(binary_blob)
    else
      IOBuffer(binary_blob).data
    end
  else
    binary_file = uri[(data_sep + 1):end]
    read(binary_file)
  end
end

function Transform(node::GLTF.Node)
  if !isnothing(node.matrix)
    if length(node.matrix) ≠ 16
      @warn "Expected 16-component list for matrix data, got list with length $(length(node.matrix))"
      return Transform{3,Float32}()
    end
    # It is not impossible that we have shear and/or perspective projection,
    # but the spec only specifies that we get a matrix for a composed scaling, rotation and translation.
    # XXX: Have more checks for that.
    matrix = SMatrix{4,4}(node.matrix)
    return Transform(matrix)
  end
  translation = Translation(node.translation)
  rotation = Rotation(node.rotation)
  scaling = Scaling(node.scale)
  Transform{3,Float32}(translation, rotation, scaling)
end

function read_data(buffer::GLTF.Buffer, buffer_view::GLTF.BufferView)
  data = read_data(buffer)
  length(data) == buffer.byteLength || @warn "`buffer.byteLength` does not match the parsed data. This may indicate data corruption."
  stride = something(buffer_view.byteStride, 1)
  start = 1 + buffer_view.byteOffset
  stop = buffer_view.byteLength + buffer_view.byteOffset
  data[start:stride:stop]
end

function read_data(::Type{T}, buffer::GLTF.Buffer, buffer_view::GLTF.BufferView) where {T}
  reinterpret(T, read_data(buffer, buffer_view))
end

function read_data(::Type{T}, gltf, buffer_view::GLTF.BufferView) where {T}
  buffer = gltf.buffers[buffer_view.buffer]
  read_data(T, buffer, buffer_view)
end

function read_data(gltf, accessor::GLTF.Accessor)
  CT = component_type(accessor.componentType)
  T = data_type(accessor.type, CT)
  buffer_view = gltf.bufferViews[accessor.bufferView]
  read_data(T, gltf, buffer_view)
end

function read_index_data(gltf, primitive::GLTF.Primitive)
  accessor = gltf.accessors[primitive.indices]
  (; target) = gltf.bufferViews[accessor.bufferView]
  if !isnothing(target) && target !== GLTF.ELEMENT_ARRAY_BUFFER
    @debug styled"{yellow:WARNING}: Expected `ELEMENT_ARRAY_BUFFER` ($(GLTF.ELEMENT_ARRAY_BUFFER)) buffer view target for index buffer view, but got a different target ($target)"
  end
  read_data(gltf, accessor)
end

function read_mesh_encoding(gltf, primitive::GLTF.Primitive)
  topology = mesh_topology(something(primitive.mode, GLTF.TRIANGLES))
  indices = read_index_data(gltf, primitive)
  MeshEncoding(topology, indices)
end

function VertexMesh(gltf::GLTF.Object, mesh::GLTF.Mesh)
  length(mesh.primitives) == 1 || error("In mesh, exactly one primitive is supported at the moment.")
  primitive = mesh.primitives[0]
  !isnothing(primitive.indices) || error("Only indexed geometries are supported at the moment.")
  encoding = read_mesh_encoding(gltf, primitive)
  @debug "Found mesh named '$(mesh.name)' of topology $(encoding.topology) with $(length(encoding.indices)) indices of type $(eltype(encoding.indices))"
  haskey(primitive.attributes, "POSITION") || error("`POSITION` attribute is required but not present for primitive in mesh $(node.mesh)")
  vertex_locations = read_data(gltf, gltf.accessors[primitive.attributes["POSITION"]])
  vertex_normals = haskey(primitive.attributes, "NORMAL") ? read_data(gltf, gltf.accessors[primitive.attributes["NORMAL"]]) : nothing
  VertexMesh(encoding, vertex_locations; vertex_normals)
end

function VertexMesh(gltf::GLTF.Object, node::GLTF.Node)
  !isnothing(node.mesh) || throw(ArgumentError("Node `$node` does not have a mesh component."))
  mesh = gltf.meshes[node.mesh]
  vmesh = VertexMesh(gltf, mesh)
  tr = Transform(node)
  # XXX: Apply the transform to the node.
  tr ≉ Transform{3,Float32}() && error("Non-identity GLTF node transforms not supported yet")
  vmesh
end

function VertexMesh(gltf::GLTF.Object)
  scene = gltf.scenes[gltf.scene]
  mesh_indices = findall(x -> !isnothing(x.mesh), collect(gltf.nodes))
  isempty(mesh_indices) && error("No mesh found.")
  length(mesh_indices) > 1 && error("More than one mesh found.")
  i = only(mesh_indices)
  node = gltf.nodes[scene.nodes[i]]
  VertexMesh(gltf, node)
end

load_mesh_gltf(file::AbstractString) = VertexMesh(GLTF.load(file))

@compile_workload begin
  file = joinpath(pkgdir(GeometryExperiments), "test", "assets", "cube.gltf")
  load_mesh_gltf(file)
end

end # module
