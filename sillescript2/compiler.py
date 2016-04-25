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
KEYWORD_END = "end"
KEYWORD_COMMENT = "#"
assert len(KEYWORD_COMMENT) == 1

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

INSTR_CMP = 16 #TODO: Actual code

MODES = {
    "$"    :1, #Immediate
    "~"    :2, #Indirect
} #default when others

#All mode strings must have length 1
for mode in MODES:
    assert (len(mode) == 1)

MODE_DEFAULT = 0 #Direct
MODE_ADRESS_ON_NEXT_LINE = 1 #Immediate

#Jump instructions for bool operators. Note that they are inverted; we jump if expression is false.
BOOL_OPs = {
    ">"     :5, #BMI
    "!"     :4, #BEQ
    "="     :6,  #BNE
}

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
#Placeholder instructions doesn't use these and only contain the instruction segment
def completeInstruction(instruction, grx, mode, address):
    result = bitify(instruction, INSTRUCTION_WIDTH) +BITSEP+ bitify(grx, GRX_WIDTH) +BITSEP+ bitify(mode, MODE_WIDTH) +BITSEP+ bitify(address, ADDRESS_WIDTH)
    assert (len(result) == 3 + WORD_WIDTH)
    return result

def placeholderInstruction(instruction, grx, mode):
    result = bitify(instruction, INSTRUCTION_WIDTH) +BITSEP+ bitify(grx, GRX_WIDTH) +BITSEP+ bitify(mode, MODE_WIDTH) +BITSEP
    assert (len(result) == 3 + WORD_WIDTH - ADDRESS_WIDTH)
    return result

def arg(line, instructionString):
    return int(line[len(instructionString):])

#Parses a regular line to an instruction
#Returns None if unsuccesful
def lineToCompleteInstruction(line):
    #Instructiom
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
        print("B")
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
        return [completeInstruction(instr, grx, mode, address)]
    else:
        return [completeInstruction(instr, grx, mode, 0), bitify(address, WORD_WIDTH)]


#Parses a boolean expression to a conditional jump
#Returns None if unsuccesful
def parseBoolExpr(boolexpr):
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
            rhs = boolexpr[operatorIndex:]
    if jumpcode == -1:
        return None #Error
    result = []
    result.append(completeInstruction(INSTR_CMP, 0, 0, 0)) #TODO: LHS
    result.append(placeholderInstruction(jumpcode, 0, 0))
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
#  Returns the string with removed comments
def withoutComment(line):
    if line == "": #No trailing \n => EOF => return as is
        return ""
    result = ""
    for char in line:
        if char == KEYWORD_COMMENT:
            break
        else:
            result += char
    return result + "\n"
            

def build(filename):
    with open(filename) as f: #Open file
        result = [] #Contains lines to be printed
        placeHolderIndexStack = [] #Contains indexes to lines that needs to change when reaching an "END" line
        while True:
            line = f.readline().lower()
            line = line.replace("\t", "")
            line = line.replace(" ", "")
            line = withoutComment(line)
            #print("|",line, end="")
            if line == "": #End of file
                break
            elif line == "\n": #Empty line TODO: Isn't caught
                continue
            line = line.replace("\n", "") #Remove trailing \n
            
            if not line.startswith(KEYWORD_END): #If instruction can be parsed by parseLine()...
                instructions = parseLine(line)
                if instructions is None:
                    print("Error: Illegal instruction '", line, "'.")
                    return
                #If we were given an instruction missing argument...
                for i, instruction in enumerate(instructions):
                    if len(instruction) < WORD_WIDTH: #Still works with a few "_" thrown in, luckily. TODO: Somehow make finding these spots not depend on string length
                        placeHolderIndexStack.append(len(result) + i) #Append index of coming instruction
                result += (instructions)
            else:
                #We've got an "end". Append next line as argument for placeholder instruction on stack.
                if len(placeHolderIndexStack) == 0:
                    print('Error: Trailing "', KEYWORD_END, '"')
                    return
                index = placeHolderIndexStack.pop()
                #TODO:Not really working
                result[index] += bitify(len(result), ADDRESS_WIDTH) #Append next line as argument (to jump to) 
                #TODO: actual memory location instead
        
        return result
    print("Failed to open ", filename)
    return None

#Adds some fluffs to lines to make them easy to copy-paste into program, and returns it.
#Designed for this project, and this project only.
def fancifyForVHDL(lines):
    result = "type p_mem_t is array (0 to " + str(len(lines)-1) + ") of unsigned(31 downto 0);\n"
    result += "constant p_mem_c : p_mem_t :=\n"
    result += "    (\n"
    result += "        --OP   GRx M  ADRESS\n"
    for line in lines:
        result += '        b"' + line + '",\n'
    result = result[:len(result)-2] #Remove last ,\n
    result += "\n"
    result += "    );\n"
    return result

def main():
    builded = build(sys.argv[1]) #Build file given by command line
    print(fancifyForVHDL(builded))
    

if  __name__ =='__main__':
    main()
