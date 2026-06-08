#!/usr/bin/env python3

import struct
import argparse

# python slop written as fast as possible

# opcode map
opcodes = {
	"nop": 0x00,
	"add": 0x02,
	"addi": 0x03,
	"sub": 0x04,
	"subi": 0x05,
	"and": 0x06,
	"andi": 0x07,
	"or": 0x08,
	"ori": 0x09,
	"xor": 0x0a,
	"xori": 0x0b,
	"shl": 0x0c,
	"shli": 0x0d,
	"shr": 0x0e,
	"shri": 0x0f,
	"ld": 0x10,
	"st": 0x11,
	"beq": 0x12,
	"blt": 0x13,
	"jmp": 0x14,
	"jal": 0x15,
	"jrel": 0x16,
	"ldi": 0x17,
	"halt": 0xff,
};

# aliases
aliases = {
	"hlt": "halt",
};

vmembase = 0xfc00; # default executable base

symbols = {}; # symbols - filled at runtime

macros = {}; # macros - same thing

unresolved = []; # unresolved symbols - same

exports = []; # exports - same

pie = True; # pie - set by --no-pie

# `mov` instruction virtual overload resolver, resolve to st, ld, or ldi depending on operand types
def mov_virtual_instruction(a, b):
	if (a["type"] == "mem" and b["type"] == "reg"):
		return {"type": "instruction", "name": "st"};

	if (a["type"] == "reg" and b["type"] == "mem"):
		return {"type": "instruction", "name": "ld"};

	if (a["type"] == "reg" and b["type"] == "int"):
		return {"type": "instruction", "name": "ldi"};

	return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

# `jmp` instruction virtual resolver, resolve to jrel or jmp depending on pie settings
def jmp_virtual_instruction(a):
	if (pie):
		return {"type": "instruction", "name": "jrel"};

	return {"type": "instruction", "name": "jmp"};

# generic register, register || #imm virtual resolver, resolve to rr or imm depending on operand types
def rr_imm_virtual_resolver(a, b, c, rr, imm):
	if (c == False):
		c = b;
		b = a;

	if (a["type"] != "reg" and b["type"] != "reg"):
		return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

	if (c["type"] == "reg"):
		return {"type": "instruction", "name": rr, "operands": [a, b, c]};

	if (c["type"] == "int" or c["type"] == "sym"):
		return {"type": "instruction", "name": imm, "operands": [a, b, c]};

	return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

# generic operand serialiser, serialises an operand of type to bytesize-bytes
def serialise(bytesize, operand):
	value = operand["value"];

	# decimal - float (not supported by this procesor, oh well!)
	if (operand["type"] == "decimal" and bytesize == 4):
		return struct.pack(">f", value);
	if (operand["type"] == "decimal" and bytesize == 8):
		return struct.pack(">d", value);

	if (operand["type"] == "int" or operand["type"] == "sym"):
		if (operand["type"] == "sym"):
			if value not in symbols:
				return {"type": "error", "value": ERR_SYM_NOT_FOUND};
			value = symbols[value];

		format = {
			1: "B",
			2: "H",
			4: "I",
			8: "Q",
		};
		return struct.pack(">" + format[bytesize], value);

	if (operand["type"] == "str"):
		return bytes(value, "utf-8");

	return {"type": "error", "value": ERR_SERIALISATION_FAILED};

# `org` virtual instruction, set vmembase to int operand
def org_virtual(origin):
	global vmembase
	if (origin["type"] != "int"):
		return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

	if (origin["value"] < 0 or origin["value"] >= 0x10000):
		return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

	vmembase = origin["value"];
	return {"type": "null"};

# `extern` virtual instruction, export sym operand
def extern_virtual(sym):
	if (sym["type"] != "sym"):
		return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

	exports.append(sym["value"]);
	return {"type": "null"};

# define-data virtual instruction, serialise operands of type
def dd_virtual(bytesize, *operands):
	data = b"";
	for operand in operands:
		serialised = serialise(bytesize, operand);
		if (type(serialised) != bytes):
			return serialised;
		data += serialised;

	return {"type": "data", "value": data};

