include Makefile.config

SED := sed
CAT := cat
AWK := awk
COQC := coqc
COQDEP := coqdep
OCAMLOPT := ocamlopt
COQMAKEFILE := coq_makefile
CP := cp

CC=gcc
OFLAGS=-Os
CLIGHTGEN=clightgen
CLIGHTGEN32=$(CLIGHTGEN32DIR)/clightgen

THIS_FILE := $(lastword $(MAKEFILE_LIST))

# Disable warnings on notations (that are coming from the standard
# library)
COQPROJOPTS := $(shell $(CAT) _CoqProject)
COQDEPOPTS := $(COQPROJOPTS)
COQCOPTS := $(COQPROJOPTS) -w all,-notation
COQEXTROPTS :=  -R ../src dx.src -w all,-extraction

OCAMLINCS := -I extr # -I src

all:
	@echo $@
	@$(MAKE) comm
	@$(MAKE) model
	@$(MAKE) compile
	@$(MAKE) extract
	@$(MAKE) repatch
	@$(MAKE) clight
	@$(MAKE) clightproof
	@$(MAKE) correctproof

COQMODEL =  $(addprefix model/, Syntax.v Decode.v Semantics.v)
COQSRC =  $(addprefix src/, InfComp.v GenMatchable.v CoqIntegers.v DxIntegers.v DxValues.v DxNat.v DxAST.v DxFlag.v DxList64.v DxOpcode.v IdentDef.v DxMemType.v DxMemRegion.v DxRegs.v DxState.v DxMonad.v DxInstructions.v Tests.v TestMain.v ExtrMain.v)
COQEQUIV =  $(addprefix equivalence/, switch.v equivalence.v)
COQISOLATION = $(wildcard isolation/*.v)

COQCOMM = $(wildcard comm/*.v)
#COQMODEL = $(wildcard model/*.v)
#COQSRC = $(wildcard src/*.v)

comm:
	@echo $@
#	rm -f comm/*.vo
	$(COQMAKEFILE) -f _CoqProject $(COQCOMM) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

model:
	@echo $@
#	rm -f model/*.vo
	$(COQMAKEFILE) -f _CoqProject $(COQMODEL) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

isolation:
	@echo $@
#	rm -f isolation/*.vo
	$(COQMAKEFILE) -f _CoqProject $(COQISOLATION) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

equivalence:
	@echo $@
#	rm -f equivalence/*.vo
	$(COQMAKEFILE) -f _CoqProject $(COQEQUIV) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

compile:
	@echo $@
#	rm -f src/*.vo
	$(COQMAKEFILE) -f _CoqProject $(COQSRC) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile
	$(CP) TestMain.ml src # mv -> cp to avoid when running `make` again, it doesn't find the two files
	$(CP) TestMain.mli src

extract:
	@echo $@
	$(COMPCERTSRCDIR)/tools/modorder $(COMPCERTSRCDIR)/.depend.extr cfrontend/PrintCsyntax.cmx | \
	    $(AWK) '{ delete paths ;                                                                 \
	              for(i = 1; i <= NF; i++) {                                                     \
	                 x = $$i ;                                                                   \
	                 sub("/[^/]*$$", "", x) ;                                                    \
	                 paths[x] = 1 ;                                                              \
	              }                                                                              \
	              for(p in paths) {                                                              \
	                 print "-I" ;                                                                \
	                 print "$(COMPCERTSRCDIR)/" p ;                                              \
	              }                                                                              \
	            }' > compcertsrc-I	
	$(COMPCERTSRCDIR)/tools/modorder $(COMPCERTSRCDIR)/.depend.extr cfrontend/PrintCsyntax.cmx | \
	    $(AWK) 'BEGIN { RS=" " } /cmx/ { gsub(".*/","") ; print }' > compcertcprinter-cmx-args
	$(OCAMLOPT) -args compcertsrc-I -I $(DXDIR)/extr -I $(DXDIR)/src -I src src/TestMain.mli	
	$(OCAMLOPT) -args compcertsrc-I -I $(DXDIR)/extr -I $(DXDIR)/src -I src -c src/TestMain.ml
	$(OCAMLOPT) -args compcertsrc-I -a -args compcertcprinter-cmx-args -o compcertcprinter.cmxa
	$(OCAMLOPT) -args compcertsrc-I -a -args compcertcprinter-cmx-args -o compcertcprinter.a
	$(OCAMLOPT) -args compcertsrc-I str.cmxa unix.cmxa compcertcprinter.cmxa $(DXDIR)/extr/ResultMonad.cmx $(DXDIR)/extr/DXModule.cmx $(DXDIR)/extr/DumpAsC.cmx src/TestMain.cmx -o src/main
	ln -sf $(COMPCERTSRCDIR)/compcert.ini src/compcert.ini
	cd src && ./main

repatch:
	@echo $@
	$(CP) src/generated.c repatch
	cd repatch && $(CC) -o repatch1 repatch1.c && ./repatch1 && $(CC) -o repatch2 repatch2.c && ./repatch2 && $(CC) -o repatch3 repatch3.c && ./repatch3 && $(CC) -o repatch4 repatch4.c && ./repatch4
	$(CP) repatch/interpreter.c clight

clight:
	@echo $@
	cd clight && $(CC) -o $@ $(OFLAGS) fletcher32_bpf_test.c interpreter.c # && ./$@
	cd clight && $(CLIGHTGEN32) interpreter.c
	$(COQMAKEFILE) -f _CoqProject clight/interpreter.v COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

PROOF = $(addprefix proof/correctproof/, correct_upd_pc.v correct_eval_pc.v correct_upd_pc_incr.v correct_eval_reg.v  correct_eval_flag.v correct_upd_flag.v correct_eval_mrs_regions.v correct_get_addr_ofs.v correct_get_dst.v correct_get_immediate.v correct_is_well_chunk_bool.v correct_get_block_ptr.v correct_get_block_size.v correct_get_start_addr.v correct_get_add.v correct_get_sub.v correct_upd_reg.v correct_get_opcode_alu64.v)

# correct_check_mem_aux.v correct_step_opcode_alu64.v correct_load_mem.v

CLIGHTLOGICDIR =  $(addprefix proof/, clight_exec.v CommonLib.v Clightlogic.v MatchState.v CorrectRel.v CommonLemma.v CommonLemmaNat.v)


clightproof:
	@echo $@
#	rm -f proof/*.vo
	$(COQMAKEFILE) -f _CoqProject $(CLIGHTLOGICDIR) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefilePrf
	make -f CoqMakefilePrf


# PROOF = $(wildcard proof/correctproof/*.v)
correctproof:
	@echo $@
#	rm -f proof/correctproof/*.vo
	$(COQMAKEFILE) -f _CoqProject $(PROOF) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefilePrf
	make -f CoqMakefilePrf

clean :
	@echo $@
	make -f CoqMakefile clean
	make -f CoqMakefilePrf clean
	find . -name "*\.vo" -exec rm {} \;
	find . -name "*\.cmi" -exec rm {} \;
	find . -name "*\.cmx" -exec rm {} \;


# We want to keep the .cmi that were built as we go
.SECONDARY:

.PHONY: all test comm model equivalence compile extract repatch clight proof correctproof clean
