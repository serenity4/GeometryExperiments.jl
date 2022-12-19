@testset "Camera" begin
  # Optical center is z = -1,
  # Image plane is located at z = 0.
  # Camera is therefore looking downwards.
  O = P3(0, 0, -1)
  A₁ = P3(1, 0, 0)
  A₂ = P3(1, 1, 0)
  A₃ = P3(0, 1, 0)

  camera = PinholeCamera(O, A₁, A₂, A₃)

  # All points viewed from the camera should end up with a null z component.
  # A point already in the image plane should stay in the image plane.
  p = P3(1.2, 1, 0)
  @test camera(p) == p
  # A point at exactly the focal length will be inverted along its x and y components.
  p = P3(1.2, 1, -2)
  @test camera(p) == P3(-1.2, -1, 0)
end;
