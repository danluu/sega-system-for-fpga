///////////////////////////
// definitions of z80_I_ID
// these should be also defined
// in xlator	  
///////////////////////////
#ifndef __Z80_I_ID_H
#define __Z80_I_ID_H

#define NOP	   0
#define ADC_A_s_1  1
#define ADC_A_s_2  2
#define ADC_A_s_3  3
#define ADC_A_s_4  4
#define ADC_A_s_5  5
#define ADC_HL_ss  6
#define ADD_A_HL   7
#define ADD_A_IX_d  8
#define ADD_A_IY_d  9
#define ADD_A_n     10
#define ADD_A_r     11
#define ADD_HL_ss   12
#define ADD_IX_pp   13
#define ADD_IY_rr   14
#define AND_s_1     15
#define AND_s_2     16
#define AND_s_3     17
#define AND_s_4     18
#define AND_s_5     19
#define BIT_b_HL    20
#define BIT_b_IX_d  21
#define BIT_b_IY_d  22
#define BIT_b_r     23
#define CALL_cc_nn  24
#define CALL_nn     25
#define CCF         26
#define CP_s_1      27
#define CP_s_2      28
#define CP_s_3      29
#define CP_s_4      30
#define CP_s_5      31
#define CPD         32
#define CPDR        33
#define CPI         34
#define CPIR        35
#define CPL         36
#define DAA         37
#define DEC_IX      38
#define DEC_IY      39
#define DEC_m_1     40
#define DEC_m_2     41
#define DEC_m_3     42
#define DEC_m_4     43
#define DEC_ss      44
#define DI          45
#define DJNZ_e      46
#define EI          47
#define EX_SP_HL    48
#define EX_SP_IX    49
#define EX_SP_IY    50
#define EX_AF_AF    51
#define EX_DE_HL    52
#define EXX         53
#define HALT        54
#define IM0         55
#define IM1         56
#define IM2         57
#define IN_A_n      58
#define IN_r_C      59
#define INC_HL      60
#define INC_IX_d    61
#define INC_IY_d    62
#define INC_IX      63
#define INC_IY      64
#define INC_r       65
#define INC_ss      66
#define IND         67
#define INDR        68
#define INI         69
#define INIR        70
#define JP_HL       71
#define JP_IX       72
#define JP_IY       73
#define JP_cc_nn    74
#define JP_nn       75
#define JR_NC_e     76
#define JR_C_e      77
#define JR_e        78
#define JR_NZ_e     79
#define JR_Z_e      80
#define LD_BC_A     81
#define LD_DE_A     82
#define LD_HL_n     83
#define LD_HL_r     84
#define LD_IX_d_n   85
#define LD_IX_d_r   86
#define LD_IY_d_n   87
#define LD_IY_d_r   88
#define LD_nn_A     89
#define LD_nn_dd    90
#define LD_nn_HL    91
#define LD_nn_IX    92
#define LD_nn_IY    93
#define LD_A_BC     94
#define LD_A_DE     95
#define LD_A_nn     96
#define LD_A_I      97
#define LD_A_R      98
#define LD_dd_nn    99
#define LD_dd_nn2   100
#define LD_HL_nn    101
#define LD_I_A      102
#define LD_IX_nn    103
#define LD_IX_nn2   104
#define LD_IY_nn    105
#define LD_IY_nn2   106
#define LD_r_HL     107
#define LD_r_IX_d   108
#define LD_r_IY_d   109
#define LD_R_A      110
#define LD_r_r      111
#define LD_r_n      112
#define LD_SP_HL    113
#define LD_SP_IX    114
#define LD_SP_IY    115
#define LDD         116
#define LDDR        117
#define LDI         118
#define LDIR        119
#define NEG         120
#define OR_s_1      121
#define OR_s_2      122
#define OR_s_3      123
#define OR_s_4      124
#define OR_s_5      125
#define OTDR        126
#define OTIR        127
#define OUT_C_r     128
#define OUT_n_A     129
#define OUTD        130
#define OUTI        131
#define POP_IX      132
#define POP_IY      133
#define POP_qq      134
#define PUSH_IX     135
#define PUSH_IY     136
#define PUSH_qq     137
#define RES_b_m_1   138
#define RES_b_m_2   139
#define RES_b_m_3   140
#define RES_b_m_4   141
#define RET         142
#define RET_cc      143
#define RETI        144
#define RETN        145
#define RL_m_1      146
#define RL_m_2      147
#define RL_m_3      148
#define RL_m_4      149
#define RLA         150
#define RLC_HL      151
#define RLC_IX_d    152
#define RLC_IY_d    153
#define RLC_r       154
#define RLCA        155
#define RLD         156
#define RR_m_1      157
#define RR_m_2      158
#define RR_m_3      159
#define RR_m_4      160
#define RRA         161
#define RRC_m_1     162
#define RRC_m_2     163
#define RRC_m_3     164
#define RRC_m_4     165
#define RRCA        166
#define RRD         167
#define RST_p       168
#define SBC_A_s_1   169
#define SBC_A_s_2   170
#define SBC_A_s_3   171
#define SBC_A_s_4   172
#define SBC_A_s_5   173
#define SBC_HL_ss   174
#define SCF         175
#define SET_b_HL    176
#define SET_b_IX_d  177
#define SET_b_IY_d  178
#define SET_b_r     179
#define SLA_m_1     180
#define SLA_m_2     181
#define SLA_m_3     182
#define SLA_m_4     183
#define SRA_m_1     184
#define SRA_m_2     185
#define SRA_m_3     186
#define SRA_m_4     187
#define SRL_m_1     188
#define SRL_m_2     189
#define SRL_m_3     190
#define SRL_m_4     191
#define SUB_s_1     192
#define SUB_s_2     193
#define SUB_s_3     194
#define SUB_s_4     195
#define SUB_s_5     196
#define XOR_s_1     197
#define XOR_s_2     198
#define XOR_s_3     199
#define XOR_s_4     200
#define XOR_s_5     201
//////undocument////////
#define SLL_m_1		202
#define SLL_m_2		203
#define SLL_m_3		204
#define SLL_m_4		205
//#define INT_handler 254
//#define NMI_handler 255
#endif
///////////////////////////
// end of definitions of z80_I_ID
///////////////////////////

