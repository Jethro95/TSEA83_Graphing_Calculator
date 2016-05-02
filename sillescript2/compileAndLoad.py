
"""
USAGE: python compileAndLoad.py [filename of file to build]
For example: python compileAndLoad.py ../assembly/print_num
"""

import sys
import compiler

START_OF_P_MEM = "-- program Memory"
END_OF_P_MEM = "signal p_mem : p_mem_t := p_mem_c;"
TARGET_FILE = "../src/cpu.vhd"

def loadTo(newCode, targetFilename):
    contents = ""
    with open(targetFilename) as f:
        contents = f.read()
    preCode, rest = contents.split(START_OF_P_MEM)
    code, postCode = rest.split(END_OF_P_MEM)
    newfile = preCode + START_OF_P_MEM + "\n" + newCode + "\n\n" + END_OF_P_MEM  + postCode
    with open(targetFilename, "w") as f:
        f.write(newfile)

def main():
    buildResult = compiler.build(sys.argv[1])
    if buildResult is None:
        print("Stopped due to build errors.")
        return
    result = compiler.fancifyForVHDL(buildResult)
    loadTo(result, TARGET_FILE)

if __name__ == '__main__':
    main()
