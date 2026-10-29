; ==============================================================================
; Proyecto: LowMonitor - Diagnóstico y monitorización de hardware
; Módulos 4 y 5: Monitor de rendimiento del CPU y Gestión jerárquica de memoria
; Arquitectura: x86-64 nativo (Linux ELF64) - Ensamblador: NASM
; ==============================================================================

section .data
    ; --- Mensajes del Módulo 4 ---
    hdr_mod4        db 10, "=== MODULO 4: MONITOR DE RENDIMIENTO DEL CPU ===", 10
    len_hdr_mod4    equ $ - hdr_mod4

    msg_ciclos      db "Ciclos totales medidos: "
    len_ciclos      equ $ - msg_ciclos

    msg_freq        db "Frecuencia:             3.4 GHz", 10
    len_freq        equ $ - msg_freq

    msg_cpi         db "CPI promedio:           "
    len_cpi         equ $ - msg_cpi

    msg_ipc         db "IPC:                    "
    len_ipc         equ $ - msg_ipc

    msg_tput        db "Throughput:             "
    len_tput        equ $ - msg_tput

    msg_gflops      db " GFLOPS", 10
    len_gflops      equ $ - msg_gflops

    ; --- Mensajes del Módulo 5 ---
    hdr_mod5        db 10, "=== MODULO 5: GESTION JERARQUICA DE MEMORIA ===", 10
    len_hdr_mod5    equ $ - hdr_mod5

    msg_reg         db "Registros:  "
    len_reg         equ $ - msg_reg
    suf_reg         db " ciclo", 10
    len_suf_reg     equ $ - suf_reg

    msg_l1          db "L1 cache:   "
    len_l1          equ $ - msg_l1
    suf_l1          db " ciclos  (32KB)", 10
    len_suf_l1      equ $ - suf_l1

    msg_l2          db "L2 cache:   "
    len_l2          equ $ - msg_l2
    suf_l2          db " ciclos  (256KB)", 10
    len_suf_l2      equ $ - suf_l2

    msg_l3          db "L3 cache:   "
    len_l3          equ $ - msg_l3
    suf_l3          db " ciclos  (8MB)", 10
    len_suf_l3      equ $ - suf_l3

    msg_ram         db "RAM:        "
    len_ram         equ $ - msg_ram
    suf_ram         db " ciclos (32GB)", 10, 10
    len_suf_ram     equ $ - suf_ram

    punto           db "."
    salto_linea     db 10

    ; Vectores alineados para operaciones SIMD
    align 16
    vec_a           dd 1.5, 2.5, 3.5, 4.5
    vec_b           dd 2.0, 2.0, 2.0, 2.0

section .bss
    ; Variables reservadas: Buffer de 8 MB para pruebas de caché y RAM
    alignb 64
    mem_buffer      resb 8388608
    num_buffer      resb 32


section .text
    global _start
    global modulo4_rendimiento
    global modulo5_memoria

_start:
    ; Punto de entrada principal
    call modulo4_rendimiento
    call modulo5_memoria

    ; Rutina de salida mediante SYSCALL 64-bit (sys_exit = 60)
    mov rax, 60
    xor rdi, rdi
    syscall

; ==============================================================================
; MÓDULO 4: MONITOR DE RENDIMIENTO DEL CPU
; ==============================================================================
modulo4_rendimiento:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rsi, hdr_mod4
    mov rdx, len_hdr_mod4
    call print_string

    movaps xmm0, [rel vec_a]
    movaps xmm1, [rel vec_b]

    ; 100,000 iteraciones x 10 instrucciones = 1,000,000 de instrucciones
    mov rcx, 100000
    mov r14, 1000000

    ; --- Medición inicial del Timestamp Counter ---
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.loop_bench_cpu:
    addps xmm0, xmm1             ; 1
    mulps xmm0, xmm1             ; 2
    add r8, 1                    ; 3
    add r9, 2                    ; 4
    add r10, 3                   ; 5
    xor r8, r9                   ; 6
    addps xmm0, xmm1             ; 7
    mulps xmm0, xmm1             ; 8
    dec rcx                      ; 9
    jnz .loop_bench_cpu          ; 10

    ; --- Medición final del Timestamp Counter ---
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    jnz .ciclos_ok
    mov rax, 1                   ; Handler de error contra división por cero
.ciclos_ok:
    mov r13, rax                 ; r13 = Ciclos totales

    ; Mostrar Frecuencia
    mov rsi, msg_freq
    mov rdx, len_freq
    call print_string

    ; Mostrar Ciclos totales
    mov rsi, msg_ciclos
    mov rdx, len_ciclos
    call print_string
    mov rax, r13
    call print_uint64
    mov rsi, salto_linea
    mov rdx, 1
    call print_string

    ; Calcular y mostrar CPI promedio = (Ciclos * 100) / Instrucciones
    mov rsi, msg_cpi
    mov rdx, len_cpi
    call print_string
    mov rax, r13
    imul rax, 100
    xor rdx, rdx
    div r14
    call print_fixed2
    mov rsi, salto_linea
    mov rdx, 1
    call print_string

    ; Calcular y mostrar IPC = (Instrucciones * 100) / Ciclos
    mov rsi, msg_ipc
    mov rdx, len_ipc
    call print_string
    mov rax, r14
    imul rax, 100
    xor rdx, rdx
    div r13
    call print_fixed2
    mov rsi, salto_linea
    mov rdx, 1
    call print_string

    ; Calcular y mostrar Throughput en GFLOPS
    mov rsi, msg_tput
    mov rdx, len_tput
    call print_string
    mov rax, 1600000
    imul rax, 340
    xor rdx, rdx
    div r13
    call print_fixed2
    mov rsi, msg_gflops
    mov rdx, len_gflops
    call print_string

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ==============================================================================
; MÓDULO 5: GESTIÓN JERÁRQUICA DE MEMORIA
; ==============================================================================
modulo5_memoria:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rsi, hdr_mod5
    mov rdx, len_hdr_mod5
    call print_string

    lea rbx, [rel mem_buffer]

    ; Inicializar buffer con Non-Temporal Stores (movnti)
    xor rcx, rcx
