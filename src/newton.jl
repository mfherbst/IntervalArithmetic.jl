using ValidatedNumerics
using AutoDiff

isthin(x) = (m = (x.lo + x.hi) / 2; m == x.lo || m == x.hi)  # no more precision


#mid(x::Interval) = @interval((x.lo + x.hi) / 2)

#mid(x::Interval) = Interval(@round_down( (x.lo + x.hi) / 2 ), @round_up( (x.lo + x.hi) / 2) )

function N(f::Function, x::Interval, deriv=None)

    if deriv==None
        deriv = differentiate(f, x)
    end

#     set_rounding(BigFloat, RoundDown)
#     m1 = (x.lo + x.hi) / 2
#     set_rounding(BigFloat, RoundUp)
#     m2 = (x.lo + x.hi) / 2

#     m = Interval(m1, m2)  # rounded mid-point
#     @show m

    m = (x.lo + x.hi) / 2
    if m == 0  # midpoint exactly 0
        alpha = 0.45
        m = alpha*x.lo + (1-alpha)*x.hi   # displace to another point in interval
    end

    m = Interval(m)


    Nx = m - ( f(m) / deriv )

end


function refine(f::Function, x::Interval)
    println("Refining $x")
    i = 0
    while i < 20  # avoid problem with tiny floating-point numbers if 0 is a root
        Nx = N(f, x)
        Nx = Nx ∩ x
        @show x, Nx
        # if Nx == x
        if Nx == x
            return @show (x, :unique)
        end
        x = Nx
        i += 1
        #@show x
    end
    return x
end

newton(f::Function, x::Nothing) = []

# *strict* subset:
⊂(a::Interval, b::Interval) = b.lo < a.lo && a.hi < b.hi
⊂(a::Nothing, b::Interval) = false



function newton(f::Function, x::Interval)

    if isempty(x)
        return []
    end
    # @show x

    m = mid(x)
    deriv = differentiate(f, x)

    if !(0 in deriv)
        Nx = N(f, x, deriv)

        println("Inside newton")
        @show (x, Nx)

        #if Nx ⊂ x
        if Nx in x && diam(Nx) < diam(x)
            return refine(f, Nx)
        end

        if isempty(Nx ∩ x)   # this is a type instability, since nothing is not an Interval
            return []
        end

        if isthin(x)
            return (x, :unknown)
        end

        # bisect:
        return vcat(newton(f, Interval(x.lo, m)),  # must be careful with rounding of m ?
                    newton(f, Interval(m, x.hi))
                    )

    else  # 0 in deriv
        y1 = Interval(deriv.lo, -0.0)
        y2 = Interval(0.0, deriv.hi)

        y1 = N(f, x, y1) ∩ x
        y2 = N(f, x, y2) ∩ x

        @show (y1, y2)


        return vcat(newton(f, y1),
                    newton(f, y2))
    end
end

import Base.show

#show(io::IO, x::Interval) = print(io, "[$(round(float(x.lo), 5)), $(round(float(x.hi), 5))]")
