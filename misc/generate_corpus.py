from sys import argv
import random

if len(argv) < 2:
  print("directory name is missing.")
  exit()
dirname = argv[1]

def write_to_file(i, request):
  with open(f'{dirname}/seed{i}', 'wb') as cfile: 
    cfile.write(request)

main_methods = ['GET', 'POST', 'HEAD', 'OPTIONS']
main_uris = ['/a/b/c?d=e&g=h', 'http://localhost:80/a/b/c?d=e&g=h']
main_versions = [' HTTP/1.0', ' HTTP/1.1']
main_headers = ['if-match:*,"xyzzy"', 'sec-websocket-key:dghlihnhbxbszsbub25jzq==', 'ttl:1', 'proxy-authorization:mutual ywxhzgrpbjpvcgvuc2vzyw1l', 'if-schedule-tag-match:*', 'proxy-authorization:bearer 123456', 'cdn-loop:foo123.foocdn.example,anothercdn; abc=123; def="456"', 'upgrade:shttp/1.3', 'early-data:1', 'schedule-reply:t', 'alpn:h2,http%2f1.1', 'prefer:respond-async,handling=lenient', 'cdn-loop:anothercdn; abc=123; def="456",foo123.foocdn.example', 'ttl:0', 'if-range:sun, 06 nov 1994 08:49:37 gmt', 'authorization:negotiate ywxhzgrpbjpvcgvuc2vzyw1l', 'accept-encoding:gzip;q=0.0', 'overwrite:t', 'accept-ranges:none', 'range:none=5-', 'if-range:*', 'authorization:oauth 123456', 'proxy-authorization:oauth ywxhzgrpbjpvcgvuc2vzyw1l', 'if-modified-since:sun, 06 nov 1994 08:49:37 gmt', 'alt-used:alternate.example.net', 'if-none-match:*,"xyzzy"', 'cdn-loop:foo123.foocdn.example,barcdn.example; trace="abcdef"', 'if-match:*,*', 'max-forwards:1', 'allow:options', 'accept-encoding:chunked;q=1.0', 'proxy-authorization:bearer ywxhzgrpbjpvcgvuc2vzyw1l', 'prefer:wait=100,wait=100', 'upgrade:websocket', 'if-unmodified-since:sun, 06 nov 2094 08:49:37 gmt', 'if-none-match:"xyzzy",*', 'prefer:handling=lenient,respond-async', 'date:sun, 06 nov 2094 08:49:37 gmt', 'sec-websocket-extensions:deflate-stream,deflate-stream', 'destination:http://example.com/example', 'if-unmodified-since:sun, 06 nov 1994 08:49:37 gmt', 'if-match:"xyzzy","xyzzy"', 'authorization:negotiate 123456', 'content-length:0', 'range:bytes=5-', 'prefer:respond-async,wait=100', 'ordering-type:http://example.org/example.html', 'timeout:second-4100000000', 'sec-websocket-extensions:mux,max-channels:4; flow-control', 'authorization:hoba 123456', 'if-match:*', 'cache-control:min-fresh=5', 'urgency:normal', 'transfer-encoding:br', 'cache-control:no-cache', 'sec-websocket-extensions:mux,mux', 'authorization:digest 123456', 'cache-control:max-age=5', 'range:none=5-8', 'urgency:low', 'accept-ranges:bytes', 'accept-encoding:compress;q=1.0', 'allow:head', 'authorization:digest ywxhzgrpbjpvcgvuc2vzyw1l', 'content-location:http://example.com/example', 'sec-websocket-protocol:chat,superchat', 'expect:100-continue', 'authorization:scram-sha-1 123456', 'proxy-authorization:basic ywxhzgrpbjpvcgvuc2vzyw1l', 'authorization:scram-sha-1 ywxhzgrpbjpvcgvuc2vzyw1l', 'accept:example.com', 'cdn-loop:anothercdn; abc=123; def="456"', 'proxy-authorization:negotiate 123456', 'proxy-authorization:hoba 123456', 'authorization:scram-sha-256 123456', 'accept-language:fr;q=1.0', 'content-encoding:chunked', 'prefer:wait=100', 'urgency:high', 'allow:put', 'prefer:respond-async', 'max-forwards:0', 'http2-settings:aamaaabkaaraaaaaaaiaaaaa', 'range:bytes=5-8', 'sec-websocket-extensions:deflate-stream,mux', 'odata-isolation:snapshot', 'timeout:infinite,second-4100000000', 'cdn-loop:barcdn.example; trace="abcdef",anothercdn; abc=123; def="456"', 'upgrade:rta/x11', 'sec-websocket-extensions:max-channels:4; flow-control', 'timeout:infinite,infinite', 'depth:infinity', 'sec-websocket-extensions:max-channels:4; flow-control,mux', 'prefer:handling=lenient,handling=lenient', 'pragma:no-cache', 'allow:delete', 'alpn:h2,h2', 'if-match:"xyzzy"', 'sec-websocket-accept:s3pplmbitxaq9kygzzhzrbk+xoo=', 'cookie:phpsessid=298zf09hf012fh2; csrftoken=u32t4o3tb3gg43; _gat=1', 'content-language:fr;q=1.0', 'if-modified-since:sun, 06 nov 2094 08:49:37 gmt', 'allow:get', 'sec-websocket-extensions:deflate-stream,max-channels:4; flow-control', 'accept-language:de;q=1.0', 'timeout:second-4100000000,infinite', 'trailer:expires', 'accept-language:en;q=1.0', 'prefer:handling=lenient,wait=100', 'te:identity;q=1.0', 'proxy-authorization:vapid 123456', 'if-none-match:"xyzzy"', 'via:1.0 fred', 'user-agent:curl/7.16.3 libcurl/7.16.3 openssl/0.9.7l zlib/1.2.3', 'sec-websocket-extensions:max-channels:4; flow-control,max-channels:4; flow-control', 'accept-language:fr;q=0.0', 'via:1.0 fred,1.1 p.example.net', 'upgrade:http/2.0', 'sec-websocket-protocol:superchat', 'content-language:de;q=1.0', 'upgrade:irc/6.9', 'sec-websocket-protocol:chat,chat', 'authorization:vapid 123456', 'if-none-match:"xyzzy","xyzzy"', 'cdn-loop:anothercdn; abc=123; def="456",barcdn.example; trace="abcdef"', 'if-none-match:*', 'if-match:"xyzzy",*', 'cdn-loop:barcdn.example; trace="abcdef",foo123.foocdn.example', 'oscore:csu', 'topic:upd', 'if:(<urn:uuid:58f202ac-22cf-11d1-b12d-002035b29092>)', 'prefer:handling=lenient', 'content-language:en;q=0.0', 'accept-language:en;q=0.0', 'position:after example.html', 'content-encoding:compress', 'transfer-encoding:deflate', 'if-none-match:*,*', 'authorization:bearer 123456', 'proxy-authorization:hoba ywxhzgrpbjpvcgvuc2vzyw1l', 'accept-encoding:deflate;q=0.0', 'cdn-loop:anothercdn; abc=123; def="456",anothercdn; abc=123; def="456"', 'if-range:"xyzzy"', 'proxy-authorization:digest ywxhzgrpbjpvcgvuc2vzyw1l', 'caldav-timezones:f', 'expires:sun, 06 nov 2094 08:49:37 gmt', 'cache-control:no-transform', 'referer:http://example.com/example', 'position:first', 'content-location:/example', 'proxy-authorization:scram-sha-1 123456', 'sec-websocket-extensions:mux', 'proxy-authorization:mutual 123456', 'mime-version:1.1', 'forwarded:by http://example.com/example', 'origin:null', 'prefer:respond-async,respond-async', 'ordering-type:dav:unordered', 'content-encoding:gzip', 'proxy-authorization:vapid ywxhzgrpbjpvcgvuc2vzyw1l', 'timeout:infinite', 'slug:the beach at s%c3%a8te', 'date:sun, 06 nov 1994 08:49:37 gmt', 'via:1.1 p.example.net,1.1 p.example.net', 'via:1.1 p.example.net', 'authorization:oauth ywxhzgrpbjpvcgvuc2vzyw1l', 'content-language:en;q=1.0', 'cookie:sid=31d4d96e407aad42', 'allow:connect', 'schedule-reply:f', 'allow:post', 'ordering-type:dav:custom', 'transfer-encoding:compress', 'authorization:basic 123456', 'via:1.1 p.example.net,1.0 fred', 'sec-websocket-version:13', 'cdn-loop:barcdn.example; trace="abcdef",barcdn.example; trace="abcdef"', 'cache-control:max-stale=5', 'authorization:hoba ywxhzgrpbjpvcgvuc2vzyw1l', 'urgency:very-low', 'accept-encoding:gzip;q=1.0', 'sec-websocket-extensions:max-channels:4; flow-control,deflate-stream', 'alpn:http%2f1.1,h2', 'depth:0', 'proxy-authorization:negotiate ywxhzgrpbjpvcgvuc2vzyw1l', 'cache-control:only-if-cached', 'transfer-encoding:chunked', 'content-language:fr;q=0.0', 'accept-charset:utf-8;q=1.0', 'proxy-authorization:oauth 123456', 'odata-version:4.0', 'if-range:sun, 06 nov 2094 08:49:37 gmt', 'alpn:http%2f1.1,http%2f1.1', 'accept-encoding:deflate;q=1.0', 'caldav-timezones:t', 'content-encoding:identity', 'proxy-authorization:scram-sha-256 123456', 'accept:0', 'alpn:http%2f1.1', 'expires:sun, 06 nov 1994 08:49:37 gmt', 'proxy-authorization:digest 123456', 'odata-maxversion:4.0', 'link:<http://example.com/example>', 'content-language:de;q=0.0', 'overwrite:f', 'accept-language:de;q=0.0', 'if:(<urn:uuid:181d4fae-7d8c-11d0-a765-00a0c91e6bf2>)', 'authorization:scram-sha-256 ywxhzgrpbjpvcgvuc2vzyw1l', 'position:last', 'cache-control:no-store', 'prefer:wait=100,respond-async', 'depth:1', 'allow:trace', 'cdn-loop:foo123.foocdn.example', 'origin:http://example.com', 'proxy-authorization:basic 123456', 'if-schedule-tag-match:"xyzzy"', 'authorization:mutual ywxhzgrpbjpvcgvuc2vzyw1l', 'cdn-loop:foo123.foocdn.example,foo123.foocdn.example', 'sec-websocket-extensions:deflate-stream', 'content-encoding:br', 'from:webmaster@w3.org', 'mime-version:1.0', 'via:1.0 fred,1.0 fred', 'proxy-authorization:scram-sha-256 ywxhzgrpbjpvcgvuc2vzyw1l', 'sec-websocket-extensions:mux,deflate-stream', 'transfer-encoding:identity', 'transfer-encoding:gzip', 'prefer:wait=100,handling=lenient', 'content-encoding:deflate', 'sec-token-binding:aikaagbbqlgtrpwfpn66kxhxgrtakrzcmthw7hv8', 'proxy-authorization:scram-sha-1 ywxhzgrpbjpvcgvuc2vzyw1l', 'timeout:second-4100000000,second-4100000000', 'sec-websocket-protocol:superchat,superchat', 'authorization:vapid ywxhzgrpbjpvcgvuc2vzyw1l', 'cdn-loop:barcdn.example; trace="abcdef"', 'authorization:bearer ywxhzgrpbjpvcgvuc2vzyw1l', 'sec-websocket-protocol:chat', 'oscore:aa', 'sec-websocket-protocol:superchat,chat', 'alpn:h2']
main_bodies = ['\r\nContent-Length: 19\r\n\r\n2\r\nBB\r\n2\r\nBB\r\n0\r\n\r\n', '\r\nTransfer-Encoding: chunked\r\n\r\n2\r\nBB\r\n2;foo=bar\r\nBB\r\n0\r\nfoo:bar\r\n\r\n', '\r\n\r\n']

