#!/usr/bin/env python3

import struct
import argparse

# python slop written as fast as possible

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
	"halt": 0xff,
};

aliases = {
	"hlt": "halt",
};

def mov_virtual_instruction(a, b):
	if (a["type"] == "mem" and b["type"] == "reg"):
		return {"type": "instruction", "name": "st"};

	if (a["type"] == "reg" and b["type"] == "mem"):
		return {"type": "instruction", "name": "ld"};

	return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

def rr_imm_virtual_resolver(a, b, c, rr, imm):
	if (c == False):
		c = b;
		b = a;

	if (a["type"] != "reg" and b["type"] != "reg"):
		return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

	if (c["type"] == "reg"):
		return {"type": "instruction", "name": rr, "operands": [a, b, c]};

	if (c["type"] == "int"):
		return {"type": "instruction", "name": imm, "operands": [a, b, c]};

	return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

def serialise(bytesize, operand):
	value = operand["value"];

	# decimal - float (not supported by this procesor, oh well!)
	if (operand["type"] == "decimal" and bytesize == 4):
		return struct.pack("<f", value);
	if (operand["type"] == "decimal" and bytesize == 8):
		return struct.pack("<d", value);

	if (operand["type"] == "int"):
		format = {
			1: "B",
			2: "H",
			4: "I",
			8: "Q",
		};
		return struct.pack("<" + format[bytesize], value);

	if (operand["type"] == "str"):
		return bytes(value, "utf-8");

	return {"type": "error", "value": ERR_SERIALISATION_FAILED};

def dd_virtual(bytesize, *operands):
	data = b"";
	for operand in operands:
		serialised = serialise(bytesize, operand);
		if (type(serialised) != bytes):
			return serialised;
		data += serialised;

	return {"type": "data", "value": data};

virtual = {
	"mov": {"args": [2], "resolve": mov_virtual_instruction},
	"add": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "add", "addi")},
	"sub": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "sub", "subi")},
	"and": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "and", "andi")},
	"or": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "or", "ori")},
	"xor": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "xor", "xori")},
	"shl": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "shl", "shli")},
	"shr": {"args": [2, 3], "resolve": lambda a, b, c=False: rr_imm_virtual_resolver(a, b, c, "shr", "shri")},
	"db": {"args": False, "resolve": lambda *operands: dd_virtual(1, *operands)},
	"dw": {"args": False, "resolve": lambda *operands: dd_virtual(2, *operands)},
	"dd": {"args": False, "resolve": lambda *operands: dd_virtual(4, *operands)},
	"dq": {"args": False, "resolve": lambda *operands: dd_virtual(8, *operands)},
};

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
	"ld": {"args": 2, "encoding": "da"},
	"st": {"args": 2, "encoding": "ab"},
	"beq": {"args": 3, "encoding": "abi"},
	"blt": {"args": 3, "encoding": "abi"},
	"jmp": {"args": 1, "encoding": "i"},
	"jal": {"args": 2, "encoding": "di"},
	"halt": {"args": 0, "encoding": ""},
};

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

def splitn(obj, n):
	return [obj[i:i + n] for i in range(0, len(obj), n)];

def fpgasynth_format_transformer(bin):
	output = b"";
	words = splitn(bin, 2);
	for word in words:
		high = hex(word[0])[2:].zfill(2).upper();
		low = hex(word[1])[2:].zfill(2).upper();
		output += bytes(high + low + "\n", "utf-8");
	return output

formats = {
	"bin": lambda bin: bin, # already binary, no transform
	"fpgasynth": fpgasynth_format_transformer,
};

ERR_DECODE_FAILED = 0;
ERR_RESOLUTION_FAILED = 1;
ERR_UNKNOWN_DECODE_ERROR = 2;
ERR_INCORRECT_ARG_COUNT = 3;
ERR_UNSUPPORTED_ARGS = 4;
ERR_SERIALISATION_FAILED = 5;

ERR_GENERIC = -0xff;

def decode_decimal_operand(operand):
	try:
		return {"type": "decimal", "value": float(operand)};
	except Exception as e:
		return {"type": "error", "value": ERR_DECODE_FAILED};

def decode_str_operand(operand):
	return {"type": "error", "value": ERR_DECODE_FAILED};

