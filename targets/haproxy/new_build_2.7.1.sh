#!/bin/bash -eu
# Copyright 2020 Google Inc.
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
mkdir -p /logs && chmod o+w /logs
export ORIG_CFLAGS=${CFLAGS}
cd /src/haproxy

cp /tmp/haproxy.c /src/haproxy/src/haproxy.c
cp /tmp/tools.c /src/haproxy/src/tools.c

# Fix some things in the Makefile where there are no options available
sed 's/CFLAGS = $(ARCH_FLAGS) $(CPU_CFLAGS) $(DEBUG_CFLAGS) $(SPEC_CFLAGS)$/CFLAGS = $(ARCH_FLAGS) $(CPU_CFLAGS) $(DEBUG_CFLAGS) $(SPEC_CFLAGS) ${ORIG_CFLAGS} -fsanitize=fuzzer-no-link/g' -i Makefile
sed 's/LDFLAGS = $(ARCH_FLAGS) -g$/LDFLAGS = $(ARCH_FLAGS) -g ${CXXFLAGS}/g' -i Makefile

make V=1 TARGET=generic CC=${CC} LD=${CXX} ADDLIB="-lpthread -c" 

#exit 1

# Make a copy of the main file since it has many global functions we need to declare
# We dont want the main function but we need the rest of the stuff in haproxy.c
cd /src/haproxy
sed 's/int main(int argc/int main2(int argc/g' -i ./src/haproxy.c
sed 's/dladdr(main,/dladdr(main2,/g' -i ./src/tools.c
sed 's/(void*)main\([^0-9a-zA-Z]\)/(void*)main2\1/g' -i ./src/tools.c


SETTINGS="-Iinclude -g -DUSE_POLL -DUSE_TPROXY -DUSE_SLZ -DCONFIG_HAPROXY_VERSION=\"\" -DCONFIG_HAPROXY_DATE=\"\""

$CC $CFLAGS $LIB_FUZZING_ENGINE -fsanitize=fuzzer $SETTINGS -c -o ./src/haproxy.o ./src/haproxy.c

ar cr libhaproxy.a ./src/*.o

$CXX $CXXFLAGS $SETTINGS -c /src/fuzz-diff.cc  -o /src/fuzz-diff.o

#$CXX -g $CXXFLAGS -fsanitize=fuzzer $LIB_FUZZING_ENGINE /src/fuzz_diff.o /src/haproxy/libhaproxy.a -o $OUT/fuzz_diff -lpthread -lcrypt
$CXX -g $CXXFLAGS -fsanitize=fuzzer $LIB_FUZZING_ENGINE /src/fuzz-diff.o src/slz.o src/ev_poll.o src/mux_h2.o src/mux_fcgi.o src/mux_h1.o src/tcpcheck.o src/stream.o src/stats.o src/http_ana.o src/server.o src/stick_table.o src/sample.o src/flt_spoe.o src/tools.o src/log.o src/cfgparse.o src/peers.o src/backend.o src/resolvers.o src/cli.o src/connection.o src/proxy.o src/http_htx.o src/cfgparse-listen.o src/pattern.o src/check.o src/haproxy.o src/cache.o src/stconn.o src/http_act.o src/http_fetch.o src/http_client.o src/listener.o src/dns.o src/vars.o src/debug.o src/tcp_rules.o src/sink.o src/h1_htx.o src/task.o src/mjson.o src/h2.o src/filters.o src/server_state.o src/payload.o src/fcgi-app.o src/map.o src/htx.o src/h1.o src/pool.o src/cfgparse-global.o src/trace.o src/tcp_sample.o src/flt_http_comp.o src/mux_pt.o src/flt_trace.o src/mqtt.o src/acl.o src/sock.o src/mworker.o src/tcp_act.o src/ring.o src/session.o src/proto_tcp.o src/fd.o src/channel.o src/activity.o src/queue.o src/lb_fas.o src/http_rules.o src/extcheck.o src/flt_bwlim.o src/thread.o src/http.o src/lb_chash.o src/applet.o src/compression.o src/raw_sock.o src/ncbuf.o src/frontend.o src/errors.o src/uri_normalizer.o src/http_conv.o src/lb_fwrr.o src/sha1.o src/proto_sockpair.o src/mailers.o src/lb_fwlc.o src/ebmbtree.o src/cfgcond.o src/action.o src/xprt_handshake.o src/protocol.o src/proto_uxst.o src/proto_udp.o src/lb_map.o src/fix.o src/ev_select.o src/arg.o src/sock_inet.o src/mworker-prog.o src/hpack-dec.o src/cfgparse-tcp.o src/sock_unix.o src/shctx.o src/proto_uxdg.o src/fcgi.o src/eb64tree.o src/clock.o src/chunk.o src/cfgdiag.o src/signal.o src/regex.o src/lru.o src/eb32tree.o src/eb32sctree.o src/cfgparse-unix.o src/hpack-tbl.o src/ebsttree.o src/ebimtree.o src/base64.o src/auth.o src/uri_auth.o src/time.o src/ebistree.o src/dynbuf.o src/wdt.o src/pipe.o src/init.o src/http_acl.o src/hpack-huff.o src/hpack-enc.o src/dict.o src/freq_ctr.o src/ebtree.o src/hash.o src/dgram.o src/version.o -o $OUT/fuzz-diff -lpthread -lcrypt -lcrypto
