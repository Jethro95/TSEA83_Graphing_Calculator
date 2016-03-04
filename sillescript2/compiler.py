import sys

"""
SYNTAX EXPLANATION

Update this section as syntax changes.

Instructions are separated by newline
Assembly instructions are written as:
  INSTR_NAME INSTR_ARG
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

WORD_WIDTH = 4 #Bytes
INSTRUCTION_WIDTH = 1 #Bytes 
ARGUMENT_WIDTH = WORD_WIDTH - INSTRUCTION_WIDTH

KEYWORD_IF = "if"
KEYWORD_END = "end"
KEYWORD_COMMENT = "#"
assert len(KEYWORD_COMMENT) == 1

INSTR_BRA = 0
INSTR_BRA_S = "bra"

#========================================================================================
#   CODE
#========================================================================================

#Converts an int to a properly formatted hex string of length byteCount
def hexify(num, byteCount):
    hx = hex(int(num))[2:] #Hex code, we'll need to add zeroes
    return ('0' * (2*byteCount-len(hx))) + hx

#Converts a full instruction to bytecode.
#Placeholder instructions doesn't use these and only contain the instruction segment
def completeInstruction(instruction, argument):
    return hexify(instruction, INSTRUCTION_WIDTH) + hexify(argument, ARGUMENT_WIDTH)

def placeholderInstruction(instruction):
    return hexify(instruction, INSTRUCTION_WIDTH)

def arg(line, instructionString):
    return int(line[len(instructionString):])

def lineToCompleteInstruction(line, instruction, instructionString):
    return completeInstruction(instruction, arg(line, instructionString))

#Returns an assembly line
#Parsing of "end" is handled separetly
#Returns None if an illegal instruction was given
def parseLine(line):
    if line.startswith(KEYWORD_IF):
        #TODO: Find and use proper GOTO
        #Note that we should jump on !<given expression>
        return placeholderInstruction(INSTR_BRA)
    #TODO: Loops
    if line.startswith(INSTR_BRA_S):
        return lineToCompleteInstruction(line, INSTR_BRA, INSTR_BRA_S)
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
            

def main():
    with open(sys.argv[1]) as f: #Open file given in command line
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
                instruction = parseLine(line)
                if instruction is None:
                    print("Error: Illegal instruction '", line, "'.")
                    return
                if len(instruction) < 2*WORD_WIDTH: #If we were given an instruction missing argument
                    placeHolderIndexStack.append(len(result)) #Append index of coming instruction
                result.append(instruction)
            else:
                #We've got an "end". Append next line as argument for placeholder instruction on stack.
                if len(placeHolderIndexStack) == 0:
                    print('Error: Trailing "', KEYWORD_END, '"')
                    return
                index = placeHolderIndexStack.pop()
                result[index] += hexify(len(result), ARGUMENT_WIDTH) #Append next line as argument (to jump to) 
                #TODO: actual memory location instead
        
        for line in result:
            print(line)
            
    

if  __name__ =='__main__':
    main()
