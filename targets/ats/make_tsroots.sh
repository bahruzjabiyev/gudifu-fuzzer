#!/bin/bash

ts_root=/tmp/ats$1

mkdir -p $ts_root/var/trafficserver/
mkdir -p $ts_root/var/log/trafficserver
mkdir -p $ts_root/etc/trafficserver/
mkdir -p $ts_root/etc/trafficserver/body_factory
touch $ts_root/var/trafficserver/server.lock

chown nobody:nogroup $ts_root/var/trafficserver/server.lock
chown nobody:nogroup $ts_root/var/log/trafficserver

confdir="$ts_root/etc/trafficserver"
cat << END > $confdir/records.config

CONFIG proxy.config.reverse_proxy.enabled INT 1
CONFIG proxy.config.url_remap.remap_required INT 1
CONFIG proxy.config.url_remap.pristine_host_hdr INT 1
CONFIG proxy.config.http.server_ports STRING $1
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
