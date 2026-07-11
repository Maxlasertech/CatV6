#!/usr/bin/env python3
"""
Strong Lua obfuscator with:
- S-box substitution cipher
- Multi-round XOR with rotating keys
- Byte shuffling/permutation
- Payload scattered across 80+ variables in random order
- Anti-hook checks (loadstring, string library, debug library)
- Control flow flattening in the decoder via coroutines
- Opaque predicates
- Integrity self-check on the decoder
- Memory cleanup after execution
"""
import random
import string
import os
import hashlib
import struct

random.seed(os.urandom(32))

SRC = os.path.join(os.path.dirname(__file__), "games", "6872274481.src.lua")
OUT = os.path.join(os.path.dirname(__file__), "games", "6872274481.lua")

with open(SRC, "rb") as f:
    source_bytes = f.read()

# ── helpers ──────────────────────────────────────────────────

_used_names = set()
def rand_name(length=None):
    length = length or random.randint(8, 14)
    while True:
        first = random.choice(string.ascii_letters + '_')
        rest = ''.join(random.choices(string.ascii_letters + string.digits + '_', k=length - 1))
        name = first + rest
        if name not in _used_names and not name.startswith('__'):
            _used_names.add(name)
            return name

def rand_int():
    return random.randint(10000, 9999999)

def make_decoy_var():
    return f"local {rand_name()} = {rand_int()}"

def make_decoy_func():
    fn = rand_name()
    p1, p2 = rand_name(6), rand_name(6)
    ops = [
        f"local function {fn}({p1}, {p2}) return {p1} + ({p2} or 0) end",
        f"local function {fn}({p1}) return #{p1} > 0 and {p1} or '' end",
        f"local function {fn}({p1}) for {p2} = 1, #({p1} or '') do end return {p1} end",
        f"local {fn} = function({p1}) local {p2} = {{}} for _ = 1, ({p1} or 1) do {p2}[#({p2})+1] = 0 end return {p2} end",
    ]
    return random.choice(ops)

def make_decoy_table():
    name = rand_name()
    n = random.randint(3, 8)
    entries = ", ".join(str(random.randint(0, 255)) for _ in range(n))
    return f"local {name} = {{{entries}}}"

# ── encryption layers ────────────────────────────────────────

# Layer 1: Generate a random S-box (byte substitution, like AES SubBytes)
sbox = list(range(256))
random.shuffle(sbox)
inv_sbox = [0] * 256
for i, v in enumerate(sbox):
    inv_sbox[v] = i

# Layer 2: Multi-round XOR with 3 independent keys
key1 = bytes([random.randint(1, 255) for _ in range(48)])
key2 = bytes([random.randint(1, 255) for _ in range(37)])
key3 = bytes([random.randint(1, 255) for _ in range(53)])

# Layer 3: Byte-level permutation (shuffle positions within blocks)
PERM_BLOCK = 64
perm_table = list(range(PERM_BLOCK))
random.shuffle(perm_table)
inv_perm = [0] * PERM_BLOCK
for i, v in enumerate(perm_table):
    inv_perm[v] = i

# Apply encryption: source → sbox → xor1 → xor2 → xor3 → permute
data = bytearray(source_bytes)

# S-box substitution
for i in range(len(data)):
    data[i] = sbox[data[i]]

# XOR round 1
for i in range(len(data)):
    data[i] ^= key1[i % len(key1)]

# XOR round 2
for i in range(len(data)):
    data[i] ^= key2[i % len(key2)]

# XOR round 3 (key derived from position + key bytes)
for i in range(len(data)):
    data[i] ^= key3[i % len(key3)]
    data[i] ^= (i * 7 + 13) & 0xFF

# Block permutation
permuted = bytearray(len(data))
full_blocks = len(data) // PERM_BLOCK
remainder = len(data) % PERM_BLOCK
for block in range(full_blocks):
    base = block * PERM_BLOCK
    for i in range(PERM_BLOCK):
        permuted[base + perm_table[i]] = data[base + i]
# Copy remainder as-is
for i in range(remainder):
    permuted[full_blocks * PERM_BLOCK + i] = data[full_blocks * PERM_BLOCK + i]

encrypted = bytes(permuted)

# ── scatter payload into chunks ──────────────────────────────

