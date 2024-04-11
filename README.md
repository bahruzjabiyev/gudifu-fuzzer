# Gudifu
Gudifu (**Gu**ided **Di**fferential **Fu**zzer) improves the state-of-the-art HTTP differential fuzzing approaches in two main ways: 1) takes a graybox fuzzing approach to probe the parsing behavior of HTTP servers and 2) uses a holistic method to search for parsing discrepancies (by looking at the whole request instead of, for example, just the request body). 

The flow diagram of Gudifu is shown below. The data flow starts with a single input corpus populated with a set of HTTP requests. A number of fuzzer instances, one for each target server, share this input corpus and read inputs from it before mutating them and delivering them to their respective target servers. The target servers receive the inputs and process them, possibly returning an error message to the fuzzer instance, and possibly forwarding a message to their respective echo server. Regardless, the target servers are instrumented to report the code coverage achieved by processing the input back to the fuzzer instance in order to influence future input selection and mutation. The echo servers receive the forwarded requests from the target servers and log them to a single shared database for offline processing. They then send a response back to the target server, which sends it back to the fuzzer instance, which then can decide whether to add the mutated test case back to the input corpus for other fuzzer instances to draw from and mutate in future fuzzing iterations.

<p></p>
<p align="center">
  <image src="misc/gudifu-1.png">
</p>
<p></p>

## Building Targets
We created our target images from the [base images](https://github.com/google/oss-fuzz/tree/master/infra/base-images) of Google oss-fuzz project and added server build instructions and fuzzing harness code (both specific to each server) in each image which can be found under the [targets](/targets) folder. Fuzzing harness codes can be viewed separately under the [harnesses](/harnesses) folder.

## Modifying LibFuzzer Code
For the paper, the only modification we made in the libfuzzer code was for avoiding to add input requests which trigger an error back to the corpus. This was to make sure that the fuzzing does not get stuck in error states since we rely on forwarded requests to compare the parsing behavior of targets. If you are also interested in making the same modification, make sure that you create your own version of `gcr.io/oss-fuzz-base/base-clang` by applying a few patches given in the [misc](/misc) folder. 

## Running Experiments
Once the building of fuzzing binaries and targets are completed, the fuzzing experiment can be started with the command below (should be run on each target separately).

`/out/fuzz-diff /path/to/corpus/ -mutate-depth=2 -jobs=100`

The first element in the command (i.e., `/out/fuzz-diff` is the path to the fuzzing binary), the second is the path to the corpus folder ([can](/misc/generate_corpus.py) be automatically generated) which is shared among all targets, the third is an optional argument for specifying the maximum number of mutations and finally the `jobs` argument can be used to run multiple instances of the fuzzer for a better speed. The [harnesses](/harnesses) have been designed to support multiprocessing (by using pid numbers for identification).

Once the experiments are completed, the parsing discrepancies can be extracted and analyzed. For the paper, we developed an algorithm and a [code](/misc/compare.py) for the holistic search of discrepancies. Helper codes for getting the experiment results are in the [misc](/misc) folder. Essentially, the invocation of `get_common_requests.sh` and `get_results.sh`, one after another, will show you the parsing discrepancies in buckets (which makes the analysis easier).
