module flush_unit (flush0, flush1, flush2, targetPC, PCupdate,
                   br_targetPC, br_taken, paging_RQ, interrupt_RQ, mem_pipe_stall,
                   bubble, EOI_RF_stage, EOI_EXE_stage, EOI_MEM_stage,
                   PC_EXE_stage, PC_MEM_stage);
output flush0, flush1, flush2, PCupdate;
output [15:0] targetPC;

input [15:0] br_targetPC, PC_EXE_stage, PC_MEM_stage;
input br_taken, paging_RQ, interrupt_RQ, mem_pipe_stall, bubble,
      EOI_RF_stage, EOI_EXE_stage, EOI_MEM_stage;
      
reg flush0, flush1, flush2, PCupdate;
reg [15:0] targetPC;

always@(br_targetPC or br_taken or paging_RQ or interrupt_RQ or mem_pipe_stall or
        EOI_EXE_stage or EOI_MEM_stage or
        PC_EXE_stage or PC_MEM_stage)
begin
  // default settings
  flush2 <= 0;
  flush1 <= 0;
  flush0 <= 0;
  targetPC <= 0;
  PCupdate <= 0;

  if(mem_pipe_stall == 1'b1) /////////////stall. ignore the curr clk cycle
    begin
    /* same as default */
    end
  else if(paging_RQ == 1'b1) //////////////paging condition
    begin
      if(EOI_MEM_stage == 1'b1)
        begin
          flush2 <= 1;
          flush1 <= 1;
          flush0 <= 1;
          targetPC <= PC_MEM_stage;
          PCupdate <= 1;
        end
      else if((EOI_EXE_stage == 1'b1) || (br_taken == 1'b1)) // one in EXE
        begin
          flush2 <= 0;
          flush1 <= 1;
          flush0 <= 1;
          targetPC <= (br_taken == 1'b1) ? br_targetPC : PC_EXE_stage;
          PCupdate <= 1;
        end
      // NOV25, ikim changed it to not taking care of EOI in RF
      // to avoid the situation that an instruction in RF later
      // causes a fetch redirection for taken branch
      else // neither EOI nor taken branch. wait
        begin
          /* do nothing */
        end
    end  //////////////////////// end of paging cases
  else if (br_taken == 1'b1) ////////////// taken branch/jump
    begin
      flush2 <= 0;
      flush1 <= 1;
      flush0 <= 1;
      targetPC <= br_targetPC;
      PCupdate <= 1;
    end ///////////////////////// end of branch taken case
  else if (interrupt_RQ == 1'b1)
    begin
      if((EOI_EXE_stage == 1'b1)) // one in EXE
        begin
          flush2 <= 0;
          flush1 <= 1;
          flush0 <= 1;
          targetPC <= PC_EXE_stage;
          PCupdate <= 1;
        end
      // NOV25, ikim changed it to not taking care of EOI in RF
      // to avoid the situation that an instruction in RF later
      // causes a fetch redirection for taken branch
      else // neither EOI nor taken branch. wait
        begin
          /* do nothing */
        end
    end ///////////////////////////end of interrupt case
  else
    begin
      /* do nothing */
    end
end	// end of always
endmodule
