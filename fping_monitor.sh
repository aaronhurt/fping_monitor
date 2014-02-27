#!/usr/bin/env bash

## fping location
_fping_bin=$(which fping)

## default host list
_hosts="localhost"

## default polling interval
_poll=60

## default ping log
_log="${PWD}/ping-log.txt"

## show help
_show_help() {
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "    -s   space separated list of hosts"
    echo "    -i   polling interval (fpint reporting period)"
    echo "    -l   logfile location"
    echo "    -h   show this message"
    echo ""
    exit 0
}

## get arguments
while getopts "s:c:l:h" opt; do
    case $opt in
        s)
            ## set hosts
            _hosts=$OPTARG
        ;;
        c)
            ## set count
            _count=$OPTARG
        ;;
        l)
            ## set log
            _log=$OPTARG
        ;;
        h)
            ## show help
            _show_help
        ;;
        *)
            ## display error
            echo "Invalid argument ${OPTARG}"
            ## show help
            _show_help
        ;;
    esac
done

## shift options
shift $((OPTIND - 1))

## log function
_do_log() {
    ## log to stdout
    echo $1
    ## log to file
    echo $1 >> $_log
}

## parse fping lines
_parse_line() {
    ## match timestamps
    if [[ "${1}" =~ ^\[(.*)\]$ ]]; then
        _ts=${BASH_REMATCH[1]}
    fi

    ## match result lines
    if [[ "${1}" =~ ([0-9]+)/([0-9]+)/([0-9]+)\% ]]; then
        ## parse out sent packets
        local _sent=${BASH_REMATCH[1]}
        ## parse out received packets
        local _received=${BASH_REMATCH[2]}
        ## parse out loss percent packets
        local _loss=${BASH_REMATCH[3]}
        ## get hostname
        local _name=$(echo ${1} | awk '{ print $1 }')
        ## logic checks
        if [ $_received -lt $_sent ]; then
            ## calculate lost packet count
            local _lost=$(expr $_sent - $_received)
            ## print log
            _do_log "$(printf '@%s %d of %d packets lost (%s%%) to %s over %d second window' $_ts $_lost $_sent $_loss $_name $_poll)"
        fi
    fi
}

## run fping
_do_fping() {
    while read line; do
        _parse_line "$line"
    done < <($_fping_bin -r 1 -p 500 -Q $_poll -l $_hosts 2>&1)
}

## do it
_do_fping
