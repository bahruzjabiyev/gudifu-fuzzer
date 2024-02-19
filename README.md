# gudifu-fuzzer
Guided Differential Fuzzing for HTTP Request Parsing Discrepancies

# Building Targets
We created our target images from the [base images](https://github.com/google/oss-fuzz/tree/master/infra/base-images) of Google oss-fuzz project and added server build instructions and fuzzing harness code (both specific to each server) in each image which can be found under the [targets](/targets) folder. Fuzzing harness codes can be viewed separately under the [harnesses](/harnesses) folder.

## Modifying LibFuzzer Code
For the paper, the only modification we made in the libfuzzer code was for avoiding to add input requests which trigger an error back to the corpus. This was to make sure that the fuzzing does not get stuck in error states since we rely on forwarded requests to compare the parsing behavior of targets. If you are also interested in making the same modification, make sure that you create your own version of `gcr.io/oss-fuzz-base/base-clang` by applying a few patches given in the [misc](/misc) folder. 

