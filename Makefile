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
	@$(MAKE) monadicmodel
	@$(MAKE) compile
	@$(MAKE) extract
	@$(MAKE) repatch
	@$(MAKE) clightmodel
	@$(MAKE) clightlogic
	@$(MAKE) simulation
	@$(MAKE) isolation
	@$(MAKE) equivalence

COQMODEL =  $(addprefix model/, Syntax.v Decode.v Semantics.v)
COQEMONADIC =  $(addprefix monadicmodel/, Opcode.v rBPFInterpreter.v)
COQSRC =  $(addprefix src/, InfComp.v GenMatchable.v CoqIntegers.v DxIntegers.v DxValues.v DxNat.v DxAST.v DxFlag.v DxList64.v DxOpcode.v IdentDef.v DxMemType.v DxMemRegion.v DxRegs.v DxState.v DxMonad.v DxInstructions.v Tests.v TestMain.v ExtrMain.v)
COQEQUIV =  $(addprefix equivalence/, equivalence1.v equivalence2.v)
COQISOLATION = $(addprefix isolation/, CommonISOLib.v AlignChunk.v RegsInv.v MemInv.v VerifierInv.v IsolationLemma.v Isolation.v)
COQCOMM = $(addprefix comm/, Flag.v LemmaNat.v List64.v rBPFAST.v rBPFMemType.v rBPFValues.v MemRegion.v Regs.v State.v Monad.v)

comm:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(COQCOMM) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

model:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(COQMODEL) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

monadicmodel:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(COQEMONADIC) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

isolation:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(COQISOLATION) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

equivalence:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(COQEQUIV) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

compile:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(COQSRC) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile
	$(CP) TestMain.ml src
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

clightmodel:
	@echo $@
	cd clight && $(CC) -o $@ $(OFLAGS) fletcher32_bpf_test.c interpreter.c && ./$@
	cd clight && $(CLIGHTGEN32) interpreter.c
	$(COQMAKEFILE) -f _CoqProject clight/interpreter.v COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefile
	make -f CoqMakefile

PROOF = $(addprefix simulation/, correct_eval_pc.v correct_upd_pc.v correct_upd_pc_incr.v correct_eval_reg.v correct_upd_reg.v correct_eval_flag.v correct_upd_flag.v correct_eval_mrs_num.v correct_eval_mrs_regions.v correct_load_mem.v correct_store_mem_reg.v correct_store_mem_imm.v correct_eval_ins_len.v correct_eval_ins.v correct_cmp_ptr32_nullM.v correct_get_dst.v correct_get_src.v correct_get_mem_region.v correct__bpf_get_call.v correct_exec_function.v correct_reg64_to_reg32.v correct_get_offset.v correct_get_immediate.v correct_eval_immediate.v correct_get_src64.v correct_get_src32.v correct_get_opcode_ins.v correct_get_opcode_alu64.v correct_get_opcode_alu32.v correct_get_opcode_branch.v correct_get_opcode_mem_ld_imm.v correct_get_opcode_mem_ld_reg.v correct_get_opcode_mem_st_imm.v correct_get_opcode_mem_st_reg.v correct_get_opcode.v correct_get_add.v correct_get_sub.v correct_get_addr_ofs.v correct_get_start_addr.v correct_get_block_size.v correct_get_block_perm.v correct_is_well_chunk_bool.v correct_check_mem_aux2.v correct_check_mem_aux.v correct_check_mem.v correct_step_opcode_alu64.v correct_step_opcode_alu32.v correct_step_opcode_branch.v correct_step_opcode_mem_ld_imm.v correct_step_opcode_mem_ld_reg.v correct_step_opcode_mem_st_reg.v correct_step_opcode_mem_st_imm.v correct_step.v correct_bpf_interpreter_aux.v correct_bpf_interpreter.v)

CLIGHTLOGICDIR =  $(addprefix proof/, clight_exec.v Clightlogic.v CommonLib.v CommonLemma.v MatchState.v CorrectRel.v CommonLemmaNat.v)


clightlogic:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(CLIGHTLOGICDIR) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefilePrf
	make -f CoqMakefilePrf

simulation:
	@echo $@
	$(COQMAKEFILE) -f _CoqProject $(PROOF) COQEXTRAFLAGS = '-w all,-extraction'  -o CoqMakefilePrf
	make -f CoqMakefilePrf

clean :
	@echo $@
	make -f CoqMakefile clean
	make -f CoqMakefilePrf clean
	find . -name "*\.vo" -exec rm {} \;
	find . -name "*\.cmi" -exec rm {} \;
	find . -name "*\.cmx" -exec rm {} \;
	find . -name "*\.crashcoqide" -exec rm {} \;


# We want to keep the .cmi that were built as we go
.SECONDARY:

.PHONY: all test comm model monadicmodel isolation equivalence compile extract repatch clightmodel proof simulation clean
