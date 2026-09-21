# 02 — Mô hình Task

## 1. TCB

`zrtos_tcb_t` tối thiểu cần chứa:

- saved stack pointer;
- stack base / stack size;
- task entry;
- task argument;
- base priority;
- effective priority;
- task state;
- ready/event/delayed list metadata cần thiết;
- wait result / timeout metadata;
- diagnostic counters.

Nếu assembly port truy cập trực tiếp field `sp`, layout của field này phải được khóa bằng `_Static_assert` hoặc cơ chế compile-time tương đương.

---

## 2. Task states

```text
UNUSED --create--> READY --schedule--> RUNNING
RUNNING --yield/tick--> READY
RUNNING --delay/event--> BLOCKED
BLOCKED --event/timeout--> READY
```

Không thêm state mới nếu chưa có use case rõ ràng trong v1.

---

## 3. Task entry

Public task entry contract:

```c
void task_entry(void *arg);
```

Task không được return. Initial LR của task phải trỏ tới một trap function, ví dụ:

```c
void zrtos_task_exit_error(void);
```

---

## 4. Static task creation

V1 không cấp phát heap cho task.

Application cung cấp:

- TCB storage;
- stack storage;
- task function;
- argument;
- priority.

Ví dụ định hướng API:

```c
zrtos_status_t zrtos_task_create_static(
    zrtos_tcb_t *tcb,
    zrtos_task_fn_t entry,
    void *arg,
    uint32_t *stack,
    size_t stack_words,
    zrtos_priority_t priority
);
```

---

## 5. Initial stack

Stack là full-descending.

Initial context gồm hai phần logic:

```text
software frame: R4-R11
hardware frame: R0-R3, R12, LR, PC, xPSR
```

Yêu cầu:

- stack top align đúng;
- `xPSR.T = 1`;
- `PC = task_entry`;
- `R0 = argument`;
- `LR = task_return_trap`.

---

## 6. Stack diagnostics

Nếu bật diagnostics:

- fill unused stack bằng pattern cố định;
- đặt canary/guard word;
- cung cấp API high-watermark;
- kiểm tra saved SP range/alignment ở các checkpoint phù hợp.

Diagnostics không thay thế MPU hoặc memory protection.
