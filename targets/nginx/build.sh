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
################################################################################
# create folders for saving files
#mkdir -p /logs;
#for c1 in 0 1 2 3 4 5 6 7 8 9 a b c d e f;do
#  for c2 in 0 1 2 3 4 5 6 7 8 9 a b c d e f;do
#    for c3 in 0 1 2 3 4 5 6 7 8 9 a b c d e f;do
#        mkdir -p /logs/$c1$c2$c3;
#    done;
#  done;
#done

mkdir -p /logs && chmod o+w /logs

cat << END > /tmp/setflags.sh

export CFLAGS="-O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=fuzzer-no-link"
export CXXFLAGS="-O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -ldl -stdlib=libc++"

END

source /tmp/setflags.sh

hg import $SRC/add_fuzzers.diff --no-commit

cp -r $SRC/fuzz src/
cp $SRC/make_fuzzers auto/make_fuzzers

cd src/fuzz
rm -rf genfiles && mkdir genfiles && $SRC/LPM/external.protobuf/bin/protoc http_request_proto.proto --cpp_out=genfiles
cd ../..

auto/configure \
    --with-cc-opt='-DNGX_DEBUG_PALLOC=1' \
    --with-http_v2_module 
make -f objs/Makefile fuzzers

#cp objs/*_fuzzer $OUT/
cp objs/http_request_fuzzer /out/fuzz-diff
cp $SRC/fuzz/*.dict $OUT/
