    /////////////////////////////////////////
    // start of 3 byte z80 instruction decode
    /////////////////////////////////////////      
	bus_pre.n3 = inst3;
	bus_pre.d = inst3;
	bus_pre.nn1_i = (unsigned short)(((int)inst2 << 8) + inst3);
	bus_pre.nn1 = (unsigned short)(((int)inst3 << 8) + inst2);

	if ((Doze.ir & 0x00ff) == 0x007f)
		Doze.ir &= 0x1100;
	else
		Doze.ir++;

	switch(inst1)							//I_word[31:24])
		{
		  case 0x3A:
		    { uINSTR_RUN(LD_A_nn); goto end_micro_inst; }
		  case 0x32:
		    { uINSTR_RUN(LD_nn_A); goto end_micro_inst; }
		  case 0x2A:
		    { uINSTR_RUN(LD_HL_nn); goto end_micro_inst; }
		  case 0x22:
		    { uINSTR_RUN(LD_nn_HL); goto end_micro_inst; }
		  case 0xC3:
		    { uINSTR_RUN(JP_nn); goto end_micro_inst; }
		  case 0xCD:
		    { uINSTR_RUN(CALL_nn); goto end_micro_inst; }
//---------------------------------------------------
//					DD group
//---------------------------------------------------
          case 0xDD:
			  
			  //nDozeCycles -= 4;
              switch(inst2)					//I_word[23:16])
				{
                case 0x86:
                  { uINSTR_RUN(ADD_A_IX_d); goto end_micro_inst; }
                case 0x8E:
                  { INSTR_RUN(ADC_A_s_4); goto end_micro_inst; }
                case 0x96:
                  { uINSTR_RUN(SUB_s_4); goto end_micro_inst; }
                case 0x9E:
                  { uINSTR_RUN(SBC_A_s_4); goto end_micro_inst; }
                case 0xA6:
                  { uINSTR_RUN(AND_s_4); goto end_micro_inst; }  
                case 0xB6:
                  { uINSTR_RUN(OR_s_4); goto end_micro_inst; }
                case 0xAE:
                  { uINSTR_RUN(XOR_s_4); goto end_micro_inst; }
                case 0xBE:
                  { uINSTR_RUN(CP_s_4); goto end_micro_inst; }
                case 0x34:
                  { uINSTR_RUN(INC_IX_d); goto end_micro_inst; }
                case 0x35:
                  { uINSTR_RUN(DEC_m_3); goto end_micro_inst; }  
                default:
					if ((inst2 & 0xC0) == 0x40)			// 8'b01??????:
					{
					  // if((I_word[21:19] != 3'b110) && (I_word[18:16] == 3'b110))
					  if (((inst2 & 0x38) != 0x30) && ((inst2 & 0x07) == 0x06))
						{ uINSTR_RUN(LD_r_IX_d); goto end_micro_inst; }
					  // else if((I_word[21:19] == 3'b110) && (I_word[18:16] != 3'b110))
					  else if (((inst2 & 0x38) == 0x30) && ((inst2 & 0x07) != 0x06))	
					    { uINSTR_RUN(LD_IX_d_r); goto end_micro_inst; }
					}
				}
			  break;
			  
			  //nDozeCycles += 4;

//---------------------------------------------------
//					FD group
//---------------------------------------------------
          case 0xFD:
			  
			  //nDozeCycles -= 4;
              switch(inst2)					//I_word[23:16])
				{
                case 0x86:
                  { uINSTR_RUN(ADD_A_IY_d); goto end_micro_inst; }
                case 0x8E:
                  { uINSTR_RUN(ADC_A_s_5); goto end_micro_inst; }     
                case 0x96:
                  { uINSTR_RUN(SUB_s_5); goto end_micro_inst; }
                case 0x9E:
                  { uINSTR_RUN(SBC_A_s_5); goto end_micro_inst; }
                case 0xA6:
                  { uINSTR_RUN(AND_s_5); goto end_micro_inst; }
                case 0xB6:
                  { uINSTR_RUN(OR_s_5); goto end_micro_inst; }
                case 0xAE:
                  { uINSTR_RUN(XOR_s_5); goto end_micro_inst; }
                case 0xBE:
                  { uINSTR_RUN(CP_s_5); goto end_micro_inst; }
                case 0x34:
                  { uINSTR_RUN(INC_IY_d); goto end_micro_inst; }
                case 0x35:
                  { uINSTR_RUN(DEC_m_4); goto end_micro_inst; }
                default:
   					if ((inst2 & 0xC0) == 0x40)			// 8'b01??????:
					{
					  // if((I_word[21:19] != 3'b110) && (I_word[18:16] == 3'b110))
					  if (((inst2 & 0x38) != 0x30) && ((inst2 & 0x07) == 0x06))
						{ uINSTR_RUN(LD_r_IY_d); goto end_micro_inst; }
					  // else if((I_word[21:19] == 3'b110) && (I_word[18:16] != 3'b110))
					  else if (((inst2 & 0x38) == 0x30) && ((inst2 & 0x07) != 0x06))	
					    { uINSTR_RUN(LD_IY_d_r); goto end_micro_inst; }
					}
				}
			  break;
			  
			  //nDozeCycles += 4;


          default:
			if ((inst1 & 0xCF) == 0x01)				// 00??0001:
				{ uINSTR_RUN(LD_dd_nn2); goto end_micro_inst; }
			else if ((inst1 & 0xC7) == 0xC2)		// 11???010:
				{ uINSTR_RUN(JP_cc_nn); goto end_micro_inst; }
			else if ((inst1 & 0xC7) == 0xC4)		// 11???100:
				{ uINSTR_RUN(CALL_cc_nn); goto end_micro_inst; }
	} 