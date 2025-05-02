.data
prompt:     .asciz "\nEnter angle in degrees: "   # komunikat do użytkownika
factor:     .word 1144                            # (pi/180) * 2^16 - przelicznik stopni na radiany w formacie fixed-point
scale:      .word 65536                           # 2^16 (faktyczna skala do normalizacji wyniku)
to_sincos:  .word 39797                           # początkowa wartość cos(x) = 1.0 w formacie fixed-point
sin_x:      .asciz "  |  sin(x) = "               # etykieta dla sin(x)
cos_x:      .asciz "cos(x) = "                    # etykieta dla cos(x)
atan_array: .word 51472, 30386, 16055, 8150, 4091, 2047, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1
            # tablica wartości atan(2^-i) w formacie fixed-point (16 wartości)

.text
.globl main


get_angle:
    # --- Wczytaj kąt od użytkownika ---
    li a7, 4
    la a0, prompt
    ecall                    # syscall: wypisz tekst

    li a7, 5
    ecall                    # syscall: pobierz liczbę całkowitą
    mv t0, a0                # zapisz podany kąt w t0
    
    li a0, 90
    jal angle_above

        
main:
    # --- Konwersja kąta ze stopni na radiany ---
    lw t1, factor            # załaduj przelicznik
    mul t2, t0, t1           # t2 = degrees * (pi/180) * 2^24
    mv a0, t2                # a0 = radiany w formacie fixed-point

    # --- Inicjalizacja zmiennych dla algorytmu CORDIC ---
    la t0, atan_array        # t0 = adres tablicy atan
    li t1, 0                 # t1 = indeks i = 0
    mv t2, a0                # t2 = alpha (docelowy kąt)
    li t3, 17                # t3 = liczba iteracji = 16
    li s2, 0                 # s2 = theta = 0 (aktualny kąt)

    lw s3, to_sincos         # s3 = początkowe x = 1 (fixed-point)
    li s4, 0                 # s4 = początkowe y = 0

loop:
    # --- Sprawdzenie zakończenia iteracji ---
    beq t1, t3, calculate_sincos         # jeśli i == 16, zakończ algorytm

    # --- Pobierz atan(2^-i) ---
    slli t4, t1, 2           # t4 = i * 4 (przesunięcie bajtowe)
    add t5, t0, t4           # t5 = adres atan_array[i]
    lw t6, 0(t5)             # t6 = atan(2^-i) (fixed-point)

    # --- Przygotuj indeks do przesunięć ---
    addi t1, t1, 1           # zwiększ indeks i
    addi a6, t1, -1          # a6 = i - 1 (potrzebne do obliczeń)

    # --- Porównaj theta z alpha ---
    blt s2, t2, signum       # jeśli theta < alpha, sigma = +1 (idź do signum)

    # --- Obliczenia dla sigma = -1 ---
    sub s2, s2, t6           # theta = theta - atan(2^-i)

    # x' = x + (y >> i)
    sra s5, s4, a6           # s5 = y >> (i-1)
    add s5, s3, s5
    # y' = y - (x >> i)
    sra s6, s3, a6
    sub s4, s4, s6

    mv s3, s5                # zaktualizuj x

    j loop                   # przejdź do następnej iteracji

signum:
    # --- Obliczenia dla sigma = +1 ---
    add s2, s2, t6           # theta = theta + atan(2^-i)

    # x' = x - (y >> i)
    sra s5, s4, a6
    sub s5, s3, s5
    # y' = y + (x >> i)
    sra s6, s3, a6
    add s4, s4, s6

    mv s3, s5                # zaktualizuj x

    j loop                   # przejdź do następnej iteracji
    

calculate_sincos:
    # --- Przelicz wyniki na wartości zmiennoprzecinkowe ---
    fcvt.s.w fa3, s3         # konwersja x na float
    fcvt.s.w fa4, s4         # konwersja y na float

    lw a0, scale             # załaduj skalę
    fcvt.s.w fa1, a0         # konwersja skali na float
    
    fdiv.s fa2, fa4, fa1     # normalizacja sin(x)
    fdiv.s fa0, fa3, fa1     # normalizacja cos(x)
    
    j choose_part

