TARGET=Fuzzing

#Binary
HttpEXE=fuzz-diff

#Flags
INCDIR=-I..
LIBDIR=-L..
MANFLAGS=-DHAVE_CONFIG_H 
CPPFLAGS=-D_GNU_SOURCE -DOPENSSL_NO_SSL_INTERN -DOPENSSL_API_COMPAT=10002 -DOPENSSL_IS_OPENSSL3
AM_CFLAGS=-std=gnu99 -g -pipe -Wall -Wno-deprecated-declarations -Qunused-arguments -Wextra -Wno-ignored-qualifiers -Wno-unused-parameter -fno-strict-aliasing -mcx16
AM_CXXFLAGS=-std=c++17 -g -pipe -Wall -Wno-deprecated-declarations -Qunused-arguments -Wextra -Wno-ignored-qualifiers -Wno-unused-parameter -fno-strict-aliasing -Wno-invalid-offsetof -mcx16
AM_CPPFLAGS=-Dlinux -D_LARGEFILE64_SOURCE=1 -D_COMPILE64BIT_SOURCE=1 -D_REENTRANT -D__STDC_LIMIT_MACROS=1 -D__STDC_FORMAT_MACROS=1
MACROS=$(MANFLAGS) $(CPPFLAGS) $(AM_CPPFLAGS)

EsiINC=\
	$(INCDIR)/include \
	$(INCDIR)/plugins/esi \
	$(INCDIR)/plugins/esi/lib \
	$(INCDIR)/plugins/esi/fetcher 

EsiLIB=$(LIB_FUZZING_ENGINE) \
	$(LIBDIR)/plugins/esi/.libs/ \
	$(EsiLib) -lesicore

#HttpEXE
HttpINC=\
	$(INCDIR)/include \
	$(INCDIR)/iocore/aio \
	$(INCDIR)/iocore/cache \
	$(INCDIR)/iocore/dns \
	$(INCDIR)/iocore/eventsystem \
	$(INCDIR)/iocore/hostdb \
	$(INCDIR)/iocore/net \
	$(INCDIR)/iocore/net/quic \
	$(INCDIR)/iocore/utils \
	$(INCDIR)/lib \
	$(INCDIR)/proxy/api \
	$(INCDIR)/proxy/hdrs \
	$(INCDIR)/proxy/http

CoreLib=$(LIBDIR)/lib/yamlcpp \
	$(LIBDIR)/src/tscore/.libs/ -ltscore \
	$(LIBDIR)/src/tscpp/util/.libs/ -ltscpputil \
	$(LIBDIR)/src/tscpp/api/.libs/ -ltscppapi \
	-lpcre -lssl -lcrypto -lresolv \
	-Wl,-rpath=/out/lib/

all: $(TARGET)
#main_src_object = /src/trafficserver/src/traffic_server/traffic_server-traffic_server.o

main_src_object = /src/trafficserver/src/traffic_server/traffic_server-traffic_server.o /src/trafficserver/src/traffic_server/traffic_server-InkIOCoreAPI.o /src/trafficserver/src/traffic_server/traffic_server-InkAPI.o /src/trafficserver/src/traffic_server/traffic_server-FetchSM.o /src/trafficserver/src/traffic_server/traffic_server-Crash.o /src/trafficserver/src/traffic_server/traffic_server-HostStatus.o /src/trafficserver/src/traffic_server/traffic_server-SocksProxy.o /src/trafficserver/src/shared/traffic_server_traffic_server-overridable_txn_vars.o \
		 /src/trafficserver/src/records/RecConfigParse.o /src/trafficserver/src/records/RecCore.o /src/trafficserver/src/records/RecDebug.o /src/trafficserver/src/records/RecFile.o /src/trafficserver/src/records/RecHttp.o /src/trafficserver/src/records/RecMessage.o /src/trafficserver/src/records/RecMutex.o /src/trafficserver/src/records/RecRawStats.o /src/trafficserver/src/records/RecUtils.o /src/trafficserver/src/records/P_RecCore.o \

$(TARGET):
	$(CXX) $(CXXFLAGS) $(AM_CXXFLAGS) $(MACROS) $(HttpINC) -c /src/$(HttpEXE).cc
	$(CXX) $(CXXFLAGS) $(AM_CXXFLAGS) $(HttpINC) -o $(HttpEXE) $(HttpEXE).o $(main_src_object) -Wl,--start-group $(static_libs) -Wl,--end-group $(LIB_FUZZING_ENGINE) $(CoreLib) -lpthread -ldl -lz 

clean:
	rm $(HttpEXE) *.o

.PHONY: all clean

static_libs = /src/trafficserver/mgmt/utils/.libs/libutils_p.a /src/trafficserver/mgmt/.libs/libmgmt_c.a /src/trafficserver/mgmt/.libs/libmgmt_p.a /src/trafficserver/lib/fastlz/libfastlz.a /src/trafficserver/lib/yamlcpp/.libs/libyamlcpp.a /src/trafficserver/iocore/utils/libinkutils.a /src/trafficserver/iocore/net/libinknet.a /src/trafficserver/iocore/aio/libinkaio.a /src/trafficserver/iocore/dns/libinkdns.a /src/trafficserver/iocore/eventsystem/libinkevent.a /src/trafficserver/iocore/cache/libinkcache.a /src/trafficserver/iocore/hostdb/libinkhostdb.a /src/trafficserver/proxy/http/libhttp.a /src/trafficserver/proxy/http/remap/libhttp_remap.a /src/trafficserver/proxy/logging/liblogging.a /src/trafficserver/proxy/libproxy.a /src/trafficserver/proxy/shared/libdiagsconfig.a /src/trafficserver/proxy/hdrs/libhdrs.a /src/trafficserver/proxy/http2/libhttp2.a /src/trafficserver/plugins/esi/.libs/libtest.a /src/trafficserver/plugins/esi/.libs/libesicore.a /src/trafficserver/src/records/librecords_p.a #/src/trafficserver/src/records/librecords_lm.a /src/trafficserver/mgmt/.libs/libmgmt_lm.a /src/trafficserver/mgmt/utils/.libs/libutils_lm.a 
