# Contributing to zRTOS

Cảm ơn bạn đã quan tâm đến **zRTOS**.

zRTOS là một RTOS kernel mang tính học tập và portfolio, được xây dựng từ đầu cho **ARM Cortex-M3**, với target đầu tiên là **STM32F103C8T6**.

Mục tiêu của project không phải là chạy theo số lượng feature, mà là giữ kernel nhỏ, dễ hiểu, có kiến trúc rõ ràng và có thể kiểm chứng được behavior.

---

## 1. Nguyên tắc chung

Mọi thay đổi nên tuân theo các nguyên tắc sau:

- Hiểu cơ chế trước khi thêm abstraction.
- Không sao chép implementation từ FreeRTOS hoặc RTOS khác.
- Kernel phải độc lập với peripheral STM32.
- `kernel/` không được phụ thuộc SPL.
- Code phụ thuộc Cortex-M3 phải nằm trong `port/cortex_m3/`.
- Code phụ thuộc board/peripheral phải nằm trong `bsp/`.
- `libraries/` chỉ chứa third-party code như CMSIS và STM32 SPL.
- ISR không được thực hiện blocking operation.
- Task chờ event phải block thay vì polling nếu kernel đã hỗ trợ primitive phù hợp.
- Mỗi feature mới phải đi kèm cách kiểm thử hoặc tiêu chí xác minh rõ ràng.
- Không đánh dấu feature là hoàn thành chỉ vì code build thành công.

Các invariant và contract hiện tại được mô tả trong thư mục [`docs/`](docs/).

---

## 2. Build system

zRTOS sử dụng:

- CMake
- Ninja
- `arm-none-eabi-gcc`

Workflow chuẩn:

```bash
cmake --preset debug
cmake --build --preset debug
```

Không thêm Makefile song song chỉ để gọi lại CMake/Ninja.

Không commit thư mục build hoặc artifact sinh ra trong quá trình build.

Ví dụ các file không nên được commit:

```text
build/
*.elf
*.hex
*.bin
*.map
```

---

## 3. Quy tắc kiến trúc

### `include/zrtos/`

Chỉ chứa **public API** và public types.

Application có thể include:

```c
#include "zrtos/zrtos.h"
#include "zrtos/zrtos_queue.h"
```

Application không nên include trực tiếp private header trong `kernel/` hoặc
implementation detail của `port/`.

### `kernel/`

Chứa logic RTOS không phụ thuộc STM32 peripheral:

- task management;
- scheduler;
- ready/wait lists;
- timing;
- blocking;
- semaphore;
- queue;
- mutex;
- diagnostics.

Không được gọi trực tiếp:

```text
GPIO_*
USART_*
ADC_*
DMA_*
RCC_*
```

hoặc API SPL tương đương.

### `port/cortex_m3/`

Chứa phần phụ thuộc kiến trúc CPU:

- MSP / PSP;
- SVC;
- PendSV;
- SysTick;
- context save / restore;
- interrupt masking;
- Cortex-M3-specific runtime support.

Scheduler policy nên nằm trong C/kernel. Assembly chỉ xử lý phần thực sự cần
thiết cho execution context.

### `bsp/`

BSP là lớp thích nghi giữa firmware/application và phần cứng STM32.

BSP có thể sử dụng STM32 SPL.

Ví dụ:

```text
Application
    |
    v
BSP API
    |
    v
STM32 SPL
    |
    v
STM32F103
```

### `libraries/`

Chứa third-party source.

Không xóa hoặc thay đổi license/header của CMSIS, STM32 SPL hoặc code từ vendor
khác nếu license của chúng yêu cầu giữ lại thông tin đó.

---

## 4. Coding style

Project sử dụng C và một lượng nhỏ ARM Assembly.

Ưu tiên:

- tên rõ nghĩa hơn tên ngắn;
- function nhỏ, có trách nhiệm cụ thể;
- hạn chế global state không cần thiết;
- không dùng magic number nếu có thể đặt macro/enum rõ nghĩa;
- critical section phải ngắn;
- invariant quan trọng nên có assert;
- không thêm abstraction chỉ để làm code trông "framework-like".

Naming convention chính:

```text
Public API      zrtos_*
Kernel internal zrtos_kernel_* / zrtos_scheduler_* / zrtos_list_*
Port            zrtos_port_*
BSP             bsp_*
Macro           ZRTOS_*
Type            zrtos_*_t
```

Ví dụ:

```c
zrtos_task_create_static();
zrtos_delay();
zrtos_queue_send();
zrtos_mutex_lock();

zrtos_port_request_context_switch();

bsp_uart_write();
```

Nếu repository có `.clang-format`, code C/C++ mới nên được format theo file đó.

---

## 5. Feature workflow

Một feature không được xem là hoàn thành chỉ vì đã compile.

Quy trình mong muốn:

