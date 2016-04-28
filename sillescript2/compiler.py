import sys

"""
SYNTAX EXPLANATION

Update this section as syntax changes.

Instructions are separated by newline
Assembly instructions are written as:
  INSTR_NAME INSTR_MODE INSTR_GRx , INSTR_ARG
The argument is written in decimal.

Control structures:
if <comparison>
  <Do stuff>
end

loop
  if <comparison>
    break
  end
  <Do stuff>
end

A comparison looks like:
GRx OPERATOR LITERAL/ADDRESS

GRx is written like an integer
Operators are:
    = : equals
    ! : not equals
    > : GRx larger than
    < : GRx smaller than
If you want to compare with contents at an address, simply write the address on the rhs.
If you want to compare with a literal, write $ before the literal.

Comments are written after #'s




"""

#========================================================================================
#   CONSTANTS
#========================================================================================

BITSEP = "_" #Separator for different parts of output instruction

GRX_ADDRESS_SEPERATOR = "," #For telling grx and address apart on input

INSTRUCTION_WIDTH = 5 #Bits
GRX_WIDTH = 3 #Bits
MODE_WIDTH = 2 #Bits
ADDRESS_WIDTH = 22 #Bits 
WORD_WIDTH = INSTRUCTION_WIDTH + GRX_WIDTH + MODE_WIDTH + ADDRESS_WIDTH

KEYWORD_IF = "if"
KEYWORD_END_IF = "endif"
KEYWORD_COMMENT = "#"
assert len(KEYWORD_COMMENT) == 1

#Character used to denote literals in bool expressions
LITERAL_DENOTER = "$"

#Instructions and the numbers for their respective instructions in bytecode
INSTRUCTIONS = {
    "halt"        :0, 
    "load"        :1, 
    "store"       :2, 
    "add"         :8, 
    "addf"        :9, 
    "sub"         :10, 
    "subf"        :11, 
    "divf"        :12, 
    "multf"       :13,
    "and"         :14,
    "asl"         :15,
    "asr"         :16,
    "jmp"         :17,
    "lsl"         :18,
    "lsr"         :19,
    "storefp"     :20,
    "itr"         :21,
    "rti"         :22
}

#The compare instruction
INSTR_CMP = 23 #TODO: Actual code

#The characters for using different modes for the instructions, 
#   and their respective mode number
MODES = {
    "$"    :1, #Immediate
    "~"    :2, #Indirect
} #default when others

#All mode strings must have length 1
for mode in MODES:
    assert (len(mode) == 1)

#The mode used when no mode is specified
MODE_DEFAULT = 0 #Direct
#The mode that requires the address argument on the next line
MODE_ADRESS_ON_NEXT_LINE = 1 #Immediate
#Needed for boolean evaluation
MODE_IMMEDIATE = 1
MODE_DIRECT = 0

#An instruction that jumps to itself, without address.
#The adress given will be the line it is on.
#TODO: Replace logic using this with HALT.
INSTRUCTION_JUMP_TO_SELF = "10001_000_00_"

#Jump instructions for bool operators. Note that they are inverted; we jump if expression is false.
BOOL_OPs = {
    "<"     :5, #BMI --TODO: BPLUS for >
    "!"     :4, #BEQ
    "="     :6  #BNE
}

FANCIFY_DESIRED_LENGTH = 32 + 4

#========================================================================================
#   CODE
#========================================================================================

#Converts integer to bitstring of length bitCount
def bitify(num, bitcount):
    bitstring = bin(int(num))
    bitstring = bitstring[bitstring.find("b")+1:] #Cutting of 0b and occasionally -0b. Dunno why - shows up.
    while len(bitstring) < bitcount:
        bitstring = "0" + bitstring
    return bitstring[:bitcount]

