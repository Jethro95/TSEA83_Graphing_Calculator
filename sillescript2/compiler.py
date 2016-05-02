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
end if

while <comparison>
  <Do stuff>
end while

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

You can also use labels.
Define a label by writing "LABEL_BAME :" at the start of your line to label
  that line with the given name
To reference a label in an instruction or a boolean expression, use & as a prefix.
Note that trying to use labels with immediate addresses is currently unimplemented
  and will therefore yield and error.

Comments are written after #'s

SLI is an additional supported instruction. It only takes one argument, as opposed
  to all others. It sets the line to the value given.
Example usage
  SLI 0 #Sets the line to all zeroes
  SLI 1337 #Sets the line to the unsigned representation of 1337
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
KEYWORD_WHILE = "while"
KEYWORD_END_IF = "endif"
KEYWORD_ELSE = "else" 
KEYWORD_END_WHILE = "endwhile"
KEYWORD_COMMENT = "#"
assert len(KEYWORD_COMMENT) == 1

#A list of keywords that will produce an error if they 
#  do not complete the argument of a previous line
KEYWORDS_MUST_MODIFY = [KEYWORD_END_IF, KEYWORD_ELSE, KEYWORD_END_WHILE]

#Boolean expression evaluated to BRA
KEYWORD_TRUE = "true"

#Character used to denote literals in bool expressions
LITERAL_DENOTER = "$"
#Character used to denote label names anywhere
LABEL_DENOTER = "&"

assert (len(LITERAL_DENOTER) == len(LABEL_DENOTER) == 1)

#Char used for label definitions
LABEL_DEFINITION = ":"

assert (len(LABEL_DEFINITION) == 1)

#Instructions and the numbers for their respective instructions in bytecode
INSTRUCTIONS = {
    "load"        :1, 
    "store"       :2, 
    "add"         :9, 
    "addf"        :10, 
    "sub"         :11, 
    "subf"        :12, 
    "multf"       :13,
    "divf"        :14, 
    "and"         :15,
    "asl"         :16,
    "asr"         :17,
    "itr"         :18,
    "rti"         :19,
    "jmp"         :20,
    "lsr"         :21,
    "lsl"         :22,
    "storep"      :23,
    "rc"          :24
}

#The compare instruction
INSTR_CMP = 25
#The jump instruction
INSTR_JMP = 20

#A special instruction that sets the bytecode line to the single
#   value given as an argument. Only takes one argument; no commas.
SPECIAL_INSTR_SET_LINE = "sli"

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

#Jump instructions for bool operators. Note that they are inverted; we jump if expression is false.
BOOL_OPs = {
    "<"     :8, #BPL
    ">"     :5, #BMI
    "!"     :4, #BEQ
    "="     :6  #BNE
}

for op in BOOL_OPs:
    assert (len(op) == 1)

#For while-true loops
INSTR_BRA = 3

#Desired length for rows in output
#Recommended to be larger than 47
#Lines will only be extended; a value of 0 will not remove lines.
FANCIFY_DESIRED_LENGTH = 50


#========================================================================================
#   CODE
#========================================================================================

