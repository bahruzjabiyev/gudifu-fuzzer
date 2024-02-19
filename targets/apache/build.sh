#!/bin/bash -eu
# Copyright 2021 Google LLC
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

unset CPP
unset CXX
export LDFLAGS="-l:libbsd.a"

sed -i 's/int main(/int fuzz_without_main(/g' /src/httpd/server/main.c
sed -i 's/(LINK)/(LINK) -c/' /src/httpd/build/program.mk 
sed -i 's/= malloc/= (char*)malloc/;s/= calloc/= (char*)calloc/' /src/fuzz-headers/lang/c/ada_fuzz_header.h

# Download apr and place in httpd srclib folder. Apr-2.0 includes apr-utils
cd /src/httpd/srclib/apr; svn cleanup; cd ../..
svn checkout https://svn.apache.org/repos/asf/apr/apr/trunk/ srclib/apr

cat << END > /tmp/setflags.sh

export CFLAGS="-O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=fuzzer-no-link"

END
source /tmp/setflags.sh

# Build httpd
./buildconf
./configure --with-included-apr --enable-pool-debug
make
./configure --with-included-apr --enable-pool-debug --enable-proxy=static --enable-proxy-http=static --enable-unixd=static --enable-authz-core=static --enable-slotmem-shm=static
make

# Build libfuzzer and create the corpus
/usr/local/bin/compile_libfuzzer && mkdir -p /logs && chmod o+w /logs && mkdir -p /tmp/corpus && chown daemon:daemon /tmp/corpus && cp /src/new_seed /tmp/corpus/

# Create some directories needed for httpd to run
mkdir -p /tmp/apache/logs 

static_pcre=($(find /src/pcre2 -name "libpcre2-8.a"))

echo $CXX
echo $CXXFLAGS
echo $LIB_FUZZING_ENGINE
# Build fuzzer
clang++ $CXXFLAGS -lpthread -fsanitize=fuzzer-no-link $LIB_FUZZING_ENGINE \
  -I/src/fuzz-headers/lang/c -I./include -I./os/unix \
  -I./srclib/apr/include -I./srclib/apr-util/include/ \
  $SRC/fuzz-diff.cc -o /out/fuzz-diff \
  ./server/main.o ./modules.o buildmark.o \
  modules/proxy/ajp_header.o modules/proxy/ajp_link.o modules/proxy/ajp_msg.o modules/proxy/ajp_utils.o modules/proxy/mod_proxy.o modules/proxy/mod_proxy_ajp.o modules/proxy/mod_proxy_balancer.o modules/proxy/mod_proxy_connect.o modules/proxy/mod_proxy_express.o modules/proxy/mod_proxy_fcgi.o modules/proxy/mod_proxy_fdpass.o modules/proxy/mod_proxy_ftp.o modules/proxy/mod_proxy_hcheck.o modules/proxy/mod_proxy_http.o modules/proxy/mod_proxy_scgi.o modules/proxy/mod_proxy_uwsgi.o modules/proxy/mod_proxy_wstunnel.o modules/proxy/proxy_util.o \
  modules/proxy/balancers/mod_lbmethod_bybusyness.o modules/proxy/balancers/mod_lbmethod_byrequests.o modules/proxy/balancers/mod_lbmethod_bytraffic.o modules/proxy/balancers/mod_lbmethod_heartbeat.o \
  -Wl,--start-group ./server/.libs/libmain.a \
                    ./modules/core/.libs/libmod_so.a \
                    ./modules/http/.libs/libmod_http.a \
                    ./modules/arch/unix/.libs/mod_unixd.a \
                    ./modules/aaa/.libs/libmod_authz_core.a \
                    ./modules/proxy/.libs/mod_proxy.a \
                    ./modules/proxy/.libs/mod_proxy_http.a \
		            ./modules/slotmem/.libs/mod_slotmem_shm.a \
                    ./server/mpm/event/.libs/libevent.a \
                    ./os/unix/.libs/libos.a \
                    ./srclib/apr/.libs/libapr-2.a \
		            -Wl,--end-group -luuid -lcrypt -lexpat -lrt -ldl -lm -lcrypto -l:libbsd.a ${static_pcre}
