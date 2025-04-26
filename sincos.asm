.data
prompt:     .asciz "\nEnter angle in degrees: "
factor:     .word 293601              # (pi/180) * 2^24
scale:      .word 16777216            # 2^24 (dla konwersji)
to_sincos:  .word 10188013
just_enter: .asciz "\n\n"
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
    mv a0, t2           # wynik do t0

	
    	la t0, atan_array      # t0 = adres tablicy
    	li t1, 0          # t1 = indeks (i)
    	mv t2, a0          # t2 = kąt(przeskalowany w radianach)
    	li t3, 25          # t3 = długość tablicy (len)
    	li s2, 0		#thetha = 0
    	
	lw s3, scale 	#cosx=1
	li s4, 0 	#sinx=0

loop:
    	beq t1, t3, done      # jeśli i == len, zakończ
    	slli t4, t1, 2        # t4 = i * 4 (rozmiar słowa w bajtach)
    	add t5, t0, t4        # t5 = adres array[i]
    	lw t6, 0(t5)          # t6 = array[i]
    	addi t1, t1, 1        # i++
    
    	blt s2, t2, signum

    
    	sub s2, s2, t6
    	add s3, s3, s4
    	
	j loop


done:

	li a7, 1
	mv a0, s2
	ecall
	

   	li a7, 4
 	la a0, just_enter
    	ecall
    	
	li a7, 1
	mv a0, t2
	ecall
	
	
	li a7, 10 #zakończ
	ecall

	
signum:
	add s2, s2, t6
	sub s3, s3, s4
	j loop



	