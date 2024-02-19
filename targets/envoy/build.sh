#!/bin/bash -eu
# Copyright 2018 Google Inc.
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

# These options are added to make sure that the code instrumentation happens.

pushd /src/envoy
mkdir -p /logs && chmod o+w /logs

sed 's/int fuzz_without_main(/int main(/' -i /src/envoy/source/exe/main.cc
python3 tools/github/write_current_source_version.py
sed 's/int main(/int fuzz_without_main(/' -i /src/envoy/source/exe/main.cc

if ! (grep -q "copts = \[\]" /src/envoy/bazel/envoy_binary.bzl); then
        sed 's/        linkopts = \[\],/        linkopts = [],\n        copts = [],/' -i /src/envoy/bazel/envoy_binary.bzl;
fi
if ! (grep -q "#\"-Wold-style-cast\"" /src/envoy/bazel/envoy_internal.bzl); then
        sed 's/"-Wold-style-cast"/#"-Wold-style-cast"/' -i /src/envoy/bazel/envoy_internal.bzl
fi

if ! (grep -q "fuzz-diff" /src/envoy/source/exe/BUILD); then

cat << END >> /src/envoy/source/exe/BUILD 

envoy_cc_binary(
    name = "fuzz-diff",
    srcs = ["fuzz-diff.cc"],
    features = select({
        "//bazel:windows_opt_build": ["generate_pdb_file"],
        "//conditions:default": [],
    }),
    stamped = True,
    deps = [":envoy_main_entry_lib"],
    copts = [ "-fsanitize=fuzzer",],
    linkopts = ["/usr/lib/libFuzzingEngine.a"],
)

END

fi

#bazel build --verbose_failures --dynamic_mode=off --spawn_strategy=standalone --genrule_strategy=standalone --local_cpu_resources=HOST_CPUS*0.256 --//source/extensions/wasm_runtime/v8:enabled=false --build_tag_filters=-no_asan --config=oss-fuzz --copt=-fsanitize=fuzzer-no-link //source/exe:fuzz-diff

bazel build --verbose_failures --dynamic_mode=off --per_file_copt=^.*source/extensions/access_loggers/.*\.cc$@-fsanitize-coverage=0 --per_file_copt=^.*source/common/protobuf/.*\.cc$@-fsanitize-coverage=0 --per_file_copt=^.*test/.*\.cc$@-fsanitize-coverage=0 --per_file_copt=^.*com_google_protobuf.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_google_absl.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_github_grpc_grpc.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*boringssl.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_googlesource_code_re2.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*upb.*\.cpp$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*org_brotli.*\.cpp$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_google_cel_cpp.*\.cpp$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_github_jbeder_yaml_cpp.*\.cpp$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*proxy_wasm_cpp_host/.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_github_google_libprotobuf_mutator/.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_googlesource_googleurl/.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*com_lightstep_tracer_cpp/.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*antlr4_runtimes.*\.cpp$@-fsanitize-coverage=0 --per_file_copt=^.*googletest.*\.cc$@-fsanitize-coverage=0 --per_file_copt=^.*\.pb\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --per_file_copt=^.*bazel-out/.*\.cc$@-fsanitize-coverage=0,-fno-sanitize=all --spawn_strategy=standalone --genrule_strategy=standalone --local_cpu_resources=HOST_CPUS*0.256 --//source/extensions/wasm_runtime/v8:enabled=false --build_tag_filters=-no_asan --config=oss-fuzz --action_env=CC=clang --action_env=CXX=clang++ --copt=-fsanitize=fuzzer-no-link //source/exe:fuzz-diff

find / -name fuzz-diff | grep "bin/source/exe/fuzz-diff$" | xargs -I file cp file /out

popd
