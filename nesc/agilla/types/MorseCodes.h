#ifndef MORSECODES
#define MORSECODES

typedef nx_struct _AgillaMorseCode
{
	nx_uint8_t ascii; // ascii value of the symbol. eg. 'A'
	nx_uint8_t size; // number of bits used (from the MSB, 0..8). eg. 3
	nx_uint16_t code; // actual morse bitcode:
						// 0 = short
						// 1 = long
} AgillaMorseCode;

// timing
#define DOT_MSEC 100
#define DASH_MSEC 300

// letter and word separator delay
#define WORD_SEPARATOR 500
#define LETTER_SEPARATOR 300

#define NUMOFMORSECODES 49
AgillaMorseCode MorseCodes[ NUMOFMORSECODES ] = 
{
	{ 'A', 2, 0x40 }, { 'B', 4, 0x80 }, { 'C', 4, 0xA0 },
	{ 'D', 3, 0x80 }, { 'E', 1, 0x00 }, { 'F', 4, 0x20 },
	{ 'G', 3, 0xC0 }, { 'H', 4, 0x00 }, { 'I', 2, 0x00 },
	{ 'J', 4, 0x70 }, { 'K', 3, 0xA0 }, { 'L', 4, 0x40 },
	{ 'M', 2, 0xC0 }, { 'N', 2, 0x80 }, { 'O', 3, 0xE0 },
	{ 'P', 4, 0x60 }, { 'Q', 4, 0xD0 }, { 'R', 3, 0x40 },
	{ 'S', 3, 0x00 }, { 'T', 1, 0x80 }, { 'U', 3, 0x20 },
	{ 'V', 4, 0x10 }, { 'W', 3, 0x60 }, { 'X', 4, 0x90 },
	{ 'Y', 4, 0xB0 }, { 'Z', 4, 0xC0 }, { '0', 5, 0xF8 },
	{ '1', 5, 0x78 }, { '2', 5, 0x38 }, { '3', 5, 0x18 },
	{ '4', 5, 0x08 }, { '5', 5, 0x00 }, { '6', 5, 0x10 },
	{ '7', 5, 0x30 }, { '8', 5, 0x70 }, { '9', 5, 0xF0 },
	{ '*', 6, 0x54 }, { ',', 6, 0xCC }, { ':', 6, 0xE0 },
	{ '?', 6, 0x30 }, { '=', 5, 0x88 }, { '-', 6, 0x84 },
	{ '(', 5, 0xB0 }, { ')', 6, 0xB4 }, { '"', 6, 0x48 },
	{ '\'', 6, 0x78 }, { '/', 5, 0x90 }, { '_', 6, 0x34 },
	{ '@', 6, 0x68 }
};

#endif
