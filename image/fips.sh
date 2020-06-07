#!/bin/bash -e

# Versions to build
opensslfips=$OPENSSL_FIPS_MODULE
opensslcore=$OPEN_SSL_CORE

# Create a working directory
cd "$(dirname $0)/.."
rm -rf dist
mkdir -p dist
cd dist

# Remove existing openssl
cp /usr/bin/c_rehash c_rehash # backup c_rehash
sudo apt-get autoremove -y openssl

# Get ca-certificates which is compatible with openssl-1.0.2.xx series
curl -S https://raw.githubusercontent.com/Nitin-Salunke/passenger-docker/master/binaries/ca-certificates_20170717_16.04.2_all.deb > ca-certificates_20170717_16.04.2_all.deb

# Download source code packages
curl -S "https://www.openssl.org/source/$opensslfips.tar.gz" > "$opensslfips.tar.gz"
curl -S "https://www.openssl.org/source/$opensslcore.tar.gz" > "$opensslcore.tar.gz"

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
sudo ln -f -s /etc/ssl/openssl.cnf /usr/local/ssl/openssl.cnf

# Enable global FIPS mode in that configuration. It's all FIPS, all the time!
sudo cat << 'EOF' > /etc/ssl/openssl.cnf
openssl_conf = openssl_conf_section

[openssl_conf_section]
alg_section = evp_settings

[evp_settings]
fips_mode = no
EOF

# Copy c_rehash back to bin as it is required by ca-certificates package
cp c_rehash /usr/bin/c_rehash

# Install the compatible version of ca-certificates
apt-get install -y ./ca-certificates_20170717_16.04.2_all.deb

# Hold the package from further update
apt-mark hold openssl

# Remove existing empty certs directory and create symlink
rm -r /usr/local/ssl/certs
ln -s /etc/ssl/certs /usr/local/ssl

# Cleanup
rm -rf ca-certificates_20170717_16.04.2_all.deb "$opensslfips.tar.gz" "$opensslcore.tar.gz" "$opensslfips" "$opensslcore"




## Install libmysqlclient20 and hold the further upgrade
apt-get remove -y libmysqlclient20
curl -S https://raw.githubusercontent.com/Nitin-Salunke/passenger-docker/master/binaries/libmysqlclient20_5.7.30-1ubuntu18.04_amd64.deb > libmysqlclient20_5.7.30-1ubuntu18.04_amd64.deb
apt-get install -y ./libmysqlclient20_5.7.30-1ubuntu18.04_amd64.deb
apt-mark hold libmysqlclient20

## Install libmysqlclient-dev and hold the further upgrade
apt-get remove -y libmysqlclient-dev
curl -S https://raw.githubusercontent.com/Nitin-Salunke/passenger-docker/master/binaries/libmysqlclient-dev_5.7.30-1ubuntu18.04_amd64.deb > libmysqlclient-dev_5.7.30-1ubuntu18.04_amd64.deb
apt-get install -y ./libmysqlclient-dev_5.7.30-1ubuntu18.04_amd64.deb
apt-mark hold libmysqlclient-dev

## Cleanup libmysqlclient20 & libmysqlclient-dev
rm -rf libmysqlclient20_5.7.30-1ubuntu18.04_amd64.deb libmysqlclient-dev_5.7.30-1ubuntu18.04_amd64.deb
