; wyswietlanie dzialajacaego zegara na ekranie
; A / ACC - akumulator nie zawsze ktoras dziala
TEST bit P1.7
SEG7 bit P1.6
BUZZ bit P1.5

SKEY bit P3.5

CSDS equ 30h 				;wyœwietlacze
CSDB equ 38h 				;segmenty

KEYS equ 7Ch				;cztery ostatnie stany klawiatury sekwencyjnej/multipleksowanej

ZEGAR equ 76h 				;tablica na 6 cyfr zegara

SS equ 75h				;sekundy
MM equ 74h				;minuty
GG equ 73h				;godziny
org 0
	ljmp start

org 0Bh					;procedura/podprogram/funkcja obslugi przerwania TIMER0
	mov TH0, #227           	;wlasciwa wartosc poczatkowa
	mov TL0, #252
	setb F0				;bylo przerwanie
	reti                    	;powrot z przerwania


org 80h
start:

	mov SS, #54			;stan poczatkowy zegara
	mov MM, #26
	mov GG, #22

	mov KEYS, #0

	lcall przelicz			;wywolanie funkcji

    clr SEG7
	mov R7, #00000001b 		;najmlodszy wyswietlacz do R7
	mov R1, #ZEGAR     		;adres najmlodszej cyfry zegara do R1
	mov DPTR, #wzory   		;adres wzorow cyfr 7seg do DPTR

	mov R6, #0			;zeby pierwsza sekunda trwala sekunde
	mov R5, #4

	mov TH0, #227           	;wlasciwa wartosc poczatkowa
	mov TL0, #252          	 	;przerwanie co 900 cykli maszynowych - 1024 przerwania na sekunde

	mov IE, #0 			;zakaz obslugi jakiegokolwiek przerwania
	mov TMOD, #01110000b 		;blokujemy TIMER1, TIMER0 w trybie 13bit
	setb TR0			;zgoda na zliczanie przez TIMER0
	setb ET0 			;zgoda na obluge przerwania od TIMER0
	setb EA				;globalna zgoda na obsluge przerwan


mLoop:
	jnb F0, mLoop           	;czekamy na przerwanie
	clr F0                  	;zapominamy o przerwaniu

	;tutaj jestem 1024 razy na sekunde

	mov R0, #CSDB      		;adres zatrzasku segmentow do R0
	mov A, @R1         		;wartosc odpowiedniej cyfry zegara do ACC
	inc R1             		;w nastepnym obrocie petli bedzie nastepna cyfra
	setb SEG7          		;wylaczam wyswietlacze, zeby nie bylo duchow (cyfr)
	movx @R0, A  	   		;wysylam wzorek do zatrzasku segmentow

    mov R0, #CSDS      			;adres zatrzasku wyswieltaczy do R0
	mov A, R7          		;aktualny wyswietlacz do ACC
	movx @R0, A  	   		;wybieram aktualny wyswietlacz zatrzaskiem CSDS
	clr SEG7           		;wlaczam wyswietlacze
	
	mov C, SKEY   			;stan klawisza do bitu C (carry)
	jnc brakKlawisza
	;jezeli jest wcisniety
	orl KEYS, A


brakKlawisza:


	rl A               		;w nastepnym obrocie petli bedzie nastepny wyswietlacz
	mov R7, A          		;zapamietuje nowowybrany wyswietlacz
	jnb ACC.7, noACC7  		;test czy nie minalem wyswietlaczy
	mov R7, #00000001b  		;jezeli tak wracam na najmlodszy wyswietlacz
	mov R1, #ZEGAR     		;i najmlodsza cyfre zegara

    	;tu jest stan 4 ostatnich odczytow klawiatury

	mov A, KEYS
	cjne A, KEYS+1, niestabilna
	cjne A, KEYS+2, niestabilna  	;3 razy z rzedu przeczytal to samo
	cjne A, KEYS+3, stabilna	;jak 3 te same i 4 inny                                                   ;zeby zapobiec wielokrotnej obsludze
	
	sjmp niestabilna    		;zeby wielokrotnie nie oblugiwac tego samego klawisza                     ;tego samego klawisza

stabilna:
	jz niestabilna
	lcall obslugaKlawiatury

niestabilna:
	mov KEYS+3, KEYS+2
	mov KEYS+2, KEYS+1
	mov KEYS+1, KEYS
	mov KEYS, #0

