# Microcode

## ALU
|Binary|Action|
|---|---|
|00001|AR:=BUS|
|00010|AR:=BUS'|
|00011|AR:=0|
|00100|AR:=AR+BUS|
|00101|AR:=AR-BUS|
|00110|AR:=AR and BUS|

## Bus codes
|Binary|Item|
|---|---|
|0001|IR|
|0010|PM|
|0011|PC|
|0100|ASR|
|0101|unsigned(AR)|
|0110|GRx|

## PC
|Binary|Action|
|---|---|
|0|NOP|
|1|PC:=PC+1|

## SEQ
|Binary|Action|
|---|---|
|0000|μPC:=μPC+1|
|0001|μPC:=μAddr|
|0010|μPC:=K2(MM)|
|0011|μPC:=K1(MM)|
|1000|μPC:=μAddr if X=1|
|1001|μPC:=μAddr if N=1|
|1010|μPC:=μAddr if Z=1|
|1011|μPC:=μAddr if C=1|
|1100|μPC:=μAddr if V=1|

- - -

# ASM

## OP
|Binary|Operation|
|---|---|
|00000|LOAD|
|00001|STORE|
|00010|ADD|
|00011|SUB|
|00100|AND|

## GRx
Binary => GR#

## Memory Mode
|Binary|Mode|
|---|---|
|00|Direct|
|01|Immediate|
|10|Indirect|