# virtual instruction list
virtual = {
	"mov": {"args": [2], "resolve": mov_virtual_instruction},
	"add": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "add", "addi")},
	"sub": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "sub", "subi")},
	"and": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "and", "andi")},
	"or": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "or", "ori")},
	"xor": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "xor", "xori")},
	"shl": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "shl", "shli")},
	"shr": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "shr", "shri")},
	"org": {"args": [1], "resolve": org_virtual},
	"extern": {"args": [1], "resolve": extern_virtual},
	"jmp": {"args": [1], "resolve": jmp_virtual_instruction},
	"db": {"args": False, "resolve": lambda *operands: dd_virtual(1, *operands)},
	"dw": {"args": False, "resolve": lambda *operands: dd_virtual(2, *operands)},
	"dd": {"args": False, "resolve": lambda *operands: dd_virtual(4, *operands)},
	"dq": {"args": False, "resolve": lambda *operands: dd_virtual(8, *operands)},
};

# encoding table
encodings = {
	"nop": {"args": 0, "encoding": ""},
	"add": {"args": 3, "encoding": "dab"},
	"addi": {"args": 3, "encoding": "dai"},
	"sub": {"args": 3, "encoding": "dab"},
	"subi": {"args": 3, "encoding": "dai"},
	"and": {"args": 3, "encoding": "dab"},
	"andi": {"args": 3, "encoding": "dai"},
	"or": {"args": 3, "encoding": "dab"},
	"ori": {"args": 3, "encoding": "dai"},
	"xor": {"args": 3, "encoding": "dab"},
	"xori": {"args": 3, "encoding": "dai"},
	"shl": {"args": 3, "encoding": "dab"},
	"shli": {"args": 3, "encoding": "dai"},
	"shr": {"args": 3, "encoding": "dab"},
	"shri": {"args": 3, "encoding": "dai"},
	"ld": {"args": 2, "encoding": "dm"},
	"st": {"args": 2, "encoding": "Ma"},
	"beq": {"args": 3, "encoding": "dar"},
	"blt": {"args": 3, "encoding": "dar"},
	"jmp": {"args": 1, "encoding": "i"},
	"jal": {"args": 2, "encoding": "di"},
	"jrel": {"args": 1, "encoding": "r"},
	"ldi": {"args": 2, "encoding": "di"},
	"halt": {"args": 0, "encoding": ""},
};

# register table
registers = {
	"r0": {"type": "reg", "value": 0},
	"r1": {"type": "reg", "value": 1},
	"r2": {"type": "reg", "value": 2},
	"r3": {"type": "reg", "value": 3},
	"r4": {"type": "reg", "value": 4},
	"r5": {"type": "reg", "value": 5},
	"r6": {"type": "reg", "value": 6},
	"r7": {"type": "reg", "value": 7},
	"r8": {"type": "reg", "value": 8},
	"r9": {"type": "reg", "value": 9},
	"r10": {"type": "reg", "value": 10},
	"r11": {"type": "reg", "value": 11},
	"r12": {"type": "reg", "value": 12},
	"r13": {"type": "reg", "value": 13},
	"r14": {"type": "reg", "value": 14},
	"r15": {"type": "reg", "value": 15},
};

# split `obj` ever `n` whatevers
def splitn(obj, n):
	return [obj[i:i + n] for i in range(0, len(obj), n)];

# transform bin to fpgasynth format
def fpgasynth_format_transformer(bin):
	output = b"";
	words = splitn(bin, 2);
	for word in words:
		high = hex(word[0])[2:].zfill(2).upper();
		low = hex(word[1])[2:].zfill(2).upper();
		output += bytes(high + low + "\n", "utf-8");
	return output

# format table
formats = {
	"bin": lambda bin: bin, # already binary, no transform
	"fpgasynth": fpgasynth_format_transformer,
};

# error enum
ERR_DECODE_FAILED = 0;
ERR_RESOLUTION_FAILED = 1;
ERR_UNKNOWN_DECODE_ERROR = 2;
ERR_INCORRECT_ARG_COUNT = 3;
ERR_UNSUPPORTED_ARGS = 4;
ERR_SERIALISATION_FAILED = 5;
ERR_SYM_NOT_FOUND = 6;