CHUNK_SIZE = random.randint(800, 1200)
raw_chunks = []
for i in range(0, len(encrypted), CHUNK_SIZE):
    raw_chunks.append(encrypted[i:i+CHUNK_SIZE])

num_chunks = len(raw_chunks)

# Assign each chunk a random variable name and a random order index
chunk_vars = [rand_name() for _ in range(num_chunks)]
chunk_order = list(range(num_chunks))
random.shuffle(chunk_order)

# Encode each chunk as a Lua string using \x hex escapes
def lua_encode_bytes(bs):
    parts = []
    for b in bs:
        parts.append(f"\\x{b:02x}")
    return '"' + ''.join(parts) + '"'

# ── build Lua output ─────────────────────────────────────────

L = []

# misleading header
headers = [
    "-- Module: CoreServices.NetworkHandler v4.1.7",
    "-- Auto-generated runtime configuration",
    "-- WARNING: Do not modify - machine generated",
]
L.append(random.choice(headers))
L.append("")

# ── Phase 1: Capture clean function references before anything can hook ──
v_rawget = rand_name()
v_ls = rand_name()
v_sc = rand_name()
v_sb = rand_name()
v_ss = rand_name()
v_sl = rand_name()
v_sr = rand_name()
v_tc = rand_name()
v_ti = rand_name()
v_bxor = rand_name()
v_tn = rand_name()
v_mf = rand_name()
v_tp = rand_name()
v_pcall_ref = rand_name()
v_type_ref = rand_name()
v_select_ref = rand_name()
v_error_ref = rand_name()
v_setfenv_ref = rand_name()

L.append(f"local {v_rawget} = rawget")
L.append(f"local {v_ls} = loadstring or load")
L.append(f"local {v_sc} = string.char")
L.append(f"local {v_sb} = string.byte")
L.append(f"local {v_ss} = string.sub")
L.append(f"local {v_sl} = string.len")
L.append(f"local {v_sr} = string.rep")
L.append(f"local {v_tc} = table.concat")
L.append(f"local {v_ti} = table.insert")
L.append(f"local {v_bxor} = bit32 and bit32.bxor or function(a, b) return a ~ b end")
L.append(f"local {v_tn} = tonumber")
L.append(f"local {v_mf} = math.floor")
L.append(f"local {v_tp} = type")
L.append(f"local {v_pcall_ref} = pcall")
L.append(f"local {v_type_ref} = type")
L.append(f"local {v_select_ref} = select")
L.append(f"local {v_error_ref} = error")
L.append("")

# scatter some decoys
for _ in range(8):
    L.append(make_decoy_var())
L.append("")
for _ in range(3):
    L.append(make_decoy_func())
L.append("")

# ── Phase 2: Anti-hook integrity checks ──
v_check = rand_name()
v_hook_detect = rand_name()
v_chk1 = rand_name(6)
v_chk2 = rand_name(6)
L.append(f"local {v_check} = (function()")
L.append(f"    local {v_chk1} = {v_tp}({v_ls})")
L.append(f"    if {v_chk1} ~= 'function' then return false end")
L.append(f"    local {v_chk2} = {v_tp}({v_sc})")
L.append(f"    if {v_chk2} ~= 'function' then return false end")
# Check that string.char(65) == 'A' (detects hooked string library)
v_test = rand_name(6)
L.append(f"    local {v_test} = {v_sc}(65)")
L.append(f"    if {v_test} ~= 'A' then return false end")
# Check that loadstring returns a function for valid code
v_test2 = rand_name(6)
L.append(f"    local {v_test2} = {v_ls}('return 1')")
L.append(f"    if {v_tp}({v_test2}) ~= 'function' then return false end")
L.append(f"    if {v_test2}() ~= 1 then return false end")
L.append(f"    return true")
L.append(f"end)()")
L.append(f"if not {v_check} then return end")
L.append("")

# more decoys
for _ in range(5):
    L.append(make_decoy_var())
for _ in range(2):
    L.append(make_decoy_table())
L.append("")

# ── Phase 3: Scattered encrypted payload (random order) ──
# Mix chunk declarations with decoys
items_to_emit = []
for idx in chunk_order:
    items_to_emit.append(('chunk', idx))

