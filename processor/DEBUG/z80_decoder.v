///////////////////////////////////////////////////////////
// z80_decoder in translator part
///////////////////////////////////////////////////////////
module z80_decoder (CLK, RST, flush, I_wait, I_byte, xlator_stall, z80dec_stall, I_word, I_word_rdy, z80_I_ID, invalid_inst) ;

input CLK ;
input RST ;
input flush ;
input I_wait ;
input [7:0] I_byte ;
input xlator_stall ;
output z80dec_stall ;
output [31:0] I_word ;
output I_word_rdy ;
output [7:0] z80_I_ID ;
// for a test purpose
output invalid_inst;

reg z80dec_stall;
wire [2:0] num_bytes;
reg invalid_inst;

// declare a z80 decoder module
z80_I_decode DEC(num_bytes, I_word, I_word_rdy, z80_I_ID);

// declare a queue module
z80_Q QUEUE(CLK, RST, flush, I_wait, I_byte, xlator_stall, I_word, I_word_rdy, num_bytes);

//assign z80dec_stall = I_word_rdy & xlator_stall;
always@(I_word_rdy or xlator_stall)
begin
  if((I_word_rdy == 1'b1) && (xlator_stall == 1'b1))
    z80dec_stall <= 1'b1;
  else
    z80dec_stall <= 1'b0;
end

// invalid instruction?
always@(num_bytes or I_word_rdy)
begin
  if((num_bytes == 3'b100) && (I_word_rdy == 1'b0))
    invalid_inst <= 1'b1;
  else
    invalid_inst <= 1'b0;
end

endmodule 

///////////////////////////////////////////////////////////
// z80_Q module in z80_decoder
///////////////////////////////////////////////////////////
module z80_Q (CLK, RST, flush, I_wait, I_byte, xlator_stall, I_word, I_word_rdy, num_bytes) ;

input CLK ;
input RST ;
input flush ;
input I_wait ;
input [7:0] I_byte ;
input xlator_stall ;
input I_word_rdy ;
output [31:0] I_word ;
output [2:0] num_bytes;

reg [2:0] curr_state, next_state;
reg [31:0] I_word;
reg [2:0] num_bytes;

// state definitions
parameter init_s = 3'b000, byte1_s = 3'b001, byte2_s = 3'b010, byte3_s = 3'b011, byte4_s = 3'b100,
	  stall_s = 3'b101;
	  
