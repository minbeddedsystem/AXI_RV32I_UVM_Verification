# =========================================================
# VCS + UVM + Verdi 공용 Makefile
# 사용법:
#   make compile TOP=hello SRC=hello.sv          # 일반 SV 컴파일
#   make compile TOP=hello_uvm SRC=hello_uvm.sv UVM=1   # UVM 컴파일
#   make run                                      # 시뮬레이션 실행
#   make waves                                    # FSDB 덤프 실행
#   make verdi                                    # Verdi로 파형 열기
#   make clean                                    # 생성물 정리
# =========================================================

TOP    ?= hello
SRC    ?= $(TOP).sv
SIMV   := simv_$(TOP)
FSDB   := $(TOP).fsdb

VCS_OPTS := -full64 -sverilog -debug_access+all
UVM_OPTS := -ntb_opts uvm

ifeq ($(UVM),1)
  COMPILE_OPTS := $(VCS_OPTS) $(UVM_OPTS)
else
  COMPILE_OPTS := $(VCS_OPTS)
endif

.PHONY: compile run waves verdi clean help

help:
	@echo "make compile TOP=<top> SRC=\"<files>\" [UVM=1]   - 컴파일"
	@echo "make run TOP=<top>                              - 실행"
	@echo "make waves TOP=<top>                             - FSDB 덤프 실행"
	@echo "make verdi TOP=<top>                             - Verdi 파형 열기"
	@echo "make clean                                       - 생성물 정리"

compile:
	vcs $(COMPILE_OPTS) $(SRC) -o $(SIMV)

run:
	./$(SIMV)

waves:
	FSDB=$(FSDB) ./$(SIMV) -ucli -do "dump.tcl"

verdi:
	verdi -ssf $(FSDB) &

clean:
	rm -rf simv* *.daidir *.vpd *.fsdb csrc DVEfiles ucli.key \
	       novas.* verdiLog vc_hdrs.h .vlogansetup.env AN.DB \
	       *.log