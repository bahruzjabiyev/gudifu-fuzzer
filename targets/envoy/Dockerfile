# Copyright 2022 Google Inc.
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
FROM oss-fuzz-base/new-base-builder:v2.1

RUN apt-get update && apt-get -y install  \
	build-essential \
	openjdk-8-jdk   \
	make            \
    ninja-build     \
    curl            \
    autoconf        \
    libtool         \
    wget            \
    golang          \
    rsync vim

#RUN git clone https://github.com/envoyproxy/envoy.git
RUN wget https://github.com/envoyproxy/envoy/archive/refs/tags/v1.24.1.tar.gz && tar -xvzf v1.24.1.tar.gz && mv envoy-1.24.1 envoy && rm v1.24.1.tar.gz
#WORKDIR $SRC/envoy/
#ADD diff_fuzz $SRC/envoy/test/integration/diff_fuzz
#ADD targets/envoy/h1_corpus $SRC/envoy/test/integration/diff_fuzz/h1_corpus

COPY build.sh /src
COPY wordlist /src
COPY echo_server.py /src
COPY envoy.yaml /src
COPY fuzz-diff.cc /src/envoy/source/exe/
RUN /usr/local/bin/compile_libfuzzer && mkdir /tmp/corpus && cd /src/envoy && bash ../build.sh
COPY seed /tmp/corpus/seed
#COPY repository_locations.bzl /src/envoy/bazel/repository_locations.bzl

ENTRYPOINT (python3 /src/echo_server.py envoy &) && tail -f /dev/null

# TODO
# chmod o+w /logs/