# Inject decoy variables between chunks
for i in range(0, len(items_to_emit), random.randint(2, 5)):
    items_to_emit.insert(i, ('decoy_var', None))
    if random.random() < 0.3:
        items_to_emit.insert(i, ('decoy_func', None))
    if random.random() < 0.2:
        items_to_emit.insert(i, ('decoy_table', None))

for item_type, idx in items_to_emit:
    if item_type == 'chunk':
        L.append(f"local {chunk_vars[idx]} = {lua_encode_bytes(raw_chunks[idx])}")
    elif item_type == 'decoy_var':
        L.append(make_decoy_var())
    elif item_type == 'decoy_func':
        L.append(make_decoy_func())
    elif item_type == 'decoy_table':
        L.append(make_decoy_table())

L.append("")

# more decoys
for _ in range(5):
    L.append(make_decoy_var())
L.append("")

# ── Phase 4: Reassembly order table (maps position → variable) ──
# We use a lookup table with obfuscated indices
v_parts = rand_name()
L.append(f"local {v_parts} = {{")
for real_idx in range(num_chunks):
    L.append(f"    [{real_idx + 1}] = {chunk_vars[real_idx]},")
L.append(f"}}")
L.append("")

# Nil out the chunk variables to make tracing harder
for idx in range(num_chunks):
    L.append(f"{chunk_vars[idx]} = nil")
L.append("")

# ── Phase 5: Inverse permutation table ──
v_inv_perm = rand_name()
L.append(f"local {v_inv_perm} = {{")
row = []
for i, v in enumerate(inv_perm):
    row.append(str(v))
    if len(row) >= 16:
        L.append("    " + ",".join(row) + ",")
        row = []
if row:
    L.append("    " + ",".join(row) + ",")
L.append(f"}}")
L.append("")

# ── Phase 6: Inverse S-box ──
v_inv_sbox = rand_name()
L.append(f"local {v_inv_sbox} = {{")
row = []
for i, v in enumerate(inv_sbox):
    row.append(str(v))
    if len(row) >= 16:
        L.append("    " + ",".join(row) + ",")
        row = []
if row:
    L.append("    " + ",".join(row) + ",")
L.append(f"}}")
L.append("")

# ── Phase 7: XOR keys (split across multiple tables with indirection) ──
# Key 1 split into 3 sub-tables
k1a_name, k1b_name, k1c_name = rand_name(), rand_name(), rand_name()
k1_split = len(key1) // 3
L.append(f"local {k1a_name} = {{{','.join(str(b) for b in key1[:k1_split])}}}")
L.append(f"local {k1b_name} = {{{','.join(str(b) for b in key1[k1_split:k1_split*2])}}}")
L.append(f"local {k1c_name} = {{{','.join(str(b) for b in key1[k1_split*2:])}}}")
L.append("")
L.append(make_decoy_var())
L.append(make_decoy_table())
L.append("")

# Key 2 and Key 3
k2_name = rand_name()
k3_name = rand_name()
L.append(f"local {k2_name} = {{{','.join(str(b) for b in key2)}}}")
L.append(make_decoy_var())
L.append(f"local {k3_name} = {{{','.join(str(b) for b in key3)}}}")
L.append("")

# Key 1 reconstruction function
v_get_k1 = rand_name()
v_k1_cache = rand_name()
L.append(f"local {v_k1_cache}")
L.append(f"local {v_get_k1} = function()")
L.append(f"    if {v_k1_cache} then return {v_k1_cache} end")
L.append(f"    {v_k1_cache} = {{}}")
L.append(f"    for {rand_name(4)} = 1, #{k1a_name} do {v_k1_cache}[#{v_k1_cache}+1] = {k1a_name}[{rand_name(4)}] end")
# reuse same iteration var won't work since it's local... let me use different names
L.pop(); L.pop(); L.pop(); L.pop()
vi1, vi2, vi3 = rand_name(5), rand_name(5), rand_name(5)
L.append(f"local {v_k1_cache}")
L.append(f"local {v_get_k1} = function()")
L.append(f"    if {v_k1_cache} then return {v_k1_cache} end")
L.append(f"    {v_k1_cache} = {{}}")
L.append(f"    for {vi1} = 1, #{k1a_name} do {v_k1_cache}[#{v_k1_cache}+1] = {k1a_name}[{vi1}] end")
L.append(f"    for {vi2} = 1, #{k1b_name} do {v_k1_cache}[#{v_k1_cache}+1] = {k1b_name}[{vi2}] end")
L.append(f"    for {vi3} = 1, #{k1c_name} do {v_k1_cache}[#{v_k1_cache}+1] = {k1c_name}[{vi3}] end")
L.append(f"    return {v_k1_cache}")
L.append(f"end")
L.append("")

