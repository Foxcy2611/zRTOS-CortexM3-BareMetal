# 04 — Scheduler, Tick và Blocking

## 1. Priority model

- số priority lớn hơn = ưu tiên cao hơn;
- priority `0` dành cho idle;
- user priority nằm trong `1..ZRTOS_MAX_PRIORITIES-1`;
- scheduler dùng `effective_priority`, không dùng trực tiếp base priority khi PI đang active.

---

## 2. Ready lists

Mỗi priority có một ready list.

Policy:

- chọn highest non-empty priority;
- FIFO/round-robin giữa task cùng priority;
- RUNNING task không đồng thời nằm trong ready list;
- khi yield/time-slice hết, task RUNNING có thể được append lại cuối ready list cùng priority nếu vẫn runnable.

---

## 3. Preemption

Preemption có thể được request khi:

- SysTick hết time slice;
- higher-priority task trở thành READY;
- current task block;
- current task yield.

Context switch thực tế được deferred sang PendSV.

---

## 4. SysTick

SysTick duy trì kernel tick tại `ZRTOS_TICK_HZ`.

Tick handler phải ngắn và chỉ làm kernel work cần thiết.

Các trách nhiệm có thể gồm:

1. tăng tick counter modulo 32 bit;
2. xử lý deadline/delayed tasks;
3. đánh dấu task timeout;
4. request PendSV nếu cần reschedule.

---

## 5. Delay

`zrtos_delay(ticks)`:

- không busy-wait;
- chuyển current task sang BLOCKED;
- đăng ký wake deadline;
- trigger reschedule.

`zrtos_delay(0)` được định nghĩa trong API contract; không để behavior mơ hồ.

---

## 6. Tick wraparound

Deadline compare dùng phép toán wrap-safe.

Một contract phù hợp v1:

```c
(int32_t)(now - deadline) >= 0
```

Hệ quả: finite timeout không vượt quá `INT32_MAX` tick.

---

## 7. Idle task

- priority = 0;
- luôn runnable;
- không block;
- có thể dùng `__WFI()` nếu không phá debug/validation;
- là nguồn để ước lượng idle percentage nếu runtime stats được bật.
