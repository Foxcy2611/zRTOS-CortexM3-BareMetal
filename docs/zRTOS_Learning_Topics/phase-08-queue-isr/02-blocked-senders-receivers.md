# Bài 8.2 — Blocked Senders, Receivers và Wake-and-Retry

> **Phạm vi:** Blocking khi queue empty/full, hai wait lists và wake-and-retry semantics.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không reservation/zero-copy direct handoff phức tạp.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-static-ring-buffer.md) · [Bài tiếp →](03-isr-queue-producer-consumer.md)

---

## Mục lục

- [1. Hai điều kiện chờ độc lập](#1-hai-điều-kiện-chờ-độc-lập)
- [2. Send/receive thay đổi readiness](#2-sendreceive-thay-đổi-readiness)
- [3. Wake-and-retry](#3-wake-and-retry)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Hai điều kiện chờ độc lập

Receiver block vì không có item; sender block vì không có slot. Một queue vì vậy cần `waiting_receivers` và `waiting_senders` riêng.

### Empty condition

Receive(wait) trên count=0 đưa task vào receiver wait list.

### Full condition

Send(wait) trên count=capacity đưa task vào sender wait list.

### Tại sao phần này quan trọng với RTOS?

Separate wait lists trả lời chính xác loại event nào có thể wake ai.

### Góc nhìn debug

Inspect wait_item.container để xác định task chờ send hay receive.

---

## 2. Send/receive thay đổi readiness

Send làm item available và có thể wake receiver. Receive làm slot available và có thể wake sender.

### Wake one

Một operation thường wake một waiter phù hợp để tránh thundering herd trong kernel nhỏ.

### Priority waiter

Có thể chọn highest-priority waiter để phù hợp fixed-priority policy.

### Tại sao phần này quan trọng với RTOS?

IPC event và scheduler priority phải kết nối nhưng không trộn responsibility.

### Góc nhìn debug

Test queue size=1 dễ tạo full/empty alternation và waiter transitions.

---

## 3. Wake-and-retry

zRTOS queue có thể không reserve item/slot cho task vừa wake. Task resume và recheck condition trong loop.

### Competition

Task khác có thể consume item/slot trước waiter vừa wake được schedule.

### Khác semaphore direct handoff

Semaphore token có thể handoff trực tiếp; queue buffer state phức tạp hơn nếu muốn reservation.

```text
Receiver wakes
   |
   v
READY
   |
scheduled later
   |
recheck count > 0 ?
   | yes -> receive
   | no  -> block again
```

### Tại sao phần này quan trọng với RTOS?

Recheck loop làm semantics robust trước scheduling interleaving.

### Góc nhìn debug

Tạo nhiều receiver/sender cùng priority để ép competition.

---

## 4. Mental Model tổng hợp

```text
queue empty:
 receive(wait)
   -> receiver BLOCKED

send item:
 count++
 wake receiver

queue full:
 send(wait)
   -> sender BLOCKED

receive item:
 count--
 wake sender

woken task:
 recheck condition
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Receiver chỉ ở receiver wait list khi operation chờ item.
- Sender chỉ ở sender wait list khi operation chờ slot.
- Wake remove đúng wait_item trước ready insertion.
- Woken operation recheck condition nếu không có reservation.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Một wait list chung là đủ”

Không biết wake sender hay receiver khi chỉ một condition thay đổi.

### “Wake receiver nghĩa item đã thuộc nó”

Không trong wake-and-retry design.

### “Queue blocking chỉ là semaphore + array”

Hai-sided waiting làm semantics khác đáng kể.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 8.2 là nơi common blocking helper được stress mạnh: cùng task có thể block trên receive/send và phải trở lại đúng ready list.

---

## 8. Tổng kết

- Queue có hai wait conditions nên cần hai waiter sets.
- Send/receive không chỉ copy data; chúng còn tạo wake events.
- Wake nghĩa condition vừa thay đổi, không nhất thiết resource đã reserve.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao queue cần hai wait lists?
2. Send wake loại task nào? Receive wake loại nào?
3. Wake-and-retry giải quyết scheduling competition ra sao?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-static-ring-buffer.md) · [Bài tiếp →](03-isr-queue-producer-consumer.md)
