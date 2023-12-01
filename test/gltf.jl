gltf_file(filename) = joinpath(pkgdir(GeometryExperiments), "test", "assets", filename)
load_gltf(filename) = GLTF.load(gltf_file(filename))

@testset "GLTF loading" begin
  cube = load_gltf("cube.gltf")
  blob = load_gltf("blob.gltf")

  @testset "Mesh loading" begin
    mesh = VertexMesh(cube)
    @test isa(mesh, VertexMesh{UInt16,<:AbstractArray{Point3f},<:AbstractArray{Point3f}})
    @test nv(mesh) == 24

    mesh = VertexMesh(blob)
    @test isa(mesh, VertexMesh{UInt16,<:AbstractArray{Point3f},<:AbstractArray{Point3f}})
    @test nv(mesh) == 8249
  end

  @testset "Transforms" begin
    tr = Transform(only(cube.nodes))
    @test tr === Transform{3,Float32}()

    light, camera, sphere = blob.nodes

    @test Transform(light) === Transform{3,Float32}(;
      translation = Translation(4.025627613067627, 4.5642242431640625, -0.28052377700805664),
      rotation = Quaternion{Float32}(-0.28416627645492554, 0.7269423007965088, 0.34203392267227173, 0.5232754945755005),
    )
    @test Transform(camera) === Transform{3,Float32}(;
      translation = Translation(4.119870662689209, 3.0265700817108154, 4.373751640319824),
      rotation = Quaternion{Float32}(-0.17110589146614075, 0.3430515229701996, 0.0637064203619957, 0.9214012026786804)
    )
    @test Transform(sphere) === Transform{3,Float32}(;
      translation = Translation(0.8281484246253967, 0.8672217130661011, 0.3270725607872009)
    )
  end
end;
