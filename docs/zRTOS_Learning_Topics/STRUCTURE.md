# Cấu trúc bộ tài liệu

```text
zRTOS_Learning_Topics/
├── README.md
├── phase-01-cortex-m3-foundations/
│   ├── README.md
│   ├── 01-exception-model-msp-psp.md
│   ├── 02-svc-exc-return.md
│   ├── 03-pendsv-aapcs-context.md
├── phase-02-task-model/
│   ├── README.md
│   ├── 01-task-abstraction-tcb.md
│   ├── 02-task-states-lifecycle.md
│   ├── 03-initial-task-stack.md
├── phase-03-first-task-svc/
│   ├── README.md
│   ├── 01-kernel-bootstrap.md
│   ├── 02-svc-first-task-flow.md
│   ├── 03-task-entry-invariants.md
├── phase-04-context-switch-cooperative/
│   ├── README.md
│   ├── 01-pendsv-save-restore.md
│   ├── 02-tcb-sp-contract.md
│   ├── 03-cooperative-scheduler-yield.md
├── phase-05-preemptive-scheduler/
│   ├── README.md
│   ├── 01-systick-preemption.md
│   ├── 02-fixed-priority-round-robin.md
│   ├── 03-idle-starvation-invariants.md
├── phase-06-lists-blocking-delay/
│   ├── README.md
│   ├── 01-intrusive-list-ready-lists.md
│   ├── 02-blocked-state-delay.md
│   ├── 03-tick-wraparound-delayed-structures.md
├── phase-07-critical-semaphore/
│   ├── README.md
│   ├── 01-race-critical-sections.md
│   ├── 02-semaphore-wait-lists.md
│   ├── 03-fromisr-basepri.md
├── phase-08-queue-isr/
│   ├── README.md
│   ├── 01-static-ring-buffer.md
│   ├── 02-blocked-senders-receivers.md
│   ├── 03-isr-queue-producer-consumer.md
├── phase-09-mutex-timeout/
│   ├── README.md
│   ├── 01-mutex-priority-inversion.md
│   ├── 02-priority-inheritance.md
│   ├── 03-finite-timeout-races.md
├── phase-10-diagnostics-testing/
│   ├── README.md
│   ├── 01-kernel-assert-invariants.md
│   ├── 02-stack-runtime-diagnostics.md
│   ├── 03-regression-stress-limitations.md
├── phase-11-real-firmware/
│   ├── README.md
│   ├── 01-task-decomposition-priorities.md
│   ├── 02-uart-adc-dma-integration.md
│   ├── 03-shared-peripherals-full-demo.md
├── phase-12-portfolio-release/
│   ├── README.md
│   ├── 01-repo-docs-reproducibility.md
│   ├── 02-git-release-cv.md
│   ├── 03-v1-scope-future.md
└── STRUCTURE.md
```
