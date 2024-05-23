module sent_rx_crc_check(
	//reset_rx
	input reset_rx,

	//signals to control block
	
	input [2:0] enable_crc_check,

	input [27:0] data_fast_check_crc,
	input [29:0] data_channel_check_crc,

	output reg valid_data_serial,
	output reg valid_data_enhanced,
	output reg valid_data_fast
	);
	
	reg [5:0] crc_check;
	reg [35:0] temp_data;
	reg [6:0] p;
	reg [4:0] poly4 = 5'b11101;
	reg [6:0] poly6 = 7'b1011001;
    	always @(*) begin
		if(reset_rx) begin
			crc_check = 0;

			temp_data = 0;
			valid_data_serial = 0;
			valid_data_enhanced = 0;
			valid_data_fast = 0;
		end
		else begin
			case(enable_crc_check)
				3'b100: begin
					p = 19;
        				temp_data = {4'b0101,data_channel_check_crc[15:0]};

        				while (p > 3) begin
            					if (temp_data[p] == 1'b1) begin
              	  					temp_data[p-0] = temp_data[p-0] ^ 1;
                					temp_data[p-1] = temp_data[p-1] ^ poly4[3];
                					temp_data[p-2] = temp_data[p-2] ^ poly4[2];
                					temp_data[p-3] = temp_data[p-3] ^ poly4[1];
                					temp_data[p-4] = temp_data[p-4] ^ poly4[0];
            					end
            					else begin
                					p = p - 1;
            					end
        				end
					crc_check[5:4] = 2'b00;
        				crc_check[3] = temp_data[3];
        				crc_check[2] = temp_data[2];
        				crc_check[1] = temp_data[1];
        				crc_check[0] = temp_data[0];

					if(crc_check == 6'b000000) valid_data_serial = 1; 
					else valid_data_serial = 0;
				end
				
				3'b101: begin
					p = 35;
        				temp_data = {6'b010101, data_channel_check_crc};

        				while (p > 5) begin

            					if (temp_data[p] == 1'b1) begin
              	  					temp_data[p-0] = temp_data[p-0] ^ 1;
                					temp_data[p-1] = temp_data[p-1] ^ poly6[5];
                					temp_data[p-2] = temp_data[p-2] ^ poly6[4];
                					temp_data[p-3] = temp_data[p-3] ^ poly6[3];
                					temp_data[p-4] = temp_data[p-4] ^ poly6[2];
							temp_data[p-5] = temp_data[p-5] ^ poly6[1];
							temp_data[p-6] = temp_data[p-6] ^ poly6[0];
            					end
            					else begin
                					p = p - 1;
            					end

        				end

					crc_check[5] = temp_data[5];
					crc_check[4] = temp_data[4];
        				crc_check[3] = temp_data[3];
        				crc_check[2] = temp_data[2];
        				crc_check[1] = temp_data[1];
        				crc_check[0] = temp_data[0];
		
					if(crc_check == 6'b000000) valid_data_enhanced = 1; 
					else valid_data_enhanced = 0;
				end
					
				3'b001: begin
					p = 31;
        				temp_data = {4'b0101,data_fast_check_crc};

        				while (p > 3) begin
            					if (temp_data[p] == 1'b1) begin
              	  					temp_data[p-0] = temp_data[p-0] ^ 1;
                					temp_data[p-1] = temp_data[p-1] ^ poly4[3];
                					temp_data[p-2] = temp_data[p-2] ^ poly4[2];
                					temp_data[p-3] = temp_data[p-3] ^ poly4[1];
                					temp_data[p-4] = temp_data[p-4] ^ poly4[0];
            					end
            					else begin
                					p = p - 1;
            					end
        				end
					crc_check[5:4] = 2'b00;
        				crc_check[3] = temp_data[3];
        				crc_check[2] = temp_data[2];
        				crc_check[1] = temp_data[1];
        				crc_check[0] = temp_data[0];

					if(crc_check == 6'b000000) valid_data_fast = 1; 
					else valid_data_fast = 0;
				end
				
				3'b010: begin
					p = 23;
        				temp_data = {4'b0101, data_channel_check_crc[19:0]};

        				while (p > 3) begin

            					if (temp_data[p] == 1'b1) begin
              	  					temp_data[p-0] = temp_data[p-0] ^ 1;
                					temp_data[p-1] = temp_data[p-1] ^ poly6[5];
                					temp_data[p-2] = temp_data[p-2] ^ poly6[4];
                					temp_data[p-3] = temp_data[p-3] ^ poly6[3];
                					temp_data[p-4] = temp_data[p-4] ^ poly6[2];
							temp_data[p-5] = temp_data[p-5] ^ poly6[1];
							temp_data[p-6] = temp_data[p-6] ^ poly6[0];
            					end
            					else begin
                					p = p - 1;
            					end

        				end
					crc_check[5:4] = 2'b00;
        				crc_check[3] = temp_data[3];
        				crc_check[2] = temp_data[2];
        				crc_check[1] = temp_data[1];
        				crc_check[0] = temp_data[0];
		
					if(crc_check == 6'b000000) valid_data_fast = 1; 
					else valid_data_fast = 0;
				end
				3'b011: begin
					p = 19;
        				temp_data = {4'b0101, data_channel_check_crc[15:0]};

        				while (p > 3) begin

            					if (temp_data[p] == 1'b1) begin
              	  					temp_data[p-0] = temp_data[p-0] ^ 1;
                					temp_data[p-1] = temp_data[p-1] ^ poly6[5];
                					temp_data[p-2] = temp_data[p-2] ^ poly6[4];
                					temp_data[p-3] = temp_data[p-3] ^ poly6[3];
                					temp_data[p-4] = temp_data[p-4] ^ poly6[2];
							temp_data[p-5] = temp_data[p-5] ^ poly6[1];
							temp_data[p-6] = temp_data[p-6] ^ poly6[0];
            					end
            					else begin
                					p = p - 1;
            					end

        				end
					crc_check[5:4] = 2'b00;
        				crc_check[3] = temp_data[3];
        				crc_check[2] = temp_data[2];
        				crc_check[1] = temp_data[1];
        				crc_check[0] = temp_data[0];
		
					if(crc_check == 6'b000000) valid_data_fast = 1; 
					else valid_data_fast = 0;
				end
								
				default: begin
					valid_data_enhanced = 0;
					valid_data_serial = 0;
					valid_data_fast = 0;
				end
			endcase
		end
    	end

endmodule

/*
test case
data poly4 CRC4_code
0x2C7 0x13 0xD
0x287 0x13 0xA
0x285 0x15 0xC
0x200 0x18 0x8
*/