#Converts integer to bitstring of length bitCount
def bitify(num, bitcount):
    if num >= 0:
        bitstring = bin(int(num))
        bitstring = bitstring[bitstring.find("b")+1:] #Cutting of 0b and occasionally -0b. Dunno why - shows up.
        while len(bitstring) < bitcount:
            bitstring = "0" + bitstring
        return bitstring[:bitcount]
    else:
        #It's two's complement =>
        #take abs(num), add one, get the bit representation of that
        #  and then invert all bits in the resulting array. BAM.
        inverted = bitify(abs(num) + 1, bitcount)
        result = ""
        for bit in inverted:
            if bit == "0":
                result += "1"
            elif bit == "1":
                result += "0"
            else:
                assert (False) #Unreachable, hopefully
        return result
        

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

    #The bytecode
    line = ""
    #Comment after the bytecode
    comment = ""
    #The alias of this line
    label = ""
    #The label the argument part is targetting
    #  While "", this is not looking for a label
    labelArgument = ""

    #Returns True if the line is waiting for replacing
    #  it's argument with a label
    def waitingForLabelExpansion(self):
        return self.labelArgument != ""

    #Replaces label-arguments with actual addresses
    #dictionary is a dict from label names (str) to bytecode addresses (int)
    #Returns false if label-argument was not in dict, true otherwise
    def expandLabels(self, dictionary):
        if not self.waitingForLabelExpansion():
            return True
        elif self.labelArgument not in dictionary:
            return False
        else:
            address = dictionary[self.labelArgument]
            self.line = self.line + bitify(address, ADDRESS_WIDTH)
            labelArgument = ""
            return True

    #Returns a label the line wants to have expanded, or None
    #  if it is not waiting to expand any.
    def getLabelArgument():
        return labelArgument if labelArgument != "" else None
        

    #Attempt to fill out the instruction based on previous line
    #Sourceline is the assembler line to react to, lineNum its bytecode line number
    #Modifies itself, returns success, and new lines to insert at lineNum. None if no new.
    def attemptFix(self, sourceLine, lineNum):
        return False, None

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

    #Sets the line to a complete instruction with label address argument
    def setIncompleteLabel(self, instruction, grx, mode, label):
        self.line = placeholderInstruction(instruction, grx, mode)
        self.labelArgument = label
        return self

    def __init__(self, comment):
        self.line = ""
        self.label = ""
        self.labelArgument = ""
        self.comment = comment

#Represents a line with an incomplete jump, to be completed by a later keyword
class IncompleteJumpLine(MachineLine):
    complete = False
    lineDefinedAt = -1

     #Fills out instruction with proper address
    def fillOut(self, jumpTarget):
        self.line += bitify(jumpTarget-self.lineDefinedAt-1, ADDRESS_WIDTH)
        self.complete = True

    def __init__(self, comment, currentLine):
        MachineLine.__init__(self, comment)
        self.complete = False
        self.lineDefinedAt = currentLine

#The incomplete line that takes the place of an "else"
class JumpElseLine(IncompleteJumpLine):

    #Fills out instruction with a jump
    def attemptFix(self, sourceLine, lineNum):
        if not self.complete and sourceLine.startswith(KEYWORD_END_IF):
            #Jump to keywords next line, no new lines
            self.fillOut(lineNum)
            return True, None
        return False, None

    def __init__(self, comment, currentLine):
        IncompleteJumpLine.__init__(self, comment, currentLine)
        self.setIncomplete(INSTR_BRA, 0, MODE_DIRECT)
        self.complete = False
        self.lineDefinedAt = currentLine

#The incomplete line that takes the place of an "if"
class JumpIfLine(IncompleteJumpLine):

    #Fills out instruction with a jump
    def attemptFix(self, sourceLine, lineNum):
        if not self.complete:
            if sourceLine.startswith(KEYWORD_END_IF):
                #Jump to keywords next line, no new lines
                self.fillOut(lineNum)
                return True, None
            elif sourceLine.startswith(KEYWORD_ELSE):
                #Add a line that jumps to the next end.
                #Evertything below that will be the else.
                #Make sure this line jumps one below that line on False.
                self.fillOut(lineNum+1)
                newline = JumpElseLine("Else section below. Jump past.", lineNum)
                return True, [newline]
        return False, None

    def __init__(self, instruction, comment, currentLine):
        IncompleteJumpLine.__init__(self, comment, currentLine)
        self.setIncomplete(instruction, 0, MODE_DIRECT)
        self.complete = False
        self.lineDefinedAt = currentLine

