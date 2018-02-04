;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Mall för lab1 i TSEA28 Datorteknik Y
;;
;; 171208 K.Palmkvist
;;

	;; Ange att koden är för thumb mode
	.thumb
	.text
	.align 2

	;; Ange att labbkoden startar här efter initiering
	.global	main
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 	Placera programmet här

main:				; Start av programmet
	bl inituart
	bl initGPIOF
	bl initGPIOB
	bl correct
START:
	bl clearinput
	bl activatealarm
CHECK_KEY:
	bl getkey
	cmp r4,#0xF
	beq CODE_COMPARE
	bl addkey
	bl CHECK_KEY
CODE_COMPARE:
	bl checkcode
	cmp r4,#1
	beq DISABLE_ALARM
	bl PRINT
DISABLE_ALARM:
	bl deactivatealarm
WAIT_FOR_A:
	mov r9,#0
	bl getkey_timer
	cmp r4,#0xA
	beq START
	bl WAIT_FOR_A
PRINT:
	adr r4, WRONG
	mov r5,#15
	bl printstring
	bl START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;
;Inargument: Pekare till strängen i r4
; Längd på strängen i r5
printstring:
	push {r4,r0,r5,lr}
p_loop:
	ldr r0,[r4],#1
	bl printchar
	subs r5,r5,#1
	bne p_loop
	pop{r4,r0,r5,lr}
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
activatealarm:
	ldr r1,GPIOF_GPIODATA
	mov r0,#0x02
	str r0,[r1]
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;
deactivatealarm:
	ldr r1,GPIOF_GPIODATA
	mov r0,#0x08
	str r0,[r1]
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;
getkey:
	push{r0,r1,lr}
strobe_off:
	ldr r0,GPIOB_GPIODATA
	ldr r1,[r0]
	subs r1,r1,#0x10
	bcc strobe_off ; loopar om strobe är ej nedtryckt.
	mov r4,r1 ; sparar knapp tryck i r4.
strobe_on:
	ldr r0,GPIOB_GPIODATA
	ldr r1,[r0]
	subs r1,r1,#0x10
	bcs strobe_on
	pop{r0,r1,lr}
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;
addkey:
	push {r4, r0, lr, r1}
	ldr r0, KEYGEN
	ldr r1,[r0]
	lsr r1,#8
	lsl r4,#24
	adds r1,r1,r4
	str r1,[r0]
	pop{r4, r0, lr, r1}
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clearinput:
	push {r0,r1}
	ldr r0,KEYGEN
	mvn r1,#0x00
	str r1,[r0]
	pop {r0,r1}
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
correct: ;Här sätter vi rätt kod till 0001
	push {r0,r1}
	ldr r0,CORRECT_KEY
	mov r1,#1
	str r1,[r0]
	pop {r0,r1}
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkcode:
	push {r0,r1,r2,r3}
	ldr r0,KEYGEN
	ldr r1,CORRECT_KEY
	ldr r2,[r0]
	ldr r3,[r1]
	cmp r2, r3
	bne olika
	mov r4,#1
	pop{r0,r1,r2,r3}
	mov pc,lr
olika:
	mov r4,#0
	pop{r0,r1,r2,r3}
	mov pc,lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getkey_timer:
	push{r0,r1,lr,r9}
strobe_off1:
	ldr r0,GPIOB_GPIODATA
	ldr r1,[r0]
	ldr r10,TIME
	;bl AREYOUTHERE
	adds r9,r9,#1
	cmp r9,r10
	beq LOL
	subs r1,r1,#0x10
	bcc strobe_off1; loopar om strobe är ej nedtryckt.
	mov r4,r1 ; sparar knapp tryck i r4.
strobe_on1:
	ldr r0,GPIOB_GPIODATA
	ldr r1,[r0]
	subs r1,r1,#0x10
	bcs strobe_on1
	pop{r0,r1,lr,r9}
	mov pc,lr
AREYOUTHERE:
	adds r9,r9,#1
	cmp r9,r10
	beq LOL
	mov pc,lr
LOL:
	pop{r0,r1,lr,r9}
	bl START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;

;;;
;;; Allt här efter ska inte ändras ok
;;;
;;; Rutiner för initiering
;;; Se labmanual för vilka namn som ska användas
;;;
	
	.align 4

;; 	Initiering av seriekommunikation
;;	Förstör r0, r1
	
inituart:
	ldr r1,RCGCUART		; Koppla in serieport
	mov r0,#0x01
	str r0,[r1]

	ldr r1,RCGCGPIO
	ldr r0,[r1]
	orr r0,r0,#0x01
	str r0,[r1]		; Koppla in GPIO port A

	nop			; vänta lite
	nop
	nop

	ldr r1,GPIOA_GPIOAFSEL
	mov r0,#0x03
	str r0,[r1]		; pinnar PA0 och PA1 som serieport

	ldr r1,GPIOA_GPIODEN
	mov r0,#0x03
	str r0,[r1]		; Digital I/O på PA0 och PA1

	ldr r1,UART0_UARTIBRD
	mov r0,#0x08
	str r0,[r1]		; Sätt hastighet till 115200 baud
	ldr r1,UART0_UARTFBRD
	mov r0,#44
	str r0,[r1]		; Andra värdet för att få 115200 baud

	ldr r1,UART0_UARTLCRH
	mov r0,#0x60
	str r0,[r1]		; 8 bit, 1 stop bit, ingen paritet, ingen FIFO
	
	ldr r1,UART0_UARTCTL
	mov r0,#0x0301
	str r0,[r1]		; Börja använda serieport

	mov pc,lr

	;; Tvinga startadress för konstanter till ordgräns
	.align 4

