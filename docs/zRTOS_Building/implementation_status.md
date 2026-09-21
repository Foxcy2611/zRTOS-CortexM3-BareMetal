# Implementation Status

File này phản ánh trạng thái thực tế của source. Không dùng nó như roadmap.

Quy ước:

- `TODO` — chưa bắt đầu.
- `WIP` — đang hiện thực.
- `BUILD PASS` — compile/link được nhưng chưa đủ runtime evidence.
- `HOST PASS` — host test pass cho phần portable.
- `BOARD PASS` — behavior đã được xác minh trên target.
- `DONE` — implementation + required tests + required board gate đều pass.

---

| Phase | Design | Implementation | Host Test | Board Test | Status |
|---|---|---|---|---|---|
| 0 Build/Bare-metal | READY | TODO | N/A | TODO | TODO |
| 1 Cortex-M foundations | READY | TODO | N/A | TODO | TODO |
| 2 Task model | READY | TODO | TODO | TODO | TODO |
| 3 First task via SVC | READY | TODO | N/A | TODO | TODO |
| 4 PendSV/context switch | READY | TODO | N/A | TODO | TODO |
| 5 Preemptive scheduler | READY | TODO | TODO | TODO | TODO |
| 6 Lists/blocking/delay | READY | TODO | TODO | TODO | TODO |
| 7 Critical/sem | READY | TODO | TODO | TODO | TODO |
| 8 Queue/ISR IPC | READY | TODO | TODO | TODO | TODO |
| 9 Mutex/PI/timeout | READY | TODO | TODO | TODO | TODO |
| 10 Diagnostics/hardening | READY | TODO | TODO | TODO | TODO |
| 11 Full firmware | READY | TODO | N/A | TODO | TODO |
| 12 Release | READY | TODO | N/A | TODO | TODO |

---

## Ghi chú

- Không chuyển `BUILD PASS` thành `DONE` nếu chưa có runtime validation tương ứng.
- Khi một design change làm thay đổi behavior, cập nhật spec trước hoặc cùng commit với source.
- Release note chỉ được tạo sau khi status có bằng chứng phù hợp.
