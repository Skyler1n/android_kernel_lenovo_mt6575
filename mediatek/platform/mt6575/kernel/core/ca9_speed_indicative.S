    .text

    .extern cpu_speed_test_pt_update
    .extern cpu_speed_test_pt_restore
    .extern g_iDATA1
    .extern g_iDATA5
    .extern g_iDATA6

    @.equ PERIPH_BASE, 0xC000A000    @ Base address for SCU + periph
    .equ PERIPH_BASE, 0xF000A000    @ Base address for SCU + periph

nDATA1:
    .word g_iDATA1

nDATA5:
    .word g_iDATA5

nDATA6:
    .word g_iDATA6

    .global speed_indicative_loop
speed_indicative_loop:
    STMDB sp!, {r1-r12, r14}  @ save the architecture state

    @;polling L2 TAG cln&inv done
   	@           LDR r1,=L2CC_BASE
    @           LDR r4,=0x1     ; works for WAY0 only 
    @poll_L2CC  LDR r0,[r1,#0x7fC]  ; cln & inv L2CC(background)
	@	TST r0,r4
	@	BNE  poll_L2CC
    @	
    @; turn on  MMU , I$ ,D$, BTB
    @   LDR     r1,=L1_CTL_REG
    @   MRC     p15,0,r0,c1,c0,0                ; read Control reg
    @   ORR     r0,r0,r1
    @   MCR     p15,0,r0,c1,c0,0                ; write Control reg
    @
	@   DSB
    @
    @; fill L2 DATA/TAG
    @   LDR r0,=0xaaaaaaaa
    @   LDR r1,=L2TAG
    @   LDR r2,=L2ADDR
    @fill_word_1	STR r0,[r1],#0x20
	@   CMP r2,r1
	@   BNE fill_word_1
	@       
	@   DMB
	@	

range_as_loop_cpu0:
        
init_ext_mem_cpu0:
    @;turn off D$
    @MRC p15,0,r1,c1,c0,0
    @BIC r1,r1,#4
    @MCR p15,0,r1,c1,c0,0
            
    @LDR r0,=DATA1
    LDR r0, nDATA1
    LDR r0, [r0]
    MOV r1,#0
    LDR r2,=0x7F
        
    MOV r3,#0
    MOV r4,#0
    MOV r5,#0        
    MOV r6,#0
    MOV r7,#0
    MOV r8,#0
    MOV r9,#0
    MOV r10,#0
    SUB r11,r10,#1
    @LDR r12,=DATA5
    LDR r12, nDATA5
    LDR r12, [r12]
    STR r11,[r12]

init0:
    STMIA r0!,{r3-r10}
    CMP r1,r2
    ADD r1,r1,#1
    BNE init0
    
    @;turn on D$
    @MRC p15,0,r1,c1,c0,0
    @ORR r1,r1,#4
    @MCR p15,0,r1,c1,c0,0
        
    @LDR r0,=DATA1
    LDR r0, nDATA1
    LDR r0, [r0]
    MOV r1,#0
    LDR r2,=0x7F
    @LDR r5,=DATA5
    LDR r5, nDATA5
    LDR r5, [r5]
    SUB r6,r1,#1
    STR r6,[r5]

set_dirty_cpu0:
    STR r1,[r0]
    STR r1,[r0,#4]
    STR r1,[r0,#8]
    STR r1,[r0,#0xc]
    DMB
    STR r1,[r0,#0x10]
    STR r1,[r0,#0x14]
    STR r1,[r0,#0x18]
    STR r1,[r0,#0x1c]
    ADD r0,r0,#0x20
    CMP r1,r2
    ADD r1,r1,#1
    BNE set_dirty_cpu0

    @LDR r0,=DATA1
    LDR r0, nDATA1
    LDR r0, [r0]
    @LDR r2,=DATA1 + 0x1000
    LDR r2, nDATA1
    LDR r2, [r2]
    MOV r3, #0x1000
    ADD r2, r2, r3
    @;use r3 to checksum
    MOV r3,#0

    @;Cln & Inv L2CC by WAY
    @LDR r1,=L2CC_BASE
    @LDR r4,=0x1     ; works for WAY0 only 
    @STR r4,[r1,#0x7fC]  ; cln & inv L2CC(background)

read_loop_cpu0:
    LDR     r10,=PERIPH_BASE + 0xc
    LDR     r11,=0xffff
    STR     r11,[r10]  @invalidate SCU(background)
    LDR r6,[r5]
    LDR r1,[r0]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#4]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#8]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0xc]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x10]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x14]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x18]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x1c]
    ADD r3,r3,r1
    ADD r0,r0,#0x20
    CMP r0,r2
    BNE read_loop_cpu0
    LDR r4,=65024
    CMP r3,r4
    BNE end_of_test

    @MRC p15,0,r1,c1,c0,0
    @BIC r1,r1,#4
    @MCR p15,0,r1,c1,c0,0
    @LDR r0,=DATA1 + 0xFFE
    LDR r0, nDATA1
    LDR r0, [r0]
    LDR r3, =0xFFE
    ADD r0, r0, r3
    LDR r3,[r0]
    LDR r4,=0x7F
    CMP r3,r4
    BEQ end_of_test
    @LDR r0,=DATA1
    LDR r0, nDATA1
    LDR r0, [r0]
    @LDR r2,=DATA1 +  0x1000
    LDR r2, nDATA1
    LDR r2, [r2]
    MOV r3, #0x1000
    ADD r2, r2, r3
    
clean_loop_cpu0:
    MCR p15,0,r0,c7,c10,1
    ADD r0,r0,#0x20
    CMP r0,r2
    BNE clean_loop_cpu0

    @LDR r0,=DATA1
    LDR r0, nDATA1
    LDR r0, [r0]
    @LDR r2,=DATA1 + 0x1000
    LDR r2, nDATA1
    LDR r2, [r2]
    MOV r3, #0x1000
    ADD r2, r2, r3
    MOV r3,#0

check_loop_cpu0:
    LDR r6,[r5]
    LDR r1,[r0]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#4]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#8]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0xc]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x10]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x14]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x18]
    ADD r3,r3,r1
    LDR r6,[r5]
    LDR r1,[r0,#0x1c]
    ADD r3,r3,r1
    ADD r0,r0,#0x20
    CMP r0,r2
    BNE check_loop_cpu0
    LDR r4,=65024
    CMP r3,r4
    BNE end_of_test
    @MRC p15,0,r1,c1,c0,0
    @ORR r1,r1,#4
    @MCR p15,0,r1,c1,c0,0
                
    MOV  r0, #0x1
	B    Go_Back
    
    @;Fail here
end_of_test:
    @MOV  r0, #0x100		
    @LDR     r1,=L1_CTL_REG
    @MRC     p15,0,r3,c1,c0,0                ; read Control reg
    @BIC     r3,r3,r1
    @MCR     p15,0,r3,c1,c0,0                ; write Control reg
    @
    @ISB
    @DSB

    MOV     r0, #0x0    
	LDMIA   sp!, {r1-r12, r14} @restore the architecture state by cllu
    MOV     pc , r14    @return ca9_max_power_fp test 

Go_Back: 
    @; program Control register, disable  MMU , I$, D$
    @LDR     r1,=L1_CTL_REG
    @MRC     p15,0,r3,c1,c0,0                ; read Control reg
    @BIC     r3,r3,r1
    @MCR     p15,0,r3,c1,c0,0                ; write Control reg
    @
    @ISB
    @DSB
    
	LDMIA   sp!, {r1-r12, r14} @restore the architectu
    MOV     pc , r14    @return ca9_max_power_fp test 
    
    .end