```text
SPEC
  ↓
IMPLEMENT
  ↓
TEST
  ↓
TARGET VALIDATION
  ↓
PASS
```

Trước khi implement một subsystem mới:

1. Đọc phần tương ứng trong `ROADMAP.md`.
2. Đọc spec liên quan trong `docs/`.
3. Xác định invariant và API contract bị ảnh hưởng.
4. Implement theo scope nhỏ nhất cần thiết.
5. Thêm test/checkpoint.
6. Chạy regression cũ.
7. Cập nhật `docs/implementation_status.md`.

Nếu implementation buộc phải khác với spec, hãy cập nhật và giải thích thay đổi
trong spec trước khi coi feature là hoàn thành.

---

## 6. Testing

zRTOS phân biệt rõ:

- **host test**: kiểm tra logic portable;
- **cross-build**: chứng minh source compile/link cho Cortex-M3;
- **target test**: chứng minh behavior trên STM32F103 thật.

Một ELF build thành công không chứng minh context switch, interrupt hoặc timing
đang chạy đúng.

Các thay đổi liên quan tới những phần sau nên có target validation khi có thể:

- SVC / PendSV;
- scheduler/preemption;
- task blocking;
- semaphore/queue FromISR;
- timeout;
- priority inheritance;
- stack diagnostics;
- ADC/DMA/UART integration.

Checklist target nằm trong:

```text
docs/09_hardware_validation.md
```

---

## 7. Commit convention

Khuyến nghị dùng commit message ngắn, mô tả đúng phạm vi thay đổi.

Ví dụ:

```text
feat(kernel): add blocked task state
feat(sched): implement fixed-priority selection
feat(port): add PendSV context save restore
feat(ipc): add counting semaphore
feat(bsp): add USART1 support
test(kernel): add tick wraparound cases
fix(queue): prevent double wake on timeout race
docs: document scheduler invariants
build: add Ninja debug preset
refactor(kernel): split wait completion path
```

Tránh commit kiểu:

```text
update
fix stuff
done
final
final2
test
```

Một commit nên thể hiện một thay đổi kỹ thuật có thể hiểu và review độc lập.

---

## 8. Pull request / review checklist

Trước khi mở PR hoặc merge một thay đổi lớn, kiểm tra:

- [ ] Build với CMake + Ninja thành công.
- [ ] Không có warning mới.
- [ ] Không commit artifact hoặc thư mục `build/`.
- [ ] Không đưa dependency SPL vào `kernel/`.
- [ ] Public API không expose internal implementation không cần thiết.
- [ ] Kernel invariant liên quan vẫn được giữ.
- [ ] Test mới đã được thêm nếu feature cần.
- [ ] Regression test cũ vẫn pass.
- [ ] Hardware-dependent change được ghi rõ là `PENDING` nếu chưa test board.
- [ ] Documentation được cập nhật nếu contract/architecture thay đổi.
- [ ] `implementation_status.md` phản ánh đúng trạng thái thực tế.

---

## 9. Documentation

README root chỉ dùng để giới thiệu project ở mức tổng quan.

Tài liệu kỹ thuật nằm trong `docs/zRTOS_Building`.

Không nên đưa toàn bộ implementation detail vào README.

Các tài liệu thiết kế quan trọng gồm:

```text
docs/
├── 00_architecture.md
├── 01_kernel_invariants.md
├── 02_task_model.md
├── 03_context_switch.md
├── 04_scheduler.md
├── 05_ipc.md
├── 06_api_contract.md
├── 07_configuration.md
├── 08_testing.md
├── 09_hardware_validation.md
├── 10_known_limitations.md
└── implementation_status.md
```

Nếu thay đổi behavior đã được đặc tả, documentation tương ứng phải được cập nhật
cùng với source.

---

## 10. Scope

zRTOS v1 không hướng tới:

- production-grade RTOS;
- safety certification;
- SMP/multicore;
- MPU-based task isolation;
- dynamic task lifecycle phức tạp;
- hỗ trợ nhiều architecture ngay từ đầu.

Một feature ngoài scope chỉ nên được thêm khi kernel core hiện tại đã ổn định và
lợi ích của feature đủ rõ ràng.

---

## 11. Third-party code

zRTOS source do project phát triển được phát hành theo MIT License.

Code trong `libraries/` có thể sử dụng license riêng của ARM, STMicroelectronics
hoặc nhà cung cấp tương ứng.

Khi thêm third-party code:

- kiểm tra license trước;
- giữ nguyên copyright/license notice cần thiết;
- ghi rõ nguồn;
- không trình bày third-party code như code do zRTOS tự phát triển.

---

## 12. License

Bằng việc đóng góp code vào repository, bạn đồng ý rằng phần đóng góp của mình
có thể được phân phối theo license áp dụng cho zRTOS, trừ khi có thỏa thuận khác
được nêu rõ.

Xem [`LICENSE`](LICENSE) để biết chi tiết.
