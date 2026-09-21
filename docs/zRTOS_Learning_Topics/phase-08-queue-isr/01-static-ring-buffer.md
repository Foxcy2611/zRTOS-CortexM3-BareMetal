# Bài 8.1 — Static Ring Buffer và Queue Data Model

> **Phạm vi:** Queue tĩnh dùng ring buffer, metadata, copy semantics và invariants full/empty.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không zero-copy, stream buffer hoặc message buffer.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-blocked-senders-receivers.md)

---

## Mục lục

- [1. Queue = data + synchronization](#1-queue-=-data-+-synchronization)
- [2. Static ring buffer](#2-static-ring-buffer)
- [3. Copy semantics và criticality](#3-copy-semantics-và-criticality)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Queue = data + synchronization

Khác semaphore chỉ biểu diễn token, queue chứa item thực. Sự tồn tại item/slot đồng thời tạo điều kiện wake receiver/sender.

### Producer/consumer boundary

Producer không cần biết consumer đang chạy lúc nào; queue decouple timing trong giới hạn capacity.

### FIFO

zRTOS v1 dùng FIFO để behavior dễ test và predict.

### Tại sao phần này quan trọng với RTOS?

Queue là IPC abstraction quan trọng nhất để firmware tránh shared global flags/buffers tự phát.

### Góc nhìn debug

Log sequence ID item để verify FIFO.

---

## 2. Static ring buffer

Caller cung cấp vùng storage. Queue object giữ `storage`, `item_size`, `capacity`, `read_index`, `write_index`, `count`.

### Write index

Trỏ slot sender kế tiếp ghi rồi wrap modulo capacity.

### Read index

Trỏ item receiver kế tiếp đọc.

### Count

Phân biệt empty=0 và full=capacity rõ ràng.

```text
storage:
[0][1][2][3]...[N-1]
 ^        ^
 read     write

send: write=(write+1)%N, count++
recv: read =(read +1)%N, count--
```

### Tại sao phần này quan trọng với RTOS?

Ring buffer không cần shift dữ liệu khi pop/push.

### Góc nhìn debug

Test capacity 1, 2 và wrap nhiều vòng vì edge case thường lộ ở boundary.

---

## 3. Copy semantics và criticality

V1 copy item vào/out queue. Simplicity đổi lại memcpy cost theo item_size.

### Atomic metadata

Indices/count update phải protected; không để ISR/task nhìn count đã đổi nhưng data chưa copy theo contract.

### Large items

Nếu item lớn, queue pointer hoặc separate ownership protocol có thể tối ưu sau; không cần premature zero-copy.

### Tại sao phần này quan trọng với RTOS?

Data consistency quan trọng hơn micro-optimization ở first kernel.

### Góc nhìn debug

Stress producer/consumer với pattern/checksum.

---

## 4. Mental Model tổng hợp

```text
zrtos_queue_t
 |
 +--> storage
 +--> item_size
 +--> capacity
 +--> read_index
 +--> write_index
 +--> count
 |
 +--> waiting_receivers (later)
 +--> waiting_senders   (later)
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- 0 <= count <= capacity.
- read_index/write_index luôn trong range.
- FIFO order không bị phá.
- Storage lifetime >= queue lifetime.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Ring buffer không cần count”

Có nhiều design; zRTOS dùng count nên phải giữ invariant của nó.

### “Queue phải zero-copy mới embedded-friendly”

Copy semantics đủ tốt cho v1 và dễ đúng hơn.

### “Queue chỉ là array wrapper”

Blocking/wake semantics mới làm nó thành RTOS IPC.

---

## 7. Liên hệ trực tiếp với zRTOS

`zrtos_queue_init_static()` sẽ mirror triết lý static task creation: caller sở hữu storage, kernel sở hữu metadata/state transition.

---

## 8. Tổng kết

- Queue truyền dữ liệu và đồng bộ cùng lúc.
- Ring metadata phải luôn đồng bộ với storage content.
- Copy queue đơn giản, deterministic và phù hợp zRTOS v1.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Queue metadata tối thiểu gồm gì?
2. Ring buffer wrap hoạt động ra sao?
3. Copy semantics có trade-off gì?
4. Tại sao queue còn là synchronization primitive?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-blocked-senders-receivers.md)
