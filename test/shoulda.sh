function shoulda()
{
    filename=${1%:*}
    line=${1#*:}

    if [ ! -e "$filename" ]; then
        echo "Could not find file $filename"
        return
    fi

    if [ "$line" = "$filename" ]; then
        ruby "$filename"
        return
    else
        strline=$(cat $filename | head -$line | tail -1)
        echo "ruby \"$filename\" -n \"$strline\""
    fi

}

shoulda "$*"
