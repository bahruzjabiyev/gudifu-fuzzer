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
FROM gcr.io/oss-fuzz-base/base-builder

RUN apt-get update && apt-get install -y autoconf automake libtool pkg-config libpcre3-dev zlib1g-dev vim
RUN git clone https://github.com/apache/trafficserver && cd trafficserver && git reset --hard 9158cd79cc280c470da7c5bed2e4251609b5bbe7 && cd ..
## version 10.0.0
#RUN wget https://downloads.apache.org/trafficserver/trafficserver-9.1.4.tar.bz2 && tar xf trafficserver-9.1.4.tar.bz2 && mv trafficserver-9.1.4 trafficserver && rm trafficserver-9.1.4.tar.bz2
RUN git clone https://github.com/0x34d/oss-fuzz-bloat
COPY build.sh $SRC/build.sh
COPY wordlist /src
COPY make_tsroots.sh $SRC/
COPY echo_server.py $SRC/
COPY fuzz-diff.cc $SRC/
COPY Makefile $SRC/
WORKDIR $SRC/trafficserver/
RUN mkdir /tmp/corpus && /usr/local/bin/compile_libfuzzer
COPY seed /tmp/corpus
COPY setflags.sh /tmp/

ENTRYPOINT (python3 /src/echo_server.py ats &) && . /tmp/setflags.sh && tail -f /dev/null
