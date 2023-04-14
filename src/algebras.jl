macro pga2(args...)
  definitions = quote
    embed(x) = x[1]::e1 + x[2]::e2
    magnitude2(x) = x ⦿ x
    point(x) = embed(x) + 1.0::e3
  end
  varinfo = parse_variable_info(definitions; warn_override = false)
  esc(codegen_expression((2, 0, 1), args...; varinfo))
end

macro pga3(args...)
  definitions = quote
    embed(x) = x[1]::e1 + x[2]::e2 + x[3]::e3
    magnitude2(x) = x ⦿ x
    point(x) = embed(x) + 1.0::e4
  end
  varinfo = parse_variable_info(definitions; warn_override = false)
  esc(codegen_expression((3, 0, 1), args...; varinfo))
end

euclidean(kvec::KVector{1,<:Any,D}) where {D} = kvec[begin:(end - 1)] ./ kvec[end]

abstract type AlgebraicEntity end

Base.getindex(entity::AlgebraicEntity) = entity.data
SymbolicGA.getcomponent(entity::AlgebraicEntity, i) = SymbolicGA.getcomponent(entity[], i)
SymbolicGA.getcomponent(entity::AlgebraicEntity) = SymbolicGA.getcomponent(entity[])
