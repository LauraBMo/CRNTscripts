
###############################################################################
#                       Script to generate Maple matrices and equations       #
#                       To be use jointly with Procs.mpl                      #
###############################################################################
# To use it, create a file defining your networks, say networks.jl, and execute:
#
# julia networks.jl
#
# Examples of files defining networks are M1.jl, M2.jl and M1&2.jl

using Nemo
using Polymake
import LinearAlgebra: I, dot

# Nemo.isnonzero(x) = (x) != (zero(x))
# use !iszero instead (it is performance equivalent and more clean)

function findfirstnonzero(A)
    return findfirst((!iszero), A)
end

function findpivots(W)
    # return findfirstnonzero.(eachrow(W)) ## it works just for matrices, code below is more generic.
    # return mapslices(findfirstnonzero, W, dims=collect(2:ndims(W)))
    return n -> findfirstnonzero.(eachslice(W, dims=n))
end

anynonzero(A) = any((!iszero).(A))

function nonzeroslices(M)
    # return n->vec(mapslices(anynonzero, M, dims=deleteat!(collect(1:ndims(M)),n)))
    return n -> anynonzero.(eachslice(M, dims=n))
end

function dropzeroslices(M)
    indeces = nonzeroslices(M).(1:ndims(M))
    return M[indeces...]
end

function stoichiometricsources(net::AbstractMatrix, xs::AbstractVector, getcoefficient)
    return Int.([getcoefficient(p, x) for x in xs, p in net[:,1]])
end

function stoichiometrictargets(net::AbstractMatrix, xs::AbstractVector, getcoefficient)
    return Int.([getcoefficient(p, x) for x in xs, p in net[:,2]])
end

function stoichiometriccoeffs(net::AbstractMatrix, xs::AbstractVector, getcoefficient)
    return hcat(stoichiometricsources(net, xs, getcoefficient), stoichiometrictargets(net, xs, getcoefficient))
end

function stoichiometriccoeffs(net::AbstractMatrix{T}, xs::AbstractVector) where {T <: RingElem}
    return hcat(stoichiometricsources(net, xs, Nemo.coeff), stoichiometrictargets(net, xs, Nemo.coeff))
end

function stoichiometriccoeffs(net::AbstractMatrix, xs::AbstractVector)
    R = parent(xs[1])
    return stoichiometriccoeffs(R.(net), xs)
end

function stoichiometricsources(net::AbstractMatrix)
    return net[:,1:div(end, 2)]
end

function stoichiometrictargets(net::AbstractMatrix)
    return net[:,div(end, 2) + 1:end]
end

# Matrix Y
function kineticorder(net::AbstractMatrix)
    return dropzeroslices(stoichiometricsources(net))
end

# Matrix N
function stoichiometricmatrix(net::AbstractMatrix)
    return dropzeroslices(stoichiometrictargets(net) - stoichiometricsources(net))
end

function conservativelaws(N::AbstractMatrix{T}) where {T <: Integer}
    Nnemo = matrix(FlintIntegerRing(), N)
    nTs, W = left_kernel(Nnemo)
    W = hnf(W)
    return nTs, Int.(Array(W))
end

function cone_positivenullspace(N::AbstractMatrix{T}) where {T <: Integer}
    ## Migrating to Nemo
    Nnemo = Nemo.matrix(Nemo.FlintZZ, N)
    ## Computing nullsapce
    r, U = Nemo.nullspace_right_rational(Nnemo)
    ## Comming back to julia
    nullsp = T.(Array(U[:,1:r]))
    ## The vector space generated by nullsp as a cone
    rays1 = transpose(hcat(nullsp, -nullsp))
    c1 = Polymake.polytope.Cone(INPUT_RAYS=rays1)
    ## The nonnegative orthant as a cone
    rays2 = Matrix{T}(I, size(N, 2), size(N, 2))
    c2 = Polymake.polytope.Cone(INPUT_RAYS=rays2)
    ## Compute intersection of c1 c2 and save RAYS
    d = Polymake.polytope.intersection(c1, c2).RAYS
    ## Convert to integers
    d = Polymake.@convert_to Matrix{Integer} d
    ## Return the intersection as a Base.Array matrix of integers
    return T.(transpose(Array(d)))
end

function matrixtoMaple(io, M, name)
    write(io, "\n\n$(name) := Matrix$(size(M)):\n\n")
    for i in CartesianIndices(M)
        if M[i] != 0
            write(io, "$(name)[$(i[1]),$(i[2])] := $(M[i]):\n")
        end
    end
