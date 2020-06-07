#!/bin/bash -e

# Try to use a disallowed function to prove the system OpenSSL is doing FIPS properly
export OPENSSL_FIPS=1
if openssl md5 &> /dev/null
then
  echo "OpenSSL did not disallow FIPS unapproved functions"
  exit -1
else
  echo "OpenSSL FIPS looks good"
fi
unset OPENSSL_FIPS
