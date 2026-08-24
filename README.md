# AXI_APB_UVM_VIP

AXI4-Lite / APB UVM Verification IP를 설계하고, 이를 이용해 자체 설계한 하드웨어를 검증하는 프로젝트입니다. 팹리스 SoC 설계/검증 직무 포트폴리오로 진행 중이며, 현재 **Phase 1(AXI4 UVM VIP)이 완료**된 상태입니다.

## Verification Flow

![AXI4 UVM Verification Flow](work/docs/images/verification_flow.png)

## Overview

| 항목 | 내용 |
|---|---|
| 검증 방법론 | UVM (Universal Verification Methodology) |
| 시뮬레이터 | Synopsys VCS |
| 디버깅 툴 | Synopsys Verdi |
| 언어 | SystemVerilog |
| 진행 단계 | Phase 1 완료 (AXI4 VIP), Phase 2(RV32I Pipeline CPU) 진행 예정 |

## Phase 1 — AXI4-Lite UVM VIP

재사용 가능한 AXI4-Lite UVM VIP(interface, transaction, sequence, sequencer, driver, monitor, agent, scoreboard, coverage)를 직접 설계하고, 예제 AXI4-Lite 레지스터 슬레이브 DUT를 대상으로 write-read 데이터 무결성을 검증했습니다.

### 결과

| 항목 | 결과 |
|---|---|
| 총 트랜잭션 | write 13 / read 13 (랜덤 5쌍 + directed 8쌍) |
| Scoreboard | PASS 13 / FAIL 0 |
| Functional Coverage | **100%** |
| UVM_ERROR / UVM_FATAL | 0 / 0 |

Coverage 항목: write/read 여부(cp_rw), 레지스터별 접근(cp_addr), 데이터 패턴(cp_data: zero/all_one/others), 레지스터×R/W cross coverage(cx_addr_rw).

### 구조

work/
├── vip/axi4/ # 재사용 가능한 AXI4-Lite UVM VIP
│ ├── axi4_interface.sv
│ ├── axi4_transaction.sv
│ ├── axi4_sequencer.sv
│ ├── axi4_sequence.sv
│ ├── axi4_driver.sv # reset wait, AW/W 병렬 handshake, timeout
│ ├── axi4_monitor.sv # AW/W 병렬 캡처
│ ├── axi4_agent.sv
│ └── axi4_coverage.sv
├── rtl/example_dut/
│ └── axi_lite_reg_slave.sv
├── tb/vip_standalone_tb/
│ ├── axi4_wr_rd_seq.sv
│ ├── axi4_scoreboard.sv
│ └── axi4_dut_test.sv
└── docs/
├── verification_plan.md
└── bug_log.md


### 주요 트러블슈팅

- **AXI AW/W 채널 독립 handshake 문제**: driver/monitor가 AW handshake를 먼저 확인한 뒤 W를 확인하는 순차 구조였는데, AXI 스펙상 AW/W는 독립 채널이라 순서가 뒤바뀌면 handshake를 놓치는 문제 발견. `fork...join` 기반 병렬 처리로 수정.
- **Reset/Timeout 처리 부재**: 리셋 해제 대기 로직과 handshake timeout이 없어 DUT 이상 시 시뮬레이션이 무한 대기할 수 있는 구조였음. 리셋 대기 및 1000사이클 timeout(`uvm_fatal`) 추가.
- **Coverage Closure**: 완전 랜덤 시퀀스만으로는 62.5%에 그침(데이터 zero/all_one 패턴, 레지스터×R/W 조합 일부 누락). 4개 레지스터를 순회하는 directed 시퀀스 추가로 100% 달성.

자세한 내용은 [`work/docs/verification_plan.md`](work/docs/verification_plan.md), [`work/docs/bug_log.md`](work/docs/bug_log.md) 참고.

## Phase 2 — RV32I 5-Stage Pipeline CPU Verification (예정)

싱글사이클 RV32I CPU를 5-stage 파이프라인으로 재설계하고, Phase 1에서 만든 AXI4 VIP로 검증할 예정입니다.

## Tools

- Synopsys VCS (시뮬레이션)
- Synopsys Verdi (파형 디버깅)
- UVM 1.1d