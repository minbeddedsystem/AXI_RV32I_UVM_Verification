# Bug Log & Troubleshooting (Phase 1)

## 1. Driver: AW/W 채널 순차 처리 문제
**증상**: AW handshake 확인 후 W handshake를 순차적으로 기다리는 구조.
**문제**: AXI4 스펙상 AW/W는 완전히 독립된 채널이라, W가 AW보다 먼저 handshake되면 driver가 이를 놓치고 다시 오지 않을 W를 무한 대기하게 됨.
**해결**: `fork...join`으로 AW watch와 W watch를 병렬 프로세스로 분리, 각자 독립적으로 handshake를 감지하도록 수정.

## 2. Monitor: 동일한 AW/W 순차 의존성 문제
**증상**: Driver와 동일한 구조적 결함이 monitor의 `monitor_write()`에도 존재.
**해결**: Driver와 같은 방식으로 `fork` 안에서 `watch_aw`, `watch_w`를 독립 캡처하도록 수정.

## 3. Driver: Reset 처리 및 Timeout 부재
**증상**: 리셋 해제를 기다리지 않고 바로 동작 시작. DUT가 READY를 영원히 안 올리면 시뮬레이션이 무한 대기.
**해결**: `wait (vif.rst_n === 1'b1)`로 리셋 해제 대기 추가. 각 채널 handshake에 `TIMEOUT_CYCLES`(1000사이클) 카운터를 추가해 초과 시 `uvm_fatal`로 명확히 실패 처리.

## 4. PH_TIMEOUT (초기 sequence-sequencer 통합 테스트)
**증상**: sequencer/sequence만 만들고 driver 없이 실행 시 `UVM_FATAL [PH_TIMEOUT]` 발생.
**원인 분석**: `finish_item()`은 driver의 `item_done()` 응답을 기다리는데, driver가 없어 영원히 대기 → objection이 안 내려가 phase timeout.
**교훈**: sequence/sequencer만으로는 완결된 흐름이 아니며, driver 연결까지 확인해야 함.

## 5. 컴파일 에러: Undefined interface 'axi4_lite_if'
**증상**: driver/monitor가 `virtual axi4_lite_if`를 참조하는데 `axi4_interface.sv`를 SRC 목록에서 빠뜨림.
**해결**: 컴파일 SRC 목록에 interface 정의 파일 포함.

## 6. Coverage Hole: cp_data (zero/all_one), cx_addr_rw
**증상**: 랜덤 write-read 5쌍만으로는 functional coverage 62.5%에 그침. 32비트 완전 랜덤 값이 정확히 0x00000000 또는 0xFFFFFFFF가 나올 확률이 극히 낮고, 5쌍으로는 레지스터×R/W 8개 조합을 다 못 채움.
**해결**: 4개 레지스터를 순회하며 데이터 0x00000000, 0xFFFFFFFF로 write+read하는 directed 시퀀스 추가 → coverage 100% 달성.

## 7. VS Code 확장 오탐 (xvlog failed)
**증상**: Problems 탭에 `xvlog failed (invocation failed)` 에러가 계속 표시됨.
**원인**: SystemVerilog 확장의 실시간 린터가 Xilinx Vivado의 `xvlog`를 호출하려다 서버에 없어서 실패. 실제 VCS 컴파일과는 무관한 에디터 전용 오탐.
**해결**: `verilog.linting.linter` 설정을 `xvlog`에서 `none`으로 변경.


## Phase 2 — RV32I 5-Stage Pipeline CPU

### 1. Load-use hazard (설계 단계에서 인지, 정상 처리)

**증상**: load 명령어 바로 다음 명령어가 그 결과 레지스터를 사용하는 경우, forwarding만으로는 해결 불가 (load 데이터는 MEM 단계가 끝나야 나오는데, forwarding은 EX 단계 시작 시점에 필요).

