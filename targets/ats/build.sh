#!/bin/bash -eu
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

chmod a+x /src/make_tsroots.sh
for i in $(seq 10000 11024); do bash /src/make_tsroots.sh $i;done

sed -i 's/^main(/fuzz_without_main(/' /src/trafficserver/src/traffic_server/traffic_server.cc

mkdir -p /logs && chmod o+w /logs
mkdir -p /tmp/ats/var/trafficserver/
mkdir -p /tmp/ats/var/log/trafficserver
mkdir -p /tmp/ats/etc/trafficserver/
mkdir -p /tmp/ats/etc/trafficserver/body_factory
touch /tmp/ats/var/trafficserver/server.lock

chown nobody:nogroup /tmp/ats/var/trafficserver/server.lock
chown nobody:nogroup /tmp/ats/var/log/trafficserver
chown -R nobody:nogroup /tmp/corpus

confdir="/tmp/ats/etc/trafficserver"
cat << END > $confdir/records.config

CONFIG proxy.config.reverse_proxy.enabled INT 1
CONFIG proxy.config.url_remap.remap_required INT 1
CONFIG proxy.config.url_remap.pristine_host_hdr INT 1
CONFIG proxy.config.http.server_ports STRING 8000
CONFIG proxy.config.diags.debug.enabled INT 0
CONFIG proxy.config.http.cache.http INT 0

END

cat << END > $confdir/remap.config

map / http://127.0.0.1:8001/

END

cat << END > $confdir/storage.config

var/trafficserver 256M

END

cat << END > $confdir/ip_allow.yaml

ip_allow:
  - apply: in
    ip_addrs: 0.0.0.0-255.255.255.255
    action: allow
    methods: ALL
  - apply: in
    ip_addrs: ::1
    action: allow
    methods: ALL

END

autoreconf -if
./configure --enable-debug
find /src/trafficserver -name Makefile | xargs -I % sh -c "sed 's/^CXX\s*=\s*clang++$/CXX = clang++ -fsanitize=fuzzer-no-link/' -i %"
make -j$(nproc) --ignore-errors

mkdir -p /src/trafficserver/fuzzer && cp /src/Makefile /src/trafficserver/fuzzer/

pushd fuzzer/
make
#cp FuzzEsi $OUT/FuzzEsi
##cp FuzzHTTP $OUT/FuzzHTTP
popd

#pushd $SRC/oss-fuzz-bloat/trafficserver/
#cp FuzzEsi_seed_corpus.zip $OUT/FuzzEsi_seed_corpus.zip
#cp FuzzHTTP_seed_corpus.zip $OUT/FuzzHTTP_seed_corpus.zip
#popd

mkdir -p $OUT/lib
cp src/tscore/.libs/libtscore.so* $OUT/lib/.
cp src/tscpp/util/.libs/libtscpputil.so* $OUT/lib/.
cp /src/trafficserver/src/tscpp/api/.libs/libtscppapi.* $OUT/lib/
cp /src/trafficserver/fuzzer/fuzz-diff $OUT/fuzz-diff

cat << END > /tmp/setflags.sh

export TS_ROOT="/tmp/ats"

END
source /tmp/setflags.sh
