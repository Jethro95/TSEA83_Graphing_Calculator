# Microcode

## ALU
|Binary|Action|
|---|---|
|00001|AR:=BUS|
|00010|AR:=BUS'|
|00011|AR:=0|
|00100|AR:=AR+BUS|

## Bus codes
|Binary|Item|
|---|---|
|0001|IR|
|0010|PM|
|0011|PC|
|0100|ASR|
|0101|unsigned(AR)|

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


- - -

# ASM

## OP
|Binary|Operation|
|---|---|
|00000|Load (Maybe)|

## GRx
Binary => GR#

## Memory Mode
|Binary|Mode|
|---|---|
|00|Immediate|
|01|Direct|
|10|Indirect|
