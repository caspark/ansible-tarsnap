#!/bin/bash

# ###############################################################################
# CONFIGURATION
# ###############################################################################
CONF="{{ tarsnap_config_file }}"

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
tarsnapper -c "$CONF" make
log "backup generation DONE"