#Converts a full instruction to bytecode.
def completeInstruction(instruction, grx, mode, address):
    result = bitify(instruction, INSTRUCTION_WIDTH) +BITSEP+ bitify(grx, GRX_WIDTH) +BITSEP+ bitify(mode, MODE_WIDTH) +BITSEP+ bitify(address, ADDRESS_WIDTH)
    assert (len(result) == 3 + WORD_WIDTH)
    return result

#Converts a full instruction to bytecode, minus the address.
def placeholderInstruction(instruction, grx, mode):
    result = bitify(instruction, INSTRUCTION_WIDTH) +BITSEP+ bitify(grx, GRX_WIDTH) +BITSEP+ bitify(mode, MODE_WIDTH) +BITSEP
    assert (len(result) == 3 + WORD_WIDTH - ADDRESS_WIDTH)
    return result

#The representation for 
class MachineLine:
    line = ""
    comment = ""
    #Attempt to fill out the instruction based on previous line
    #Sourceline is the assembler line to react to, lineNum its bytecode line number
    def attemptFix(self, sourceLine, lineNum):
        return False

    #Sets the line to a complete instruction, and returns itself
    def setComplete(self, instruction, grx, mode, address):
        self.line = completeInstruction(instruction, grx, mode, address)
        return self

    #Sets the line to a literal, and returns itself
    def setLiteral(self, literal):
        self.line = bitify(literal, WORD_WIDTH)
        return self

    #Sets the line to a complete instruction without address, and returns itself
    def setIncomplete(self, instruction, grx, mode):
        self.line = placeholderInstruction(instruction, grx, mode)
        return self

    def __init__(self, comment):
        self.line = ""
        self.comment = comment

class JumpIfLine(MachineLine):
    complete = False

    #Fills out instruction with a jump
    def attemptFix(self, sourceLine, lineNum):
        if not self.complete and sourceLine.startswith(KEYWORD_END_IF):
            self.line += bitify(lineNum, ADDRESS_WIDTH)
            self.complete = True
            return True
        return False

    def __init__(self, instruction, comment):
        MachineLine.__init__(self, comment)
        self.setIncomplete(instruction, 0, MODE_DIRECT)
        self.complete = False

#Parses a non-loop, non-instruction to a bytecode instruction
#Returns None if unsuccesful
def lineToCompleteInstruction(line):
    #Instruction
    instr = -1
    instrLen = -1
    for instruction in INSTRUCTIONS:
        if line.startswith(instruction):
            instr = INSTRUCTIONS[instruction]
            instrLen = len(instruction)
            break
    if instr == -1:
        return None
    #Mode
    restOfLine = line[instrLen:]
    if restOfLine == "":
        return None
    mode = -1
    if restOfLine[0] in MODES:
        mode = MODES[restOfLine[0]]
        restOfLine = restOfLine[1:] #Only shorten restOfLine if a mode is given
    else:
        mode = MODE_DEFAULT
    addressOnNextLine = (mode == MODE_ADRESS_ON_NEXT_LINE)
    #GRx
    endIndex = restOfLine.find(GRX_ADDRESS_SEPERATOR)
    if endIndex == -1:
        return None
    try:
        grx = int(restOfLine[:endIndex])
    except ValueError:
        return None
    #Address
    restOfLine = restOfLine[endIndex+1:]
    if restOfLine == "":
        return None
    try:
        address = int(restOfLine)
    except ValueError:
        return None
    #Putting together
    if not addressOnNextLine:
        return [MachineLine(line).setComplete(instr, grx, mode, address)]
    else:
        #return MachineLine("foo")
        return [MachineLine(line).setComplete(instr, grx, mode,0), MachineLine(str(address)).setLiteral(address)]

