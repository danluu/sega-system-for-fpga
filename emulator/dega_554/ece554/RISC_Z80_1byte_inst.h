    /////////////////////////////////////////
    // start of 1 byte z80 instruction decode
    /////////////////////////////////////////
	bus_pre.n1 = inst1;
	bus_pre.r1 = (unsigned char)((inst1 & 0x38) >> 3);
	bus_pre.r2 = (unsigned char)(inst1 & 0x07);
	bus_pre.dd1 = (unsigned char)((inst1 & 0x30) >> 4);
	bus_pre.qq1 = (unsigned char)((inst1 & 0x30) >> 4);

	if ((Doze.ir & 0x00ff) == 0x007f)
		Doze.ir &= 0x1100;
	else
		Doze.ir++;

	switch(inst1)						//I_word[31:24])
	{
          case 0x00:
            { uINSTR_RUN(NOP); goto end_micro_inst; }
		  case 0x0A:
            { uINSTR_RUN(LD_A_BC); goto end_micro_inst; }
          case 0x1A:
            { uINSTR_RUN(LD_A_DE); goto end_micro_inst; }
          case 0x02:
            { uINSTR_RUN(LD_BC_A); goto end_micro_inst; }
          case 0x12:
            { uINSTR_RUN(LD_DE_A); goto end_micro_inst; }
          case 0xF9:
            { uINSTR_RUN(LD_SP_HL); goto end_micro_inst; }
          case 0xEB:
            { uINSTR_RUN(EX_DE_HL); goto end_micro_inst; }
          case 0x08:
            { uINSTR_RUN(EX_AF_AF); goto end_micro_inst; }
          case 0xD9:
            { uINSTR_RUN(EXX); goto end_micro_inst; }
          case 0xE3:
            { uINSTR_RUN(EX_SP_HL); goto end_micro_inst; }
          case 0x27:
            { uINSTR_RUN(DAA); goto end_micro_inst; }
          case 0x2F:
            { uINSTR_RUN(CPL); goto end_micro_inst; }
          case 0x3F:
            { uINSTR_RUN(CCF); goto end_micro_inst; }
          case 0x37:
            { uINSTR_RUN(SCF); goto end_micro_inst; }
          case 0xF3:
            { uINSTR_RUN(DI); goto end_micro_inst; }
          case 0xFB:
            { uINSTR_RUN(EI); goto end_micro_inst; }
          case 0x07:
            { uINSTR_RUN(RLCA); goto end_micro_inst; }
          case 0x17:
            { uINSTR_RUN(RLA); goto end_micro_inst; }
          case 0x0F:
            { uINSTR_RUN(RRCA); goto end_micro_inst; }
          case 0x1F:
            { uINSTR_RUN(RRA); goto end_micro_inst; }
          case 0xE9:
            { uINSTR_RUN(JP_HL); goto end_micro_inst; }
          case 0xC9:
            { uINSTR_RUN(RET); goto end_micro_inst; }
	default:
//----------------------------------------------------------
//			 Group only concerned [5:4] 2 bit				 
//----------------------------------------------------------	
		switch(inst1 & 0xCF)
		{
		  case 0xC5:			// 11??0101:
            { uINSTR_RUN(PUSH_qq); goto end_micro_inst; }
          case 0xC1:			// 11??0001:
            { uINSTR_RUN(POP_qq); goto end_micro_inst; }
          case 0x09:			// 00??1001:
            { uINSTR_RUN(ADD_HL_ss); goto end_micro_inst; }
          case 0x03:			// 00??0011:
            { uINSTR_RUN(INC_ss); goto end_micro_inst; }
          case 0x0B:			// 00??1011:
            { uINSTR_RUN(DEC_ss); goto end_micro_inst; }
		}
//----------------------------------------------------------
//			 Group only concerned [2:0] 3 bit				 
//----------------------------------------------------------
		switch(inst1 & 0xF8)
		{
          case 0x80:			// 10000???
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(ADD_A_r); goto end_micro_inst; }
              else
                { uINSTR_RUN(ADD_A_HL); goto end_micro_inst; }
          case 0x88:			// 10001???			
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(ADC_A_s_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(ADC_A_s_3); goto end_micro_inst; }
          case 0x90:			// 10010???
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(SUB_s_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(SUB_s_3); goto end_micro_inst; }
          case 0x98:			// 10011???
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(SBC_A_s_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(SBC_A_s_3); goto end_micro_inst; }
          case 0xA0:			// 10100???
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(AND_s_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(AND_s_3); goto end_micro_inst; }
          case 0xB0:			// 10110???
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(OR_s_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(OR_s_3); goto end_micro_inst; }
          case 0xA8:			// 10101???
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(XOR_s_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(XOR_s_3); goto end_micro_inst; }
          case 0xB8:			// 10111???
              if((inst1 & 0x07) != 0x06)	//I_word[26:24] != 3'b110
                { uINSTR_RUN(CP_s_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(CP_s_3); goto end_micro_inst; }
		}
//----------------------------------------------------------
//			 Group only concerned [5:3] 3 bit				 
//----------------------------------------------------------
        switch(inst1 & 0xC7)
		{
		  case 0x04:		// 00???100
              if((inst1 & 0x38) != 0x30)	//I_word[29:27] != 3'b110
                { uINSTR_RUN(INC_r); goto end_micro_inst; }
              else
                { uINSTR_RUN(INC_HL); goto end_micro_inst; }
          case 0x05:		// 00???101
              if((inst1 & 0x38) != 0x30)	//I_word[29:27] != 3'b110
                { uINSTR_RUN(DEC_m_1); goto end_micro_inst; }
              else
                { uINSTR_RUN(DEC_m_2); goto end_micro_inst; }
          case 0xC0:		// 11???000
            { uINSTR_RUN(RET_cc); goto end_micro_inst; }
          case 0xC7:		// 11???111
            { uINSTR_RUN(RST_p); goto end_micro_inst; }
		}
//-----------------------------------------------------------
        if ( (inst1 & 0xC0) == 0x40 )			// 01??????:
		{
              //if((I_word[29:27] != 3'b110) && (I_word[26:24] != 3'b110))
              if (((inst1 & 0x38) != 0x30) && ((inst1 & 0x07) != 0x06))
				{ uINSTR_RUN(LD_r_r); goto end_micro_inst; }
              //else if((I_word[29:27] != 3'b110) && (I_word[26:24] == 3'b110))
			  else if(((inst1 & 0x38) != 0x30) && ((inst1 & 0x07) == 0x06))
                { uINSTR_RUN(LD_r_HL); goto end_micro_inst; }
              //else if((I_word[29:27] == 3'b110) && (I_word[26:24] != 3'b110))
			  else if(((inst1 & 0x38) == 0x30) && ((inst1 & 0x07) != 0x06))
                { uINSTR_RUN(LD_HL_r); goto end_micro_inst; }
              else
                { uINSTR_RUN(HALT); goto end_micro_inst; }
		}
	}