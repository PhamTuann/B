module sent_rx_pulse_check (
	//clk rx and reset_rx
	input clk_rx,
	input reset_rx,

	input data_pulse,
	
	output reg [27:0] data_fast_check_crc,
	output reg [29:0] data_channel_check_crc,

	output reg [2:0] done_pre_data,

	output reg [7:0] id_decode,
	output reg [15:0] data_decode,
	output reg config_bit_decode,
	output reg write_enable_store,
	output reg [11:0] data_out
	);
	
	localparam IDLE = 0;

	//state_decode_ticks DECODE TICK
	localparam COUNT_TICKS = 1;
	localparam DONE = 2;

	//state_decode_ticks FSM DECODE
	localparam SYNC = 1;
	localparam STATUS = 2;
	localparam DATA = 3;
	localparam CRC = 4;
	localparam PAUSE = 5;	
	localparam CHECK = 6;

	reg prev_data_clk;
	reg tick;
	reg [10:0] b;
	reg prev_data_tick;
	reg [10:0] counter2;
	reg [1:0] count;
	reg [2:0] state_decode_tick;
	reg [2:0] state_decode_pulse;
	reg [10:0] count_data;
	reg [5:0] count_frame;
	reg [11:0] count_ticks;

	reg [3:0] status_nb;

	reg [17:0] saved_bit3_status;
	reg [17:0] saved_bit2_status;
	reg [27:0] saved_data_fast;

	reg done;
	reg done_data;

	reg [3:0] count_nibbles;
	reg [3:0] data_nibble_rx;

	reg serial;
	reg enhanced;
	reg first_frame;

	reg [2:0] count_enable;
	reg count_store;
	reg [1:0] done_data_to_fifo;
	reg status;
	reg [11:0] count_frame_ticks;
	reg [11:0] count_a;
	//count tick
	always @(posedge clk_rx or posedge reset_rx) begin
		if(reset_rx) begin
			b <= 0;
			state_decode_tick <= IDLE;
			counter2 <= 0;
			prev_data_clk <= 0;
		end
		else begin
			prev_data_clk <= data_pulse;
			case(state_decode_tick)
				IDLE: begin
					tick <= 0;
					b <= 0;
					if((data_pulse==0) && (prev_data_clk==1)) begin
						state_decode_tick <= COUNT_TICKS;
					end
				end
				COUNT_TICKS: begin
					if((data_pulse==0) && (prev_data_clk==1)) begin
						state_decode_tick <= DONE;
						state_decode_pulse <= STATUS;
						b <= (counter2+1)/56/2;	
					end
					else counter2 <= counter2 + 1;
				end
				DONE: begin
					counter2 <= 0;
				end
			endcase
		end
	end

	//tick -> tick clk
	always @(posedge clk_rx or posedge reset_rx) begin
		if(reset_rx) begin
			count <= 0;
			tick <= 0;
		end
		else begin
			if (count == b-1) begin
				tick <= ~tick;
				count <= 0;
			end
			else count <= count + 1;
		end
	end
	
	reg [1:0] c;
	reg j;
	reg [3:0] store_nibble;
	reg pause;
	//FSM
	always @(posedge tick or posedge reset_rx) begin
		if(reset_rx) begin
			state_decode_pulse <= STATUS;
			count_data <= 0;
			prev_data_tick <=0;
			count_frame <= 0;
			status_nb <= 0;
			count_ticks <= 0;
			count_nibbles <= 0;		
			first_frame <= 0;
			serial <= 0;
			enhanced <= 0;
			data_nibble_rx <= 0;
			config_bit_decode <= 0;
			status <= 0;
			count_frame_ticks <= 0;
			count_a <= 0;
			c <= 0;
			j <= 0;
			store_nibble <= 0;
			pause <= 0;	
			data_fast_check_crc  <= 0; 
		end
		else begin
			prev_data_tick <= data_pulse;
			
			case(state_decode_pulse)
				IDLE: begin
					
					count_ticks <= 0;
					count_frame <= 0;
					if ((data_pulse == 0) && (prev_data_tick == 1)) begin
						state_decode_pulse <= SYNC;
					end
					else state_decode_pulse <= IDLE;
				end
				SYNC: begin
					saved_data_fast <= 0;
					count_nibbles <= 0;
					if ((data_pulse == 0) && (prev_data_tick == 1)) begin
						state_decode_pulse <= STATUS;
					end
					else state_decode_pulse <= SYNC;
				end
		
				STATUS: begin
					saved_data_fast <= 0;
					count_ticks <= count_ticks + 1;
					if ((data_pulse==0) && (prev_data_tick == 1)) begin
						if(!first_frame) begin saved_bit3_status <= 0;
