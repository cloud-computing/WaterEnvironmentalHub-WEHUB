#!/bin/bash

[[ "`/usr/bin/tty`" == "not a tty" ]] && . ~/.bash_profile

. do_run_script_and_email_results.sh do_clear_html_cache.sh