.data
prompt:     .asciz "\nEnter angle in degrees: "
factor:     .word 293601              # (pi/180) * 2^24
scale:      .word 16777216            # 2^24 (dla konwersji)
to_sincos:  .word 10188013

atan_array: .word 13176794, 7778716, 4110059, 2086330, 1047213, 524117, 262122, 131069, 65535, 32767, 16383, 8191, 4095, 2047, 1023, 511, 255, 127, 63, 31, 15, 7, 3, 1, 0


.text
.globl main
main:
    # Wypisz prompt
    li a7, 4
    la a0, prompt
    ecall

    # Pobierz liczbę całkowitą (stopnie)
    li a7, 5
    ecall               # wynik w a0
    mv t0, a0           # t0 = degrees

    lw t1, factor       # t1 = przeskalowany pi/180 * 2^24

    mul t2, t0, t1      # t2 = degrees * factor (w fixed-point)
    mv a0, t2           # wynik do a0

    # Wypisz wynik
    li a7, 1
    ecall


    # Zakończ
    li a7, 10
    ecall