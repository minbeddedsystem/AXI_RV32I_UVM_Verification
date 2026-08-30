# AXI4 UVM VIP — Verification Plan (Phase 1)

## 1. 검증 목표
직접 설계한 재사용 가능한 AXI4-Lite UVM VIP를 구축하고, 예제 AXI4-Lite 레지스터 슬레이브 DUT를 대상으로 write/read 데이터 무결성과 handshake 정합성을 검증한다.

## 2. 검증 대상(DUT)
- `axi_lite_reg_slave` — 4개의 32비트 레지스터(offset 0x00/0x04/0x08/0x0C)를 갖는 AXI4-Lite 슬레이브
- AW/W 채널 독립 handshake, B 응답, AR/R 채널을 모두 구현

## 3. 테스트벤치 구조

sequence(axi4_wr_rd_seq) → sequencer → driver → axi4_lite_if → DUT
│
monitor → scoreboard / coverage

- interface: `axi4_interface.sv`
- transaction: `axi4_transaction.sv` (addr, data, is_write, resp)
- sequencer/sequence: `axi4_sequencer.sv`, `axi4_wr_rd_seq.sv`
- driver: `axi4_driver.sv` (reset 대기, AW/W 병렬 handshake, timeout)
- monitor: `axi4_monitor.sv` (AW/W 병렬 캡처, 방송 analysis port)
- agent: `axi4_agent.sv` (active agent, driver+monitor+sequencer)
- scoreboard: `axi4_scoreboard.sv` (write 값 기록 → read 값과 비교)
- coverage: `axi4_coverage.sv` (functional coverage)

## 4. 테스트 시나리오
1. **랜덤 write-read (5쌍)**: 임의 주소/데이터로 write 후 같은 주소 read, 값 일치 확인
2. **Directed 레지스터 스윕 (4레지스터 × 2데이터 패턴)**: 각 레지스터에 대해 데이터 `0x00000000`, `0xFFFFFFFF`로 write+read하여 coverage hole 보강

## 5. Functional Coverage 계획
| Coverpoint | 내용 |
|---|---|
| cp_rw | write / read 각각 최소 1회 |
| cp_addr | 4개 레지스터(reg0~reg3) 전부 접근 |
| cp_data | 데이터 값 zero / all_one / others 3가지 패턴 |
| cx_addr_rw | 레지스터 × read/write 조합 (4×2=8) |

## 6. 결과 요약
| 항목 | 결과 |
|---|---|
| 총 트랜잭션 | write 13 / read 13 (랜덤 5쌍 + directed 8쌍) |
| Scoreboard | PASS 13, FAIL 0 |
| Functional Coverage | **100%** |
| UVM_ERROR / UVM_FATAL | 0 / 0 |

## 7. 향후 확장 (Phase 1 범위 밖, 여유 있을 때)
- Burst / outstanding transaction 시퀀스
- SVA 기반 프로토콜 체커
- Error response(SLVERR/DECERR) 시나리오
- Regression 자동화 (다중 seed)



## Phase 2 — RV32I 5-Stage Pipeline CPU

### 검증 목표

싱글사이클 RV32I CPU를 5단(IF-ID-EX-MEM-WB) 파이프라인으로 재설계하면서 발생하는 hazard(load-use, control)를 forwarding/stall/flush로 올바르게 처리하는지 검증한다.

### 검증 대상

- IF/ID/EX/MEM/WB 5개 파이프라인 스테이지
- forwarding_unit (EX/MEM, MEM/WB 2단계 forwarding)
- hazard_unit (load-use stall, branch/jump flush)

### 검증 전략

UVM 대신, 기존에 보유하고 있던 싱글사이클 RV32I CPU를 golden model로 재사용하는 self-checking testbench 방식을 사용했다.

1. golden model(싱글사이클)과 DUT(파이프라인)에 동일한 명령어 메모리(`instruction_mem_sort.mem`)를 로드
2. 두 CPU가 레지스터 파일에 write하는 이벤트(`waddr`, `wdata`)를 각각 큐에 순서대로 push
3. `cpu_scoreboard`가 두 큐를 순서대로 pop하며 비교 (사이클 타이밍이 달라도 "같은 프로그램이면 같은 순서로 같은 값을 쓴다"는 것만 비교하면 되므로 큐 기반 순서 비교로 충분)
4. x0 write(아키텍처상 항상 무시됨)는 비교 대상에서 제외

### 사용한 테스트 프로그램

R-type 10개, I-type 9개, S-type(store) 3개, IL-type(load) 5개, B-type(branch, 전부 taken) 6개, U-type(LUI/AUIPC) 2개, J-type(JAL/JALR) 2개 — RV32I 전체 명령어 카테고리를 한 번씩 이상 실행하도록 구성.

### 결과

| 항목 | 결과 |
|---|---|
| 비교된 레지스터 write 이벤트 | 532건 |
| PASS | 532 |
| FAIL | 0 |

### 향후 보강 (시간 되면)

- Functional coverage: 명령어 타입별 실행 여부, hazard(load-use stall / branch flush) 발생 여부 커버리지
- AXI4-Lite 브리지를 통해 Phase 1 AXI4 UVM VIP로 정식 UVM 환경 통합 검증