**해결**: `hazard_unit`이 현재 EX 단계 명령어가 load인지(`ex_rf_src_sel == 3'b001`), 그리고 그 목적 레지스터가 현재 ID 단계 명령어의 소스 레지스터와 같은지 감지해서, PC/IF-ID 레지스터를 1사이클 정지시키고 ID/EX 레지스터에 bubble을 삽입.

### 2. Control hazard (설계 단계에서 인지, 정상 처리)

**증상**: branch/jump 여부가 EX 단계에서야 확정되는데, 그 사이 IF 단계와 ID 단계에 이미 명령어 2개가 잘못 들어와 있음(wrong-path).

**해결**: EX 단계의 `pc_sel`(branch taken 또는 jump)이 뜨면, 같은 사이클에 IF/ID와 ID/EX 레지스터를 동시에 flush(bubble로 대체)해서 wrong-path 명령어 2개를 무효화.

### 3. [버그] Golden model 조합논리 무한루프 (시뮬레이션 hang)

**증상**: golden model(싱글사이클) 단독 테스트에서도, 전체 testbench에서도 시뮬레이션이 아예 진행되지 않고 멈춤(hang). heartbeat 신호(`#100`마다 `$display`)를 추가해서 확인해보니 heartbeat조차 한 번도 안 찍힘 → 0ns 근처에서 완전히 정지.

**원인 분석**: `ps aux`로 확인한 결과 프로세스가 CPU 99%로 계속 돌고 있음(진짜 무한루프). 파이프라인용으로 `register_file.sv`에 추가했던 write-through bypass(`rf_we && waddr==raddr → wdata 즉시 반환`) 로직을 golden model에도 그대로 재사용한 게 원인. 파이프라인에서는 ID(read)와 WB(write) 사이에 파이프라인 레지스터가 여러 개 껴 있어서 안전하지만, 싱글사이클 golden model은 read와 write가 같은 사이클에 조합적으로 바로 연결돼 있어서 `rdata → alu → wdata → (bypass) → rdata`로 되돌아오는 진짜 combinational loop가 생성됨.

**해결**: golden model 전용 `register_file_golden` 모듈을 별도로 만들어 bypass 로직 제거(원본 그대로의 순수 배열 read/write). `golden_datapath.sv`가 이 모듈을 쓰도록 수정.

**교훈**: 파이프라인/싱글사이클처럼 구조가 다른 두 설계 사이에 서브모듈을 그대로 재사용할 때는, 그 모듈이 가정하고 있는 타이밍 전제(여기서는 "read와 write 사이에 최소 1개 이상의 레지스터 스테이지가 있다")가 재사용 대상에서도 성립하는지 반드시 확인해야 함.

### 4. [버그] EX/MEM 단계 forwarding이 LUI/AUIPC/JAL/JALR 값을 잘못 forwarding

**증상**: `LUI x15, 0x12345 ; ADDI x15, x15, 0x678`처럼 32비트 immediate를 만드는 전형적인 패턴에서, golden model은 `x15 = 0x12345678`을 기대하는데 DUT는 `x15 = 0x0000077b`(엉뚱한 값)를 만듦. golden model vs DUT 비교에서 532건 중 딱 1건만 실패.

**원인 분석**: `ex_stage`의 forwarding 로직이 EX/MEM 단계(1칸 forwarding, `forward_a/b == 2'b10`)에서 무조건 `mem_alu_result`(ALU 결과)만 넘기고 있었음. 그런데 LUI/AUIPC/JAL/JALR 명령어의 실제 write-back 값은 ALU 결과가 아니라 각각 immediate 원본, `pc+imm`, `pc+4`임(WB 단계 mux가 `rf_src_sel`로 5가지 중 골라줌). MEM/WB 단계 forwarding(`forward_a/b == 2'b01`)은 이미 WB 단계의 mux를 거친 `wb_wdata`를 쓰기 때문에 문제없었지만, EX/MEM 단계는 그 mux를 안 거치고 지름길로 ALU 결과만 넘기다 보니, LUI 바로 다음 명령어처럼 "생산자-소비자가 1칸 붙어있는" 경우에만 틀린 값이 forwarding됨.