ERR_GENERIC = -0xff;

# decode decimal operand from string
def decode_decimal_operand(operand):
	try:
		return {"type": "decimal", "value": float(operand)};
	except Exception as e:
		return {"type": "error", "value": ERR_DECODE_FAILED};

# decode str operand from string - UNIMPLEMENTED
def decode_str_operand(operand):
	return {"type": "error", "value": ERR_DECODE_FAILED};

# decode chr operand from string - UNIMPLEMENTED
def decode_chr_operand(operand):
	return {"type": "error", "value": ERR_DECODE_FAILED};

# decode int operand from string - UNIMPLEMENTED
def decode_int_helper(num):
	try:
		if (num.startswith("0x")):
			return int(num, 16);

		if (num.startswith("0o")):
			return int(num, 8);

		if (num.startswith("0b")):
			return int(num, 2);

		return int(num, 10);
	except Exception as e:
		return False;

# decode mem operand from string - UNIMPLEMENTED
def decode_mem_operand(operand):
	decoded = {"type": "mem", "value": 0, "imm": 0};

	reference = operand[1:-1].replace(" ", "");

	# decode adden if present, adden can be omitted ...
	try:
		adden_index = reference.index("+");
		decodedint = decode_int_helper(reference[adden_index+1:]);
		if (type(decodedint) != int):
			return {"type": "error", "value": ERR_DECODE_FAILED};

		decoded["imm"] = decodedint;
		regname = reference[:adden_index];
	except Exception as e:
		regname = reference;

	# ... ra cannot, error if not present
	if (regname not in registers):
		return {"type": "error", "value": ERR_DECODE_FAILED};

	decoded["value"] = registers[regname]["value"];
	return decoded;

# decode int operand from string - UNIMPLEMENTED
def decode_int_operand(operand):
	try:
		decoded = decode_int_helper(operand);
		if (type(decoded) != int):
			return {"type": "error", "value": ERR_DECODE_FAILED};

		return {"type": "int", "value": decoded};
	except Exception as e:
		return {"type": "error", "value": ERR_DECODE_FAILED};

# does operand look like decimal?
def looks_like_decimal(operand):
	try:
		int(operand);
		return False;
	except:
		pass
	try:
		float(operand);
		return True;
	except:
		return False;

# decode operand to type
def decode_operand(operand):
	if (operand in registers):
		return registers[operand];

	if (operand[0] == '[' and operand[-1] == ']'):
		return decode_mem_operand(operand);

	if (operand[0] == '"' and operand[-1] == '"'):
		return decode_str_operand(operand);

	if (operand[0] == '\'' and operand[-1] == '\''):
		return decode_chr_operand(operand);

	intdecode = decode_int_operand(operand); # try as int
	if (intdecode["type"] == "error"):
		decimaldecode = decode_decimal_operand(operand); # try as decimal

		if (decimaldecode["type"] == "error"):
			return {"type": "sym", "value": operand}; # assume ths is some kind of symbol

		return decimaldecode;

	return intdecode;

# resolve an instruction, pass through alias and virtual tables
def resolve_final_instruction(insname, operands):
	if (insname in aliases):
		insname = aliases[insname];

	if (insname in virtual):
		resolver = virtual[insname];
		if (resolver["args"] != False and len(operands) in resolver["args"]):
			try:
				return resolver["resolve"](*operands);
			except Exception as e:
				return {"type": "error", "value": ERR_RESOLUTION_FAILED};

	return {"type": "instruction", "name": insname};

# decode symbol to relsym or null type
def decode_symbol(symbol):
	if (symbol[-1] == ':'):
		return {"type": "relsym", "value": symbol[:-1]}; # make relative symbol here

	words = symbol.split(" ");
	if (len(words) != 3):
		return {"type": "error", "value": ERR_UNKNOWN_DECODE_ERROR};

	name = words[0];
	value = decode_int_helper(words[2]);
	symbols[name] = value;
	return {"type": "null"};

# deduplicate character in string
def strdedup(str, chr):
	dup = chr + chr;
	while (dup in str):
		str = str.replace(dup, chr);
	return str;

