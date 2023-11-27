euclidean(vec) = vec[begin:(end - 1)] ./ vec[end]

abstract type AlgebraicEntity end

Base.getindex(entity::AlgebraicEntity) = entity.data
SymbolicGA.getcomponent(entity::AlgebraicEntity, i) = SymbolicGA.getcomponent(entity[], i)
SymbolicGA.getcomponent(entity::AlgebraicEntity) = SymbolicGA.getcomponent(entity[])
