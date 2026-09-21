# Bài 12.2 — Git History, Release và CV Framing

> **Phạm vi:** Git milestone history, release discipline và cách mô tả zRTOS chính xác trong CV/phỏng vấn.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không dạy Git command cơ bản.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-repo-docs-reproducibility.md) · [Bài tiếp →](03-v1-scope-future.md)

---

## Mục lục

- [1. Git history kể quá trình engineering](#1-git-history-kể-quá-trình-engineering)
- [2. Release zRTOS v1](#2-release-zrtos-v1)
- [3. CV và interview framing](#3-cv-và-interview-framing)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Git history kể quá trình engineering

Một history tốt cho thấy design tiến hóa từ initial stack, SVC, PendSV, scheduler, blocking tới IPC và testing.

### Atomic commit

Một commit tập trung một thay đổi logic và đi kèm test/docs khi phù hợp.

### Scope naming

`feat(port)`, `feat(sched)`, `feat(queue)`, `test(...)`, `docs(...)` giúp history dễ scan.

### Không giant initial commit

Nếu có thể, tránh đưa toàn bộ kernel vào một commit duy nhất vì mất dấu quá trình học/design.

### Tại sao phần này quan trọng với RTOS?

Reviewer có thể đọc history như một timeline kỹ thuật.

### Góc nhìn debug

Xem `git log --oneline` và hỏi từng commit có mô tả được một milestone không.

---

## 2. Release zRTOS v1

Khi core scope, tests, full demo và docs đạt gate, tạo một tag/version ổn định.

### Definition of done

Không release chỉ vì code compile; clean build/test/demo/docs phải pass.

### Release notes

Liệt kê feature thật, known limitations và target hardware.

### Version policy

Có thể dùng `v1.0.0` cho portfolio stable milestone hoặc `v0.x` nếu vẫn experimental; quan trọng là nhất quán.

### Tại sao phần này quan trọng với RTOS?

Release tạo điểm dừng rõ, chống feature creep.

### Góc nhìn debug

Checkout tag release rồi build lại từ clean folder.

---

## 3. CV và interview framing

Mô tả chính xác sẽ mạnh hơn claim lớn. Một câu hợp lý: “Designed and implemented a preemptive RTOS kernel for ARM Cortex-M3 / STM32F103 from scratch.”

### Evidence

PendSV/SVC context switching, fixed-priority scheduler, blocking IPC, mutex PI, finite timeout, tests và full demo.

### Interview depth

Phải tự vẽ stack frame, explain semaphore direct handoff, queue wait, timeout race và priority inversion mà không nhìn docs.

### Không gọi ‘tự viết FreeRTOS’

FreeRTOS là tên sản phẩm cụ thể; zRTOS là RTOS kernel tự thiết kế.

### Tại sao phần này quan trọng với RTOS?

Claim chỉ mạnh khi có source/test/docs và khả năng giải thích backing.

### Góc nhìn debug

Tự mock interview 5 phút cho context switch, 5 phút cho scheduler, 5 phút cho IPC/mutex.

---

## 4. Mental Model tổng hợp

```text
clean milestone history
        |
        v
tested release tag
        |
README + docs + tests + demo
        |
        v
CV claim
        |
        v
interview explanation backed by repo
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- CV claim không vượt feature thực tế.
- Release notes nêu limitations.
- Release tag build/test được từ clean clone.
- Git history không chứa generated noise không cần thiết.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Số dòng code càng nhiều CV càng mạnh”

Depth, architecture và test quan trọng hơn LOC.

### “Gọi production-grade nghe ấn tượng hơn”

Claim không có evidence dễ phản tác dụng.

### “Git chỉ là chỗ lưu code”

History còn cho thấy design evolution.

---

## 7. Liên hệ trực tiếp với zRTOS

zRTOS sẽ mạnh khi mỗi claim trong CV có artifact backing: commit, source module, test và document tương ứng.

---

## 8. Tổng kết

- Git history là design trace, không chỉ backup.
- Release tag là snapshot có guarantee rõ hơn main branch bất kỳ.
- Portfolio value nằm ở depth và explainability.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Viết một câu CV mô tả zRTOS chính xác.
2. Release gate nên gồm những gì?
3. Git history tốt cho reviewer thấy điều gì?
4. Bạn cần giải thích được những chủ đề nào khi phỏng vấn?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-repo-docs-reproducibility.md) · [Bài tiếp →](03-v1-scope-future.md)
