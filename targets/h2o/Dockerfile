# Copyright 2016 Google Inc.
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

RUN apt-get update && apt-get install -y make autoconf automake libtool cmake zlib1g-dev pkg-config libssl-dev vim
#RUN git clone https://github.com/h2o/h2o
RUN cd /src && wget https://github.com/h2o/h2o/archive/refs/tags/v2.2.6.tar.gz && tar -xvzf v2.2.6.tar.gz && mv h2o-2.2.6 h2o && rm v2.2.6.tar.gz 
WORKDIR h2o
COPY build.sh $SRC/
COPY wordlist /src
COPY h2o.conf $SRC/
COPY fuzz-diff.cc $SRC/
COPY echo_server.py $SRC/
RUN /usr/local/bin/compile_libfuzzer && mkdir /tmp/corpus
COPY seed /tmp/corpus/seed

ENTRYPOINT (python3 /src/echo_server.py h2o &) && tail -f /dev/null
