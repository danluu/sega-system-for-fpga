module DEBUG_PROC(NMI_);

input NMI_;
wire INT_;

reg clk, clk2x, reset_b;

// data mem interface
wire WAIT_b;
wire WR_, RD_, MREQ_, IORQ_;
wire [7:0] Data_CPU_other;
wire [7:0] Data_other_CPU;
wire [15:0] Addr;

// fetch mem interface
wire WAIT_F_b;
wire Flush_b, FHRQ_b;
wire [7:0] Data_F;
wire [15:0] Addr_F;

// debug
wire [38:0] DEBUG_uop;
wire [15:0] DEBUG_seqNPC;
wire [223:0] DEBUG_RF_dump;
wire DEBUG_pipe_stall, DEBUG_taken;
wire [15:0] DEBUG_Addr;
wire [7:0] DEBUG_Rdata, DEBUG_Wdata;
wire [38:0] DEBUG_uop_xlator;
wire [8*34-1:0] outstring_xlator;

// memory
	// left bank memory signals --
	wire [18:0] la;
	wire [7:0] ld;		// tristate in/out data port
	wire lceb, loeb, lweb;
	
	// right bank memory signals --
	wire [18:0] ra;
	wire [7:0] rd; 	// tristate in/out data port
	wire rceb, roeb, rweb;
		
	wire [13:0] Addr_VDP_MPU;	// Addr bus from VDP to MPU
	wire [7:0] Data_VDP_MPU;	// Data bus from VDP to MPU
	wire [7:0] Data_MPU_VDP;	// Data bus from MPU to VDP
	wire RD_VDP_b, WR_VDP_b, WAIT_VDP_MPU_b; // read/write/wait between VDP and MPU
	
	wire WAIT_MPU_b, WAIT_VDP_b;	// wait from MPU and VDP to CPU
	assign WAIT_b = WAIT_MPU_b & WAIT_VDP_b;	// wait goes into CPU

	// VDP *******************************************************
	//assign Addr_VDP_MPU = 14'b0;
	//assign Data_VDP_MPU = 8'b0;
	// Data_MPU_VDP;
	//assign RD_VDP_b = 1;
	//assign WR_VDP_b = 1;
	// WAIT_VDP_MPU_b;
	//assign WAIT_VDP_b = 1;
	
	//assign rceb = 1;
	//assign roeb = 1;
	//assign rweb = 1;
	//assign ra = 19'b0;
	//assign rd = 8'bz;

	wire hsyncb,vsyncb,blankb,pixelclk,wrb, rdb,trste;
	wire	[7:0]	d;
	wire	[2:0]	rs;
	wire    [7:0]   NULL0, NULL1;
	VDP_top_level VDP_top_inst(.clk(clk),
	.clk2x(clk2x),
	.reset_(reset_b),
	.IN_DATA(Data_MPU_VDP),
	.wait_M_(WAIT_VDP_MPU_b),
	.CPU_Addr(Addr),
	.CPU_Data(Data_CPU_other),
	.CPU_Data_out(Data_other_CPU/*NULL0*/),
        .IORQ_(IORQ_),
        .WR_(WR_),
        .RD_(RD_),
        .addr_M(Addr_VDP_MPU),
        .WR_Mb(WR_VDP_b),
	.RD_Mb(RD_VDP_b),
	.DATA_WR(Data_VDP_MPU),
	.WAIT_(WAIT_VDP_b),
	.INT_(INT_),
	.hsyncb(hsyncb),
	.vsyncb(vsyncb),
	.blankb(blankb),
	.pixelclk(pixelclk),		//RAMDAC
	.wrb(wrb),
	.rdb(rdb),
	.rs(rs),
	.d(d),
	.trste(trste),				//RAMDAC
	.OEb(roeb),
	.CEb(rceb),
	.WEb(rweb),
	.R_DATA(rd),
	.RIGHT_ADDR(ra)
	);	