def decode_chr_operand(operand):
	return {"type": "error", "value": ERR_DECODE_FAILED};

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

def decode_int_operand(operand):
	try:
		decoded = decode_int_helper(operand);
		if (type(decoded) != int):
			return {"type": "error", "value": ERR_DECODE_FAILED};

		return {"type": "int", "value": decoded};
	except Exception as e:
		return {"type": "error", "value": ERR_DECODE_FAILED};

def looks_like_decimal(operand):
	try:
		float(operand);
		return True;
	except:
		return False;

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
		return decode_decimal_operand(operand); # try as decimal

	return intdecode;

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

def decode_instruction(instruction):
	try:
		instruction = instruction.strip();
		if " " in instruction:
			splitpoint = instruction.index(" ");
			insname = instruction[:splitpoint].strip().lower();

			oplist = instruction[splitpoint+1:];
			operands = oplist.split(",");
		else:
			insname = instruction;
			operands = [];

		decoded_operands = [];
		for operand in operands:
			decoded = decode_operand(operand.strip());
			if (decoded["type"] == "error"):
				return decoded;
			decoded_operands.append(decoded);

		resolved = resolve_final_instruction(insname, decoded_operands);
		if (resolved["type"] == "data" or resolved["type"] == "error"):
			return resolved;

		if (resolved["type"] != "instruction"):
			return {"type": "error", "value": ERR_UNKNOWN_DECODE_ERROR};

		if ("operands" in resolved):
			decoded_operands = resolved["operands"];

		return {"type": "instruction", "name": resolved["name"], "operands": decoded_operands};
	except Exception as e:
		return {"type": "error", "value": ERR_UNKNOWN_DECODE_ERROR};

def serialise_instruction(instruction):
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
		letter = encoding["encoding"][i];
		if ((letter == "d" or letter == "a" or letter == "b") and (operand["type"] != "reg" and operand["type"] != "mem")):
			return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

		if (letter == "i" and operand["type"] != "int"):
			return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

		if (letter == "d"):
			serialised[1] = serialised[1] | (operand["value"] << 4);

		if (letter == "a"):
			serialised[1] = serialised[1] | operand["value"];

		if (letter == "b"):
			serialised[2] = serialised[2] | (operand["value"] << 4);

		if (letter == "i"):
			if (operand["value"] < 0 or operand["value"] >= 0x10000):
				return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

			serialised[3] = operand["value"] & 0xff;
			serialised[2] = (operand["value"] >> 8) & 0xff;

		if ((letter == "d" or letter == "a" or letter == "b") and operand["type"] == "mem"):
			if (operand["imm"] < 0 or operand["imm"] >= 0x10000):
				return {"type": "error", "value": ERR_UNSUPPORTED_ARGS};

			serialised[3] = operand["imm"] & 0xff;
			serialised[2] = (operand["imm"] >> 8) & 0xff;

		i = i + 1;

	return bytes(serialised);

def assemble_instruction(instruction):
	decoded = decode_instruction(instruction);
	if (decoded["type"] == "error"):
		return decoded;

	if (decoded["type"] == "data"):
		return decoded["value"];

	if (decoded["type"] != "instruction"):
		return {"type": "error", "value": ERR_UNKNOWN_DECODE_ERROR};

	return serialise_instruction(decoded);

def process_file(source, output, format):
	if (output == None):
		output = "a.out";

	if (format == None):
		format = "bin";

	file = open(source, "r");
	contents = file.read();
	file.close();

	assembly = b"";
	for line in contents.split("\n"):
		line = line.strip();
		if (line == ""):
			continue;
		instruction = assemble_instruction(line);
		if (type(instruction) != bytes):
			print("error");
			return;

		assembly += instruction;

	assembly = formats[format](assembly);

	ofile = open(output, "wb");
	ofile.write(assembly);
	ofile.close();

if __name__ == "__main__":
	parser = argparse.ArgumentParser(prog="rrasm", description="Roadrunner Assembler");
	parser.add_argument("source");
	parser.add_argument("-o", "--output");
	parser.add_argument("-f", "--format");
	args = parser.parse_args();
	process_file(args.source, args.output, args.format);
