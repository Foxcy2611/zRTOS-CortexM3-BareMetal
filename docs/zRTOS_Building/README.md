# zRTOS Documentation Map

Thư mục này chứa các đặc tả dùng làm contract xuyên suốt quá trình xây zRTOS.

Mỗi tài liệu trả lời một câu hỏi khác nhau. Không nên dồn toàn bộ chi tiết vào README root.

| File | Trả lời câu hỏi |
|---|---|
| `00_architecture.md` | Hệ thống được chia thành các layer nào? |
| `01_kernel_invariants.md` | Những điều nào tuyệt đối không được sai? |
| `02_task_model.md` | Task/TCB/stack/state được mô hình hóa thế nào? |
| `03_context_switch.md` | Cortex-M3 port save/restore context ra sao? |
| `04_scheduler.md` | Scheduler, tick, ready/blocking hoạt động theo contract nào? |
| `05_ipc.md` | Semaphore, queue, mutex và timeout race hoạt động thế nào? |
| `06_api_contract.md` | Public API phải trả về behavior gì? |
| `07_configuration.md` | Các compile-time config của kernel là gì? |
| `08_testing.md` | Test và verification được tổ chức ra sao? |
| `09_hardware_validation.md` | Điều kiện nào phải PASS trên board thật? |
| `10_known_limitations.md` | zRTOS v1 cố tình không giải quyết điều gì? |
| `implementation_status.md` | Hiện tại project đang ở trạng thái nào? |

---

## Nguyên tắc sử dụng docs

1. **Spec trước, code sau.**
2. Nếu implementation buộc phải khác spec, thay đổi spec có chủ ý rồi mới chấp nhận behavior mới.
3. `implementation_status.md` phản ánh sự thật hiện tại; không ghi PASS trước khi có bằng chứng.
4. Build PASS không đồng nghĩa runtime PASS.
5. Release note là artifact sau cùng, không phải design document.
6. Mỗi invariant quan trọng nên có assert hoặc test tương ứng nếu khả thi.

---

## Flow phát triển

```text
ROADMAP
   ↓
DESIGN SPEC
   ↓
IMPLEMENT
   ↓
TEST
   ↓
HARDWARE VALIDATION
   ↓
STATUS UPDATE
   ↓
RELEASE
```

---

## Build convention

Project sử dụng thống nhất:

- CMake để mô tả build graph.
- Ninja làm build backend.
- `arm-none-eabi-gcc` làm cross-compiler.

Không duy trì Makefile build song song trong v1 để tránh hai nguồn cấu hình build khác nhau.
