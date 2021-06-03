"""
    @forward MyType.prop method1, method2, ...

Extend the provided methods by forwarding the property `prop` of `MyType` instances.
This will give, for a given `method`:
```julia
method(x::MyType, args...; kwargs...) = method(x.prop, args...; kwargs...)
```

"""
macro forward(ex, fs)
    Expr(:block, esc.(forward(ex, fs).args)...)
end

function forward(ex::Expr, fs::Expr; wrap=identity)
    T, prop = @match ex begin
        :($T.$prop) => (T, prop)
        _ => error("Invalid expression $ex, expected <Type>.<prop>")
    end

    fs = @match fs begin
        :(($(fs...),)) => fs
        :($mod.$method) => [fs]
        ::Symbol => [fs]
        _ => error("Expected a method or a tuple of methods, got $fs")
    end

    defs = map(fs) do f
        :($f(x::$T, args...; kwargs...) = $(wrap(:($f(x.$prop, args...; kwargs...)))))
    end

    Expr(:block, defs...)
end

macro forward_rewrap(ex, wrap, fs)
    Expr(:block, esc.(forward(ex, fs; wrap = x -> :($wrap($x))).args)...)
end