saved_bit2_status <= 0;
saved_data_fast <= 0;status_nb <= count_data - 13; state_decode_pulse <= CHECK; count_frame_ticks <= 56 + count_ticks - 1; end
						else begin status_nb <= count_data - 12; state_decode_pulse <= DATA; end
						count_data <= 0;
						done <= 1;
						count_ticks <= 0;
						
					end
					else count_data <= count_data + 1;
				end

				CHECK: begin
					first_frame <= 1;
					if(!first_frame && status_nb[3]) enhanced <= 1;
					else if(!first_frame && !status_nb[3]) serial <= 1;

					if(j) begin
						count_a <= count_a + 1;
						if(count_a > 27) begin
							state_decode_pulse <= SYNC;
							count_frame_ticks <= 0;
							count_a <= 0;
							j <= 0;
							end
	
						else begin
							if ((data_pulse == 0) && (prev_data_tick == 1)) begin
								count_frame <= 1;
								state_decode_pulse <= DATA;
								j <= 0;
								count_data <= 0;
								count_nibbles <= 0;
								status_nb <= count_data -12;
								store_nibble <= count_nibbles -1;
								done <= 1;
								count_a <= 0;
								count_frame_ticks <= 0;
								case(count_nibbles) 
									8: begin
										pause <= 1;
										c <= 2'b01;
									end
									6: begin
										pause <= 1;
										c <= 2'b10;
									end
									7: begin
										pause <= 0;
										c <= 2'b01;
									end
									4: begin
										pause <= 0;
										c <= 2'b11;
									end
									5: begin
										if(count_frame_ticks > 200) begin
											pause <= 1; c <= 2'b11;
										end
										else begin pause <= 0; c <= 2'b10; end 
									end
								
								endcase
								if(count_nibbles == 8 || count_nibbles == 6) begin 
									pause <= 1;
								end
								else if(count_nibbles == 7 || count_nibbles == 4)begin
									pause <= 0;
								end
								else if(count_nibbles == 5) begin 
									if(count_frame_ticks > 200) begin
										pause <= 1;
									end
									else pause <= 0;
								end
								else begin
								
								end
							end
							else begin 
								count_data <= count_data + 1; 
							end
						end
					end
					else begin
						count_frame_ticks <= count_frame_ticks + 1;
						count_ticks <= count_ticks + 1;
						if ((data_pulse == 0) && (prev_data_tick == 1)) begin
							count_data <= 0;
							state_decode_pulse <= CHECK;
							count_ticks <= 0;
							if(count_nibbles > 7 || count_data > 56 || (count_data < 56 && count_data >27) ) begin 
									count_frame <= count_frame + 1; 
									state_decode_pulse <= SYNC; 
									store_nibble <= count_nibbles - 1 ; 
									pause <= 1; 
									data_fast_check_crc <= saved_data_fast;
									done_pre_data <= 3'b001;
									done_data_to_fifo <= 2'b01;
									count_frame_ticks <= 0;
									end
							else if(count_data == 56) begin j <= 1; count_frame_ticks <= count_frame_ticks - 56; end
							else begin data_nibble_rx <= count_data - 12; done_data <= 1; count_nibbles <= count_nibbles + 1; end
						end
						else begin 
							count_data <= count_data + 1; 
						end
					end
				end

				DATA: begin

					if(count_frame == 7 && enhanced) config_bit_decode <= status_nb[3];

					count_ticks <= count_ticks + 1;
					if ((data_pulse==0) && (prev_data_tick == 1)) begin
						data_nibble_rx <= count_data - 12;
						count_data <= 0;
						done_data <= 1;
	
						if(count_nibbles == store_nibble) begin
							if(count_nibbles == 6) begin c <= 2'b01; end
							else if(count_nibbles == 4) begin c <= 2'b10; end
							else if(count_nibbles == 3) begin c <= 2'b11;end
							if(pause) begin state_decode_pulse <= PAUSE;  end
							else begin 
								if(serial && count_frame == 15) begin 
									done_pre_data <= 3'b100; 
									state_decode_pulse <= IDLE; 
									state_decode_tick <= IDLE; 
									serial <= 0; 
									first_frame <= 0;
									count_frame <= 0;
									count_nibbles <= 0;
								end
								else if(enhanced && count_frame == 17) begin 
									done_pre_data <= 3'b101; 
									state_decode_pulse <= IDLE; 
									state_decode_tick <= IDLE; 
									prev_data_tick <= 0;
									enhanced <= 0; 
									first_frame <= 0;
									count_frame <= 0;
									count_nibbles <= 0;
								end
								else begin
								 
								
								state_decode_pulse <= SYNC; 
								count_frame <= count_frame + 1; 
								data_fast_check_crc <= saved_data_fast;
								end
							end
							end else count_nibbles <= count_nibbles + 1;

						end
						else begin state_decode_pulse <= DATA; 
						
						count_ticks <= 0;
						count_data <= count_data + 1;
						
					end 
					
					
				end
				PAUSE: begin
					
					if ((data_pulse == 0) && (prev_data_tick == 1)) begin
						if(serial && count_frame == 15) begin 
							done_pre_data <= 3'b100; 
							state_decode_pulse <= IDLE; 
							state_decode_tick <= IDLE; 
							serial <= 0; 
							first_frame <= 0;
							count_frame <= 0;
							pause <= 0;
							count_nibbles <= 0;
						end
						else if(enhanced && count_frame == 17) begin 
							done_pre_data <= 3'b101; 
							state_decode_pulse <= IDLE; 
							state_decode_tick <= IDLE; 
							prev_data_tick <= 0;
							enhanced <= 0; 
							first_frame <= 0;
							count_frame <= 0;
							pause <= 0;
							count_nibbles <= 0;
						end
						else begin
						state_decode_pulse <= SYNC;
						count_frame <= count_frame + 1;	
						end
					end
					else state_decode_pulse <= PAUSE;
				end
			endcase
		end
	end

	always @(posedge clk_rx or posedge reset_rx) begin
		if(reset_rx) begin
			data_decode <= 0;
			done <= 0;
			done_data <= 0;
			done_pre_data <= 3'b000;
			done_data_to_fifo <= 2'b00;
			write_enable_store <= 0;
			saved_bit3_status <= 0;
			saved_bit2_status <= 0;
			saved_data_fast <= 0;
			data_channel_check_crc <= 0;
			id_decode <= 0;
			data_decode <= 0;

			count_enable <= 0;
			count_store <= 0;
			data_out <= 0;
		end
		else begin
			if(done) begin
				saved_bit3_status <= {saved_bit3_status,status_nb[3]};
				saved_bit2_status <= {saved_bit2_status,status_nb[2]};
				done <= 0;
			end

			if(done_data) begin
				saved_data_fast <= {saved_data_fast,data_nibble_rx};
				done_data <= 0;
			end
		
			if(c == 2'b01 && !done_data) begin data_fast_check_crc <= saved_data_fast; saved_data_fast <= 0; c <= 0; done_pre_data <= 3'b001; done_data_to_fifo <= 2'b01;end
			else if(c == 2'b10 && !done_data) begin data_fast_check_crc <= saved_data_fast; saved_data_fast <= 0; c <= 0; done_pre_data <= 3'b010; done_data_to_fifo <= 2'b10; end
			else if(c == 2'b11 && !done_data) begin data_fast_check_crc <= saved_data_fast; saved_data_fast <= 0; c <= 0;  done_pre_data <= 3'b011; done_data_to_fifo <= 2'b11;end
			

			if(done_pre_data == 3'b100) begin
				data_channel_check_crc <= saved_bit2_status[15:0];
				id_decode <= saved_bit2_status[15:12];
				data_decode <= saved_bit2_status[11:4];
			end

			if(done_pre_data == 3'b101) begin
				data_channel_check_crc <= {saved_bit2_status[11], saved_bit3_status[11], saved_bit2_status[10], saved_bit3_status[10],
								saved_bit2_status[9], saved_bit3_status[9], saved_bit2_status[8], saved_bit3_status[8],
								saved_bit2_status[7], saved_bit3_status[7], saved_bit2_status[6], saved_bit3_status[6],
								saved_bit2_status[5], saved_bit3_status[5], saved_bit2_status[4], saved_bit3_status[4],
								saved_bit2_status[3], saved_bit3_status[3], saved_bit2_status[2], saved_bit3_status[2],
								saved_bit2_status[1], saved_bit3_status[1], saved_bit2_status[0], saved_bit3_status[0],
								saved_bit2_status[17], saved_bit2_status[16], saved_bit2_status[15], saved_bit2_status[14],
								saved_bit2_status[13], saved_bit2_status[12] };

				if(config_bit_decode) begin
					id_decode <= saved_bit3_status[9:6];
					data_decode <= {saved_bit3_status[4:1], saved_bit2_status[11:0]};
				end
				else begin
					id_decode <= {saved_bit3_status[9:6], saved_bit3_status[4:1]};
					data_decode <= saved_bit2_status[11:0];
				end
			end
			
			case(done_data_to_fifo)
				2'b01: begin
					if(count_enable == 6) begin
						write_enable_store <= 1;
						count_enable <= 0;
						if(!count_store) begin
							data_out <= data_fast_check_crc[27:16]; 
							count_store <= 1; 
						end else begin 
							data_out <= data_fast_check_crc[15:4]; 
							count_store <= 0; 
							done_data_to_fifo <= 0;
						end
						end
					else begin count_enable <= count_enable + 1; end
				end

				2'b10: begin
					if(count_enable == 6) begin
						write_enable_store <= 1;
						count_enable <= 0;
						data_out <= {data_fast_check_crc[18:16],data_fast_check_crc[14:12],data_fast_check_crc[10:8],data_fast_check_crc[6:4]}; 
						done_data_to_fifo <= 0;
					end
					else begin count_enable <= count_enable + 1; end
				end

				2'b11: begin
					if(count_enable == 6) begin
						write_enable_store <= 1;
						count_enable <= 0;
						data_out <= data_fast_check_crc[15:4]; 
						done_data_to_fifo <= 0;
					end
					else begin count_enable <= count_enable + 1; end
				end
			endcase
			if(done_pre_data != 0) done_pre_data <= 3'b000;
			if(write_enable_store) write_enable_store <= 0;
		end
	end
endmodule