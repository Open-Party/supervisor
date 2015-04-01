#!/usr/bin/env bash

##################### function #########################
_report_err() { echo "${MYNAME}: Error: $*" >&2 ; }

# if the output is terminal, display infomation in colors.
if [ -t 1 ]
then
    RED="$( echo -e "\e[31m" )"
    HL_RED="$( echo -e "\e[31;1m" )"
    HL_BLUE="$( echo -e "\e[34;1m" )"

    NORMAL="$( echo -e "\e[0m" )"
fi

_hl_red()    { echo "$HL_RED""$@""$NORMAL";}
_hl_blue()   { echo "$HL_BLUE""$@""$NORMAL";}

_trace() {
    echo $(_hl_blue '  ->') "$@" >&2
}

_print_fatal() {
    echo $(_hl_red '==>') "$@" >&2
}

function check_mkdir() {
    local dir=$1

    if [ x"$dir" == "x" ]; then
	_trace "dir string is null."
	return $RET_FAILED
    elif [ -d "${dir}" ]; then
	_trace "dir of ${dir} is existed, skip mkdir."
        return $RET_OK
    else
	_trace "mkdir ${dir}"
	mkdir -p ${dir}
	return $?
    fi
}

usage() {
    cat << USAGE
Usage: bash ${MYNAME} [options].

Options:
    -h, --help            Print this help infomation.

USAGE

    exit 1
}

RET_OK=0
RET_FAILED=1

#
# Parses command-line options.
#  usage: _parse_options "$@" || exit $?
#
function _parse_options()
{
    declare -a argv

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
            	usage
            	exit
            	;;
            --)
            	shift
                argv=("${argv[@]}" "${@}")
            	break
            	;;
            -*)
            	_print_fatal "command line: unrecognized option $1" >&2
            	return 1
            	;;
            *)
                argv=("${argv[@]}" "${1}")
                shift
                ;;
        esac
    done
}

_parse_options "${@}" || usage

g_SOFTWARE="${g_SOFTWARE:-/usr/bin/supervisord}"
if command -v "${g_SOFTWARE}" >/dev/null; then
    _trace "${g_SOFTWARE} is already intalled."
    exit $RET_OK
fi

g_SOFTLIST="elementtree-1.2.6  meld3-0.6.5  setuptools-14.3.1  supervisor-3.1.3"
for soft in ${g_SOFTLIST}; do
    _trace "Installing software now: $soft"
    if [ -d "$soft" ]; then
        pushd .
	cd $soft && python setup.py install
	popd
    else
        _print_fatal "Install $soft failed."
	exit $RET_FAILED
    fi
done

#
for dir in "/opt/log/supervisor"; do
    check_mkdir "${dir}"
done

g_CONF_FILE="supervisord.conf"
if [ -f "${g_CONF_FILE}" ]; then
    _trace "cp configure file to /etc/"
    cp -uf "${g_CONF_FILE}" /etc/
else
    _print_fatal "Configure file ${g_CONF_FILE} is not existed."
    exit $RET_FAILED
fi

g_EXEC_FILE="supervisord"
if [ -f "${g_EXEC_FILE}" ]; then
    _trace "cp exec file to /etc/init.d"
    cp -uf "${g_EXEC_FILE}" /etc/init.d/
else
    _print_fatal "Exec file ${g_EXEC_FILE} is not existed."
    exit $RET_FAILED
fi
#
touch /var/tmp/supervisor.sock

if [ $? -eq 0 ]; then
    sudo /sbin/chkconfig --add supervisord
fi

