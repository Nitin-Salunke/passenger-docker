#!/bin/bash -e

# Versions to build
opensslfips=$OPENSSL_FIPS_MODULE
opensslcore=$OPEN_SSL_CORE
nodejs=node-$NODE_VERSION

# Create a working directory
cd "$(dirname $0)/.."
rm -rf dist
mkdir -p dist
cd dist

# Remove existing openssl
cp /usr/bin/c_rehash c_rehash # backup c_rehash
sudo apt-get autoremove -y openssl

# Get ca-certificates which is compatible with openssl-1.0.2.xx series
curl -s http://archive.ubuntu.com/ubuntu/pool/main/c/ca-certificates/ca-certificates_20170717~16.04.2_all.deb > ca-certificates.deb

# Download source code packages
curl -s "https://www.openssl.org/source/$opensslfips.tar.gz" > "$opensslfips.tar.gz"
curl -s "https://www.openssl.org/source/$opensslcore.tar.gz" > "$opensslcore.tar.gz"

# Verify packages downloaded successfully
echo "$(curl https://www.openssl.org/source/$opensslfips.tar.gz.sha256) $opensslfips.tar.gz" > openssl-checksums.sha256
echo "$(curl https://www.openssl.org/source/$opensslcore.tar.gz.sha256) $opensslcore.tar.gz" >> openssl-checksums.sha256
sha256sum -c openssl-checksums.sha256

# Unpack packages
tar xzvf "$opensslfips.tar.gz"
tar xzvf "$opensslcore.tar.gz"

# Build the FIPS module first
pushd "$opensslfips"
  ./config
  make
  sudo make install
popd

# Then build OpenSSL with FIPS support
pushd "$opensslcore"
  ./config fips shared
  make -j $(nproc)
  # Have used checkinstall so that apt-get is aware of the package and donot try to reinstall it as dependency of another package
  sudo checkinstall
popd

# Make the built OpenSSL binary the default one for the system
sudo update-alternatives --force --install /usr/bin/openssl openssl /usr/local/ssl/bin/openssl 50

# Point the built OpenSSL's configuration at the system default (which is the one Node looks at)
#sudo ln -f -s /etc/ssl/openssl.cnf /usr/local/ssl/openssl.cnf

# Enable global FIPS mode in that configuration. It's all FIPS, all the time!
# sudo cat << 'EOF' > /etc/ssl/openssl.cnf
# openssl_conf = openssl_conf_section
#
# [openssl_conf_section]
# alg_section = evp_settings
#
# [evp_settings]
# fips_mode = yes
# EOF

# Copy c_rehash back to bin as it is required by ca-certificates package
cp c_rehash /usr/bin/c_rehash

# Install the compatible version of ca-certificates
apt-get install -y ./ca-certificates.deb


# Cleanup
rm -rf ca-certificates.deb "$opensslfips.tar.gz" "$opensslcore.tar.gz" "$opensslfips" "$opensslcore"