#Parses a boolean expression to a conditional jump
#Returns None if unsuccesful
def parseBoolExpr(boolexpr):
    #Splitting and finding jumpcode
    jumpcode = -1
    lhs = ""
    rhs = ""
    operatorIndex = -1
    for op in BOOL_OPs:
        operatorIndex = boolexpr.find(op)
        #print("op: ", op, " opi: ", operatorIndex)
        if operatorIndex != -1:
            jumpcode = BOOL_OPs[op]
            lhs = boolexpr[:operatorIndex]
            rhs = boolexpr[operatorIndex+1:]
    if jumpcode == -1:
        return None #Error
    #Checking if needed casts are possible
    try:
        int(lhs)
    except ValueError:
        return None #Error
    #Evaluating to compare
    result = []
    if rhs.startswith(LITERAL_DENOTER): #If RHS is literal
        result.append(MachineLine(boolexpr).setComplete(INSTR_CMP, MODE_IMMEDIATE, int(lhs), 0))
        result.append(MachineLine(rhs).setLiteral(int(rhs[1:]))) #RHS value
    else:
        result.append(MachineLine(boolexpr).setComplete(INSTR_CMP, MODE_DIRECT, int(lhs), int(rhs)))
    #Adding jump
    result.append(JumpIfLine(jumpcode, "Conditional jump"))
    return result

#Returns a list of assembly lines
#Parsing of "end" is handled separetly
#Returns None if an illegal instruction was given
def parseLine(line):
    #IF:s
    if line.startswith(KEYWORD_IF):
        return parseBoolExpr(line[len(KEYWORD_IF):])
    #TODO: Loops
    #Others
    result = lineToCompleteInstruction(line)
    if result is not None:
        return result
    #Unrecognized instruction
    return None

#Removes comments from a line. Keeps trailing \n.
#Returns the string with removed comments
def withoutComment(line):
    if line == "": #No trailing \n => EOF => return as is
        return ""
    result = ""
    for char in line:
        if char == KEYWORD_COMMENT or char == "\n":
            break
        else:
            result += char
    return result + "\n"
            
#Parses the contents of the given file and converts it to lines of bytecode
#Returns a list of those lines
def build(filename):
    with open(filename) as f: #Open file
        result = [] #Contains lines to be printed
        while True:
            line = f.readline().lower()
            line = line.replace("\t", "")
            line = line.replace(" ", "")
            line = withoutComment(line)
            #print("|",line, end="")
            if line == "": #End of file
                break
            if line == "\n": #Empty line TODO: Isn't caught
                continue
            line = line.replace("\n", "") #Remove trailing \n
            
            #Find out if the line modifies a previous instruction, and do the mod
            modified = False
            for instruction in result:
                if instruction.attemptFix(line, len(result)):
                    modified = True
                    break

            if not modified:
                #It's a new instruction/control structure: eval and append.
                instructions = parseLine(line)
                if instructions is None:
                    print("Error: Illegal instruction '", line, "'.")
                    return
                result += instructions
        
        return result
    print("Failed to open ", filename)
    return None

#Adds some fluffs to lines to make them easy to copy-paste into program, and returns it.
#Formatting designed specifically for this project.
def fancifyForVHDL(lines):
    result  = "type p_mem_t is array (0 to " + str(len(lines)) + ") of unsigned(31 downto 0);\n"
    result += "constant p_mem_c : p_mem_t :=\n"
    result += "    (\n"
    result += "        --OP    GRx M  ADRESS\n"
    i = 0
    for line in lines:
        prefix = '        b"' + line.line + '", --'
        newline = prefix
        #TODO: Extend so everyone has the same length
        newline = newline + str(i) + ": " + line.comment + '\n'
        result += newline
        i += 1
    #Extra instruction preventing going out of bounds
    #TODO: Replace with HALT
    result += '        b"' + INSTRUCTION_JUMP_TO_SELF + bitify(len(lines), ADDRESS_WIDTH) + '"\n'
    result += "\n"
    result += "    );"
    return result

def main():
    builded = build(sys.argv[1]) #Build file given by command line
    if builded is None:
        print("Stopped due to errors.")
    else:
        print(fancifyForVHDL(builded))
    

if  __name__ =='__main__':
    main()