# preform fixed symbol decoding prepass
def fixed_sym_decode_prepass(instruction):
	deduped = strdedup(instruction, ' ').strip();
	words = deduped.split(' ');
	if (len(words) != 3):
		return {"type": "null"};

	if (words[1].lower() == "equ"):
		return decode_symbol(deduped);

	return {"type": "null"};

# decode instruction to ast object
def decode_instruction(instruction):
	try:
		instruction = instruction.strip();
		if ' ' in instruction:
			deduped = strdedup(instruction, ' ').strip();
			words = deduped.split(' ');
			if (len(words) == 3 and words[1].lower() == "equ"):
				return {"type": "null"};

			splitpoint = instruction.index(' ');
			insname = instruction[:splitpoint].strip().lower();

			oplist = instruction[splitpoint+1:];
			operands = oplist.split(',');
		else:
			if (instruction[-1] == ':'):
				return decode_symbol(instruction.replace(' ', ''));

			insname = instruction;
			operands = [];

		decoded_operands = [];
		for operand in operands:
			decoded = decode_operand(operand.strip());
			if (decoded["type"] == "error"):
				return decoded;
			decoded_operands.append(decoded);

		resolved = resolve_final_instruction(insname, decoded_operands);
		if (resolved["type"] in ["data", "error", "null"]):
			return resolved;

		if (resolved["type"] != "instruction"):
			return {"type": "error", "value": ERR_UNKNOWN_DECODE_ERROR};

		if ("operands" in resolved):
			decoded_operands = resolved["operands"];

		return {"type": "instruction", "name": resolved["name"], "operands": decoded_operands};
	except Exception as e:
		return {"type": "error", "value": ERR_UNKNOWN_DECODE_ERROR};

# serialise instruction at file offset
def serialise_instruction(instruction, offset):
	name = instruction["name"];
	operands = instruction["operands"];
	if (name not in opcodes):
		return {"type": "error", "value": ERR_RESOLUTION_FAILED};

	serialised = bytearray([opcodes[name], 0, 0, 0]);
	encoding = encodings[name];
	if (encoding["args"] != len(operands)):
		return {"type": "error", "value": ERR_INCORRECT_ARG_COUNT};

	i = 0;
	for operand in operands:
		relative_unresolved = False;
		letter = encoding["encoding"][i];
		if (operand["type"] == "sym"):
			symname = operand["value"];
			if (symname in symbols):
				operand = {"type": "int", "value": symbols[symname]};
			else:
				operand = {"type": "int", "value": vmembase};
				if (letter == 'r'):
					relative_unresolved = True;
					unresolved.append({"type": "rel16", "symname": symname, "address": offset + 2, "relbase": vmembase + (offset >> 1)});
				else:
					unresolved.append({"type": "abs16", "symname": symname, "address": offset + 2});

		# this needs to be simplified, very messy due to frequent changes
		if ((letter == 'd' or letter == 'a' or letter == 'b') and operand["type"] != "reg"):
			return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

		if ((letter == 'm' or letter == 'M') and operand["type"] != "mem"):
			return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

		if ((letter == 'i' or letter == 'r') and operand["type"] != "int"):
			return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

		if (letter == 'd' or letter == 'M'):
			serialised[1] = serialised[1] | (operand["value"] << 4);

		if (letter == 'a' or letter == 'm'):
			serialised[1] = serialised[1] | operand["value"];

		if (letter == 'b'):
			serialised[2] = serialised[2] | (operand["value"] << 4);

		if (letter == 'i'):
			value = operand["value"];
			if (value < 0 or value >= 0x10000):
				return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

			serialised[3] = value & 0xff;
			serialised[2] = (value >> 8) & 0xff;

		if (letter == 'r' and relative_unresolved == False):
			value = operand["value"] - (vmembase + (offset >> 1));
			if ((value < -0x7fff) or (value > 0x7fff)):
				print(value, operand, vmembase, offset);
				return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

			packed = struct.pack(">h", value);
			serialised[2] = packed[0];
			serialised[3] = packed[1];

		if ((letter == 'm' or letter == 'M') and operand["type"] == "mem"):
			if (operand["imm"] < 0 or operand["imm"] >= 0x10000):
				return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

			serialised[3] = operand["imm"] & 0xff;
			serialised[2] = (operand["imm"] >> 8) & 0xff;

		i = i + 1;

	return bytes(serialised);