#header_sublists = []
#j = 0
#while j<len(headers):
#  header_sublists.append('\r\n'.join(headers[j:j+6]))
#  j = j + 6
#
#for method in main_methods:
#  for uri in main_uris:
#    for version in main_versions:
#      for body in main_bodies:

i = 0
for header in main_headers:
  i = i + 1
  method = random.choice(main_methods)
  uri = random.choice(main_uris)
  version = random.choice(main_versions)
  body = random.choice(main_bodies)
  request = method.encode() + b' ' + uri.encode() + version.encode() + b'\r\nConnection: close\r\nHost: localhost\r\n' + header.encode() + body.encode()
  #write_to_file(i, request)
  print(request)

print(i)

#      i = i + 1
#      request = method.encode() + b' ' + uri.encode() + version.encode() + b'\r\nConnection: close\r\nHost: localhost\r\n' + b'Transfer-Encoding: chunked\r\n\r\n' + b'2\r\nBB\r\n2;foo=bar\r\nBB\r\n0\r\nfoo:bar\r\n\r\n'
#      write_to_file(i, request)
#
#      i = i + 1
#      request = method.encode() + b' ' + uri.encode() + version.encode() + b'\r\nConnection: close\r\nHost: localhost\r\n\r\n'
#      write_to_file(i, request)