#The incomplete line that takes the place of a "while"
class JumpWhileLine(JumpIfLine):
    #How many lines the respective compare takes
    cmpOffset = -1

    #Fills out instruction with a jump, and appends a jump to this line
    #  at the next end
    def attemptFix(self, sourceLine, lineNum):
        #print(sourceLine)
        if not self.complete and sourceLine.startswith(KEYWORD_END_WHILE):
            self.fillOut(lineNum+1)#We will add an extra instruction: jump past it
            #Instruction to jump to one line before the conditional jump; the compare.
            newline = MachineLine("Jump to loop compare").setComplete(INSTR_JMP, 0, MODE_DIRECT, self.lineDefinedAt-self.cmpOffset)
            return True, [newline]
        return False, None

    def __init__(self, instruction, comment, currentLine, cmpIsTwoLines):
        JumpIfLine.__init__(self, instruction, comment, currentLine)
        self.cmpOffset = 2 if cmpIsTwoLines else 1
    

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
    #Checking for label or literal/address
    addressUsesLabel = False
    address = None
    if restOfLine.startswith(LABEL_DENOTER):
        #Label
        addressUsesLabel = True
        address = restOfLine[1:]
    else:
        #Actual address
        try:
            address = int(restOfLine)
        except ValueError:
            return None
    #Putting together
    if addressUsesLabel:
        if mode == MODE_ADRESS_ON_NEXT_LINE:
            return None #Labels incompatible with adress on next line
        return [MachineLine(line).setIncompleteLabel(instr, grx, mode, address)]
    elif not addressOnNextLine:
        return [MachineLine(line).setComplete(instr, grx, mode, address)]
    else:
        return [MachineLine(line).setComplete(instr, grx, mode,0), MachineLine(str(address)).setLiteral(address)]

#Parses a boolean expression
#Returns (success, jumpcode, grx, isLiteral, isLabel, literal/address/label)
def parseBoolExpr(boolexpr):
    #True is a special case...
    if boolexpr == KEYWORD_TRUE:
        #Return success, tell them to jump with INSTR_BRA
        #TODO: GRx=0,arg=0 generates a useless CMP
        #        Still works, but ineffiecent.
        return (True, INSTR_BRA, 0, False, False, 0)
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
        return (False,0,0,False,False,0) #Error
    #Checking if needed casts are possible
    try:
        int(lhs)
    except ValueError:
        return (False,0,0,False,False,0) #Error
    #Return result
    if rhs.startswith(LITERAL_DENOTER):
        return (True, jumpcode, int(lhs), True, False, int(rhs[1:]))
    elif rhs.startswith(LABEL_DENOTER):
        return (True, jumpcode, int(lhs), True, True, int(rhs[1:]))
    else:
        return (True, jumpcode, int(lhs), False, False, int(rhs))

#Returns the compare instructions for given inputs
def conditionCompare(grx, isLiteral, isLabel, arg, comment):
    result = []
    if isLiteral: #If RHS is literal
        result.append(MachineLine(comment).setComplete(INSTR_CMP, grx, MODE_IMMEDIATE, 0))
        result.append(MachineLine(str(arg)).setLiteral(arg)) #RHS value
    elif isLabel:
        result.append(MachineLine(comment).setIncompleteLabel(INSTR_CMP, grx, MODE_DIRECT, arg))
    else: #It's address
        result.append(MachineLine(comment).setComplete(INSTR_CMP, grx, MODE_DIRECT, arg))
    return result

#Parses a boolean expression to a conditional jump
#Returns None if unsuccesful
def parseBoolExprForIf(boolexpr, currentBytecodeLinum):
    success, jumpcode, grx, isLiteral, isLabel, arg = parseBoolExpr(boolexpr)
    if not success:
        return None
    #Evaluating to compare
    result = conditionCompare(grx, isLiteral, isLabel, arg, "cmp " + boolexpr)
    #Adding jump
    result.append(JumpIfLine(jumpcode, "Conditional jump for if", currentBytecodeLinum+len(result)))
    return result

