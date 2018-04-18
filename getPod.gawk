## function: return the indexed item from pod info

function getItemFromInfo(i)
{
    print $i
}
## script: get the needed item from info
BEGIN {
    FS=":"
}
{
    getItemFromInfo(n)
}

