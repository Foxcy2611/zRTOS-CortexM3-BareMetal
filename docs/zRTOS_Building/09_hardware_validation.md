# 09 — Hardware Validation Checklist

Tài liệu này là release gate trên STM32F103C8T6.

Không thay `PENDING` bằng `PASS` nếu chưa quan sát trực tiếp trên board.

---

## 1. Thiết bị

- STM32F103C8T6 board.
- ST-Link qua SWD.
- USB-UART 3.3 V.
- ADC test source 0-3.3 V.
- HSE/clock source theo board thực tế.

---

## 2. Run metadata

| Trường | Giá trị |
|---|---|
| Date/time | PENDING |
| Board/revision | PENDING |
| Commit hash | PENDING |
| GCC version | PENDING |
| CMake version | PENDING |
| Ninja version | PENDING |
| OpenOCD version | PENDING |
| ST-Link | PENDING |
| Clock/HSE | PENDING |

---

## 3. Firmware gates

| Firmware | Quan sát bắt buộc | Status |
|---|---|---|
| `zrtos_phase0` | flash verify, LED/UART smoke, reset nhiều lần | PENDING |
| `zrtos_first_task` | SVC, task dùng PSP, handler dùng MSP, arg đúng | PENDING |
| `zrtos_scheduler_demo` | preemption, delay, RR, no HardFault | PENDING |
| `zrtos_ipc_stress` | sequence đúng, no double-wake, stress dài hạn | PENDING |
| `zrtos_full_demo` | UART IRQ, ADC/DMA, logging, no corruption | PENDING |

---

## 4. Boundary / fault tests

- [ ] Cố ý phá stack canary -> assert/fault hook.
- [ ] Cố ý return khỏi task -> task return trap.
- [ ] Ép tick gần `UINT32_MAX` -> delay/timeout qua wrap.
- [ ] Tái hiện Low/Medium/High -> kiểm chứng priority inheritance.
- [ ] Event xảy ra sát timeout -> task chỉ wake đúng một lần.
- [ ] Làm đầy queue/log path -> kernel vẫn sống và error/drop counter đúng nếu có.
- [ ] Reset/reflash nhiều lần có và không debugger.

---

## 5. Stress target

Release v1 nên có ít nhất một stress run nhiều giờ cho scheduler + IPC.

Khuyến nghị minimum gate:

```text
>= 8 giờ
```

Nếu project thực tế cần thấp hơn trong quá trình phát triển, status vẫn là PARTIAL chứ chưa phải release PASS.

---

## 6. Release condition

Chỉ tạo `v1.0.0` khi:

- required gates PASS;
- docs khớp source;
- implementation status được cập nhật;
- known limitations được rà soát;
- clean clone build được bằng CMake + Ninja.
