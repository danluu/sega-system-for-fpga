    /////////////////////////////////////////
    // start of 4 byte z80 instruction decode
    /////////////////////////////////////////      
	bus_pre.n4 = inst4;
	bus_pre.nn2 = inst4;
	bus_pre.nn2 = (unsigned short)(((bus_pre.nn2) << 8) + inst3);
	bus_pre.b4 = (unsigned char)((inst4 & 0x38) >> 3);

if ((inst1 == 0xDD) && (inst2 == 0xCB) && (((inst4)&0xC7) != 0x06))
{inst4 = inst4;}

	if ((Doze.ir & 0x00ff) == 0x007f)
		Doze.ir &= 0x1100;
	else
		Doze.ir++;

	switch(inst1)
		{
//---------------------------------------------------
//					DD group
//---------------------------------------------------
	      case 0xDD:
			  
			  //nDozeCycles -= 4;
	          switch(inst2)			//I_word[23:16])
				{
	            case 0x36:
	              { INSTR_RUN(LD_IX_d_n); goto end_inst; }
	            case 0x21:
	              { INSTR_RUN(LD_IX_nn2); goto end_inst; }
	            case 0x2A:
	              { INSTR_RUN(LD_IX_nn); goto end_inst; }
	            case 0x22:
	              { INSTR_RUN(LD_nn_IX); goto end_inst; }
	            case 0xCB:
				  //nDozeCycles -= 4;
	              switch(inst4)		//I_word[7:0])
					{
	                  case 0x06:
	                    { INSTR_RUN(RLC_IX_d); goto end_inst; }
	                  case 0x16:
	                    { INSTR_RUN(RL_m_3); goto end_inst; }
	                  case 0x0E:
	                    { INSTR_RUN(RRC_m_3); goto end_inst; }
	                  case 0x1E:
	                    { INSTR_RUN(RR_m_3); goto end_inst; }
	                  case 0x26:
	                    { INSTR_RUN(SLA_m_3); goto end_inst; }
// SLL
	                  case 0x36:
	                    { INSTR_RUN(SLL_m_3); goto end_inst; }
	                  case 0x2E:
	                    { INSTR_RUN(SRA_m_3); goto end_inst; }
	                  case 0x3E:
	                    { INSTR_RUN(SRL_m_3); goto end_inst; }
					  default: 
						switch (inst4 & 0xC7)
						{
						  case 0x46:			// 01???110:
							{ INSTR_RUN(BIT_b_IX_d); goto end_inst; }
						  case 0xC6:			// 11???110:
							{ INSTR_RUN(SET_b_IX_d); goto end_inst; }
						  case 0x86:			// 10???110:
							{ INSTR_RUN(RES_b_m_3); goto end_inst; }
						}
					}
				  //nDozeCycles += 4;
	            default: break;
				}
			  break;
			  
			  //nDozeCycles += 4;
//---------------------------------------------------
//					ED group
//---------------------------------------------------
	      case 0xED:	   
			  
			  //nDozeCycles -= 4;
	          switch(inst2 & 0xCF)
				{
				case 0x4B:			// 01??1011:
	              { INSTR_RUN(LD_dd_nn); goto end_inst; }
				case 0x43:			// 01??0011:
	              { INSTR_RUN(LD_nn_dd); goto end_inst; }
	            default: break;
				}
			  break;
			  //nDozeCycles += 4;

//---------------------------------------------------
//					FD group
//---------------------------------------------------
	      case 0xFD:
			  
			  //nDozeCycles -= 4;
	          switch(inst2)			//I_word[23:16])
				{
	            case 0x36:
	              { INSTR_RUN(LD_IY_d_n); goto end_inst; }
	            case 0x21:
	              { INSTR_RUN(LD_IY_nn2); goto end_inst; }
	            case 0x2A:
	              { INSTR_RUN(LD_IY_nn); goto end_inst; }
	            case 0x22:
	              { INSTR_RUN(LD_nn_IY); goto end_inst; }
	            case 0xCB:
					//nDozeCycles -= 4;
	              switch(inst4)		//I_word[7:0])
					{
					  case 0x06:
	                    { INSTR_RUN(RLC_IY_d); goto end_inst; }
	                  case 0x16:
	                    { INSTR_RUN(RL_m_4); goto end_inst; }
	                  case 0x0E:
	                    { INSTR_RUN(RRC_m_4); goto end_inst; }
	                  case 0x1E:
	                    { INSTR_RUN(RR_m_4); goto end_inst; }
	                  case 0x26:
	                    { INSTR_RUN(SLA_m_4); goto end_inst; }
// SLL
	                  case 0x36:
	                    { INSTR_RUN(SLL_m_4); goto end_inst; }
	                  case 0x2E:
	                    { INSTR_RUN(SRA_m_4); goto end_inst; }
	                  case 0x3E:
	                    { INSTR_RUN(SRL_m_4); goto end_inst; }
	                  default: 
						switch(inst4 & 0xC7)
						{
						  case 0x46:		// 01???110:
							{ INSTR_RUN(BIT_b_IY_d); goto end_inst; }
						  case 0xC6:		// 11???110:
							{ INSTR_RUN(SET_b_IY_d); goto end_inst; }
						  case 0x86:		// 10???110:
							{ INSTR_RUN(RES_b_m_4); goto end_inst; }
						}
					}
				  //nDozeCycles += 4;
	            default: break;
				}
			  break;

			  
			  //nDozeCycles += 4;


	    default: break;
		}