use application "polytope";
use Polymake;
use Polymake::User;
use Polymake::Core::CPlusPlus;
##########################
##
## polymake --script VerticesPolymake.pl "exponents.txt" "verticies.txt" 
##
## "exponents.txt" is the input file with the list of homo. exponents.
## "verticies.txt" is the name for the output file to save the list of vertices.
##########################
##
## Save exponents in Maple with
## writedata("exponents.txt", listofexponents, integer)
## where 'listofexponents' is the 'list' of homogenised exponenets (with an extra first coordinate equal 1).
my $rf=shift @ARGV;
open(INPUT, "<", $rf);
my $m = new Matrix<Rational>(<INPUT>);
close(INPUT);
my $p = new Polytope(POINTS=>$m);
my $wf=shift @ARGV;
open(my $f, '>', $wf); print $f $p->VERTICES; close $f;
print $p->N_VERTICES;
print "\n\n";
## Load points to Maple with
## Ver:= readdata(vertices.txt,integer,n)
## where n is the dimension (that is, number of rows)
## the number printed by the last line :)
## Now, in Maple we can compare points and vertices:
## convert(L, set) intersect convert(Ver, set)
#############################
##
## IF you want to compute a point realising the negativity:
##
## Finally, pick your favourite vertex, set $v and execute the following lines
# $v = ??;
# $j = for ($i=0; $i <= ($p->N_VERTICES); $i++){last if ($p->VERTICES[$i]==$v);} $i;
# open(my $g, '> cone.txt'); print $g normal_cone($p, $j, outer=>1)->RAYS; close $g;
## Then in Maple
# cone:=ImportMatrix("cone.txt", delimiter = " ")
## Compute an interior point, why not:
# dir := (Matrix(1, RowDimension(cone), fill = 1)).cone
## Create the column vector of exponents
# T := convert(dir,Vector):
# for i to ColumnDimension(dir) do
# T[i] := t^dir[1, i]:
# end do
### Here we use as initial point [1,1...]
