with(LinearAlgebra);
with(ListTools);
with(ArrayTools);

## Suit of useful procs.
equfy := proc(u)
local i, v;
    v := copy(u);
    for i in seq(1..Size(v,1))
    do v[i] := v[i] = 0;
    end do;
    return v;
end proc:


## Angelica
SignCoeffs := proc(p, var)
    return ListTools[MakeUnique](map(signum, [coeffs(collect(p, convert(var,set), distributed), var)]));
end proc:

## Angelica
PolyToVector := proc(p, var)
local i, j, thecoeffs, terms;
    thecoeffs := [coeffs(collect(p, var, distributed), var, 'terms')];
    return [seq([thecoeffs[j], seq(degree(terms[j], var[i]), i = 1 .. numelems(var))], j = 1 .. numelems([terms]))];
end proc:

SetFirstToOne := proc(l::list)::list;
local i, t;
    t := Array(1 .. nops(l));
    for i to nops(l) do
        t[i] := l[i];
        t[i][1] := 1;
    end do;
    return convert(t, list);
end proc:

SearchAllPredicate := proc(f, L)
local i, e, index;
    i := 0;
    index := Vector[row]();
    for e in L do
        i := i + 1;
        if f(e) then
            index := <index | i>;
        end if;
    end do;
    return index;
end proc:

PotentiallyNegCoeffs := proc(poly, parameters)
local signcffs, index, negcffs, negexps;
    # polyvec := PolToVector(poly, vars);
    signcffs := map(X -> SignCoeffs(X, parameters), [seq(poly[i][1], i=1..nops(poly))]);
    print(signcffs);
    index := SearchAllPredicate(X -> (-1) in X, signcffs);
    negcffs := [seq(factor(poly[i][1]), i in index)];
    negexps := [seq(poly[i][2..], i in index)];
    print(Vector[column](negcffs));
    return (negcffs, negexps, index);
end proc:

krelations := proc(poly, ks)
local lc, facts, krel, fact;
    facts := factors(poly);
    krel := 1;
    for fact in facts[2] do
        if type(fact[2], odd) and (-1) in SignCoeffs(fact[1], {op(ks)}) then
            krel := krel*fact[1];
        end if;
    end do;
    return facts[1]*krel;
end proc:

SearchingMultistationarity := proc(sys, DJ, depenvars, xs, ks)
local param, freevars, DJparam, polyA, vecpolyA, negcffA, negexpA, negA, krels;
    param := solve(convert(equfy(sys), set), convert(depenvars, set));
    freevars := [op(convert(xs, set) minus convert(depenvars, set))];
    DJparam := subs(param, DJ);
    polyA := numer(DJparam);
    print("Denominator of DJparam:(check that its sign just depends on the numerator)");
    print(denom(DJparam));
    vecpolyA := PolyToVector(polyA, freevars);
    negcffA, negexpA, negA := PotentiallyNegCoeffs(vecpolyA, convert(ks, set));
    krels := map(X -> krelations(X, ks), negcffA);
    return (krels, negcffA, negexpA, negA, collect(polyA, freevars, 'distributed', factor), vecpolyA, param);
end proc:

StabilityMatrix := proc(M::Matrix)
local p, i, j, d, pol, m, k;
global H;
    d := LinearAlgebra[Dimension](M)[1] - LinearAlgebra[Rank](M);
    p := simplify(LinearAlgebra[CharacteristicPolynomial](M, y)/y^d);
    H := HurwitzDet(degree(p, y));
    m := numelems(H);
    for i to m do H[i] := subs(seq(a[k] = coeff(p, y, k), k = 0 .. degree(p, y)), H[i]);
    end do;
    print(m*'expressions*will*be*studied');
    for j to m - 1 do print(['Hurwitz*determinant'*'H'[j], SignCoeffs(numer(H[j]), indets(numer(H[j]))), SignCoeffs(denom(H[j]), indets(denom(H[j])))]);
    end do;
    print(["Lowest degree term", SignCoeffs(numer(H[m]), indets(numer(H[m]))), SignCoeffs(denom(H[m]), indets(denom(H[m])))]);
end proc:

HurwitzDet := proc(n::integer)::list;
local s, t, H, M, i, j, k;
    M := Matrix(n);
    for i to n do
        for j to n do
            if (n - 2*i + j) in [seq(t, t = 0 .. n)] then M[i, j] := a[n - 2*i + j];
            end if;
        end do;
    end do;
    H := [];
    for i to n - 1 do H := [op(H), factor(LinearAlgebra[Determinant](LinearAlgebra[SubMatrix](M, [seq(k, k = 1 .. i)], [seq(k, k = 1 .. i)])))];
    end do;
    H := [op(H), a[0]];
    return H;
end proc:

# splitkrel := proc(krel, ks)
# local poskrel, negkrel, terms, coefflist, i;
#     poskrel := 0;
#     negkrel := 0;
#     coefflist := coeffs(collect(krel, ks, distributed), ks, 'terms');
#     for i from 1 to numelems(coefflist) do
#         if coefflist[i] < 0 then
#             negkrel := negkrel - coefflist[i]*terms[i];
#         else
#             poskrel := poskrel + coefflist[i]*terms[i];
#         end if;
#     end do;
#     return [factor(negkrel), factor(poskrel)]
# end proc:

splitkrel := proc(krel, ks)
local poskrel, negkrel, terms, coefflist, ct;
    poskrel := 0;
    negkrel := 0;
    coefflist := coeffs(collect(krel, ks, distributed), ks, 'terms');
    for ct in zip(`[]`, [coefflist], [terms]) do
        if ct[1] < 0 then
            negkrel := negkrel - ct[1]*ct[2];
        else
            poskrel := poskrel + ct[1]*ct[2];
        end if;
    end do;
    return [factor(negkrel), factor(poskrel)]
end proc:

nicekrelstoLaTeX := proc(krel, ks)
local skrel;
    skrel := splitkrel(krel, ks);
    return latex(skrel[2]<skrel[1]);
end proc:

Velocities := proc(Y, vars)
local i, j, v;
    v := Vector[column](LinearAlgebra[ColumnDimension](Y));
    for i to LinearAlgebra[ColumnDimension](Y) do
        v[i] := 1;
        for j to LinearAlgebra[RowDimension](Y) do
            v[i] := v[i]*vars[j]^Y[j, i];
        end do;
    end do;
    return v;
end proc:
