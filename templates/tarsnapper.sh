#!/bin/bash

# ###############################################################################
# FUNCTIONS
# ###############################################################################
function log {
    echo `date +%F\ %T`: "$@"
}

function failed {
    log "backup generation FAILED: Line: $1, Code: $2"
    exit $2
}

# ###############################################################################
# ENVIRONMENT
# ###############################################################################
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

trap 'failed ${LINENO} ${$?}' ERR

exec > >(tee -a "{{ tarsnap_log_file }}")
exec 2>&1

. {{ tarsnapper_virtualenv_path }}/bin/activate

# ###############################################################################
# MAIN
# ###############################################################################
log "backup generation START"
# arguments to tarsnap (via -o) must be before arguments to tarsnapper
tarsnapper -o configfile "{{ tarsnap_config_file }}" -c "{{ tarsnapper_config_file }}"  make
log "backup generation DONE"
