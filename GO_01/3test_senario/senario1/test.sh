a=1
b=1
c=0
let "c = $b + 1"
echo $c

if [ $a -eq $b ]; then
    let "b+=1"
fi
echo $b

testfunc2 ()
{
    echo "$# parameters";
    
    echo Using '1 $*';
    for p in $*;
    do
        echo "[$p]";
    done;
    
    echo Using '2 "$*"';
    for p in "$*";
    do
        echo "[$p]";
    done;
    echo Using '3 $@';
    for p in $@;
    do
        echo "[$p]";
    done;
    echo Using '4 "$@"';
    for p in "$@";
    do
        echo "[$p]";
    done
}

testfunc2 is a function