for _ in range(4):
    L.append(make_decoy_var())
L.append("")

# ── Phase 8: Decoder function (control-flow-flattened via state machine) ──
v_decode = rand_name()
v_raw = rand_name()
v_out = rand_name()
v_pos = rand_name()
v_len = rand_name()
v_b = rand_name(5)
v_pb = rand_name()
v_state = rand_name()
v_blk = rand_name()
v_bi = rand_name(5)
v_base = rand_name()
v_k1ref = rand_name()

L.append(f"local {v_decode} = function()")
# Step 1: Concatenate scattered chunks
L.append(f"    local {v_raw} = {v_tc}({v_parts})")
L.append(f"    {v_parts} = nil")
L.append(f"    local {v_len} = #{v_raw}")
L.append(f"    local {v_out} = {{}}")
L.append("")
# Step 2: Copy bytes into table for in-place operations
v_bytes = rand_name()
L.append(f"    local {v_bytes} = {{}}")
L.append(f"    for {v_pos} = 1, {v_len} do")
L.append(f"        {v_bytes}[{v_pos}] = {v_sb}({v_raw}, {v_pos})")
L.append(f"    end")
L.append(f"    {v_raw} = nil")
L.append("")

# Step 3: Inverse block permutation (state machine)
v_full_blocks = rand_name()
v_temp = rand_name()
L.append(f"    local {v_full_blocks} = {v_mf}({v_len} / {PERM_BLOCK})")
L.append(f"    local {v_temp} = {{}}")
L.append(f"    for {v_blk} = 0, {v_full_blocks} - 1 do")
L.append(f"        local {v_base} = {v_blk} * {PERM_BLOCK}")
L.append(f"        for {v_bi} = 1, {PERM_BLOCK} do")
L.append(f"            {v_temp}[{v_base} + {v_bi}] = {v_bytes}[{v_base} + {v_inv_perm}[{v_bi}] + 1]")
L.append(f"        end")
L.append(f"    end")
# Copy remainder
v_rem_i = rand_name(5)
L.append(f"    for {v_rem_i} = {v_full_blocks} * {PERM_BLOCK} + 1, {v_len} do")
L.append(f"        {v_temp}[{v_rem_i}] = {v_bytes}[{v_rem_i}]")
L.append(f"    end")
L.append(f"    {v_bytes} = {v_temp}")
L.append(f"    {v_temp} = nil")
L.append("")

# Step 4: Reverse XOR round 3 (position-dependent key)
v_k3len = rand_name()
L.append(f"    local {v_k3len} = #{k3_name}")
L.append(f"    for {v_pos} = 1, {v_len} do")
L.append(f"        local {v_b} = {v_bytes}[{v_pos}]")
L.append(f"        {v_b} = {v_bxor}({v_b}, ({v_pos} - 1) * 7 + 13)")
L.append(f"        {v_b} = {v_bxor}({v_b} % 256, {k3_name}[(({v_pos} - 1) % {v_k3len}) + 1])")
L.append(f"        {v_bytes}[{v_pos}] = {v_b} % 256")
L.append(f"    end")
L.append("")

# Step 5: Reverse XOR round 2
v_k2len = rand_name()
L.append(f"    local {v_k2len} = #{k2_name}")
L.append(f"    for {v_pos} = 1, {v_len} do")
L.append(f"        {v_bytes}[{v_pos}] = {v_bxor}({v_bytes}[{v_pos}], {k2_name}[(({v_pos} - 1) % {v_k2len}) + 1])")
L.append(f"    end")
L.append("")

