module GeometryExperimentsGLTFExt

using GeometryExperiments
using StaticArrays: SVector
using Base64: base64decode
using StyledStrings
using PrecompileTools
import GLTF

import GeometryExperiments: load_gltf

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

function load_gltf(file::AbstractString)
  gltf = GLTF.load(file)
  scene = gltf.scenes[gltf.scene]
  length(scene.nodes) == 1 || error("Exactly one scene node is supported at the moment.")
  node = gltf.nodes[scene.nodes[1]]
  mesh = gltf.meshes[node.mesh]
  length(mesh.primitives) == 1 || error("In mesh, exactly one primitive is supported at the moment.")
  primitive = mesh.primitives[0]
  !isnothing(primitive.indices) || error("Only indexed geometries are supported at the moment.")
  encoding = read_mesh_encoding(gltf, primitive)
  @debug "Found mesh named '$(mesh.name)' of topology $(encoding.topology) with $(length(encoding.indices)) indices of type $(eltype(encoding.indices))"
  haskey(primitive.attributes, "POSITION") || error("`POSITION` attribute is required but not present for primitive in mesh $(node.mesh)")
  accessor = gltf.accessors[primitive.attributes["POSITION"]]
  position = read_data(gltf, accessor)
  VertexMesh(encoding, position)
end

@compile_workload begin
  file = joinpath(pkgdir(GeometryExperiments), "test", "assets", "cube.gltf")
  load_gltf(file)
end

end # module
