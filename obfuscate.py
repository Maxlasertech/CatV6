#!/usr/bin/env python3
import random
import string
import sys
import os

random.seed(os.urandom(16))

SRC = os.path.join(os.path.dirname(__file__), "games", "6872274481.src.lua")
OUT = os.path.join(os.path.dirname(__file__), "games", "6872274481.lua")

with open(SRC, "rb") as f:
    source_bytes = f.read()

key_length = 32
xor_key = bytes([random.randint(1, 255) for _ in range(key_length)])

encoded = bytearray()
for i, b in enumerate(source_bytes):
    encoded.append(b ^ xor_key[i % key_length])

def rand_name(length=8):
    return '_' + ''.join(random.choices(string.ascii_letters, k=length))

v_tonumber = rand_name(9)
v_strsub = rand_name(8)
v_strchar = rand_name(8)
v_tblinsert = rand_name(9)
v_concat = rand_name(7)
v_mathfloor = rand_name(9)
v_i = rand_name(6)
v_byte = rand_name(7)
v_xor_byte = rand_name(8)
v_decoded = rand_name(8)
v_rawdata = rand_name(9)
v_output = rand_name(9)
v_len = rand_name(6)
v_keylen = rand_name(8)
v_func = rand_name(11)
v_err = rand_name(10)
v_protected = rand_name(10)
v_decode_hex = rand_name(11)
v_hex_chunks = rand_name(10)
key_table_name = rand_name(9)

decoys = []
for _ in range(15):
    decoys.append(f"local {rand_name(10)} = {random.randint(1, 99999)}")

decoy_funcs = []
for _ in range(5):
    fname = rand_name(11)
    pname = rand_name(6)
    decoy_funcs.append(f"local function {fname}({pname}) return {pname} end")

key_lua = "{" + ",".join(str(b) for b in xor_key) + "}"
hex_data = encoded.hex()

CHUNK_SIZE = 4000
chunks = [hex_data[i:i+CHUNK_SIZE] for i in range(0, len(hex_data), CHUNK_SIZE)]

lines = []

lines.append("-- Roblox Services Loader v3.2.1")
lines.append("")

random.shuffle(decoys)
for d in decoys[:5]:
    lines.append(d)
lines.append("")

lines.append(f"local {rand_name(10)} = (function()")
lines.append(f"    local {rand_name(5)} = tostring({{}}):sub(1,5)")
lines.append(f"    return true")
lines.append(f"end)()")
lines.append("")

for df in decoy_funcs[:3]:
    lines.append(df)
lines.append("")

for d in decoys[5:10]:
    lines.append(d)
lines.append("")

lines.append(f"local {v_tonumber} = tonumber")
lines.append(f"local {v_strsub} = string.sub")
lines.append(f"local {v_strchar} = string.char")
lines.append(f"local {v_tblinsert} = table.insert")
lines.append(f"local {v_concat} = table.concat")
lines.append(f"local {v_mathfloor} = math.floor")
lines.append("")

lines.append(f"local {key_table_name} = {key_lua}")
lines.append(f"local {v_keylen} = {key_length}")
lines.append("")

lines.append(f"local {v_hex_chunks} = {{")
for chunk in chunks:
    lines.append(f'    "{chunk}",')
lines.append("}")
lines.append("")

for d in decoys[10:]:
    lines.append(d)
lines.append("")
for df in decoy_funcs[3:]:
    lines.append(df)
lines.append("")

lines.append(f"local {v_decode_hex} = function()")
lines.append(f"    local {v_rawdata} = {v_concat}({v_hex_chunks})")
lines.append(f"    local {v_output} = {{}}")
lines.append(f"    local {v_len} = #{v_rawdata}")
lines.append(f"    local {v_i} = 1")
lines.append(f"    local {rand_name(5)} = 0")
lines.append(f"    while {v_i} <= {v_len} do")
lines.append(f"        local {v_byte} = {v_tonumber}({v_strsub}({v_rawdata}, {v_i}, {v_i} + 1), 16)")
lines.append(f"        local {v_xor_byte} = {key_table_name}[(({v_mathfloor}(({v_i} - 1) / 2)) % {v_keylen}) + 1]")
lines.append(f"        local {v_decoded}")
lines.append(f"        if bit32 then")
lines.append(f"            {v_decoded} = bit32.bxor({v_byte}, {v_xor_byte})")
lines.append(f"        else")
lines.append(f"            {v_decoded} = ({v_byte} ~ {v_xor_byte})")
lines.append(f"        end")
lines.append(f"        {v_tblinsert}({v_output}, {v_strchar}({v_decoded}))")
lines.append(f"        {v_i} = {v_i} + 2")
lines.append(f"    end")
lines.append(f"    return {v_concat}({v_output})")
lines.append(f"end")
lines.append("")

lines.append(f"local {v_protected} = {v_decode_hex}()")
lines.append(f"local {v_func}, {v_err} = loadstring({v_protected})")
lines.append(f"if {v_func} then")
lines.append(f"    {v_func}()")
lines.append(f"else")
lines.append(f"    warn({v_err})")
lines.append(f"end")

output = "\n".join(lines) + "\n"

with open(OUT, "w") as f:
    f.write(output)

print(f"Done: {len(source_bytes)} bytes -> {len(output)} bytes")
print(f"Output: {OUT}")
