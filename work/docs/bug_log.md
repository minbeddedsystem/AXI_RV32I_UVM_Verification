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