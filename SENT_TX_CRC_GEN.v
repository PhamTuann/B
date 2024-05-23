module sent_tx_crc_gen(
	//reset_tx
	input reset_tx,

	//signals to control block
	input [2:0] enable_crc_gen,
	input [23:0] data_gen_crc,
	output reg [5:0] crc_gen
	);


	reg [35:0] temp_data;

    	reg [6:0] p;
	reg [4:0] poly4 = 5'b11101;
	reg [6:0] poly6 = 7'b1011001;

    	always @(*) begin
		if(reset_tx) begin
			crc_gen = 0;
			temp_data = 0;
		end
		else begin
		//CRC SHORT
		if(enable_crc_gen == 3'b100) begin
        		p = 19;
        		temp_data = {4'b0101, data_gen_crc[11:0], 4'b0};

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
		crc_gen[5:4] = 2'b00;
        	crc_gen[3] = temp_data[3];
        	crc_gen[2] = temp_data[2];
        	crc_gen[1] = temp_data[1];
        	crc_gen[0] = temp_data[0];
		end
	

		//CRC 6 NIBBLES
		if(enable_crc_gen == 3'b001) begin
        		p = 31;
        		temp_data = {4'b0101, data_gen_crc, 4'b0};

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
		crc_gen[5:4] = 2'b00;
        	crc_gen[3] = temp_data[3];
        	crc_gen[2] = temp_data[2];
        	crc_gen[1] = temp_data[1];
        	crc_gen[0] = temp_data[0];
		end

		//CRC 4 NIBBLES
		if(enable_crc_gen == 3'b010) begin
        		p = 23;
        		temp_data = {4'b0101, data_gen_crc[15:0], 4'b0};

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
		crc_gen[5:4] = 2'b00;
        	crc_gen[3] = temp_data[3];
        	crc_gen[2] = temp_data[2];
        	crc_gen[1] = temp_data[1];
        	crc_gen[0] = temp_data[0];
		end

		//CRC 3 NIBBLES
		if(enable_crc_gen == 3'b011) begin
        		p = 19;
        		temp_data = {4'b0101, data_gen_crc[11:0], 4'b0};

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
		crc_gen[5:4] = 2'b00;
        	crc_gen[3] = temp_data[3];
        	crc_gen[2] = temp_data[2];
        	crc_gen[1] = temp_data[1];
        	crc_gen[0] = temp_data[0];
		end
		
		//CRC ENHANCED
		if(enable_crc_gen == 3'b101) begin
        		p = 35;
        		temp_data = {6'b010101, data_gen_crc, 6'b0};

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

		crc_gen[5] = temp_data[5];
		crc_gen[4] = temp_data[4];
        	crc_gen[3] = temp_data[3];
        	crc_gen[2] = temp_data[2];
        	crc_gen[1] = temp_data[1];
        	crc_gen[0] = temp_data[0];
		end


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


