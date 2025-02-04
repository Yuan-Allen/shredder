# Shredder
This is a modified version of [Shredder](https://github.com/utah-scs/shredder).

## Install
Shredder has been tested on Ubuntu 18.04. 
To compile Shredder:
1. Run ./setup_v8.sh to fetch V8 code and compile V8. If visibility errors happen when compiling v8, modify the `visibility` of `internal_config_base`, `features` and `toolchain` from `:/` to `./*` in `v8/BUILD.gn` to temporarily solve this. 
2. Run ./setup_seastar.sh to fetch Seastar code and compile Seastar.
3. Run make

## Usage
To run Shredder:
1. Run ./shredder & in background. Use -c to run Shredder on multiple cores, for example "./shredder -c2" runs Shredder on 2 cores.
2. example_client.c is an example Shredder client implementation. 
   Shredder uses Redis protocol, so Redis client library such as hredis can be used to communicate with Shredder server.
   Shredder adds a new command "JS" to run JavaScript functions. Example JS functions can be found in "script.js", including a dataset setup function, a simple key value query function, a graph traversal function and a neural model predict function.

For DPDK, please follow instructions in seastar/dpdk to setup DPDK. To run Shredder with DPDK, run "sudo ./shredder --network-stack native --dpdk-pmd".

## Caveats

This is a research prototype, so many features are incomplete or hacky.
For example, tenant support is not completely implemented, currently Shredder assigns a new tenant ID for each new incoming network connection, which cannot be used in real production.
