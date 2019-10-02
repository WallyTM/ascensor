list p=16F88
#include <P16F88.INC>
__CONFIG    _CONFIG1, _CP_OFF & _CCP1_RB0 & _DEBUG_OFF & _WRT_PROTECT_OFF & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _PWRTE_ON & _WDT_OFF & _XT_OSC
__CONFIG    _CONFIG2, _IESO_OFF & _FCMEN_OFF
#define		clk				PORTA,0
#define		dato			PORTA,1
#define		v				PORTA,2
#define		enc_v			PORTA,3
#define		set_v			PORTA,4
#define		sw1				PORTB,2
#define		sw2				PORTB,3
#define		pwm1			val_motores,0
#define		direc1			val_motores,1
#define		pwm2			val_motores,2
#define		direc2			val_motores,3
#define		led4			val_leds,5
#define		led3_a			val_leds,4
#define		led3_b			val_leds,3
#define		led2_a			val_leds,2
#define		led2_b			val_leds,1
#define		led1			val_leds,0
#define		down4			pul1,0
#define		up3				pul1,1
#define		down3			pul1,2
#define		up2				pul1,3
#define		down2			pul1,4
#define		up1				pul1,5
#define		p1				pul1,6
#define		p2				pul1,7
#define		p3				pul2,0
#define		p4				pul2,1
#define		p1h				pri,0
#define		p2h				pri,1

cblock 0x20
	val_motores,val_leds,disp_piso,num_piso,reg_seriales,nbits,tecla,cont1,cont2,pul1,pul2,piso_act,piso_s,encoder,enc_piso,aux_1,aux_2_up,aux_2_down,pri,pri1,pri2
endc

org	0x00
	goto	inicio
org	0x05
tabla1
	addwf	PCL,1
	dt		0xff,0xf9,0xa4,0xb0,0x99,0x92,0x82,0xf8,0x80,0x90
;---------------------------------------			
inicio
	bsf		STATUS,RP0
	movlw	b'00011000'
	movwf	TRISA
	movlw	b'11111100'
	movwf	TRISB
	bcf		OPTION_REG,7
	clrf	ANSEL
	bcf		STATUS,RP0
	bcf		v
	clrf	PORTA
	clrf	pul1
	clrf	pul2
	clrf	pri
	clrf	val_motores
	clrf	val_leds
	clrf	num_piso
	call	act_serial

	call	set_all
	call	ret_1s

ini_p	
	call	test_portb
	movf	aux_1,0
	movwf	piso_s
	call	mov_asc
	call	act_serial
	goto	ini_p

set_all
	bsf		pwm1
	bcf		direc1
	call	act_serial
	btfss	set_v
	goto	$-1
	bcf		pwm1
	movlw	.1
	movwf	num_piso
	movwf	piso_act
	clrf	encoder
	call	act_serial
	bsf		pwm2
	bcf		direc2
	call	act_serial
	btfsc	sw2
	goto	$-1
	bcf		pwm2
	call	act_serial
	return

act_serial
	bcf		v
	movf	num_piso,0
	call	tabla1
	movwf	disp_piso
serial_1
	movf	val_motores,0
	movwf	reg_seriales
	call	enviar
serial_2
	movf	val_leds,0
	movwf	reg_seriales
	call	enviar	
serial_3
	movf	disp_piso,0
	movwf	reg_seriales
	call	enviar
	bsf		v
	return
	
enviar
	movlw	.8
	movwf	nbits
test_bits
	btfss	reg_seriales,7
	goto	bajo
	goto	alto
bajo
	bcf		dato
	bsf		clk
	nop;call	ret_5us
	bcf		clk
	goto	sig_bit
alto
	bsf		dato
	bsf		clk
	nop;call	ret_5us
	bcf		clk
	bcf		dato
	goto	sig_bit
sig_bit
	rlf		reg_seriales,1
	decfsz	nbits,1
	goto	test_bits
	return

mov_asc
	movlw	.0
	subwf	piso_s,0
	btfsc	STATUS,Z
	return
	movf	piso_act,0
	subwf	piso_s,0
	btfss	STATUS,C
	goto	negativo
	btfss	STATUS,Z
	goto	positivo
piso_sol
	call	piso_solicitado
	return
negativo
	movf	aux_2_down,0
	movwf	enc_piso
	bsf		pwm1
	bcf		direc1
	call	act_serial
