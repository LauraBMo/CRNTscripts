include("writeMat.jl")

nxs = 8
SP, X = PolynomialRing(Nemo.ZZ,["X$i" for i in 1:nxs])

net = [X[2] X[1];
       X[1] X[2];
       X[3] X[5];
       X[5] X[4];
       X[4] X[6];
       X[4] X[3];
       X[6] X[5];
       X[7] X[2]+X[3];
       X[8] X[2]+X[4];
       X[1]+X[5] X[7];
       X[1]+X[6] X[8];
       X[7] X[1]+X[5];
       X[8] X[1]+X[6]]

toMaple(net, X, "M1.mpl")

net = [X[2] X[1];
       X[1] X[2];
       X[3] X[5];
       X[5] X[4];
       X[4] X[6];
       X[4] X[3];
       X[6] X[5];
       X[7] X[2]+X[3];
       X[8] X[2]+X[4];
       X[1]+X[5] X[7];
       X[1]+X[6] X[8]]

toMaple(net, X, "M1nonrev11.mpl")

net = [X[2] X[1];
       X[1] X[2];
       X[3] X[5];
       X[5] X[4];
       X[4] X[6];
       X[4] X[3];
       X[6] X[5];
       X[1]+X[5] X[2]+X[3];
       X[8] X[2]+X[4];
       0 0;
       X[1]+X[6] X[8]]

toMaple(net, X, "M1nonrev01.mpl")

net = [X[2] X[1];
       X[1] X[2];
       X[3] X[5];
       X[5] X[4];
       X[4] X[6];
       X[4] X[3];
       X[6] X[5];
       X[7] X[2]+X[3];
       X[1]+X[6] X[2]+X[4];
       X[1]+X[5] X[7]
       0 0];

toMaple(net, X, "M1nonrev10.mpl")

net = [X[2] X[1];
       X[1] X[2];
       X[3] X[5];
       X[5] X[4];
       X[4] X[6];
       X[4] X[3];
       X[6] X[5];
       X[1]+X[5] X[2]+X[3];
       X[1]+X[6] X[2]+X[4]
       0 0;
       0 0;]

toMaple(net, X, "M1nonrev00.mpl")
