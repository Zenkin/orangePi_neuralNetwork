#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Script to build ccache for debian and ubuntu based images.

set -ex

pushd .

echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list

apt update -o Acquire::Check-Valid-Until=false --fix-missing || true
apt install -y --force-yes \
    libxslt1-dev \
    docbook-xsl \
    xsltproc \
    libxml2-utils

apt install -y --force-yes --no-install-recommends --allow-unauthenticated \
    autoconf \
    asciidoc \
    xsltproc

mkdir -p /work/deps
cd /work/deps

git clone --recursive -b v3.4.2 https://github.com/ccache/ccache.git

cd ccache

./autogen.sh
# Manually specify x86 gcc versions so that this script remains compatible with dockcross (which uses an ARM based gcc
# by default).
CC=/usr/bin/gcc CXX=/usr/bin/g++ ./configure

# Don't build documentation #11214
#perl -pi -e 's!\s+\Q$(installcmd) -d $(DESTDIR)$(mandir)/man1\E!!g' Makefile
#perl -pi -e 's!\s+\Q-$(installcmd) -m 644 ccache.1 $(DESTDIR)$(mandir)/man1/\E!!g' Makefile
make -j$(nproc)
make install

rm -rf /work/deps/ccache

popd

