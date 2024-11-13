var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = GeometryExperiments","category":"page"},{"location":"#GeometryExperiments","page":"Home","title":"GeometryExperiments","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for GeometryExperiments.","category":"page"},{"location":"","page":"Home","title":"Home","text":"(work in progress)","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [GeometryExperiments]","category":"page"},{"location":"#GeometryExperiments.BezierCurve-Tuple{Any}","page":"Home","title":"GeometryExperiments.BezierCurve","text":"Apply Horner's method on the monomial representation of the Bézier curve B = ∑ᵢ aᵢtⁱ with i ∈ [0, n], n the degree of the curve, aᵢ = binomial(n, i) * pᵢ * t̄ⁿ⁻ⁱ and t̄ = (1 - t). Horner's rule recursively reconstructs B from a sequence bᵢ with bₙ = aₙ and bᵢ₋₁ = aᵢ₋₁ + bᵢ * t until b₀ = B.\n\n\n\n\n\n","category":"method"},{"location":"#GeometryExperiments.BezierEvalMethod","page":"Home","title":"GeometryExperiments.BezierEvalMethod","text":"Evaluation method used to obtain a point along a Bézier curve from a parametric expression.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.EdgeIterator","page":"Home","title":"GeometryExperiments.EdgeIterator","text":"Iterator on a mesh face which returns a tuple (prev, next, edge, swapped) where prev and next are the previous and next vertices in the edge cycle, edge the corresponding undirected edge and swapped a boolean value indicating whether the vertices of the undirected edge were swapped to yield prev and next.\n\nThe face must be a complete cycle of connected edges. Edges are not required to be connected exactly at dst => src points; since they are undirected, the last next vertex must simply be included as one of the two endpoints of the next edge in the face.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.Ellipsoid","page":"Home","title":"GeometryExperiments.Ellipsoid","text":"Ellipsoid(semiaxes)\n\nAn ellipsoid with semi-axes semiaxes. Is equivalent to a scaled HyperSphere.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.FixedDegree","page":"Home","title":"GeometryExperiments.FixedDegree","text":"Fast evaluation in the case of a fixed small number N of control points.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.GranularVector","page":"Home","title":"GeometryExperiments.GranularVector","text":"A vector type which can have items deleted without modifying indices of other values.\n\nFeatures include:\n\nNo hashing is ever performed to access its contents.\nThe underlying buffer is contiguous in memory.\nNo allocations occur when retrieving elements by indices from that container or when iterating on the whole container.\nElements can be deleted from the container without having to worry about indices of other elements being shifted.\n\nIt is furthermore optimized to reuse indices of previously deleted elements when the number of deleted elements is greater than the number of live elements in the collection. For this reason, push! is O(n/2) in the worst case scenario (which should very rarely happen).\n\nNote that buffer slots are never deleted by purpose, except with empty!. Therefore, if the container grows then shrinks logically, memory won't be freed automatically. In this case, you must empty! the container manually or build another one.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.Horner","page":"Home","title":"GeometryExperiments.Horner","text":"Approximate evaluation using Horner's method. Recommended for a large number of control points, if you can afford a precision loss. See https://en.wikipedia.org/wiki/Horner%27s_method.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.HyperSphere","page":"Home","title":"GeometryExperiments.HyperSphere","text":"Hypersphere centered around the origin\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.Mesh","page":"Home","title":"GeometryExperiments.Mesh","text":"General representation of a two-dimensional mesh embedded in an arbitrary space.\n\nThe associated surface needs not be manifold; there can be dangling edges, lone vertices, and faces linked only by a single vertex.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.MeshEncoding","page":"Home","title":"GeometryExperiments.MeshEncoding","text":"Way to connect the various elements of a mesh, encoding its connectivity using integer indices.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.Patch","page":"Home","title":"GeometryExperiments.Patch","text":"Patch made by \"gluing\" curves together.\n\nIf compact is set to true, each curve starts from the point of the last curve, assumed to be on the curve.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.Projection","page":"Home","title":"GeometryExperiments.Projection","text":"Projection of an object of type O onto the first N dimensions.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.Quaternion","page":"Home","title":"GeometryExperiments.Quaternion","text":"Quaternion, using an WXYZ convention (real part first, then pure part).\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.SmoothingStrategy","page":"Home","title":"GeometryExperiments.SmoothingStrategy","text":"Describe how vertex normals should be computed for a given mesh.\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.Transform","page":"Home","title":"GeometryExperiments.Transform","text":"Linear transformation in Euclidean space.\n\nA Transform encodes a linear operation obtained by scaling, rotating and translating an object, in this particular order. Scaling and rotation are defined around the origin; rotation around another object must be encoded as a rotation first and then a translation.\n\nTo apply the transform to a point, use apply_transform(p, transform) To apply the inverse of this transform to a point, use apply_transform_inverse(p, transform).\n\n\n\n\n\n","category":"type"},{"location":"#GeometryExperiments.VertexMesh","page":"Home","title":"GeometryExperiments.VertexMesh","text":"Mesh represented with indexed vertices using a specific MeshEncoding.\n\n\n\n\n\n","category":"type"},{"location":"#Base.allunique-Tuple{Mesh}","page":"Home","title":"Base.allunique","text":"Check whether the mesh has duplicate elements.\n\n\n\n\n\n","category":"method"},{"location":"#GeometryExperiments.angle-Tuple{StaticArraysCore.SVector, StaticArraysCore.SVector}","page":"Home","title":"GeometryExperiments.angle","text":"Angle between (O,x) and (O, y) with O the origin of the Euclidean space.\n\n\n\n\n\n","category":"method"},{"location":"#GeometryExperiments.compute_vertex_normals","page":"Home","title":"GeometryExperiments.compute_vertex_normals","text":"Compute vertex normals for a triangle mesh.\n\n\n\n\n\n","category":"function"},{"location":"#GeometryExperiments.ensure_cyclic_edges!-Tuple{MeshFace, Mesh}","page":"Home","title":"GeometryExperiments.ensure_cyclic_edges!","text":"Make sure that edges specified in the face form a cycle.\n\nIf they don't form a cycle originally, then edges will be reordered so that a cycle can be formed with all edges; otherwise, an error will be thrown.\n\n\n\n\n\n","category":"method"},{"location":"#GeometryExperiments.ismanifold-Tuple{Mesh}","page":"Home","title":"GeometryExperiments.ismanifold","text":"Return whether the mesh represents the boundary of a 3-dimensional volume, i.e. it is homogeneously made of connected faces and there is no boundary (every edge is attached to exactly two faces).\n\n\n\n\n\n","category":"method"},{"location":"#GeometryExperiments.projection-Tuple{Any, Any}","page":"Home","title":"GeometryExperiments.projection","text":"projection(object, x) -> x′\n\nProject x onto object, and return the resulting point x′.\n\n\n\n\n\n","category":"method"},{"location":"#GeometryExperiments.projection_parameter","page":"Home","title":"GeometryExperiments.projection_parameter","text":"projection_parameter(parametric, x) -> t\n\nProject x onto parametric, and return the corresponding value t in parametric's parameter space.\n\n\n\n\n\n","category":"function"}]
}