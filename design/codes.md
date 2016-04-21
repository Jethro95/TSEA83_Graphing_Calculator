# Microcode

## ALU

Binary | Action
------ | ---------------------------
00001  | AR:=BUS
00010  | AR:=BUS'
00011  | AR:=0
00100  | AR:=AR+BUS
00101  | AR:=AR-BUS
00110  | AR:=AR and BUS
00111  | AR:=signed_to_float(AR)
01000  | AR:=float_to_signed(AR)
01001  | AR:=AR>>
01010  | AR:=<<AR
01011  | AR:=AR+BUS (floating point)
01100  | AR:=AR-BUS (floating point)
01101  | AR:=AR*BUS (floating point)
01110  | AR:=AR/BUS (floating point)

## Bus codes

Binary | Item
------ | ------------
0001   | IR
0010   | PM
0011   | PC
0100   | ASR
0101   | AR
0110   | AR_f
0111   | GRx

## PC

Binary | Action
------ | --------
0      | NOP
1      | PC:=PC+1

## SEQ

Binary | Action
------ | -----------------
0000   | μPC:=μPC+1
0001   | μPC:=μAddr
0010   | μPC:=K2(MM)
0011   | μPC:=K1(MM)
1000   | μPC:=μAddr if X=1
1001   | μPC:=μAddr if N=1
1010   | μPC:=μAddr if Z=1
1011   | μPC:=μAddr if C=1
1100   | μPC:=μAddr if V=1

--------------------------------------------------------------------------------

# ASM

## OP

Binary | Operation
------ | ---------
00000  | HALT
00001  | LOAD
00010  | STORE
00011  | BRA
00100  | BEQ
00101  | BMI
00110  | BNE
00111  | BRF
01000  | ADD
01001  | ADDF
01010  | SUB
01011  | SUBF
01100  | DIVF
01101  | MULTF
01110  | AND
01111  | ASR
10000  | ASL
10001  | ITF (Integer To Float)
10010  | FTI (Float To Integer)

Note on STORE: Addr above 1000 is used to store in picture memory, at pict_mem(addr-1000). Last 8 bits are used.

## GRx

Binary => GR#

## Memory Mode

Binary | Mode
------ | ---------
00     | Direct
01     | Immediate
10     | Indirect

## Flags

Flag | Name     | Comment
---- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
C    | Carry    | Works as you would expect carry to work. Also contains the bit that was shifted out after a shift operation.
V    | Overflow | Will be set if a result can't be represented.
Z    | Zero     | Set if AR is zero.
N    | Negative | Set if AR is negative.
X    | Extended | This flag is a copy of the carry-flag, but it won't be changed in all operations where C is changed. This allows you to first make a check (that will set C and X), then some other instructions that will change the C flag but not the X flag, and THEN you can make the branch according to the flags, which means you can use the X flag.
