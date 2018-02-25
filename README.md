### Graphing calculator
Done for the course [TSEA83](http://www.isy.liu.se/edu/kurs/TSEA83/) in computer construction.

### Overview
  - CPU and VGA unit written in VHDL
  - Graphing calculator written in "glorified assembly"
  - Compiler from "glorified assembly" to assembly instructions

### CPU/VGA
[VHDL code](https://github.com/felixharnstrom/TSEA83_Graphing_Calculator/tree/master/src) intended to run on a Nexys 3 board. 

A fully featured 32-bit CPU with integer/fixed point arithmetics of , 8 general registers. 

The graphic unit displays a 640x480 pixel image at 60Hz. Split into one 320x480 bitmapped area, and the other half of the display showing 20x30 tiles from [1-9], [A-Ö] and a select range of mathematical symbols.

[There is an included converter from a ttf font to tiles.](https://github.com/felixharnstrom/TSEA83_Graphing_Calculator/tree/master/fonts)

### Sillescript2
A relatively advanced cross-assembler that includes support for if/else-statemets, while-loops, include-statements and comments.
~~~~
# Modify function: Replace X'es
load$ 0,0 # Loop counter
while 0 < &inputLength # GR0 < number of input elements
      # Put the value &nextInputType is pointing to on GR2.
      load~ 2,&nextInputType
      if 2=$2 # If value is X
      	 # Replace the X in the function with proper Xval
      	 store~ 1,&nextInput
      end if
      ...
      # Increment loop counter
      add$ 0,1
      ...
end while

# Labels this row as inputLength. Start value: 8.
inputLength: sli 8
~~~~

See [the assembly folder](https://github.com/felixharnstrom/TSEA83_Graphing_Calculator/tree/master/assembly) for sample code, and the (swedish) [report](https://github.com/felixharnstrom/TSEA83_Graphing_Calculator/blob/master/redovisning/Rapport.tex) for a description.

A compiler is available [here](https://github.com/felixharnstrom/TSEA83_Graphing_Calculator/tree/master/sillescript2)

### The graphing calculator
The calculator includes support for addition, substraction, multiplication and division of fixed point numbers written in reverse-polish notation. Can plot functions with a custom range and auto-adjusting axes.
Fully written in assembly (sillescript2) with source code available [here](https://github.com/felixharnstrom/TSEA83_Graphing_Calculator/tree/master/assembly). Calc is the main program that includes other neccecary programs.
![](https://github.com/felixharnstrom/TSEA83_Graphing_Calculator/raw/master/redovisning/drawings/display2.png)
