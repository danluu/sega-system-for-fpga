

#ifndef __DATA_VALUE_H
#define __DATA_VALUE_H

class BUS
{
	public:
		// r1 = bit[5:3] in 1st byte (r)
		// r2 = bit[2:0] in 1st byte (r')
		// r3 = bit[5:3] in 2nd byte (r)
		// r4 = bit[2:0] in 2nd byte (r)
		// d = 3rd byte offset.
		// dd1 = bit[5:4] in 1st byte (dd)
		// dd2 = bit[5:4] in 2nd byte (dd)
		// qq1 = bit[5:4] in 1st byte (qq)
		// pp2 = bit[5:4] in 2nd byte (pp)
		// rr2 = bit[5:4] in 2nd byte (rr)
		// n1 = 1st byte imm.
		// n2 = 2nd byte imm.
		// n3 = 3rd byte imm.
		// n4 = 4th byte imm.
		// nn1 = {n3<<8, n2}
		// nn2 = {n4<<8, n3}
		// b4 = bit[5:3] in 4th byte (b)
		unsigned char d, dd1, dd2, qq1, pp2, rr2, n1, n2, n3, n4, r1, r2, r3, r4, b4;
		unsigned short nn1, nn2, nn1_i, nn2_i;
};

class Flag
{
   public:
	unsigned char C: 1;			// Carry flag
	unsigned char N: 1;			// Add/Subtract flag
	unsigned char PV: 1;		// Parity & overflow flag
	unsigned char no_use1: 1;	
	unsigned char H: 1;			// Half_carry flag
	unsigned char no_use2: 1;
	unsigned char Z: 1;			// Zero flag
	unsigned char S: 1;			// Sign flag
};

extern Flag flag;
extern BUS bus_pre;
extern unsigned char _ID;

#endif
