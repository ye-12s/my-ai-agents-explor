---
name: embedded-logging
description: Use when implementing printf-style debugging in embedded systems, creating lightweight logging frameworks, or optimizing log output for resource-constrained devices
---

# Embedded Logging

## Overview

Lightweight logging for microcontrollers with configurable levels, output targets, and compile-time optimization.

## Quick Reference

| Level | Macro | Use Case |
|-------|-------|----------|
| ERROR | `LOGE()` | Critical failures, system halt |
| WARN  | `LOGW()` | Recoverable issues, attention needed |
| INFO  | `LOGI()` | Normal operation milestones |
| DEBUG | `LOGD()` | Development details |
| VERBOSE | `LOGV()` | Fine-grained tracing |

## Minimal Implementation

```c
// log.h
#pragma once
#include <stdio.h>

typedef enum {
    LOG_LEVEL_NONE = 0,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_WARN,
    LOG_LEVEL_INFO,
    LOG_LEVEL_DEBUG,
    LOG_LEVEL_VERBOSE
} log_level_t;

#ifndef LOG_LEVEL
#define LOG_LEVEL LOG_LEVEL_DEBUG
#endif

#define LOG_PRINT(level, fmt, ...) \
    printf("[%s] " fmt "\r\n", level, ##__VA_ARGS__)

#if LOG_LEVEL >= LOG_LEVEL_ERROR
#define LOGE(fmt, ...) LOG_PRINT("E", fmt, ##__VA_ARGS__)
#else
#define LOGE(fmt, ...)
#endif

#if LOG_LEVEL >= LOG_LEVEL_DEBUG
#define LOGD(fmt, ...) LOG_PRINT("D", fmt, ##__VA_ARGS__)
#else
#define LOGD(fmt, ...)
#endif
```

## Usage Examples

```c
#include "log.h"

void init_sensor(void) {
    LOGI("Initializing sensor...");
    
    if (!sensor_detect()) {
        LOGE("Sensor not found at address 0x%02X", SENSOR_ADDR);
        return;
    }
    
    uint8_t id = sensor_read_id();
    LOGD("Sensor ID: 0x%02X", id);
    LOGI("Sensor initialized successfully");
}
```

## Advanced Features

### Timestamp Support
```c
#include <stdint.h>

extern volatile uint32_t system_ticks;

#define LOG_PRINT(level, fmt, ...) \
    printf("[%10lu][%s] " fmt "\r\n", system_ticks, level, ##__VA_ARGS__)
```

### Module Prefix
```c
#define LOG_MODULE "I2C"
#define LOG_PRINT(level, fmt, ...) \
    printf("[%s][%s] " fmt "\r\n", LOG_MODULE, level, ##__VA_ARGS__)
```

### Conditional Compilation by Module
```c
// In config.h
#define LOG_ENABLE_I2C 1
#define LOG_ENABLE_SPI 0

// In module
#if LOG_ENABLE_I2C
#define I2C_LOGD(fmt, ...) LOGD(fmt, ##__VA_ARGS__)
#else
#define I2C_LOGD(fmt, ...)
#endif
```

## Output Targets

### UART Output (most common)
```c
int _write(int file, char *ptr, int len) {
    for (int i = 0; i < len; i++) {
        uart_send_byte(ptr[i]);
    }
    return len;
}
```

### ITM/SWO (ARM Cortex debug)
```c
#define ITM_PORT ((volatile uint32_t *)0xE0000000)

#define LOG_PRINT(level, fmt, ...) do { \
    char buf[128]; \
    snprintf(buf, sizeof(buf), "[%s] " fmt "\n", level, ##__VA_ARGS__); \
    for (char *p = buf; *p; p++) {
        ITM_SendChar(*p);
    } \
} while(0)
```

### RTT (J-Link)
```c
#include "SEGGER_RTT.h"
#define LOG_PRINT(level, fmt, ...) do { \
    char buf[128]; \
    snprintf(buf, sizeof(buf), "[%s] " fmt "\r\n", level, ##__VA_ARGS__); \
    SEGGER_RTT_WriteString(0, buf); \
} while(0)
```

## Optimization Tips

1. **Compile-time filtering**: Higher levels completely removed at compile time
2. **Buffer output**: Batch writes to reduce UART overhead
3. **Use `printf` sparingly**: Formatting is expensive on small MCUs
4. **Binary logging**: For high-frequency data, send raw bytes

## Common Mistakes

| Mistake | Impact | Solution |
|---------|--------|----------|
| Logging in ISR | System instability | Use ring buffer, defer to main loop |
| No rate limiting | UART flooding | Add counters, throttle logs |
| Dynamic memory in log | Heap fragmentation | Use static buffers only |
| Blocking UART calls | Real-time misses | Use DMA or ITM |

## Size Impact (STM32F4, -O2)

| Configuration | Flash | RAM |
|--------------|-------|-----|
| All levels enabled | ~4KB | 256B |
| ERROR only | ~1KB | 128B |
| All disabled | 0B | 0B |
