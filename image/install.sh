#!/bin/bash
set -e
source /pd_build/buildconfig

run /pd_build/enable_repos.sh
run /pd_build/prepare.sh
run /pd_build/utilities.sh

# Install FIPS enabled openssl package
run chmod 777 /pd_build/fips.sh
run /pd_build/fips.sh

# Install Ruby 2.7.1
run /pd_build/ruby-2.7.1.sh

# Must be installed after Ruby, so that we don't end up with two Ruby versions.
run /pd_build/nginx-passenger.sh

run /pd_build/finalize.sh