test_enc_neg
	btfsc	enc_v
	goto	$-1
	btfss	enc_v
	goto	$-1
	decf	encoder,1	

	movlw	.27
	subwf	encoder,0
	btfss	STATUS,Z
	goto	$+4
	movlw	.3
	movwf	num_piso
	goto	$+7

	movlw	.13
	subwf	encoder,0
	btfss	STATUS,Z
	goto	$+4
	movlw	.2
	movwf	num_piso
	call	act_serial

	movlw	.0
	subwf	enc_piso,0
	btfss	STATUS,Z
	goto	$+5
	btfss	set_v
	goto	test_enc_neg
	clrf	encoder
	goto	$+5

	movf	encoder,0
	subwf	enc_piso,0
	btfss	STATUS,Z
	goto	test_enc_neg

	call	apagar_led

	call	detener
	call	piso_solicitado	
	goto	piso_sol
positivo
	movf	aux_2_up,0
	movwf	enc_piso
	bsf		pwm1
	bsf		direc1
	call	act_serial
test_enc_pos
	btfsc	enc_v
	goto	$-1
	btfss	enc_v
	goto	$-1
	incf	encoder,1

	movlw	.13
	subwf	encoder,0
	btfss	STATUS,Z
	goto	$+4
	movlw	.2
	movwf	num_piso
	goto	$+7

	movlw	.27
	subwf	encoder,0
	btfss	STATUS,Z
	goto	$+4
	movlw	.3
	movwf	num_piso
	call	act_serial
	
	movf	encoder,0
	subwf	enc_piso,0
	btfss	STATUS,Z
	goto	test_enc_pos

	call	apagar_led

	call	detener
	call	piso_solicitado
	goto	piso_sol

apagar_led
	clrf	val_leds
	return

detener
	bcf		pwm1
	movf	piso_s,0
	movwf	num_piso
	call	act_serial
	call	ret_1s
	return

piso_solicitado
	movf	piso_s,0
	movwf	piso_act
	call	apagar_led
	bsf		pwm2
	bsf		direc2
	call	act_serial
	btfsc	sw1
	goto	$-1
	bcf		pwm2
	call	act_serial
	call	ret_1s
	call	ret_1s
	bsf		pwm2
	bcf		direc2
	call	act_serial
	btfsc	sw2
	goto	$-1
	bcf		pwm2
	call	act_serial
	call	ret_1s
	call	ret_1s
	return

test_portb
	movf	PORTB,0
	movwf	tecla
	comf	tecla,1
	swapf	tecla,1
	movlw	0x0f
	andwf	tecla,1
piso4
	movf	tecla,0
	sublw	.1
	btfsc	STATUS,Z
	goto	$+7
	movf	tecla,0
	sublw	.7
	btfss	STATUS,Z
	goto	piso3
	bsf		p4
	goto	$+3
	bsf		down4
	bsf		led4
	movlw	.4
	movwf	aux_1
	movlw	.40
	movwf	aux_2_up
	return
piso3
	movf	tecla,0
	sublw	.2
	btfsc	STATUS,Z
	goto	$+0e
	movf	tecla,0
	sublw	.3
	btfsc	STATUS,Z
	goto	$+7
	movf	tecla,0
	sublw	.8
	btfss	STATUS,Z
	goto	piso2
	bsf		p3
	goto	$+6
	bsf		down3
	bsf		led3_b
	goto	$+3
	bsf		up3
	bsf		led3_a
	movlw	.3
	movwf	aux_1
	movlw	.27
	movwf	aux_2_up
	movlw	.28
	movwf	aux_2_down
	return

piso2
	movf	tecla,0
	sublw	.4
	btfsc	STATUS,Z
	goto	$+0e
	movf	tecla,0
	sublw	.5
	btfsc	STATUS,Z
	goto	$+7
	movf	tecla,0
	sublw	.9
	btfss	STATUS,Z
	goto	piso1
	bsf		p2
	goto	$+6
	bsf		down2
	bsf		led2_b
	goto	$+3
	bsf		up2
	bsf		led2_a
	movlw	.2
	movwf	aux_1
	movlw	.13
	movwf	aux_2_up
	movlw	.14
	movwf	aux_2_down
	return
piso1
	movf	tecla,0
	sublw	.6
	btfsc	STATUS,Z
	goto	$+7
	movf	tecla,0
	sublw	.10
	btfss	STATUS,Z
	goto	no_tecla
	bsf		p1
	goto	$+3
	bsf		up1
	bsf		led1
	movlw	.1
	movwf	aux_1
	movlw	.0
	movwf	aux_2_down
	return
no_tecla
	movlw	.0
	movwf	aux_1
	return

ret_100us
	movlw 	.5
	movwf 	cont1
	movlw 	.5
	movwf 	cont2
	decfsz 	cont2
	goto 	$-1
	decfsz 	cont1
	goto 	$-5
	return

ret_100ms
	movlw 	.130
	movwf 	cont1
	movlw 	.255
	movwf 	cont2
	decfsz 	cont2
	goto 	$-1
	decfsz 	cont1
	goto 	$-5
	return

ret_1s
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	call	ret_100ms
	return

end