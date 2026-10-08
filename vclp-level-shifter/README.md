# VC LP Level Shifter 최소 예제 (Power 2개)

```
              VDDH = 1.0V (PD_TOP)
   +-----------------------------------------------+
   | top                                           |
   |            VDDL = 0.8V (PD_CORE)              |
   |   clk  --[LS H->L]-->+---------------+        |
   |   rst_n--[LS H->L]-->|    u_core     |        |
   |   din  --[LS H->L]-->| dout <= ~din  |--[LS L->H]--> dout
   |                      +---------------+        |
   +-----------------------------------------------+
                     VSS (공통)
```

## 구성
| 파일 | 설명 |
|---|---|
| `rtl/core.v` | 0.8V 블록 (플립플롭 1개) |
| `rtl/top.v`  | 1.0V 최상위, `u_core` 인스턴스 |
| `upf/top.upf` | 전원 2개 + Level Shifter strategy |
| `run/run_vclp.tcl` | VC LP 실행 스크립트 |

## 실행
```bash
cd run
vc_static_shell -f run_vclp.tcl
```

## 에러가 나지 않게 하는 핵심 포인트
1. **모든 supply port에 state 정의** (`add_port_state`) – 누락 시 `UPF_SUPPLY_NO_STATE` 류 에러.
2. **PST에 두 전원이 동시에 ON인 상태만 존재** → 두 도메인 모두 always-on이므로 **Isolation strategy 불필요** (`ISO_STRATEGY_MISSING` 없음).
3. **전압이 다른 모든 crossing에 LS strategy** – `-applies_to both -rule both` 로 입력(H→L) / 출력(L→H) 모두 커버 → `LS_STRATEGY_MISSING` 없음.
4. **Top IO의 driver/receiver supply 지정** (`set_port_attributes`) – 포트 전압이 PD_TOP과 동일함을 명시해 IO 경계에서 불필요한 LS 요구가 없음.
5. LS 위치는 `parent` (PD_TOP). 모든 supply net이 top scope에 있으므로 LS의 입력/출력 supply 모두 사용 가능.

## 확인용 변형 (일부러 에러 내보기)
- `set_level_shifter` 블록을 주석 처리 → `LS_STRATEGY_MISSING` 발생.
- `-rule low_to_high` 로 변경 → 입력 3개(clk/rst_n/din)에 대해 H→L LS 누락 위반 발생.
- PST에 `add_pst_state CORE_OFF -pst PST -state {HV OFF GND}` 추가 (VDDL에 `-state {OFF off}` 추가 필요) → `ISO_STRATEGY_MISSING` 발생.

## Netlist 단계로 확장할 때
`run_vclp.tcl`의 `link_library` 주석을 풀고, 합성 netlist + 동일 UPF로 `check_lp -stage design` 을 돌리면 실제 LS cell 삽입/연결 (`LS_INST_MISSING`, `LS_SUPPLY_*`) 까지 검증됩니다. 이때 LS cell 지정이 필요하면 UPF에 아래를 추가하세요.
```tcl
map_level_shifter_cell LS_CORE -domain PD_CORE -lib_cells {<LS_CELL_NAME>}
```
