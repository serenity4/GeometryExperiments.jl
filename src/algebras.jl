macro pga2(T, ex)
  definitions = quote
    embed(x) = x[1]::e1 + x[2]::e2
    magnitude2(x) = x ⦿ x
    point(x) = embed(x) + 1.0::e3
  end
  bindings = parse_bindings(definitions; warn_override = false)
  esc(codegen_expression((2, 0, 1), ex; T, bindings))
end
macro pga2(ex)
  esc(:(@pga2 $nothing $ex))
end

macro pga3(T, ex)
  definitions = quote
    embed(x) = x[1]::e1 + x[2]::e2 + x[3]::e3
    magnitude2(x) = x ⦿ x
    point(x) = embed(x) + 1.0::e4
  end
  bindings = parse_bindings(definitions; warn_override = false)
  esc(codegen_expression((3, 0, 1), ex; T, bindings))
end
macro pga3(ex)
  esc(:(@pga3 $nothing $ex))
end

euclidean(kvec::KVector{1,<:Any,D}) where {D} = kvec[begin:(end - 1)] ./ kvec[end]

abstract type AlgebraicEntity end

Base.getindex(entity::AlgebraicEntity) = entity.data
SymbolicGA.getcomponent(entity::AlgebraicEntity, i) = SymbolicGA.getcomponent(entity[], i)
SymbolicGA.getcomponent(entity::AlgebraicEntity) = SymbolicGA.getcomponent(entity[])
