#!/bin/bash
# This script automates building and installing Fluentd packages on Amazon Linux 2023 (aarch64).
# It installs required dependencies, starts Docker, builds packages from GitHub repository,
# installs the built package, and stops Docker after installation.

# Should be ${FLUENT_PACKAGE_BUILDER_VERSION:-v4.5.0} but v5 it's not released yet and 
# v4.5.0 has no support for Amazon Linux 2023.
FLUENT_PACKAGE_BUILDER_VERSION="${FLUENT_PACKAGE_BUILDER_VERSION:-master}"

yum install -y git docker ruby3.2 ruby3.2-devel
yum groupinstall -y "Development Tools"
gem install rake

systemctl start docker

ruby --version
bundler --version
rake --version

rm -rf fluent-package-builder
git clone --depth 1 --branch "$FLUENT_PACKAGE_BUILDER_VERSION" https://github.com/fluent/fluent-package-builder.git
cd fluent-package-builder/
rake yum:build YUM_TARGETS="amazonlinux-2023-aarch64"

# Specify the directory containing the RPM files
RPM_DIRECTORY="/root/fluent-package-builder/fluent-package/yum/repositories/amazon/2023/aarch64/Packages"

# Loop through each RPM file and install using yum
for rpm_file in "$RPM_DIRECTORY"/fluent-package-*.amzn2023.aarch64.rpm; do
    if [[ -f "$rpm_file" ]]; then
        echo "Installing: $rpm_file"
        yum install -y "$rpm_file"
    fi
done

systemctl stop docker

yum list | grep fluent