#Parses a boolean expression to a conditional jump for a while-structure
#Returns None if unsuccesful
def parseBoolExprForWhile(boolexpr, currentBytecodeLinum):
    success, jumpcode, grx, isLiteral, isLabel, arg = parseBoolExpr(boolexpr)
    if not success:
        return None
    #Evaluating to compare
    result = conditionCompare(grx, isLiteral, isLabel, arg, "cmp " + boolexpr)
    #Adding jump
    result.append(JumpWhileLine(jumpcode, "Conditional jump for while", currentBytecodeLinum+len(result), len(result) == 2))
    return result

#Input is a line without any label definitions
#Returns a list of assembly lines
#Parsing of "end" is handled separetly
#Returns None if an illegal instruction was given
def parseLine(line, currentBytecodeLinum):
    #IF:s
    if line.startswith(KEYWORD_IF):
        return parseBoolExprForIf(line[len(KEYWORD_IF):], currentBytecodeLinum)
    #Loops
    if line.startswith(KEYWORD_WHILE):
        return parseBoolExprForWhile(line[len(KEYWORD_WHILE):], currentBytecodeLinum)
    #Special instructions
    if line.startswith(SPECIAL_INSTR_SET_LINE):
        try:
            value = int(line[len(SPECIAL_INSTR_SET_LINE):])
        except ValueError:
            return None
        return [MachineLine("Line initialized to " + str(value)).setLiteral(value)]
    #Others
    result = lineToCompleteInstruction(line)
    if result is not None:
        return result
    #Unrecognized instruction
    return None

#Removes the label portion of a line.
#Returns (newline, label) where newline is the line without the label.
#label is a string, though None if non-existant
def extractLabel(line):
    if LABEL_DEFINITION not in line:
        return (line, None)
    index = line.find(LABEL_DEFINITION)
    return (line[index+1:], line[:index])


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
        labels = {} #Contains found label definitions
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
            line, label = extractLabel(line)

            if line == "":
                print("Error: Empty line after label", label, "definition.")
                return
            elif label == "":
                print("Error: Empty label on line", line,".")
                return
            elif label is not None:
                if label in labels:
                    print("Error: Multiple definitions of label", label, ".")
                    return
                #Associate next bytecode line with given label
                labels[label] = len(result)
            
            #Find out if the line modifies a previous instruction, and do the mod
            modified = False
            for instruction in reversed(result):
                success, newlines = instruction.attemptFix(line, len(result))
                if success:
                    modified = True
                    #Insert new instructions
                    if newlines is not None:
                        result += newlines
                    break

            #If the line SHOULD'VE changed a previous line argument
            if not modified and line in KEYWORDS_MUST_MODIFY:
                print("Error: trailing", line, ".")
                return

            if not modified:
                #It's a new instruction/control structure: eval and append.
                instructions = parseLine(line, len(result))
                if instructions is None:
                    print("Error: Illegal instruction '", line, "'.")
                    return
                result += instructions
        
        #Replace label references with actual addresses
        for line in result:
            if not line.expandLabels(labels):
                print("Error: label '", line.getLabelArgument(), "' referenced but not defined.")
                return

        return result
    print("Failed to open ", filename)
    return None

#Adds some fluffs to lines to make them easy to copy-paste into program, and returns it.
#Formatting designed specifically for this project.
def fancifyForVHDL(lines):
    result  = "type p_mem_t is array (0 to " + str(len(lines)-1) + ") of unsigned(31 downto 0);\n"
    result += "constant p_mem_c : p_mem_t :=\n"
    result += "    (\n"
    result += "        --OP    GRx M  ADRESS\n"
    i = 0
    for line in lines:
        prefix = '        b"' + line.line + '"'
        #Add comma unless we are on last line
        prefix += " " if i+1 == len(lines) else ","
        newline = prefix
        #Extend newline to desired length
        while len(newline) < FANCIFY_DESIRED_LENGTH:
            newline += " "
        #Add comment and \n
        newline += " --" + str(i) + ": " + line.comment + '\n'
        #Append to result
        result += newline
        i += 1
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