always@(posedge CLK)
begin
  if((RST == 1'b1) || (flush == 1'b1))
  begin
    curr_state <= init_s;
    I_word <= 32'H0;	// initialize I_word
  end	// end of RST handling
  else
  begin
    I_word <= I_word;   // default setup
    if(I_wait == 1'b0)
    begin
      case(next_state)	// synchronous storage control
        init_s: begin	// nothing to read from I_byte
          end
        byte1_s: 		// read I_byte and put it into I_word[??:??]
          I_word[31:24] <= I_byte;
        byte2_s:
    	  I_word[23:16] <= I_byte;
        byte3_s:
       	  I_word[15:8]  <= I_byte;
        byte4_s:
    	  I_word[7:0]   <= I_byte;
        stall_s: begin	// do nothing
    	         end
        default: begin	// do nothing
    	         end
      endcase
    end
    // proceed to the next state
    curr_state <= next_state;
  end
end

// determine the next state
always@(curr_state or I_wait or I_word_rdy or xlator_stall or num_bytes) // NOV23
begin
  case(curr_state)
    init_s:
      begin
        num_bytes <= 3'b000; 
        if(I_wait == 1'b0)	// no I_wait. read I_word
          next_state <= byte1_s;
        else
          next_state <= init_s;
      end
    byte1_s:
      begin
        num_bytes <= 3'b001;
        if(I_word_rdy == 1'b1)	// a complete z80 instruction
        begin
          if(xlator_stall == 1'b1)
            next_state <= stall_s;
          else
          begin
            if(I_wait == 1'b0)
              next_state <= byte1_s;
            else
              next_state <= init_s;
          end
        end
        else
        begin
          if(I_wait == 1'b0)
            next_state <= byte2_s;
          else
            next_state <= byte1_s;
        end
      end
    byte2_s:
      begin
        num_bytes <= 3'b010;
        if(I_word_rdy == 1'b1)
        begin
          if(xlator_stall == 1'b1)
            next_state <= stall_s;
          else
          begin
            if(I_wait == 1'b0)
              next_state <= byte1_s;
            else
              next_state <= init_s;
          end
        end
        else
        begin
          if(I_wait == 1'b0)
            next_state <= byte3_s;
          else
            next_state <= byte2_s;
        end
      end
    byte3_s:
      begin
        num_bytes <= 3'b011;      
        if(I_word_rdy == 1'b1)
        begin
          if(xlator_stall == 1'b1)
            next_state <= stall_s;
          else
          begin
            if(I_wait == 1'b0)
              next_state <= byte1_s;
            else
              next_state <= init_s;
          end
        end
        else
        begin
          if(I_wait == 1'b0)
            next_state <= byte4_s;
          else
            next_state <= byte3_s;
        end
      end
    byte4_s:
      begin
        num_bytes <= 3'b100;      
        if(I_word_rdy == 1'b1)
        begin
          if(xlator_stall == 1'b1)
            next_state <= stall_s;
          else
          begin
            if(I_wait == 1'b0)
              next_state <= byte1_s;
            else
              next_state <= init_s;
          end
        end
        else
        begin	// if you reach this stage, something is wrong. Drop insts
          if(I_wait == 1'b0)
            next_state <= byte1_s;
          else
            next_state <= init_s;
        end
      end
    stall_s:
      begin
        num_bytes <= num_bytes;
        if(xlator_stall == 1'b1)
          next_state <= stall_s;
        else
        begin
          if(I_wait == 1'b0)
            next_state <= byte1_s;
          else
            next_state <= init_s;
        end
      end
    default:
      begin
        num_bytes <= 3'b000;
        next_state <= init_s;
      end
  endcase
end	// end of next state generation  
       
endmodule 

///////////////////////////////////////////////////////////
// z80_I_decode in z80_decoder
///////////////////////////////////////////////////////////
module z80_I_decode (num_bytes, I_word, I_word_rdy, z80_I_ID) ;

input [2:0] num_bytes;
input [31:0] I_word;
output I_word_rdy;
output [7:0] z80_I_ID;

reg I_word_rdy;
reg [7:0] z80_I_ID;

// include instruction ID definitions
`include "z80_I_ID.def"

// define emit
task EMIT;
  input [7:0] I_ID;
  begin
    z80_I_ID <= I_ID;
    I_word_rdy <= 1'b1;
  end
endtask
   
always@(num_bytes or I_word)
begin
  // default output
  I_word_rdy <= 1'b0;
  z80_I_ID <= 8'b0;
  
  case(num_bytes)
    3'b000: 	// no valid instruction
      begin
        I_word_rdy <= 1'b0;
        z80_I_ID <= 8'b0;	// maybe nop
      end
    /////////////////////////////////////////
    // start of 1 byte z80 instruction decode
    /////////////////////////////////////////
    3'b001:
      begin
        casez(I_word[31:24])
          8'H00:
            EMIT(NOP);
          8'b01??????:
            begin
              if((I_word[29:27] != 3'b110) && (I_word[26:24] != 3'b110))
                EMIT(LD_r_r);
              else if((I_word[29:27] != 3'b110) && (I_word[26:24] == 3'b110))
                EMIT(LD_r_HL);
              else if((I_word[29:27] == 3'b110) && (I_word[26:24] != 3'b110))
                EMIT(LD_HL_r);
              else
                EMIT(HALT);
            end
          8'H0A:
            EMIT(LD_A_BC);
          8'H1A:
            EMIT(LD_A_DE);
          8'H02:
            EMIT(LD_BC_A);
          8'H12:
            EMIT(LD_DE_A);
          8'HF9:
            EMIT(LD_SP_HL);
          8'b11??0101:
            EMIT(PUSH_qq);
          8'b11??0001:
            EMIT(POP_qq);
          8'HEB:
            EMIT(EX_DE_HL);
          8'H08:
            EMIT(EX_AF_AF);
          8'HD9:
            EMIT(EXX);
          8'HE3:
            EMIT(EX_SP_HL);
          8'b10000???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(ADD_A_r);
              else
                EMIT(ADD_A_HL);
            end
          8'b10001???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(ADC_A_s_1);
              else
                EMIT(ADC_A_s_3);
            end
          8'b10010???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(SUB_s_1);
              else
                EMIT(SUB_s_3);
            end
          8'b10011???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(SBC_A_s_1);
              else
                EMIT(SBC_A_s_3);
            end
          8'b10100???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(AND_s_1);
              else
                EMIT(AND_s_3);
            end
          8'b10110???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(OR_s_1);
              else
                EMIT(OR_s_3);
            end
          8'b10101???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(XOR_s_1);
              else
                EMIT(XOR_s_3);
            end
          8'b10111???:
            begin
              if(I_word[26:24] != 3'b110)
                EMIT(CP_s_1);
              else
                EMIT(CP_s_3);
            end
          8'b00???100:
            begin
              if(I_word[29:27] != 3'b110)
                EMIT(INC_r);
              else
                EMIT(INC_HL);
            end
          8'b00???101:
            begin
              if(I_word[29:27] != 3'b110)
                EMIT(DEC_m_1);
              else
                EMIT(DEC_m_2);
            end
          8'H27:
            EMIT(DAA);
          8'H2F:
            EMIT(CPL);
          8'H3F:
            EMIT(CCF);
          8'H37:
            EMIT(SCF);
          8'HF3:
            EMIT(DI);
          8'HFB:
            EMIT(EI);
          8'b00??1001:
            EMIT(ADD_HL_ss);
          8'b00??0011:
            EMIT(INC_ss);
          8'b00??1011:
            EMIT(DEC_ss);
          8'H07:
            EMIT(RLCA);
          8'H17:
            EMIT(RLA);
          8'H0F:
            EMIT(RRCA);
          8'H1F:
            EMIT(RRA);
          8'HE9:
            EMIT(JP_HL);
          8'HC9:
            EMIT(RET);
          8'b11???000:
            EMIT(RET_cc);
          8'b11???111:
            EMIT(RST_p);
          default: begin end
        endcase
      end
    
    /////////////////////////////////////////
    // start of 2 byte z80 instruction decode
    /////////////////////////////////////////
    3'b010:
      begin
        casez(I_word[31:24])
          8'b00???110:
            if(I_word[29:27] != 3'b110)
              EMIT(LD_r_n);
            else
              EMIT(LD_HL_n);
          8'HC6:
            EMIT(ADD_A_n);
          8'HCE:
            EMIT(ADC_A_s_2);
          8'HD6:
            EMIT(SUB_s_2);
          8'HDE:
            EMIT(SBC_A_s_2);
          8'HE6:
            EMIT(AND_s_2);
          8'HF6:
            EMIT(OR_s_2);
          8'HEE:
            EMIT(XOR_s_2);
          8'HFE:
            EMIT(CP_s_2);
          8'H18:
            EMIT(JR_e);
          8'H38:
            EMIT(JR_C_e);
          8'H30:
            EMIT(JR_NC_e);
          8'H28:
            EMIT(JR_Z_e);
          8'H20:
            EMIT(JR_NZ_e);
          8'H10:
            EMIT(DJNZ_e);
          8'HDB:
            EMIT(IN_A_n);
          8'HD3:
            EMIT(OUT_n_A);
   
          // CB group ///////////////////////
	      8'HCB:
	        begin
	          casez(I_word[23:16])
	            8'b00000???:
	              if(I_word[18:16] != 3'b110)
	                EMIT(RLC_r);
	              else
	                EMIT(RLC_HL);
	            8'b00010???:
	              if(I_word[18:16] != 3'b110)
	                EMIT(RL_m_1);
	              else
	                EMIT(RL_m_2);
	            8'b00001???:
	              if(I_word[18:16] != 3'b110)
	                EMIT(RRC_m_1);
	              else
	                EMIT(RRC_m_2);
	            8'b00011???:
	              if(I_word[18:16] != 3'b110)
	                EMIT(RR_m_1);
	              else
	                EMIT(RR_m_2);
	            8'b00100???:
	              if(I_word[18:16] != 3'b110)
	                EMIT(SLA_m_1);
	              else
	                EMIT(SLA_m_2);
	            8'b00101???:
	              if(I_word[18:16] != 3'b110)
	                EMIT(SRA_m_1);
	              else
	                EMIT(SRA_m_2);
	            8'b00110???:							// undocumented
	              if(I_word[18:16] != 3'b110)
	                EMIT(SLL_m_1);
	              else
	                EMIT(SLL_m_2);
	            8'b00111???:
	              if(I_word[18:16] != 3'b110)
	                EMIT(SRL_m_1);
	              else
	                EMIT(SRL_m_2);
	            8'b01??????:
	              if(I_word[18:16] != 3'b110)
	                EMIT(BIT_b_r);
	              else
	                EMIT(BIT_b_HL);
	            8'b11??????:
	              if(I_word[18:16] != 3'b110)
	                EMIT(SET_b_r);
	              else
	                EMIT(SET_b_HL);
	            8'b10??????:
	              if(I_word[18:16] != 3'b110)
	                EMIT(RES_b_m_1);
	              else
	                EMIT(RES_b_m_2);
	            default: begin end
	          endcase
	        end         
              
          // DD group ///////////////////////
	      8'HDD:
	        begin
	          casez(I_word[23:16])
	            8'HF9:
	              EMIT(LD_SP_IX);
	            8'HE5:
	              EMIT(PUSH_IX);
	            8'HE1:
	              EMIT(POP_IX);
	            8'HE3:
	              EMIT(EX_SP_IX);
	            8'b00??1001:					//8'b01??1001:
	              EMIT(ADD_IX_pp);
	            8'H23:
	              EMIT(INC_IX);
	            8'H2B:
	              EMIT(DEC_IX);
	            8'HE9:
	              EMIT(JP_IX);    	              
	            default: begin end
	          endcase
	        end         
              
          // ED group ///////////////////////
          8'HED:
            begin
              casez(I_word[23:16])
                8'H57:
                  EMIT(LD_A_I);
                8'H5F:
                  EMIT(LD_A_R);
                8'H47:
                  EMIT(LD_I_A);
                8'H4F:
                  EMIT(LD_R_A);
                8'HA0:
                  EMIT(LDI);
                8'HB0:
                  EMIT(LDIR);
                8'HA8:
                  EMIT(LDD);
                8'HB8:
                  EMIT(LDDR);
                8'HA1:
                  EMIT(CPI);
                8'HB1:
                  EMIT(CPIR);
                8'HA9:
                  EMIT(CPD);
                8'HB9:
                  EMIT(CPDR);
          		//8'H44:
          		//  EMIT(NEG);
          		  
          		// NOV20 reduce NEG cases
          		8'b01???100:
          		  EMIT(NEG);
          		  
          		8'H46:
          		  EMIT(IM0);
          		8'H56:
          		  EMIT(IM1);
          		8'H5E:
          		  EMIT(IM2);
          		8'b01??1010:
          		  EMIT(ADC_HL_ss);
          		8'b01??0010:
          		  EMIT(SBC_HL_ss);
          		8'H6F:
          		  EMIT(RLD);
          		8'H67:
          		  EMIT(RRD);
          		8'H4D:
          		  EMIT(RETI);
          		8'H45:
          		  EMIT(RETN);
          		8'b01???000:
          		  EMIT(IN_r_C);
          	    8'HA2:
          	      EMIT(INI);
          	    8'HB2:
          	      EMIT(INIR);
          	    8'HAA:
          	      EMIT(IND);
          	    8'HBA:
          	      EMIT(INDR);
          	    8'b01???001:
          	      EMIT(OUT_C_r);
          	    8'HA3:
          	      EMIT(OUTI);
          	    8'HB3:
          	      EMIT(OTIR);
          	    8'HAB:
          	      EMIT(OUTD);
          	    8'HBB:
          	      EMIT(OTDR);
          	      
          	    // undocumented instructions 
				//8'H64:
				//  EMIT(NEG);
				8'H65:
				  EMIT(RETN);
				8'H66:
				  EMIT(IM0);
				//8'H4C:
				//  EMIT(NEG);
				//8'H6C:
				//  EMIT(NEG);
				8'H6D:
				  EMIT(RETN);
				8'H4E:
				  EMIT(IM0);
				8'H6E:
				  EMIT(IM0);
				//8'H54:
				//  EMIT(NEG);
				//8'H74:
				//  EMIT(NEG);
				8'H55:
				  EMIT(RETN);
				8'H75:
				  EMIT(RETN);
				8'H76:
				  EMIT(IM1);
				8'H77:
				  EMIT(NOP);
				//8'H5C:
				//  EMIT(NEG);
				8'H5D:
				  EMIT(RETN);
				//8'H7C:
				//  EMIT(NEG);
				8'H7D:
				  EMIT(RETN);
				8'H7E:
				  EMIT(IM2);
				8'H7F:
				  EMIT(NOP);
				  	    
                default: begin end
              endcase
            end

          // FD group ///////////////////////
	      8'HFD:
	        begin
	          casez(I_word[23:16])
	            8'HF9:
	              EMIT(LD_SP_IY);
	            8'HE5:
	              EMIT(PUSH_IY);
	            8'HE1:
	              EMIT(POP_IY);
	            8'HE3:
	              EMIT(EX_SP_IY);
	            8'b00??1001:				// 8'b01??1001:
	              EMIT(ADD_IY_rr);  
	            8'H23:
	              EMIT(INC_IY);
	            8'H2B:
	              EMIT(DEC_IY);
	            8'HE9:
	              EMIT(JP_IY);
	            default: begin end
	          endcase
	        end         
          default: begin end    
        endcase
      end

    /////////////////////////////////////////
    // start of 3 byte z80 instruction decode
    /////////////////////////////////////////      
    3'b011:
      begin
        casez(I_word[31:24])
		  8'H3A:
		    EMIT(LD_A_nn);
		  8'H32:
		    EMIT(LD_nn_A);
		  8'b00??0001:
		    EMIT(LD_dd_nn2);
		  8'H2A:
		    EMIT(LD_HL_nn);
		  8'H22:
		    EMIT(LD_nn_HL);
		  8'HC3:
		    EMIT(JP_nn);
		  8'b11???010:
		    EMIT(JP_cc_nn);
		  8'HCD:
		    EMIT(CALL_nn);
		  8'b11???100:
		    EMIT(CALL_cc_nn);
        
          // DD group /////////////////
          8'HDD:
            begin
              casez(I_word[23:16])
                8'b01??????:
                  if((I_word[21:19] != 3'b110) && (I_word[18:16] == 3'b110))
                    EMIT(LD_r_IX_d);
                  else if((I_word[21:19] == 3'b110) && (I_word[18:16] != 3'b110))
                    EMIT(LD_IX_d_r);
                8'H86:
                  EMIT(ADD_A_IX_d);
                8'H8E:
                  EMIT(ADC_A_s_4);
                8'H96:
                  EMIT(SUB_s_4);
                8'H9E:
                  EMIT(SBC_A_s_4);
                8'HA6:
                  EMIT(AND_s_4);  
                8'HB6:
                  EMIT(OR_s_4);
                8'HAE:
                  EMIT(XOR_s_4);
                8'HBE:
                  EMIT(CP_s_4);
                8'H34:
                  EMIT(INC_IX_d);
                8'H35:
                  EMIT(DEC_m_3);  
                default: begin end
              endcase
            end

          // FD group /////////////////
          8'HFD:
            begin
              casez(I_word[23:16])
                8'b01??????:
                  if((I_word[21:19] != 3'b110) && (I_word[18:16] == 3'b110))
                    EMIT(LD_r_IY_d);
                  else if((I_word[21:19] == 3'b110) && (I_word[18:16] != 3'b110))
                    EMIT(LD_IY_d_r);
                8'H86:
                  EMIT(ADD_A_IY_d);
                8'H8E:
                  EMIT(ADC_A_s_5);     
                8'H96:
                  EMIT(SUB_s_5);
                8'H9E:
                  EMIT(SBC_A_s_5);
                8'HA6:
                  EMIT(AND_s_5);
                8'HB6:
                  EMIT(OR_s_5);
                8'HAE:
                  EMIT(XOR_s_5);
                8'HBE:
                  EMIT(CP_s_5);
                8'H34:
                  EMIT(INC_IY_d);
                8'H35:
                  EMIT(DEC_m_4);
                default: begin end
              endcase
            end
          default: begin end
        endcase      
      end
      
    /////////////////////////////////////////
    // start of 4 byte z80 instruction decode
    /////////////////////////////////////////      
    3'b100:
      begin	// should be rdy
	    casez(I_word[31:24])
	      // DD group ///////////////////////
	      8'HDD:
	        begin
	          casez(I_word[23:16])
	            8'H36:
	              EMIT(LD_IX_d_n);
	            8'H21:
	              EMIT(LD_IX_nn2);
	            8'H2A:
	              EMIT(LD_IX_nn);
	            8'H22:
	              EMIT(LD_nn_IX);
	            8'HCB:
	              begin							// undocumented instruction section
	                casez(I_word[7:0])
	                  8'b00000???:				// documented 8'H06:
	                    EMIT(RLC_IX_d);
	                  8'b00010???: 				// 8'H16:
	                    EMIT(RL_m_3);
	                  8'b00001???: 				// 8'H0E:
	                    EMIT(RRC_m_3);
	                  8'b00011???: 				// 8'H1E:
	                    EMIT(RR_m_3);
	                  8'b00100???:				// 8'H26:
	                    EMIT(SLA_m_3);
	                  8'H36:
	                    EMIT(SLL_m_3);
	                  8'b00101???: 				// 8'H2E:
	                    EMIT(SRA_m_3);
	                  8'b00111???:				// 8'H3E:
	                    EMIT(SRL_m_3);
	                  8'b01??????:				// documented ???110
	                    EMIT(BIT_b_IX_d);
	                  8'b11??????:				// documented ???110
	                    EMIT(SET_b_IX_d);
	                  8'b10??????:				// documented ???110
	                    EMIT(RES_b_m_3);
	                  default: begin end
	                endcase
	              end
	            default: begin end
	          endcase
	        end

	      // ED group ///////////////////////
	      8'HED:
	        begin
	          casez(I_word[23:16])
	            8'b01??1011:
	              EMIT(LD_dd_nn);
	            8'b01??0011:					// 8'b00??0011:
	              EMIT(LD_nn_dd);
	            default: begin end
	          endcase
	        end

	      // FD group ///////////////////////
	      8'HFD:
	        begin
	          casez(I_word[23:16])
	            8'H36:
	              EMIT(LD_IY_d_n);
	            8'H21:
	              EMIT(LD_IY_nn2);
	            8'H2A:
	              EMIT(LD_IY_nn);
	            8'H22:
	              EMIT(LD_nn_IY);
	            8'HCB:
	              begin								// undocumented section
	                casez(I_word[7:0])
	                  8'b00000???:					// 8'H06: documented
	                    EMIT(RLC_IY_d);
	                  8'b00010???:					// 8'H16:
	                    EMIT(RL_m_4);
	                  8'b00001???: 					// 8'H0E:
	                    EMIT(RRC_m_4);
	                  8'b00011???:					// 8'H1E:
	                    EMIT(RR_m_4);
	                  8'b00100???:					// 8'H26:
	                    EMIT(SLA_m_4);
	                  8'H36:
	                    EMIT(SLL_m_4);
	                  8'b00101???:					// 8'H2E:
	                    EMIT(SRA_m_4);
	                  8'b00111???:					// 8'H3E:
	                    EMIT(SRL_m_4);
	                  8'b01??????:					// ???110 documented
	                    EMIT(BIT_b_IY_d);
	                  8'b11??????:					// ???110 undocumented
	                    EMIT(SET_b_IY_d);
	                  8'b10??????:					// ???110 undocumented
	                    EMIT(RES_b_m_4);
	                  default: begin end
	                endcase
	              end
	            default: begin end
	          endcase
	        end
	      default: begin end
	    endcase
      end
      
    default:	// shouldn't be here. no instruction is decoded
      begin
        I_word_rdy <= 1'b0;
        z80_I_ID <= 8'b0;
      end
  endcase  
end
endmodule  // end of z80_I_decode in z80_decoder
