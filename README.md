# A verified eBPF Virtual Machine for femto-container

This repository contains the version of CertrBPF presented in the CAV22 submission #.

## CertrBPF Overview

CertrBPF is a formally verified rBPF interpreter in Coq. (rBPF is a register-based virtual machine of eBPF) It consists of the following models:

- The proof model: formal syntax and semantics of rBPF in coq as well as the expected isolation property proof. (see the `model` and `isolation` folders)

- The synthesis model: an optimizated & formal rBPF interpreter model in Coq (see `src` and `monadicmodel`), it is equivalent to the proof model (see the `equivalence` folder) but its *code-style* is very close to the original rBPF C implementaion. This Coq model is extracted to C code by the [dx](https://gitlab.univ-lille.fr/samuel.hym/dx) tool.

- The clight model: the extracted C implementation could be re-extracted to a CompCert Clight model by [VST-clight](https://github.com/PrincetonUniversity/VST) (see `clight`). Then refinement proof between the synthesis model and the clight model can be done with the help of our ClightLogic framework (see `proof`).

There are also some folders:

1. `comm`: all comm definitions and functions shared by above three models, e.g. `State`, `Monad`, etc.
2. `repatch`: repatching the dx-extracted C implementation in order to make it executable.
3. `benchmark data`: all experiment data from our benchmark.
4. `simulation`: the whole refinement proofs are moved from `proof/correctproof` into `simulation`. The foundational lemmas, i.e. preserving forward simulation, are defined in `proof/MatchState.v`, and they are used in `simulation/correct_upd_*.v`. 
## Installation

### Dependencies

To install CertrBPF (and dx), you will require:
-   Linux (e.g. Ubuntu)
-   `make` (and standard tools: `sed`, `awk`, `cat`)
-   Coq
-   coq-elpi
-   CompCert32 (version 3.9)
-   VST32 (version 2.8)
-   OCaml compiler

CertrBPF is currently developed with the following versions of these
dependencies:

```shell
opam list ocaml coq coq-elpi coq-compcert-32 coq-vst-32
# Name          # Installed # Synopsis
coq             8.13.2      Formal proof management system
coq-compcert-32 3.9         The CompCert C compiler (32 bit)
coq-elpi        1.11.0      Elpi extension language for Coq
coq-vst-32      2.8         Verified Software Toolchain
ocaml           4.11.1      The OCaml compiler (virtual package)

```
### Building CertrBPF

_NB: you need to modify the makefile of the source project_, to run this repo:
1. install `dx`
```shell
$ git clone https://gitlab.univ-lille.fr/samuel.hym/dx
$ cd dx
$ ./configure ...
$ ./configure --install-compcert-printer --cprinterdir=/home/YOUR-NAME/.opam/YOUR-BPF-OPAM-SWITCH/lib/coq/user-contrib/dx/extr
$ make; make install
```
2. download this repo and config the Makefie.config:
```shell
$ git clone THIS-REPO
$ cd rbpf-dx
$ vim Makefile.config #`OPAMPREFIX := `/home/YOUR-NAME/.opam/YOUR-BPF-OPAM-SWITCH`
$ make all
```

*You also need to set path of Compcert32 in the environment.*

## Checking Coq code

1. `make all`: compiling the proof model, the synthesis model and the clight model; extracting the verified C implementation; proofing the refinement relation between the synthesis model (Coq) and the Clight one (C).

2. `make isolation`: checking the isolation proof of the proof model.

3. `make equivalence`: checking the equivalence relation (equality) between the proof model and the synthesis model.

4. `make clean`: make the repo to a clean state (when you fail to check the Coq code in some steps)
