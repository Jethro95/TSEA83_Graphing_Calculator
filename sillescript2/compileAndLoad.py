
"""
USAGE: python compileAndLoad.py [filename of file to build]
For example: python compileAndLoad.py ../assembly/print_num
"""

import sys
import compiler

START_OF_P_MEM = "-- program Memory"
END_OF_P_MEM = "signal p_mem : p_mem_t := p_mem_c;"
START_OF_PM_LIMITER = "when ASR <"
END_OF_PM_LIMITER = "else (others =>"
TARGET_FILE = "../src/cpu.vhd"

def loadTo(newCode, linecount, targetFilename):
    contents = ""
    with open(targetFilename) as f:
        contents = f.read()
    preCode, rest = contents.split(START_OF_P_MEM)
    code, postCode = rest.split(END_OF_P_MEM)
    newfile = preCode + START_OF_P_MEM + "\n" + newCode + "\n\n" + END_OF_P_MEM  + postCode

    # Also limit for which ASR PM is set.
    preCode, rest = newfile.split(START_OF_PM_LIMITER)
    code, postCode = rest.split(END_OF_PM_LIMITER)
    newfile = preCode + START_OF_PM_LIMITER + str(linecount) +" " + END_OF_PM_LIMITER  + postCode
    with open(targetFilename, "w") as f:
        f.write(newfile)

def main():
    buildResult = compiler.build(sys.argv[1])
    if buildResult is None:
        print("Stopped due to build errors.")
        return
    result = compiler.fancifyForVHDL(buildResult)
    loadTo(result, len(buildResult), TARGET_FILE)

if __name__ == '__main__':
    main()
