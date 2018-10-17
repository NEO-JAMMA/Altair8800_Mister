 ; Interrupt Acknowledge Cycle Demo
 0000 org 0
 0000 310001 lxi sp,400Q ;init stack pointer
 0003 3E03 mvi a,3 ;reset the ACIA
 0005 D310 out 20Q
 0007 3E95 mvi a,225Q ;8n1 rcv ints on
 0009 D310 out 20Q
 000B FB ei ;enable 8080 interrupts
 ; Idle loop
 000C 00 loop nop
 000D 00 nop ;demo with hlt here as well
 000E C30C00 jmp loop
 ; Interrupt service routine for RST7 is at 70 octal.
 0038 org 70Q ;RST7 entry address
 0038 DB11 in 21Q ;input clears device interrupt
 003A FB ei ;re-enable 8080 interrupts
 003B C9 ret
Here is the program in octal for easier entry into the Altair:
 000: 061 000 001 076 003 323 020 076
 010: 225 323 020 373 000 000 303 014
 020: 000
 070: 333 021 373 311