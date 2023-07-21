euclidean(kvec::KVector{1,<:Any,D}) where {D} = kvec[begin:(end - 1)] ./ kvec[end]

abstract type AlgebraicEntity end

Base.getindex(entity::AlgebraicEntity) = entity.data
SymbolicGA.getcomponent(entity::AlgebraicEntity, i) = SymbolicGA.getcomponent(entity[], i)
SymbolicGA.getcomponent(entity::AlgebraicEntity) = SymbolicGA.getcomponent(entity[])
