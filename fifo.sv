module fifomem
#(
  parameter DATASIZE = 12, // Memory data word width
  parameter ADDRSIZE = 8  // Number of mem address bits
)
(
  input   write_enable, write_full, write_clk,
  input   [ADDRSIZE-1:0] waddr, raddr,
  input   [DATASIZE-1:0] write_data,
  output  [DATASIZE-1:0] read_data
);
  // RTL Verilog memory model
  localparam DEPTH = 1<<ADDRSIZE;//2*adDATASIZE

  logic [DATASIZE-1:0] mem [0:DEPTH-1];

  assign read_data = mem[raddr];

  always_ff @(posedge write_clk)
    if (write_enable && !write_full) 
      	mem[waddr] <= write_data; 
endmodule


module rptr_empty
#(
  parameter ADDRSIZE = 8
)
(
  input   read_enable, read_clk, read_reset,
  input   [ADDRSIZE :0] rq2_wptr,
  output reg  read_empty,
  output  [ADDRSIZE-1:0] raddr,
  output reg [ADDRSIZE :0] rptr
);

  reg [ADDRSIZE:0] rbin;
  wire [ADDRSIZE:0] rgraynext, rbinnext;

  //-------------------
  // GRAYSTYLE2 pointer
  //-------------------
  always_ff @(posedge read_clk or posedge read_reset)
    if (read_reset)
      {rbin, rptr} <= '0;
    else
      {rbin, rptr} <= {rbinnext, rgraynext};

  // Memory read-address pointer (okay to use binary to address memory)
  assign raddr = rbin[ADDRSIZE-1:0];
  assign rbinnext = rbin + (read_enable & ~read_empty);
  assign rgraynext = (rbinnext>>1) ^ rbinnext;

  //---------------------------------------------------------------
  // FIFO empty when the next rptr == synchronized wptr or on reset
  //---------------------------------------------------------------
  assign read_empty_val = (rgraynext == rq2_wptr);

  always_ff @(posedge read_clk or posedge read_reset)
    if (read_reset)
      read_empty <= 1'b1;
    else
      read_empty <= read_empty_val;

endmodule

module sync_r2w
#(
  parameter ADDRSIZE = 8
)
(
  input   write_clk, write_reset,
  input   [ADDRSIZE:0] rptr,
  output reg  [ADDRSIZE:0] wq2_rptr//readpointer with write side
);

  reg [ADDRSIZE:0] wq1_rptr;

  always_ff @(posedge write_clk or posedge write_reset)
    if (write_reset) {wq2_rptr,wq1_rptr} <= 0;
    else {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

endmodule

module sync_w2r
#(
  parameter ADDRSIZE = 8
)
(
  input   read_clk, read_reset,
  input   [ADDRSIZE:0] wptr,
  output reg [ADDRSIZE:0] rq2_wptr
);

  reg [ADDRSIZE:0] rq1_wptr;

  always_ff @(posedge read_clk or posedge read_reset)
    if (read_reset)
      {rq2_wptr,rq1_wptr} <= 0;
    else
      {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

endmodule

module wptr_full
#(
  parameter ADDRSIZE = 8
)
(
  input   write_enable, write_clk, write_reset,
  input   [ADDRSIZE :0] wq2_rptr,
  output reg  write_full,
  output  [ADDRSIZE-1:0] waddr,
  output reg [ADDRSIZE :0] wptr
);

   reg [ADDRSIZE:0] wbin;
  wire [ADDRSIZE:0] wgraynext, wbinnext;

  // GRAYSTYLE2 pointer
  always_ff @(posedge write_clk or posedge write_reset)
    if (write_reset)
      {wbin, wptr} <= '0;
    else
      {wbin, wptr} <= {wbinnext, wgraynext};

  // Memory write-address pointer (okay to use binary to address memory)
  assign waddr = wbin[ADDRSIZE-1:0];
  assign wbinnext = wbin + (write_enable & ~write_full);
  assign wgraynext = (wbinnext>>1) ^ wbinnext;

  //------------------------------------------------------------------
  // Simplified version of the three necessary full-tests:
  // assign write_full_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
  // (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
  // (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
  //------------------------------------------------------------------
  assign write_full_val = (wgraynext=={~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});

  always_ff @(posedge write_clk or posedge write_reset)
    if (write_reset)
      write_full <= 1'b0;
    else
      write_full <= write_full_val;

endmodule

module async_fifo
#(
  parameter DATASIZE = 12,
  parameter ADDRESSSIZE = 8
 )
(
  input   write_enable, write_clk, write_reset,//write_enable write enable signal
  input   read_enable, read_clk, read_reset,//read_enable read enable signal
  input   [DATASIZE-1:0] write_data,

  output  [DATASIZE-1:0] read_data,
  output  write_full,
  output  read_empty
);

  wire [ADDRESSSIZE-1:0] waddr, raddr;
  wire [ADDRESSSIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

  sync_r2w sync_r2w (.*);
  sync_w2r sync_w2r (.*);
  fifomem #(DATASIZE, ADDRESSSIZE) fifomem (.*);
  rptr_empty #(ADDRESSSIZE) rptr_empty (.*);
  wptr_full #(ADDRESSSIZE) wptr_full (.*);

endmodule