; Definitioner för registeradresser (32-bitars konstanter)
GPIOHBCTL	.field	0x400FE06C, 32
RCGCUART	.field	0x400FE618, 32
RCGCGPIO	.field	0x400fe608, 32
UART0_UARTIBRD	.field	0x4000c024, 32
UART0_UARTFBRD	.field	0x4000c028, 32
UART0_UARTLCRH	.field	0x4000c02c, 32
UART0_UARTCTL	.field	0x4000c030, 32
UART0_UARTFR	.field	0x4000c018, 32
UART0_UARTDR	.field	0x4000c000, 32
GPIOA_GPIOAFSEL	.field	0x40004420, 32
GPIOA_GPIODEN	.field	0x4000451c, 32
GPIOB_GPIODATA	.field	0x400053fc, 32
GPIOB_GPIODIR	.field	0x40005400, 32
GPIOB_GPIOAFSEL	.field	0x40005420, 32
GPIOB_GPIOPUR	.field	0x40005510, 32
GPIOB_GPIODEN	.field	0x4000551c, 32
GPIOB_GPIOAMSEL	.field	0x40005528, 32
GPIOB_GPIOPCTL	.field	0x4000552c, 32
GPIOF_GPIODATA	.field	0x4002507c, 32
GPIOF_GPIODIR	.field	0x40025400, 32
GPIOF_GPIOAFSEL	.field	0x40025420, 32
GPIOF_GPIODEN	.field	0x4002551c, 32
GPIOF_GPIOLOCK	.field	0x40025520, 32
GPIOKEY			.field	0x4c4f434b, 32
GPIOF_GPIOPUR	.field	0x40025510, 32
GPIOF_GPIOCR	.field	0x40025524, 32
GPIOF_GPIOAMSEL	.field	0x40025528, 32
GPIOF_GPIOPCTL	.field	0x4002552c, 32
TESTEST 		.field 	0x010000c0, 32;COPYRIGHT (C)
KEYGEN			.field 	0x20001000, 32 ; Här läggs dom 4 senaste trycken
CORRECT_KEY		.field  0x20001010, 32 ; Rätt kod
WRONG 			.string "Felaktig kod!",10,13
TIME			.field	0x00555003, 32

;; Initiering av port F
;; Förstör r0, r1, r2
initGPIOF:
	ldr r1,RCGCGPIO
	ldr r0,[r1]
	orr r0,r0,#0x20		; Koppla in GPIO port F
	str r0,[r1]
	nop 			; Vänta lite
	nop
	nop

	ldr r1,GPIOHBCTL	; Använd apb för GPIO
	ldr r0,[r1]
	mvn r2,#0x2f		; bit 5-0 = 0, övriga = 1
	and r0,r0,r2
	str r0,[r1]

	ldr r1,GPIOF_GPIOLOCK
	ldr r0,GPIOKEY
	str r0,[r1]		; Lås upp port F konfigurationsregister

	ldr r1,GPIOF_GPIOCR
	mov r0,#0x1f		; tillåt konfigurering av alla bitar i porten
	str r0,[r1]

	ldr r1,GPIOF_GPIOAMSEL
	mov r0,#0x00		; Koppla bort analog funktion
	str r0,[r1]

	ldr r1,GPIOF_GPIOPCTL
	mov r0,#0x00		; använd port F som GPIO
	str r0,[r1]

	ldr r1,GPIOF_GPIODIR
	mov r0,#0x0e		; styr LED (3 bits), andra bitar är ingångar
	str r0,[r1]

	ldr r1,GPIOF_GPIOAFSEL
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	ldr r1,GPIOF_GPIOPUR
	mov r0,#0x11		; svag pull-up för tryckknapparna
	str r0,[r1]

	ldr r1,GPIOF_GPIODEN
	mov r0,#0xff		; alla pinnar som digital I/O
	str r0,[r1]

	mov pc,lr


;; Initiering av port B
;; Förstör r0, r1
initGPIOB:
	ldr r1,RCGCGPIO
	ldr r0,[r1]
	orr r0,r0,#0x02		; koppla in GPIO port B
	str r0,[r1]
	nop			; vänta lite
	nop
	nop

	ldr r1,GPIOB_GPIODIR
	mov r0,#0x0		; alla bitar är ingångar
	str r0,[r1]

	ldr r1,GPIOB_GPIOAFSEL
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	ldr r1,GPIOB_GPIOAMSEL
	mov r0,#0x00		; använd inte analoga funktioner
	str r0,[r1]

	ldr r1,GPIOB_GPIOPCTL
	mov r0,#0x00		; använd inga specialfunktioner på port B
	str r0,[r1]

	ldr r1,GPIOB_GPIOPUR
	mov r0,#0x00		; ingen pullup på port B
	str r0,[r1]

	ldr r1,GPIOB_GPIODEN
	mov r0,#0xff		; alla pinnar är digital I/O
	str r0,[r1]

	mov pc,lr


;; Utskrift av ett tecken på serieport
;; r0 innehåller tecken att skriva ut (1 byte)
;; returnerar först när tecken skickats
;; förstör r1 och r2
printchar:
    ldr r1,UART0_UARTFR		; peka på serieportens statusregister
loop1:
    ldr r2,[r1]			; hämta statusflaggor
    ands r2,r2,#0x20		; kan ytterligare tecken skickas?
    bne loop1			; nej, försök igen
    ldr r1,UART0_UARTDR		; ja, peka på serieportens dataregister
    str r0,[r1]			; skicka tecken
    mov pc,lr
