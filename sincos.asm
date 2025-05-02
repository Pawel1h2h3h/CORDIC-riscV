.data
prompt:     .asciz "\nEnter angle in degrees: "   # komunikat do użytkownika
factor:     .word 1144                            # (pi/180) * 2^24 - przelicznik stopni na radiany w formacie fixed-point
scale:      .word 65536                           # 2^16 (faktyczna skala do normalizacji wyniku)
to_sincos:  .word 39797                           # początkowa wartość cos(x) = 1.0 w formacie fixed-point
just_enter: .asciz "\n\n"                         # pusty wiersz (formatowanie)
y:          .asciz "   y = "                      # etykieta dla y
x:          .asciz "x = "                         # etykieta dla x
sin_x:      .asciz "  |  sin(x) = "               # etykieta dla sin(x)
cos_x:      .asciz "cos(x) = "                    # etykieta dla cos(x)
ez:         .asciz ". "                           # separator
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

    lw s3, to_sincos         # s3 = początkowe cos(x) = 1.0 (fixed-point)
    li s4, 0                 # s4 = początkowe sin(x) = 0.0

loop:
    # --- Sprawdzenie zakończenia iteracji ---
    beq t1, t3, done_1         # jeśli i == 16, zakończ algorytm

    # --- Pobierz atan(2^-i) ---
    slli t4, t1, 2           # t4 = i * 4 (przesunięcie bajtowe)
    add t5, t0, t4           # t5 = adres atan_array[i]
    lw t6, 0(t5)             # t6 = atan(2^-i) (fixed-point)

    # --- Przygotuj indeks do przesunięć ---
    addi t1, t1, 1           # zwiększ indeks i
    addi a6, t1, -1          # a6 = i - 1 (potrzebne do obliczeń)

    # --- Debug: Wypisz aktualne wartości ---
    #jal ra, print_xy         # wywołaj pomocniczą funkcję wypisywania

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

done_1:
	
    li a0, 4
    rem a0, s0, a0
    li a1, 1
    beq a0, a1, done_2
  
    li a0, 4
    rem a0, s0, a0
    li a1, 2
    beq a0, a1, done_3
    
    li a0, 4
    rem a0, s0, a0
    li a1, 3
    beq a0, a1, done_4
    
    # --- Przelicz wyniki na wartości zmiennoprzecinkowe ---
    fcvt.s.w fa3, s3         # konwersja x na float
    fcvt.s.w fa4, s4         # konwersja y na float

    lw a0, scale             # załaduj skalę
    fcvt.s.w fa1, a0         # konwersja skali na float

    # --- Wydrukuj cos(x) ---
    fdiv.s fa0, fa3, fa1     # normalizacja cos(x)
    li a7, 4
    la a0, cos_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall

    # --- Wydrukuj sin(x) ---
    fdiv.s fa0, fa4, fa1     # normalizacja sin(x)
    li a7, 4
    la a0, sin_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall

    # --- Zakończ program ---
    li a7, 10
    ecall
    
done_2:
    # --- Przelicz wyniki na wartości zmiennoprzecinkowe ---
    fcvt.s.w fa3, s3         # konwersja x na float
    fcvt.s.w fa4, s4         # konwersja y na float

    lw a0, scale             # załaduj skalę
    fcvt.s.w fa1, a0         # konwersja skali na float
    
    # --- Wydrukuj sin(x) ---
    fdiv.s fa0, fa4, fa1     # normalizacja sin(x)
    fneg.s fa0, fa0
    
    li a7, 4
    la a0, cos_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall
    # --- Wydrukuj cos(x) ---
    fdiv.s fa0, fa3, fa1     # normalizacja cos(x) 
    li a7, 4
    la a0, sin_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall

    # --- Zakończ program ---
    li a7, 10
    ecall

done_3:
    # --- Przelicz wyniki na wartości zmiennoprzecinkowe ---
    fcvt.s.w fa3, s3         # konwersja x na float
    fcvt.s.w fa4, s4         # konwersja y na float

    lw a0, scale             # załaduj skalę
    fcvt.s.w fa1, a0         # konwersja skali na float

    # --- Wydrukuj cos(x) ---
    fdiv.s fa0, fa3, fa1     # normalizacja cos(x)
    fneg.s fa0, fa0
    li a7, 4
    la a0, cos_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall

    # --- Wydrukuj sin(x) ---
    fdiv.s fa0, fa4, fa1     # normalizacja sin(x)
    fneg.s fa0, fa0
    li a7, 4
    la a0, sin_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall

    # --- Zakończ program ---
    li a7, 10
    ecall


done_4:
    # --- Przelicz wyniki na wartości zmiennoprzecinkowe ---
    fcvt.s.w fa3, s3         # konwersja x na float
    fcvt.s.w fa4, s4         # konwersja y na float

    lw a0, scale             # załaduj skalę
    fcvt.s.w fa1, a0         # konwersja skali na float
    
    # --- Wydrukuj sin(x) ---
    fdiv.s fa0, fa4, fa1     # normalizacja sin(x)   
    li a7, 4
    la a0, cos_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall
    # --- Wydrukuj cos(x) ---
    fdiv.s fa0, fa3, fa1     # normalizacja cos(x) 
    fneg.s fa0, fa0
    li a7, 4
    la a0, sin_x
    ecall

    li a7, 2                 # syscall: wydrukuj float
    ecall

    # --- Zakończ program ---
    li a7, 10
    ecall
    
    
print_xy:
    # --- Funkcja pomocnicza - wypisuje aktualny stan zmiennych ---
    li a7, 1
    mv a0, t1           # wypisz numer iteracji (i)
    ecall

    li a7, 4
    la a0, ez           # separator ". "
    ecall

    li a7, 4
    la a0, x            # etykieta x
    ecall

    li a7, 1
    mv a0, s3           # wypisz aktualny x (cos(x))
    ecall

    li a7, 4
    la a0, y            # etykieta y
    ecall

    li a7, 1
    mv a0, s4           # wypisz aktualny y (sin(x))
    ecall

    li a7, 4
    la a0, just_enter   # nowa linia
    ecall

    # Powrót do miejsca, z którego zostało wywołane jal ra, print_xy
    jalr zero, 0(ra)

angle_above:
    neg a0, a0             # a0 = -a0, negujemy wartość (ustalamy dolną granicę jako -|a0|)

    blt t0, a0, angle_below  # jeśli t0 < -|a0|, przejdź do normalizacji w dół (angle_below)

    li a0, 90              # a0 = 90, ustawiamy górną granicę kąta

    blt t0, a0, main       # jeśli t0 < 90, to kąt jest już w zakresie [-90, 90), przejdź do main

    # Jeśli kąt >= 90, wykonujemy normalizację w górę
    addi t0, t0, -90       # t0 = t0 - 90 (odejmujemy 90 stopni)
    addi s0, s0, 1         # s0 = s0 + 1 (zliczamy jeden „obrót” do przodu)

    bgt t0, a0, angle_above  # jeśli nadal t0 > 90, powtarzamy pętlę

    jalr zero, 0(ra)       # return (skok do adresu w ra), zakończ procedurę

angle_below:
    addi t0, t0, 90        # t0 = t0 + 90 (dodajemy 90 stopni)
    addi s0, s0, 1         # s0 = s0 + 1 (zliczamy jeden „obrót” do tyłu)

    bltz t0, angle_below  # jeśli nadal t0 < -90, kontynuuj dodawanie

    jalr zero, 0(ra)       # return, zakończ procedurę

