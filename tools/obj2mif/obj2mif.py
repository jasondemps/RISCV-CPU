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

# TODO: Move this file opening to read from cmd line
with open("./file.dis") as f:
    for line in f:
        regMatch = r.search(line)
        if regMatch:
            print(regMatch.group(0))
            opcodes.append((regMatch.group(0), bin(int(regMatch.group(0), 16))))

print(opcodes[1])

