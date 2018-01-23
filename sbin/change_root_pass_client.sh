pass=$1
error_exit() {
    echo $*
    exit 1
}

[ -n "$pass" ] || error_exit "$(basename $0) <password>"
tabch key=system passwd.username=root passwd.password=`openSSL passwd -1 $pass`
