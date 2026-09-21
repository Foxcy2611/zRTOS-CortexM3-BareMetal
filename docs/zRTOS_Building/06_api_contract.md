# 06 — Public API Contract

Tài liệu này khóa behavior mà application nhìn thấy. Signature cụ thể có thể tinh chỉnh trong lúc thiết kế header, nhưng semantics không được để mơ hồ.

---

## 1. Status code

V1 nên dùng một enum thống nhất, ví dụ:

```c
typedef enum {
    ZRTOS_OK = 0,
    ZRTOS_TIMEOUT,
    ZRTOS_WOULD_BLOCK,
    ZRTOS_INVALID_ARG,
    ZRTOS_INVALID_STATE,
    ZRTOS_NOT_OWNER,
    ZRTOS_FULL,
    ZRTOS_EMPTY
} zrtos_status_t;
```

Không bắt buộc giữ đúng tên trên nếu implementation chọn cách khác, nhưng phải tránh mỗi subsystem invent một kiểu return riêng.

---

## 2. Timeout type

Định nghĩa logic:

```text
NO_WAIT       -> không block
finite ticks  -> block tối đa N ticks
WAIT_FOREVER  -> không có deadline
```

`WAIT_FOREVER` không được encode bằng một finite deadline có thể wrap nhầm.

---

## 3. Task API

### `zrtos_init()`

- gọi một lần trước tạo/start task;
- reset kernel internal state;
- không start scheduler.

### `zrtos_task_create_static(...)`

- validate pointer/stack/priority;
- build initial context;
- task mới vào READY;
- không cấp phát heap.

### `zrtos_start()`

- yêu cầu có ít nhất idle + runnable task hợp lệ;
- chọn first task;
- không return khi thành công.

### `zrtos_yield()`

- chỉ hợp lệ trong task context;
- current task vẫn READY;
- request reschedule.

### `zrtos_delay(ticks)`

Đề xuất contract v1:

- `ticks == 0` tương đương yield;
- `ticks > 0` block current task đến deadline;
- không callable từ ISR.

---

## 4. Semaphore API

### `zrtos_sem_take(sem, timeout)`

- token có sẵn -> `ZRTOS_OK`;
- không có token + `NO_WAIT` -> `ZRTOS_WOULD_BLOCK`;
- finite wait hết hạn -> `ZRTOS_TIMEOUT`;
- không callable từ ISR.

### `zrtos_sem_give(sem)`

- nếu có waiter, wake một waiter theo policy;
- nếu không có waiter, tăng count không vượt `max_count`;
- behavior khi đã max phải được định nghĩa nhất quán, ví dụ `ZRTOS_FULL`.

### `zrtos_sem_give_from_isr(...)`

- không block;
- không gọi task-only code;
- có thể trả flag `higher_priority_woken` hoặc tự request PendSV theo policy đã chọn.

---

## 5. Queue API

### `zrtos_queue_send(queue, item, timeout)`

- success -> `ZRTOS_OK`;
- full + `NO_WAIT` -> `ZRTOS_FULL` hoặc `ZRTOS_WOULD_BLOCK` theo convention đã khóa;
- finite wait hết -> `ZRTOS_TIMEOUT`;
- nếu blocked-send giữ source pointer, source memory phải còn valid tới khi API return.

### `zrtos_queue_receive(queue, out, timeout)`

- item có sẵn -> copy FIFO và `ZRTOS_OK`;
- empty + `NO_WAIT` -> `ZRTOS_EMPTY` hoặc `ZRTOS_WOULD_BLOCK` theo convention đã khóa;
- finite wait hết -> `ZRTOS_TIMEOUT`.

### `FromISR`

ISR variant:

- luôn non-blocking;
- không dùng finite timeout;
- không gọi API có thể sleep/block.

---

## 6. Mutex API

### `zrtos_mutex_lock(mutex, timeout)`

- free -> current task trở thành owner;
- owner khác -> có thể block;
- recursive lock không hỗ trợ v1;
- ISR không được lock mutex.

### `zrtos_mutex_unlock(mutex)`

- chỉ owner được unlock;
- non-owner -> `ZRTOS_NOT_OWNER`;
- unlock có thể wake waiter;
- sau unlock phải recompute effective priority.

---

## 7. ISR rules

ISR không được gọi:

- delay;
- yield kiểu task-context nếu implementation không hỗ trợ;
- semaphore take;
- queue blocking send/receive;
- mutex lock/unlock.

ISR chỉ dùng API có hậu tố hoặc contract `FromISR`.

---

## 8. Error policy

Invalid public argument trả status phù hợp nếu có thể recovery.

Kernel invariant violation nội bộ dùng assert/fault path thay vì âm thầm tiếp tục.
