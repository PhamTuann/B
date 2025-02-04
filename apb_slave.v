module apb_slave 
	#(parameter ADDRESSWIDTH= 3,
	parameter DATAWIDTH= 12)

	(
	input PCLK,
	input PRESETn,
	input [ADDRESSWIDTH-1:0]PADDR,
	input [DATAWIDTH-1:0] PWDATA,
	input PWRITE,
	input PSELx,
	input PENABLE,
	output reg [DATAWIDTH-1:0] PRDATA,
	output reg PREADY = 1,

	//register
	input [7:0] reg_status,  //read_empty, write_full
	output reg [7:0] reg_command, //write_reset_n, read_reset_n, i2c_enable
	output reg [11:0] reg_transmit, //i2c_data_in
	input [11:0] reg_receive, 
	//output control fifo tx
	output reg write_enable_tx,
	output reg read_enable_rx
	
	);
	//	reg_command(2)		reg_trasmit(4)	reg_status(3)	reg_pres(6)		reg_receive(5)
	//7	write_reset_n_tx	data_to_fifo	tx_full		address i2c_slave	data_i2c_out
	//6	read_reset_n_tx				tx_empty
	//5	write_reset_n_rx			rx_full
	//4	read_reset_n_rx				rx_empty
	//3						
	//2	
	//1	
	//0
	always @(posedge PCLK or negedge PRESETn) begin
 		if(!PRESETn) begin
			PRDATA <= 0;
			reg_command <= 0;
			reg_transmit <= 0; 
			write_enable_tx <= 0;
			read_enable_rx <= 0;
		end
		else begin
			if (PENABLE & PWRITE & PSELx) begin
				case (PADDR)
					2: reg_command <= PWDATA;
					4: begin
						if(!reg_status[7]) begin	
							reg_transmit <= PWDATA;
						end
						
					end
				endcase
			end

			if (PWRITE & PADDR == 4) begin
				write_enable_tx <= PENABLE;
				reg_command[7:4] <= 4'b1111;
			end

			if(PENABLE & !PWRITE & PSELx) begin
				case (PADDR)
					3: PRDATA <= reg_status;
					5: begin 
						if(!reg_status[4]) begin
							PRDATA <= reg_receive;
						end
					end
				endcase
			end

			if (!PWRITE & PADDR == 5) read_enable_rx <= PENABLE;
		end
	end
endmodule