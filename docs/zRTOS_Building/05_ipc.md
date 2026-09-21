# 05 — IPC, Synchronization và Timeout

## 1. Waiter ordering

Mặc định waiter được chọn theo:

1. effective priority cao hơn trước;
2. FIFO khi cùng priority.

Nếu subsystem nào dùng policy khác, phải ghi rõ.

---

## 2. Semaphore

Counting semaphore có:

- `count`;
- `max_count`;
- wait list.

Behavior:

- take fast-path nếu `count > 0`;
- nếu không có token, task có thể block theo timeout;
- give ưu tiên wake waiter thay vì tăng count nếu đang có waiter;
- `give_from_isr()` không block;
- nếu wake task cao hơn current task, request PendSV.

---

## 3. Queue

Queue là static ring buffer do caller cấp storage.

Metadata tối thiểu:

- buffer;
- item size;
- capacity;
- read index;
- write index;
- count;
- receiver wait list;
- sender wait list nếu blocked-send được hỗ trợ.

V1 có thể implement theo từng mức:

1. non-blocking send/receive;
2. blocked receiver;
3. blocked sender;
4. ISR send;
5. direct handoff optimization nếu cần.

Spec cuối cùng phải bảo đảm FIFO và không mất/reorder item.

Nếu blocked sender giữ con trỏ tới source buffer, API contract phải ghi rõ lifetime requirement.

---

## 4. Mutex

Mutex khác semaphore ở ownership.

V1 contract:

- non-recursive;
- một owner;
- non-owner unlock bị từ chối;
- có waiter list;
- hỗ trợ finite timeout;
- hỗ trợ priority inheritance.

---

## 5. Priority inheritance

TCB có:

- `base_priority`;
- `effective_priority`.

Khi high-priority waiter chờ mutex do low-priority task giữ:

- owner được boost effective priority;
- nếu owner đang chờ mutex khác, inheritance có thể truyền theo chain trong giới hạn v1;
- sau unlock/timeout, effective priority được tính lại từ base priority và waiter cao nhất của các mutex còn giữ.

Cycle/deadlock prevention không thuộc v1; chỉ cần detect bất thường nếu chain traversal vượt số task hợp lệ.

---

## 6. Finite timeout

Blocking API hỗ trợ ba mode logic:

- `NO_WAIT`;
- finite number of ticks;
- `WAIT_FOREVER`.

Một timed wait có thể được hoàn tất bởi:

- event;
- timeout.

Chỉ một phía được quyền hoàn tất wait.

---

## 7. Event-vs-timeout race

Design yêu cầu exactly-once completion.

Một cách được khuyến nghị:

- mỗi task wait giữ wait-state metadata;
- event completion và timeout completion đều đi qua helper chung;
- helper chạy trong critical section;
- winner gỡ task khỏi mọi list liên quan, ghi result, đưa task READY;
- loser thấy wait đã completed và không wake lại.

Đây là invariant quan trọng cần test bằng interleaving chủ động trên target.