choose_part:
    # -- Określ ćwiartkę kąta na podstawie s0 % 4 --
    li a0, 4
    rem a0, s0, a0           # a0 = s0 % 4

    beqz a0, part_1          # jeśli a0 == 0 → I ćwiartka (0°–90°)

    li a0, 4
    rem a0, s0, a0
    li a1, 1
    beq a0, a1, part_2       # jeśli a0 == 1 → II ćwiartka (90°–180°)

    li a0, 4
    rem a0, s0, a0
    li a1, 2
    beq a0, a1, part_3       # jeśli a0 == 2 → III ćwiartka (180°–270°)

    li a0, 4
    rem a0, s0, a0
    li a1, 3
    beq a0, a1, part_4       # jeśli a0 == 3 → IV ćwiartka (270°–360°)

part_1:
    # --- I ćwiartka: cos(+) i sin(+) ---
    # Wydrukuj tekst "cos(x)"
    li a7, 4
    la a0, cos_x
    ecall

    # Wydrukuj wartość cos(x) (już w fa0)
    li a7, 2                 
    ecall

    # Wydrukuj tekst "sin(x)"
    li a7, 4
    la a0, sin_x
    ecall

    # Przenieś wartość sin(x) z fa2 do fa0 i wydrukuj
    fmv.s fa0, fa2    
    li a7, 2               
    ecall

    # Zakończ program
    li a7, 10
    ecall

part_2:
    # --- II ćwiartka: cos(-), sin(+) ---
    fneg.s fa2, fa2          # odwróć znak sin(x) → sin = -sin

    # Zamień miejscami fa0 (cos) i fa2 (sin)
    fmv.s fa3, fa0
    fmv.s fa0, fa2
    fmv.s fa2, fa3

    j part_1                 # przejdź do drukowania

part_3:
    # --- III ćwiartka: cos(-), sin(-) ---
    fneg.s fa2, fa2          # sin = -sin
    fneg.s fa0, fa0          # cos = -cos

    j part_1                 # przejdź do drukowania

part_4:
    # --- IV ćwiartka: cos(+), sin(-) ---
    fneg.s fa0, fa0          # cos = -cos

    # Zamień miejscami fa0 i fa2 (cos ↔ sin)
    fmv.s fa3, fa0
    fmv.s fa0, fa2
    fmv.s fa2, fa3

    j part_1                 # przejdź do drukowania 
    

angle_above:
    beq t0, a0, special_angles  # jeśli t0 == a0 (czyli 90), przejdź do specjalnych przypadków
    bltz t0, angle_below        # jeśli t0 < 0, przejdź do normalizacji w dół

    blt t0, a0, main            # jeśli t0 < 90, to kąt jest już w zakresie [0, 90), przejdź do głównego algorytmu

    # Jeśli t0 >= 90, wykonujemy normalizację w górę
    addi t0, t0, -90            # odejmij 90 stopni
    addi s0, s0, 1              # zwiększ licznik ćwiartek (s0 += 1)

    bge t0, a0, angle_above     # jeśli t0 >= 90, kontynuuj pętlę normalizacji

    jalr zero, 0(ra)            # return (powrót z procedury normalizującej)

angle_below:
    # --- Normalizacja kąta ujemnego ---
    li a1, 360                  # a1 = 360 (pełen obrót)
    neg t0, t0                  # t0 = -t0 (zamiana na dodatni, np. -270 → 270)
    div a2, t0, a1              # a2 = t0 / 360 (ile pełnych obrotów mieści się w kącie)
    addi a2, a2, 1              # zaokrąglamy w górę (dodajemy 1)
    mul a1, a1, a2              # a1 = 360 * a2 (całkowity zakres do dodania)
    neg t0, t0                  # przywracamy t0 do wartości ujemnej
    add t0, t0, a1              # dodajemy 360 * a2, aby przenieść kąt do zakresu dodatniego
    li s1, 1                    # ustaw s1 = 1 (flaga: oryginalny kąt był ujemny)
    j angle_above               # przejdź do normalizacji w górę

special_angles:
    # --- Obsługa kątów specjalnych: 90, 180, 270, 360 ---
    li a0, 0                    # a0 = 0 → wartość cos(x) = 0
    li a1, 1                    # a1 = 1 → wartość sin(x) = 1
    fcvt.s.w fa0, a0           # fa0 = float(0) → cos(x)
    fcvt.s.w fa2, a1           # fa2 = float(1) → sin(x)
    j choose_part              # przejdź do wyboru ćwiartki (uwzględnia s0 i s1)
