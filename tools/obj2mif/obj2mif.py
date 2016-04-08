import argparse

# Parser Init
# parser = argparse.ArgumentParser()

# # Arguments
# parser.add_argument("obj_file", type=argparse.FileType(), help="Object File to read")
# parser.add_argument("-o", "--output", type=argparse.FileType(), help="Output file")

# # Set up Parser
# args = parser.parse_args()
import re # We REGEX'n
import binascii

#pat = '\s+[0-9]?\s[0-9]?'
pat = '[0-9A-Fa-f]{8}'
r = re.compile(pat)

opcodes = []

BinLen = 32

def Format_Binary(s, maxLen):
    padLen = maxLen - len(s)
    return '0' * padLen + s;

# TODO: Move this file opening to read from cmd line
with open("./file.dis") as f:
    for line in f:
        regMatch = r.search(line)
        if regMatch:
            binVal = Format_Binary(bin(int(regMatch.group(0), 16))[2:], BinLen)
            opcodes.append((regMatch.group(0), binVal))

print(opcodes)

# Values for MIF
#Depth = 32
Depth = len(opcodes)
Width = BinLen
Addr_Radix = 0 # See Radix Table
Data_Radix = 0

# Radix Table
Radix_Table = [ 'BIN', 'HEX', 'OCT', 'DEC' ]

# Generate MIF
with open("./file.mif", "w") as f:
    # Header stuff
    f.write('DEPTH = {0};\nWIDTH = {1};\nADDRESS_RADIX = {2};\nDATA_RADIX = {3};\nCONTENT\nBEGIN\n'.format(
        str(Depth), str(Width), Radix_Table[Addr_Radix], Radix_Table[Data_Radix]))

    # Format of pairs:
    # addr : data
    # TODO: Addr is form 0# in hex!
    for idx, v in enumerate(opcodes):
        f.write('{0} : {1};\n'.format(hex(idx), v[1]))

    f.write('END;')