noACC7:


    djnz R6, mLoop     			;zliczamy przerwania do 1024
	djnz R5, mLoop

    mov R6, #0		   		;zeby kolejne sekundy trwaly sekunde
	;mov R6, #4             	;testowe szybkie odliczanie
	mov R5, #4
    ;mov R5, #1             		;tez testowe szybkie odliczanie

	;tutaj jestem co sekunde

	inc SS
	mov A, SS               	;sekundy do akumulatora
	cjne A, #60, nie60      	;testujemy czy osiagnieto wartosc 60
	mov SS, #0              	;jezeli tak to wracamy z licznikiem sekund na 0

	inc MM                  	;i inkrementujemy minuty
	mov A, MM               	;to samo dla minut
	cjne A, #60, nie60
	mov MM, #0

	inc GG                  	;to samo dla godzin
	mov A, GG
	cjne A, #24, nie60
	mov GG, #0

nie60:
	lcall przelicz

    cpl P1.7           			;przelacza diode TEST

	sjmp mLoop

przelicz:
	mov DPTR, #wzory 		;adres wzorow do DPTR

	mov A, SS         		;sekundy do akumulatora
	mov B, #10        		;dzielnik do B
	div AB           		;dzielenie calkowite - A- wynik, B-reszta

	movc A, @A+DPTR			;zamieniam dziesiatki sekund na odpowiedni wzorek
	mov ZEGAR+1, A      		;zapamietuje wzorek we wlasciwym miejscu
	mov A, B           		;jednostki sekund do akumulatora
	movc A, @A+DPTR			;zamieniam jednostki sekund na odpowiedni wzorek
	mov ZEGAR, A      		;zapamietuje wzorek we wlasciwym miejscu


	mov A, MM         		;minuty do akumulatora
	mov B, #10        		;dzielnik do B
	div AB           		;dzielenie calkowite - A- wynik, B-reszta
	
    movc A, @A+DPTR			;zamieniam dziesiatki minut na odpowiedni wzorek
	mov ZEGAR+3, A      		;zapamietuje wzorek we wlasciwym miejscu
	mov A, B           		;jednostki minut do akumulatora
	movc A, @A+DPTR			;zamieniam jednostki minut na odpowiedni wzorek
	mov ZEGAR+2, A      		;zapamietuje wzorek we wlasciwym miejscu


	mov A, GG         		;godziny do akumulatora
	mov B, #10        		;dzielnik do B
	div AB           		;dzielenie calkowite - A- wynik, B-reszta
	
	movc A, @A+DPTR			;zamieniam dziesiatki godzin na odpowiedni wzorek
	mov ZEGAR+5, A      		;zapamietuje wzorek we wlasciwym miejscu
	mov A, B           		;jednostki godzin do akumulatora
	movc A, @A+DPTR			;zamieniam jednostki godzin na odpowiedni wzorek
	mov ZEGAR+4, A      		;zapamietuje wzorek we wlasciwym miejscu

	ret

obslugaKlawiatury:                        	;enter ze strzalkami zmniejsza a escape zwieksza
	cjne A, #100010b, nieGodzinyGora      	;strzalka w lewo i escape lub enter
	mov R4, GG
	cjne R4, #23, zwiekszGodziny
	mov GG, #0
	sjmp nieGodzinyGora
zwiekszGodziny:
	inc GG

nieGodzinyGora:
	cjne A, #100001b, nieGodzinyDol
	mov R4, GG
	cjne R4, #0, zmniejszGodziny
	mov GG, #23
	sjmp nieGodzinyDol
zmniejszGodziny:
	dec GG

nieGodzinyDol:
	cjne A, #10010b, nieMinutyGora  	;strzalka w dol i escape lub enter
	mov R4, MM
	cjne R4, #59, zwiekszMinuty
	mov MM, #0
	sjmp nieMinutyGora
zwiekszMinuty:
	inc MM

nieMinutyGora:
	cjne A, #10001b, nieMinutyDol
	mov R4, MM
	cjne R4, #0, zmniejszMinuty
	mov MM, #59
	sjmp nieMinutyDol
zmniejszMinuty:
	dec MM

nieMinutyDol:
	cjne A, #110b, nieSekundyGora  		;strzalka w prawo i escape lub enter
 	mov R4, SS
	cjne R4, #59, zwiekszSekundy
	mov SS, #0
	sjmp nieSekundyGora
zwiekszSekundy:
 	inc SS

nieSekundyGora:
	cjne A, #101b, nieSekundyDol
	mov R4, SS
	cjne R4, #0, zmniejszSekundy
	mov SS, #59
	sjmp nieSekundyDol
zmniejszSekundy:
	dec SS

nieSekundyDol:
	cjne A, #1000b, nieGora   		;strzalka w gore zeruje sekundnik
	mov SS, #0
	mov R6, #0		   		;wyzerowanie licznikow przerwan
	mov R5, #4

nieGora:

    	lcall przelicz
	ret

wzory:  			 		;dla wyswietlacza 7seg
db 00111111b, 00000110b, 01011011b, 01001111b
db 01100110b, 01101101b, 01111101b, 00000111b
db 01111111b, 01101111b, 01110111b, 01111100b

end