.init_mem:
    lea rax, [rcx + 64]
    and rax, 8388607
    movnti [rbx + rcx], rax
    add rcx, 64
    cmp rcx, 8388608
    jl .init_mem
    sfence

    ; --- 1. Medición de REGISTROS ---
    mov rcx, 128
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.loop_reg:
    add r8, 1
    add r8, 1
    add r8, 1
    add r8, 1
    add r8, 1
    add r8, 1
    add r8, 1
    add r8, 1
    dec rcx
    jnz .loop_reg

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    shr rax, 10
    jnz .reg_ok
    mov rax, 1
.reg_ok:
    mov r13, rax

    mov rsi, msg_reg
    mov rdx, len_reg
    call print_string
    mov rax, r13
    call print_uint64
    mov rsi, suf_reg
    mov rdx, len_suf_reg
    call print_string

    ; --- 2. Medición de CACHÉ L1 (32 KB) ---
    xor rcx, rcx
.warm_l1:
    prefetcht0 [rbx + rcx]
    mov rax, [rbx + rcx]
    add rcx, 64
    cmp rcx, 32768
    jl .warm_l1

    xor rdi, rdi
    mov rcx, 1024
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.loop_l1:
    mov rdi, [rbx + rdi]
    and rdi, 32767
    dec rcx
    jnz .loop_l1

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    shr rax, 10
    mov r13, rax

    mov rsi, msg_l1
    mov rdx, len_l1
    call print_string
    mov rax, r13
    call print_uint64
    mov rsi, suf_l1
    mov rdx, len_suf_l1
    call print_string

    ; --- 3. Medición de CACHÉ L2 (256 KB) ---
    xor rcx, rcx
.warm_l2:
    mov rax, [rbx + rcx]
    add rcx, 64
    cmp rcx, 262144
    jl .warm_l2

    xor rdi, rdi
    mov rcx, 4096
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.loop_l2:
    mov rdi, [rbx + rdi]
    xor rdi, 4096
    and rdi, 262143
    dec rcx
    jnz .loop_l2

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    shr rax, 12
    mov r13, rax

    mov rsi, msg_l2
    mov rdx, len_l2
    call print_string
    mov rax, r13
    call print_uint64
    mov rsi, suf_l2
    mov rdx, len_suf_l2
    call print_string

    ; --- 4. Medición de CACHÉ L3 (8 MB) ---
    xor rdi, rdi
    mov rcx, 16384
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.loop_l3:
    mov rdi, [rbx + rdi]
    add rdi, 65472
    and rdi, 8388544
    dec rcx
    jnz .loop_l3

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    shr rax, 14
    mov r13, rax

    mov rsi, msg_l3
    mov rdx, len_l3
    call print_string
    mov rax, r13
    call print_uint64
    mov rsi, suf_l3
    mov rdx, len_suf_l3
    call print_string

    ; --- 5. Medición de RAM PRINCIPAL ---
    xor r14, r14
    mov rcx, 256
    xor rdi, rdi

.loop_ram:
    clflush [rbx + rdi]
    mfence
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

    mov r8, [rbx + rdi]
    lfence

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    add r14, rax

    add rdi, 4096
    and rdi, 8388607
    dec rcx
    jnz .loop_ram

    mov rax, r14
    shr rax, 8
    mov r13, rax

    mov rsi, msg_ram
    mov rdx, len_ram
    call print_string
    mov rax, r13
    call print_uint64
    mov rsi, suf_ram
    mov rdx, len_suf_ram
    call print_string

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ==============================================================================
; FUNCIONES AUXILIARES DE SALIDA (SYSCALL 64-BIT)
; ==============================================================================
print_string:
    push rax
    push rdi
    push rcx
    push r11
    mov rax, 1                   ; sys_write
    mov rdi, 1                   ; stdout
    syscall
    pop r11
    pop rcx
    pop rdi
    pop rax
    ret

print_uint64:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rcx, 10
    lea rsi, [rel num_buffer + 31]
    mov byte [rsi], 0

.conv_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .conv_loop

    lea rdx, [rel num_buffer + 31]
    sub rdx, rsi
    call print_string

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

print_fixed2:
    push rax
    push rbx
    push rdx
    push rsi

    xor rdx, rdx
    mov rbx, 100
    div rbx
    push rdx

    call print_uint64

    mov rsi, punto
    mov rdx, 1
    call print_string

    pop rax
    cmp rax, 10
    jge .print_dec
    push rax
    xor rax, rax
    call print_uint64
    pop rax
.print_dec:
    call print_uint64

    pop rsi
    pop rdx
    pop rbx
    pop rax
    ret