# assemble instruction at file offset
def assemble_instruction(instruction, offset):
	decoded = decode_instruction(instruction);
	if (decoded["type"] == "error"):
		return decoded;

	if (decoded["type"] == "data"):
		return decoded["value"];

	if (decoded["type"] == "relsym"):
		symbols[decoded["value"]] = vmembase + (offset >> 1);
		return b"";

	if (decoded["type"] == "null"):
		return b"";

	if (decoded["type"] != "instruction"):
		return {"type": "error", "value": ERR_UNKNOWN_DECODE_ERROR};

	return serialise_instruction(decoded, offset);

# strip comments
def strip_comments(line):
	if (";" not in line):
		return line;

	return line[:line.index(";")];

# error to pretty name
def err2name(code):
	if (code == ERR_DECODE_FAILED):
		return "ERR_DECODE_FAILURE";
	if (code == ERR_RESOLUTION_FAILED):
		return "ERR_RESOLUTION_FAILED";
	if (code == ERR_UNKNOWN_DECODE_ERROR):
		return "ERR_UNKNOWN_DECODE_ERROR";
	if (code == ERR_INCORRECT_ARG_COUNT):
		return "ERR_INCORRECT_ARG_COUNT";
	if (code == ERR_UNSUPPORTED_ARGS):
		return "ERR_UNSUPPORTED_ARGS";
	if (code == ERR_SERIALISATION_FAILED):
		return "ERR_SERIALISATION_FAILED";
	if (code == ERR_SYM_NOT_FOUND):
		return "ERR_SYM_NOT_FOUND";
	if (code == ERR_GENERIC):
		return "ERR_GENERIC";

# process `source`, assemble, write to `output` in `format`
def process_file(source, output, format):
	if (output == None):
		output = "a.out";

	if (format == None):
		format = "bin";

	file = open(source, "r");
	contents = file.read();
	file.close();

	assembly = bytearray();
	lines = contents.split('\n');
	linenum = 0;
	for line in lines:
		line = strip_comments(line.strip());
		if (line == ""):
			linenum += 1;
			continue;

		stat = fixed_sym_decode_prepass(line);
		if (stat["type"] != "null"):
			if (stat["type"] == "error"):
				print("%s on line %d" % (err2name(stat["value"]), linenum));
			else:
				print("unknown error on line %d" % linenum);
				print(stat);
			return;
		linenum += 1;

	offset = 0;
	linenum = 0;
	for line in lines:
		line = strip_comments(line.strip());
		if (line == ""):
			linenum += 1;
			continue;

		instruction = assemble_instruction(line, offset);
		if (type(instruction) != bytes):
			if (instruction["type"] == "error"):
				print("%s on line %d" % (err2name(instruction["value"]), linenum));
			else:
				print("unknown on line %d" % linenum);
				print(stat);
			return;

		offset += len(instruction);
		assembly += instruction;
		linenum += 1;

	for deferred in unresolved:
		addr = deferred["address"];
		symname = deferred["symname"];
		if ((addr + 1) >= len(assembly)):
			print("error");
			return;

		if (symname not in symbols):
			print("Unresolved symbol '%s'" % symname);
			return;

		if (deferred["type"] == "abs16"):
			assembly[addr:addr+2] = struct.pack(">H", symbols[symname]);
		elif (deferred["type"] == "rel16"):
			assembly[addr:addr+2] = struct.pack(">H", symbols[symname] - deferred["relbase"]);

	assembly = bytes(assembly);
	assembly = formats[format](assembly);

	ofile = open(output, "wb");
	ofile.write(assembly);
	ofile.close();

if __name__ == "__main__":
	parser = argparse.ArgumentParser(prog="rrasm", description="Roadrunner Assembler");
	parser.add_argument("source");
	parser.add_argument("-o", "--output");
	parser.add_argument("-f", "--format");
	parser.add_argument("-b", "--origin");
	parser.add_argument("-s", "--no-pie", action="store_true");
	args = parser.parse_args();
	pie = not args.no_pie;
	process_file(args.source, args.output, args.format);
