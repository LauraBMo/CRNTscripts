#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Help                                                                         #
################################################################################
Help()
{
    echo "Usage: $0 [-b|t|n|h] \"file(s)\""
    echo "Compute vertices of polytope defined by rows of \"file(s)\"."
    echo "Vertices are save in a new file with the same name replacing \"exp\" for \"ver\"."
    echo
    echo "Options:"
    echo "-h           Display this help message."
    echo "-b \"str\"     Base string to be replaced in file name (default \"exp\")."
    echo "-t \"str\"     Target string for replacement (default \"ver\")."
    echo "-n           Do not create new file, save vertices in the same file."
    echo
}

search="exp"    # Default string to replace
replace="ver"   # Default replace with

################################################################################
################################################################################
# Process the input options.                                                   #
################################################################################
while getopts ":b:t:nh" opt; do
    case ${opt} in
        b)
            search=$OPTARG
            ;;
        t)
            replace=$OPTARG
            ;;
        n)
            search=""
            replace=""
            ;;
        h)
            Help
            exit 0
            ;;      
        \?)
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
                     ;;
                 :)
                     echo "Invalid option: $OPTARG requires an argument" 1>&2
                     exit 1
                     ;;
    esac
done
shift $((OPTIND -1))

################################################################################
# Checking there is a file, it should contain the points defining the polytope.
################################################################################
if [ "$#" -eq  "0" ]; then
    echo "I need some file to work with..."
    exit 1
fi

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################
for arg in "$@";do
    if [ -f "$arg" ]; then
        polymake --script VerticesPolymake.pl "$arg" "${arg/$search/$replace}"
        echo "$arg"
    else
        echo "Argument $arg descarted, I just know to work with files."
    fi
done
