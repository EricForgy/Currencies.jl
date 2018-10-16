"""
A mutable collection of `Monetary` values of various currencies.

Like regular `Monetary` values, `Basket` values support basic arithmetic
operations, with both other baskets and with raw monetary values. The
constructor for `Basket` accepts either a monetary value or a vector of
monetary values.

```julia
basket = Basket([1USD, 5EUR])        # \$1 + 5€
basket += 2EUR                       # \$1 + 7€
basket *= 2                          # \$2 + 14€
```

`Basket` values also support iteration. The iteration order of currencies is
undefined. For instance, the following will print `1.00 USD` and `5.00 EUR`, in
some order. Iteration will skip over any currencies with zero weight in the
basket.

```julia
for amt in Basket([1USD, 5EUR])
    println(amt)
end
```

One can also mutate the basket with index notation, or with `push!`.

```julia
basket = Basket([1USD, 2EUR])
basket[:USD] = 3USD  # Basket([3USD, 2EUR])
push!(basket, 10GBP) # Basket([3USD, 2EUR, 10GBP])
```
"""
struct Basket <: AbstractMonetary
    table::SMDict
    Basket(ms::Union{AbstractArray,Tuple}) = new(buildtable(ms))
end

# basket outer constructor and convert-constructor
Basket() = Basket(())
(::Type{T})(x) where T <: Basket = convert(T, x)

# access methods
Base.length(b::Basket) = length(b.table)
Base.haskey(b::Basket, k) = haskey(b.table, k) && !iszero(b.table[k])
Base.getindex(b::Basket, T::Symbol) = get(b.table, T, zero(Monetary{T}))
Base.iterate(b::Basket, s...) = iterate(values(b.table), s...)

# arithmetic methods (for static & dynamic baskets)
- b::Basket = Basket([-x for x in b])
b::Basket + c::Basket = Basket((b, c))
b::Basket * k::Real   = Basket([x * k for x in b])
k::Real   * b::Basket = Basket([k * x for x in b])
b::Basket / k::Real   = Basket([x / k for x in b])

# methods for dynamic baskets
function Base.setindex!(b::Basket, m::Monetary, k::Symbol)
    if currency(m) ≠ k
        throw(ArgumentError("Monetary value type does not match currency"))
    end
    b.table[k] = m
    deleteifzero!(b.table, k)
    b
end

# somewhat strange because Baskets behave like collections and like numbers...
# maybe add! is a better name
Base.push!(b::Basket, m::Monetary) = (b[currency(m)] += m; b)
function Base.push!(b::Basket, c::Basket)
    for m in c
        push!(b, m)
    end
    b
end

# other methods (eltype, iszero, zero, ==)
          iszero(b::Basket) = isempty(b)
  Base.zero(::Type{Basket}) = Basket()
   Base.one(::Type{Basket}) = 1
Base.eltype(::Type{Basket}) = Monetary