end

function xstoMaple(io, stoichiometricsources)
    xs = (1:(size(stoichiometricsources, 1)))[nonzeroslices(stoichiometricsources)(1)]
    write(io, "\n\nnxs := $(size(xs, 1)):\n")
    write(io, "xs := [seq(x[i], i = [")
    for x in xs[1:(end - 1)]
        write(io, "$x, ")
    end
    write(io, "$(xs[end])])];\n\n")
    write(io, "depenvars := [seq(x[i], i = [")
    for x in xs[2:(end - 2)]
        write(io, "$x, ")
    end
    write(io, "$(xs[end - 1])])];\n\n")
end

function kstoMaple(io, stoichiometricsources)
    ks = (1:(size(stoichiometricsources, 2)))[nonzeroslices(stoichiometricsources)(2)]
    write(io, "\n\nnks := $(size(ks, 1)):\n")
    write(io, "ks := [seq(k[i], i = [")
    for k in ks[1:(end - 1)]
        write(io, "$k, ")
    end
    write(io, "$(ks[end])])];\n\n")
end

function systemtoMaple(io)
    write(io, "v := Velocities(Y,xs):\n")
    write(io, "digK := Matrix(nks):\n")
    write(io, "for i to nks do digK[i,i] := ks[i] end do:\n")
    write(io, "S := N.digK.v:\n")
    write(io, "Seq:= equfy(S);\n")
end

function WsystemtoMaple(io, nts, W)
    write(io, "\n\nSw := copy(S):\n")
    write(io, "Wx := (W.(Vector[column](xs))) - Vector[column]([seq(T[i], i = 1 .. $(nts))]):\n")
    for (i, p) in enumerate(findpivots(W)(1))
        write(io, "Sw[$p] := Wx[$i]:\n")
    end
    write(io, "Sweq:= equfy(Sw):\n")
    write(io, "J := VectorCalculus[Jacobian](Sw, xs):\n")
    write(io, "DJ := (-1)^(Rank(N))*Determinant(J):\n")
end

## It needs Y and E be defined in Maple
function ConvexparamtoMaple(io)
    write(io, "\n\ndigL := Matrix(convert(E.(Vector[column]([seq(lambda[i], i=1..LinearAlgebra[ColumnDimension](E))])), Vector[row]), shape = diagonal):\n")
    write(io, "digH := DiagonalMatrix([seq(h[i], i = 1..LinearAlgebra[ColumnDimension](LinearAlgebra[Transpose](Y)))]):\n")
    write(io, "Jconv := N.digL.LinearAlgebra[Transpose](Y).digH:\n")
end

macro matrixtoMaple(io, M)
    return quote
        matrixtoMaple($(esc(io)), $(esc(M)), $(esc((string(M)))))
    end
end

function toMaple(net, nxs, file::String)
    S = stoichiometriccoeffs(net, nxs) ## S may have zero rows and cols
    N = stoichiometricmatrix(S) ## Has no zero row or col
    nts, W = conservativelaws(N)
    Y = kineticorder(S)
    E = cone_positivenullspace(N)
    open(file, "w") do io
        write(io, "read(\"ModelsMatricies/Procs.mpl\"):\n")
        @matrixtoMaple io Y
        @matrixtoMaple io N
        @matrixtoMaple io W
        @matrixtoMaple io E
        xstoMaple(io, stoichiometricsources(S))
        kstoMaple(io, stoichiometricsources(S))
        systemtoMaple(io)
        WsystemtoMaple(io, nts, W)
        ConvexparamtoMaple(io)
    end
end

# function toMaple(net, nxs, file::String)
#     S = stoichiometriccoeffs(net, nxs) ## S may have zero rows and cols
#     N = stoichiometricmatrix(S) ## Has no zero row or col
#     nts, W = conservativelaws(N)
#     open(file, "w") do io
#         write(io, "read(\"ModelsMatricies/Procs.mpl\"):\n")
#         matrixtoMaple(io, kineticorder(S), "Y")
#         matrixtoMaple(io, N, "N")
#         matrixtoMaple(io, W, "W")
#         matrixtoMaple(io, cone_positivenullspace(N), "E")
#         xstoMaple(io, stoichiometricsources(S))
#         kstoMaple(io, stoichiometricsources(S))
#         systemtoMaple(io)
#         WsystemtoMaple(io, nts, W)
#         ConvexparamtoMaple(io)
#     end
# end
