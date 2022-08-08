;*******************************************************************************
;Universidad del Valle de Guatemala
;IE2023 Programación de Microncontroladores
;Autor: Andrés Lemus 21634
;Compilador: PIC-AS (v2.40), MPLAB X IDE (v6.00)
;Proyecto: Laboratorio 2
;Creado: 01/08/2022
;Última Modificación: 01/08/22
;*******************************************************************************
PROCESSOR 16F887
#include <xc.inc>
;*******************************************************************************
;Palabra de Configuración
;*******************************************************************************
    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF        ; Brown Out Reset Selection bits (BOR controlled by SBOREN bit of the PCON register)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;*******************************************************************************
;Variables
;*******************************************************************************
PSECT udata_shr
    bandera: DS 1
    cont: DS 1
    cont1: DS 1
    cont2: DS 1
    cont3: DS 1
    
;*******************************************************************************
;Vector Reset
;*******************************************************************************
PSECT CODE, delta=2, abs
 ORG 0x0000
    goto main

;*******************************************************************************
;Código Principal
;*******************************************************************************
PSECT CODE, delta=2, abs
 ORG 0x0100
 
tabla:
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0F     ;Se pone límite de 15
    ADDWF PCL      ;suma entre pcl y w
    RETLW 00111111B;0
    RETLW 00000110B;1
    RETLW 01011011B;2
    RETLW 01001111B;3
    RETLW 01100110B;4
    RETLW 01101101B;5
    RETLW 01111101B;6
    RETLW 00000111B;7
    RETLW 01111111B;8
    RETLW 01100111B;9
    RETLW 01110111B;A
    RETLW 01111100B;B
    RETLW 00111001B;C
    RETLW 01011110B;D
    RETLW 01111001B;E
    RETLW 01110001B;F   

main:
    
    BANKSEL ANSEL  ;Puertos como digitales
    CLRF ANSEL
    CLRF ANSELH
    
    BANKSEL OSCCON
    BSF OSCCON, 6  ;Configuramos la frecuencia de oscilación a 2 MHz
    BCF OSCCON, 5
    BSF OSCCON, 4
    
    BSF OSCCON, 0  ;Utilizar oscilador interno
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 5 ;Usar el Timer0 con el oscilador interno 
    BCF OPTION_REG, 3 ;Utilizar el prescaler con el Timer0
    
    BSF OPTION_REG, 2 ;Utilizar prescaler de 256
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0	
    
    BANKSEL TRISA
    CLRF TRISA	      ;PUERTO A COMO SALIDA 
    CLRF TRISB	      ;PUERTO B COMO SALIDA
    CLRF TRISC        ;PUERTO C COMO SALIDA
    CLRF TRISE	      ;PUERTO E COMO SALIDA
    
    BANKSEL TRISD
    BSF TRISD, 6      ;RD6 COMO ENTRADA
    BSF TRISD, 7      ;RA7 COMO ENTRADA
    
    BANKSEL PORTA     ;LIMPIAR PUERTOS
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC 
    CLRF PORTD
    CLRF PORTE

    MOVLW 1     
    MOVWF cont        ;INICIAR VARIABLE DEL DISPLAY EN "CERO"
    CLRW
    
    CLRF cont1        ;LIMPIAR CONTADOR DE 1 s
    MOVLW 61
    MOVWF TMR0	      ;CARGAMOS EL VALOR DE N = DESBORDE 100mS
    
loop:
    call timer        ;llamar funcion del timer
    BTFSC PORTD, 7    ;Se verifica si el botón de RD7 se apachó
    call anti1        ;Se llama al antirebote
    BTFSS PORTD, 7    ;Si el botón se dejo de presionar se llama a la función incrementar
    call incrementar1 
    BTFSC PORTD, 6    ;Se verifica si el botón de RD6 se apachó
    call anti2        ;Se llama al antirrebote
    BTFSS PORTD, 6    ;Si el botón se dejo de presionar se llama a la función decrementar
    call decrementar1
    goto loop
   
anti1:
    BSF bandera, 0    ;Poner bit 0 de la bandera en 1
    RETURN

incrementar1:
    BTFSS bandera, 0  ;Si el bit 0 de la bandera es 1,ya se ha presionado el boton y se ha soltado
    RETURN            ;Regresar
    INCF cont, F      ;Incrementar la variable del display
    MOVF cont, 0      ;Mover el valor de la variable del display a W
    CALL tabla        ;Llamar a la tabla y traducir W al número de instrucción de la tabla, luego mover ya traducido a W
    MOVWF PORTA       ;Mover el valor de W al Puero A
    CLRF bandera      ;Limpiar la bandera
    RETURN

anti2:
    BSF bandera, 1    ;;Poner bit 1 de la bandera en 1
    RETURN
    
decrementar1:
    BTFSS bandera, 1  ;Si el bit 1 de la bandera es 1,ya se ha presionado el boton y se ha soltado
    RETURN            ;Regresar
    DECF cont, F      ;Decrementar la variable del display
    MOVF cont, 0      ;Mover el valor de la variable del display a W
    CALL tabla        ;Llamar a la tabla y traducir W al número de instrucción de la tabla, luego mover ya traducido a W
    MOVWF PORTA       ;Mover el valor de W al Puero A
    CLRF bandera      ;Limpiar la bandera
    RETURN
    
timer:
    BTFSS INTCON, 2 ;Chequear el bit del overflow del Timer0
    GOTO $-1        ;Revisarlo hasta que este se prenda
    MOVLW 61        ;Volver a cargar valor N para desborde de 100ms
    MOVWF TMR0      ;Cargar al Timer0
    BCF INTCON,2    ;Limpiar bit de overflow de Timer0
    INCF PORTB, F   ;Se incrementa el puerto B
    INCF cont1, 1   ;Se incrementa la variable para contador de 1 s
    BTFSS cont1, 1  ;Si el bit 1 está encendido se prosigue, sino se vuelve a chequear
    RETURN
    BTFSS cont1, 3  ;Revisar el bit 3, si este es 1 significa que está en 10 y ya paso un 1s. (100ms*10)=1s
    RETURN
    CLRF cont1      ;Se limpia la varible del contador de 1s
    INCF PORTC, F   ;Se incrementa el puerto D
    BTFSC PORTC, 4  ;Se chequea bit 4 para que este sea su límite, ya que se quiere contador de 4 bits
    CLRF PORTC      ;Si es 1 el bit 4 se limpia el bit 4
    CALL veri       ;Llamamos a la función de verificación (del contador de 1s y display)
    RETURN 

veri:
    MOVF PORTC, W   ;Movemos el valor del puerto C a W
    SUBWF cont, W   ;Restamos W de la variable contador del display
    BTFSS STATUS, 2 ;Se chequea el bit ZERO, si el bit ZERO es 1 la resta es 0 y se prosigue; si el BIT ZERO es 0 se vuelve a verificar
    RETURN
    INCF PORTE, F   ;Se incrementa el Puerto E (ALARMA)
    CALL DELAY_BIG  ;Delay para apreciar que se enciende el led 
    CLRF PORTC      ;Se reincia el puerto C
    CLRF cont1      ;Se limpia la variable del contador de 1s
    BCF STATUS, 2   ;Se limpia el BIT ZERO
    RETURN
    
DELAY_BIG:
    MOVLW 50
    MOVWF cont2
    CALL DELAY_SMALL
    DECFSZ cont2, F
    GOTO $-2
    RETURN
    
DELAY_SMALL:
    MOVLW 150
    MOVWF cont3
    DECFSZ cont3, F
    GOTO $-1
    RETURN
   
END