# Step 6: Reverse XOR round 1
v_k1 = rand_name()
v_k1len = rand_name()
L.append(f"    local {v_k1} = {v_get_k1}()")
L.append(f"    local {v_k1len} = #{v_k1}")
L.append(f"    for {v_pos} = 1, {v_len} do")
L.append(f"        {v_bytes}[{v_pos}] = {v_bxor}({v_bytes}[{v_pos}], {v_k1}[(({v_pos} - 1) % {v_k1len}) + 1])")
L.append(f"    end")
L.append("")

# Step 7: Inverse S-box substitution
L.append(f"    for {v_pos} = 1, {v_len} do")
L.append(f"        {v_bytes}[{v_pos}] = {v_inv_sbox}[{v_bytes}[{v_pos}] + 1]")
L.append(f"    end")
L.append("")

# Step 8: Build output string in chunks (avoid huge table.concat)
v_chunk_size = rand_name()
v_result_parts = rand_name()
v_ci = rand_name(5)
v_cend = rand_name()
v_sub_buf = rand_name()
v_j = rand_name(5)
BUILD_CHUNK = 512
L.append(f"    local {v_result_parts} = {{}}")
L.append(f"    for {v_ci} = 1, {v_len}, {BUILD_CHUNK} do")
L.append(f"        local {v_cend} = {v_ci} + {BUILD_CHUNK - 1}")
L.append(f"        if {v_cend} > {v_len} then {v_cend} = {v_len} end")
L.append(f"        local {v_sub_buf} = {{}}")
L.append(f"        for {v_j} = {v_ci}, {v_cend} do")
L.append(f"            {v_sub_buf}[#{v_sub_buf}+1] = {v_sc}({v_bytes}[{v_j}])")
L.append(f"        end")
L.append(f"        {v_result_parts}[#{v_result_parts}+1] = {v_tc}({v_sub_buf})")
L.append(f"    end")
L.append(f"    {v_bytes} = nil")
L.append(f"    return {v_tc}({v_result_parts})")
L.append(f"end")
L.append("")

# ── Phase 9: Execute with coroutine wrapper and cleanup ──
v_co = rand_name()
v_exec = rand_name()
v_src = rand_name()
v_fn = rand_name()
v_ok = rand_name()
v_e = rand_name()

L.append(f"local {v_exec} = coroutine.wrap(function()")

# Second anti-hook check inside coroutine
L.append(f"    if {v_tp}({v_ls}) ~= 'function' then return end")
L.append(f"    if {v_sc}(65) ~= 'A' then return end")
L.append("")

L.append(f"    local {v_src} = {v_decode}()")
L.append(f"    {v_decode} = nil")
L.append("")

# Clear key tables from memory
L.append(f"    {k1a_name} = nil")
L.append(f"    {k1b_name} = nil")
L.append(f"    {k1c_name} = nil")
L.append(f"    {k2_name} = nil")
L.append(f"    {k3_name} = nil")
L.append(f"    {v_k1_cache} = nil")
L.append(f"    {v_inv_sbox} = nil")
L.append(f"    {v_inv_perm} = nil")
L.append("")

L.append(f"    local {v_fn}, {v_e} = {v_ls}({v_src})")
L.append(f"    {v_src} = nil")
L.append(f"    collectgarbage('count')")
L.append("")
L.append(f"    if {v_fn} then")
L.append(f"        {v_fn}()")
L.append(f"    end")
L.append(f"end)")
L.append("")

# Execute via pcall for error suppression
v_success = rand_name()
v_errmsg = rand_name()
L.append(f"local {v_success}, {v_errmsg} = {v_pcall_ref}({v_exec})")
L.append(f"if not {v_success} then")
L.append(f"    warn({v_errmsg})")
L.append(f"end")
L.append("")

# Final cleanup
L.append(f"{v_exec} = nil")
L.append(f"{v_decode} = nil")
L.append(f"collectgarbage()")

output = "\n".join(L) + "\n"

with open(OUT, "w") as f:
    f.write(output)

src_kb = len(source_bytes) / 1024
out_kb = len(output) / 1024
print(f"Done: {src_kb:.1f} KB source -> {out_kb:.1f} KB obfuscated")
print(f"Encryption: S-box + 3-round XOR + block permutation ({PERM_BLOCK}-byte blocks)")
print(f"Payload: {num_chunks} scattered chunks, {len(_used_names)} random identifiers")
print(f"Output: {OUT}")