//*************************************************************************** processor
Processor PROC  (.CLK(clk), .RESET_B(reset_b), .WAIT_B(WAIT_b)
                , .WR_B(WR_), .RD_B(RD_), .MREQ_B(MREQ_)
                , .IORQ_B(IORQ_), .NMI_B(NMI_), .INT_B(INT_)
                , .DATA_OUT(Data_CPU_other), .DATA_IN(Data_other_CPU), .ADDR(Addr)
                 // fetch side signals
                , .WAIT_F_B(WAIT_F_b), .FLUSH_B(Flush_b), .FHRQ_B(FHRQ_b)
                , .DATA_FETCH(Data_F), .ADDR_FETCH(Addr_F)
// debug
, .DEBUG_UOP_OUT(DEBUG_uop), .DEBUG_SEQNPC_OUT(DEBUG_seqNPC)
, .DEBUG_RF_DUMP(DEBUG_RF_dump), .DEBUG_PIPE_STALL(DEBUG_pipe_stall)
, .DEBUG_TAKEN(DEBUG_taken)
, .DEBUG_ADDR_OUT(DEBUG_Addr), .DEBUG_RDATA_OUT(DEBUG_Rdata), .DEBUG_WDATA_OUT(DEBUG_Wdata)
, .DEBUG_UOP_XLATOR_OUT(DEBUG_uop_xlator)
);

//*************************************************************************** debugger for processor
DEBUG_CPUtracer TRACER (clk, ~reset_b, DEBUG_RF_dump, DEBUG_seqNPC, DEBUG_pipe_stall, DEBUG_uop, DEBUG_taken, DEBUG_Addr, DEBUG_Rdata, DEBUG_Wdata);
DEBUG_uop_decoder UOP_XLATE (outstring_xlator, DEBUG_uop_xlator);

//*************************************************************************** memory module
	MPU MPU_main
	(.RESET_b(reset_b), .CLK(clk2x), // This module uses 2x clock
	 .Addr_F(Addr_F), .Data_F(Data_F), .FHRQ_b(FHRQ_b), .Flush_b(Flush_b), .WAIT_F_b(WAIT_F_b),
	 .Addr(Addr), .Data_in(Data_CPU_other), .Data_out(Data_other_CPU),
	 .MREQ_b(MREQ_), .RD_b(RD_), .WR_b(WR_), .WAIT_b(WAIT_MPU_b),
	 .Addr_VDP(Addr_VDP_MPU), .Data_VDP_in(Data_VDP_MPU), .Data_VDP_out(Data_MPU_VDP),
	 .RD_VDP_b(RD_VDP_b), .WR_VDP_b(WR_VDP_b), .WAIT_VDP_b(WAIT_VDP_MPU_b),
	 .Addr_SRAM(la), .Data_SRAM(ld), .ceb(lceb), .oeb(loeb), .web(lweb));	

//*************************************************************************** joy pad
	wire ps2clk, ps2data;
	assign ps2clk = 1'b1;
	assign ps2data = 1'b1;
        Joypad_controller JPC_main
	(.clk(clk), .reset_b(reset_b), .addr(Addr), .data_in(Data_other_CPU /*NULL1*/), 
	 .data_out(Data_CPU_other), .read(~RD_), .write(~WR_), .iorq(~IORQ_), 
	 .ps2_clk(ps2clk), .ps2_data(ps2data)) ;	
	
//*************************************************************************** sram
	SRAM SRAM_L(la, ld, lceb, loeb, lweb, reset_b);
	
	SRAM SRAM_R(ra, rd, rceb, roeb, rweb, reset_b);
	
	
// main clock 12.5Mhz
always
begin
    #0	  clk = 0;
    #40   clk = 1;
    #40   clk = 0;
end

// 2x clock  25Mhz
always
begin
    #0	  clk2x = 1;
    #20   clk2x = 0;
    #20   clk2x = 1;
end

// reset
initial
begin
    #0    reset_b = 0;
    #150  reset_b = 1;
end

endmodule