**해결**: `ex_stage`에 WB 단계와 동일한 5-way mux(`mem_fwd_value`)를 추가해서, EX/MEM 단계 forwarding도 `mem_rf_src_sel`에 따라 `mem_alu_result`/`mem_imm`/`mem_pc_imm`/`mem_pc_4` 중 올바른 값을 고르도록 수정.

**교훈**: forwarding 경로를 설계할 때 "ALU 결과만 forwarding하면 된다"고 가정하기 쉬운데, write-back 값의 출처가 명령어 타입마다 다른 CPU(LUI/AUIPC/JAL 등 ALU를 거치지 않는 write-back 경로가 있는 경우)에서는 모든 forwarding 지점에 WB mux와 동일한 선택 로직을 일관되게 적용해야 함. golden model 기반 scoreboard가 아니었다면 파형만 봐서는 놓치기 쉬운 종류의 버그였음.

### Phase 2 최종 검증 결과

golden model 기반 scoreboard 비교: 레지스터 write 이벤트 532건 중 **PASS 532 / FAIL 0**.



## Phase 3 — APB UVM VIP + AXI-APB Bridge

### 1. `` `timescale `` 지시어와 UVM 패키지 파싱 충돌

**증상**: `apb_interface.sv`를 포함해 UVM 클래스 파일들에 `` `timescale 1ns / 1ps `` 를 넣고 `-ntb_opts uvm`으로 컴파일했더니 `Error-[ITSFM] Illegal `timescale for module` 발생. 이어서 뒤에 파싱되는 `apb_transaction.sv`에서도 `uvm_sequence_item` 토큰을 못 찾는 문법 에러로 이어짐.

**원인**: VCS가 UVM 패키지(`uvm_pkg.sv`, `` `timescale `` 없음)를 SRC 목록보다 먼저 파싱하는데, 그 뒤에 `` `timescale `` 이 있는 모듈이 나오면 "이전 모듈/패키지들과 timescale 사용 여부가 다르다"는 이유로 에러가 남. 첫 파일에서 파싱이 깨지면서 그 여파로 다음 파일 파싱도 같이 꼬임.

**해결**: UVM 클래스를 담은 파일들(`apb_transaction.sv`, `apb_sequencer.sv`, `apb_driver.sv`, `apb_monitor.sv`, `apb_agent.sv`, `apb_coverage.sv`, sequence/scoreboard/test 파일들)에서 `` `timescale `` 을 전부 제거. 순수 RTL 모듈(`apb_interface.sv`, `apb_reg_slave.sv`, `axi_apb_bridge.sv`)에도 동일하게 넣지 않는 것으로 통일.

### 2. UVM 클래스(`uvm_sequence_item` 등) 인식 불가

**증상**: `` `timescale `` 제거 후에도 `apb_transaction.sv`에서 `uvm_sequence_item`을 알 수 없는 타입이라고 함.

**원인**: `-ntb_opts uvm` 옵션이 UVM 패키지 자체는 컴파일에 포함시켜주지만, 각 소스 파일에서 그 패키지 내용을 실제로 쓰려면 `import uvm_pkg::*;` 와 `` `include "uvm_macros.svh" `` 를 파일마다 명시적으로 선언해야 함.

**해결**: UVM 클래스를 쓰는 모든 파일 맨 위에 아래 두 줄 추가.
```systemverilog
import uvm_pkg::*;
`include "uvm_macros.svh"
```

### Phase 3 최종 검증 결과

- APB VIP 단독 검증: PASS 13 / FAIL 0, Coverage 100%
- AXI4 VIP → axi_apb_bridge → APB 슬레이브 통합 검증: PASS 13 / FAIL 0, Coverage 100%, UVM_ERROR/FATAL 0