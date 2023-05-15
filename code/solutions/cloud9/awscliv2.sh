#!/bin/bash

# Check system architecture
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]
then
    AWSCLI_PKG="awscli-exe-linux-x86_64.zip"
elif [ "$ARCH" == "aarch64" ]
then
    AWSCLI_PKG="awscli-exe-linux-aarch64.zip"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Check if awscli version 1 is installed
if yum list installed | grep awscli &> /dev/null
then
    echo "awscli version 1 is installed, removing..."
    # Uninstall awscli version 1
    sudo yum remove -y awscli
fi

# Install awscli version 2
curl "https://awscli.amazonaws.com/$AWSCLI_PKG" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install

# Print awscli version
aws --version

# Clean up
rm -f awscliv2.zip
rm -rf aws/
