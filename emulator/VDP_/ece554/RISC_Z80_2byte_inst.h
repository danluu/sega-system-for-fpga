   
    /////////////////////////////////////////
    // start of 2 byte z80 instruction decode
    /////////////////////////////////////////
	bus_pre.n2 = inst2;
	bus_pre.r3 = (unsigned char)((inst2 & 0x38) >> 3);
	bus_pre.r4 = (unsigned char)(inst2 & 0x07);
	bus_pre.dd2 = (unsigned char)((inst2 & 0x30) >> 4);
	bus_pre.pp2 = (unsigned char)((inst2 & 0x30) >> 4);
	bus_pre.rr2 = (unsigned char)((inst2 & 0x30) >> 4);
	
	if ((Doze.ir & 0x00ff) == 0x007f)
		Doze.ir &= 0x1100;
	else
		Doze.ir++;

	switch(inst1)					//I_word[31:24]
	{
          case 0xC6:
            { uINSTR_RUN(ADD_A_n); goto end_micro_inst; }
          case 0xCE:
            { uINSTR_RUN(ADC_A_s_2); goto end_micro_inst; }
          case 0xD6:
            { uINSTR_RUN(SUB_s_2); goto end_micro_inst; }
          case 0xDE:
            { uINSTR_RUN(SBC_A_s_2); goto end_micro_inst; }
          case 0xE6:
            { uINSTR_RUN(AND_s_2); goto end_micro_inst; }
          case 0xF6:
            { uINSTR_RUN(OR_s_2); goto end_micro_inst; }
          case 0xEE:
            { uINSTR_RUN(XOR_s_2); goto end_micro_inst; }
          case 0xFE:
            { uINSTR_RUN(CP_s_2); goto end_micro_inst; }
          case 0x18:
            { uINSTR_RUN(JR_e); goto end_micro_inst; }
          case 0x38:
            { uINSTR_RUN(JR_C_e); goto end_micro_inst; }
          case 0x30:
            { uINSTR_RUN(JR_NC_e); goto end_micro_inst; }
          case 0x28:
            { uINSTR_RUN(JR_Z_e); goto end_micro_inst; }
          case 0x20:
            { uINSTR_RUN(JR_NZ_e); goto end_micro_inst; }
          case 0x10:
            { uINSTR_RUN(DJNZ_e); goto end_micro_inst; }
          case 0xDB:
            { uINSTR_RUN(IN_A_n); goto end_micro_inst; }
          case 0xD3:
            { uINSTR_RUN(OUT_n_A); goto end_micro_inst; }
   
//---------------------------------------------------
//					CB group
//---------------------------------------------------
	      case 0xCB:
			  //nDozeCycles -= 4;
	          switch(inst2 & 0xF8)
				{
				case 0x00:			// 00000???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(RLC_r); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(RLC_HL); goto end_micro_inst; }
				case 0x10:			// 00010???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(RL_m_1); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(RL_m_2); goto end_micro_inst; }
				case 0x08:			// 00001???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(RRC_m_1); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(RRC_m_2); goto end_micro_inst; }
				case 0x18:			// 00011???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(RR_m_1); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(RR_m_2); goto end_micro_inst; }
				case 0x20:			// 00100???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(SLA_m_1); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(SLA_m_2); goto end_micro_inst; }
// SLL
				case 0x30:			// 00110???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(SLL_m_1); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(SLL_m_2); goto end_micro_inst; }
				case 0x28:			// 00101???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(SRA_m_1); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(SRA_m_2); goto end_micro_inst; }
				case 0x38:			// 00111???:
	              if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
	                { uINSTR_RUN(SRL_m_1); goto end_micro_inst; }
	              else
	                { uINSTR_RUN(SRL_m_2); goto end_micro_inst; }
				default:
					switch(inst2 & 0xC0)
						{
						case 0x40:			// 01??????:
						  if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
							{ uINSTR_RUN(BIT_b_r); goto end_micro_inst; }
						  else
							{ uINSTR_RUN(BIT_b_HL); goto end_micro_inst; }
						case 0xC0:			// 11??????:
						  if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
							{ uINSTR_RUN(SET_b_r); goto end_micro_inst; }
						  else
							{ uINSTR_RUN(SET_b_HL); goto end_micro_inst; }
						case 0x80:			// 10??????:
						  if((inst2 & 0x07) != 0x06)		//(I_word[18:16] != 3'b110)
							{ uINSTR_RUN(RES_b_m_1); goto end_micro_inst; }
						  else
							{ uINSTR_RUN(RES_b_m_2); goto end_micro_inst; }
						}
				}  
			  break;

			//nDozeCycles += 4;
              
//---------------------------------------------------
//					DD group
//---------------------------------------------------
	      case 0xDD:

			  //nDozeCycles -= 4;
	          switch(inst2)					//I_word[23:16])
				{
	            case 0xF9:
	              { uINSTR_RUN(LD_SP_IX); goto end_micro_inst; }
	            case 0xE5:
	              { uINSTR_RUN(PUSH_IX); goto end_micro_inst; }
	            case 0xE1:
	              { uINSTR_RUN(POP_IX); goto end_micro_inst; }
	            case 0xE3:
	              { uINSTR_RUN(EX_SP_IX); goto end_micro_inst; }
	            case 0x23:
	              { uINSTR_RUN(INC_IX); goto end_micro_inst; }
	            case 0x2B:
	              { uINSTR_RUN(DEC_IX); goto end_micro_inst; }
	            case 0xE9:
	              { uINSTR_RUN(JP_IX); goto end_micro_inst; }    
				default:
					if ((inst2 & 0xCF) == 0x09)		            // 00??1001:
						{ uINSTR_RUN(ADD_IX_pp); goto end_micro_inst; }
			  }
			  break;

			  //nDozeCycles += 4;
              
//---------------------------------------------------
//					ED group
//---------------------------------------------------
          case 0xED:

			  //nDozeCycles -= 4;
              switch(inst2)					//I_word[23:16])
				{
                case 0x57:
                  { uINSTR_RUN(LD_A_I); goto end_micro_inst; }
                case 0x5F:
                  { uINSTR_RUN(LD_A_R); goto end_micro_inst; }
                case 0x47:
                  { uINSTR_RUN(LD_I_A); goto end_micro_inst; }
                case 0x4F:
                  { uINSTR_RUN(LD_R_A); goto end_micro_inst; }
                case 0xA0:
                  { uINSTR_RUN(LDI); goto end_micro_inst; }
                case 0xB0:
                  { uINSTR_RUN(LDIR); goto end_micro_inst; }
                case 0xA8:
                  { uINSTR_RUN(LDD); goto end_micro_inst; }
                case 0xB8:
                  { uINSTR_RUN(LDDR); goto end_micro_inst; }
                case 0xA1:
                  { uINSTR_RUN(CPI); goto end_micro_inst; }
                case 0xB1:
                  { uINSTR_RUN(CPIR); goto end_micro_inst; }
                case 0xA9:
                  { uINSTR_RUN(CPD); goto end_micro_inst; }
                case 0xB9:
                  { uINSTR_RUN(CPDR); goto end_micro_inst; }
          		case 0x44:
          		  { uINSTR_RUN(NEG); goto end_micro_inst; }
          		case 0x46:
          		  { uINSTR_RUN(IM0); goto end_micro_inst; }
          		case 0x56:
          		  { uINSTR_RUN(IM1); goto end_micro_inst; }
          		case 0x5E:
          		  { uINSTR_RUN(IM2); goto end_micro_inst; }
          		case 0x6F:
          		  { uINSTR_RUN(RLD); goto end_micro_inst; }
          		case 0x67:
          		  { uINSTR_RUN(RRD); goto end_micro_inst; }
          		case 0x4D:
          		  { uINSTR_RUN(RETI); goto end_micro_inst; }
          		case 0x45:
          		  { uINSTR_RUN(RETN); goto end_micro_inst; }
          	    case 0xA2:
          	      { uINSTR_RUN(INI); goto end_micro_inst; }
          	    case 0xB2:
          	      { uINSTR_RUN(INIR); goto end_micro_inst; }
          	    case 0xAA:
          	      { uINSTR_RUN(IND); goto end_micro_inst; }
          	    case 0xBA:
          	      { uINSTR_RUN(INDR); goto end_micro_inst; }
          	    case 0xA3:
          	      { uINSTR_RUN(OUTI); goto end_micro_inst; }
          	    case 0xB3:
          	      { uINSTR_RUN(OTIR); goto end_micro_inst; }
          	    case 0xAB:
          	      { uINSTR_RUN(OUTD); goto end_micro_inst; }
          	    case 0xBB:
          	      { uINSTR_RUN(OTDR); goto end_micro_inst; }
				default:
          			if ((inst2 & 0xCF) == 0x4A)			// 01??1010:
          			  { uINSTR_RUN(ADC_HL_ss); goto end_micro_inst; }
          			else if ((inst2 & 0xCF) == 0x42)	// 01??0010:
          			  { uINSTR_RUN(SBC_HL_ss); goto end_micro_inst; }
					else if ((inst2 & 0xC7) == 0x40)	// 01???000:
          			  { uINSTR_RUN(IN_r_C); goto end_micro_inst; }
					else if ((inst2 & 0xC7) == 0x41)	// 01???001:
          			  { uINSTR_RUN(OUT_C_r); goto end_micro_inst; }
				}
			  break;	// this is the break Tsung-chi forgot to put
  
			  //nDozeCycles += 4;
//---------------------------------------------------
//					FD group
//---------------------------------------------------
	      case 0xFD:
			  
			  //nDozeCycles -= 4;
	          switch(inst2)					//I_word[23:16])
				{
	            case 0xF9:
	              { uINSTR_RUN(LD_SP_IY); goto end_micro_inst; }
	            case 0xE5:
	              { uINSTR_RUN(PUSH_IY); goto end_micro_inst; }
	            case 0xE1:
	              { uINSTR_RUN(POP_IY); goto end_micro_inst; }
	            case 0xE3:
	              { uINSTR_RUN(EX_SP_IY); goto end_micro_inst; }
	            case 0x23:
	              { uINSTR_RUN(INC_IY); goto end_micro_inst; }
	            case 0x2B:
	              { uINSTR_RUN(DEC_IY); goto end_micro_inst; }
	            case 0xE9:
	              { uINSTR_RUN(JP_IY); goto end_micro_inst; }
				default:
					if ((inst2 & 0xCF) == 0x09)		// 00??1001:
					  { uINSTR_RUN(ADD_IY_rr); goto end_micro_inst; } 
				}
			  break;  // this is the break Tsung-chi forgot to put
			  
			  //nDozeCycles += 4;

		  default:
			  if( (inst1 & 0xC7) == 0x06)				// 00???110:
			  {
				  if( (inst1 & 0x38) != 0x30)		    //(I_word[29:27] != 3'b110)
				  { uINSTR_RUN(LD_r_n); goto end_micro_inst; }
				  else
				  { uINSTR_RUN(LD_HL_n); goto end_micro_inst; }
			  }
	}
