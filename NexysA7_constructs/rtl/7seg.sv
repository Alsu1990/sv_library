// time slot mux for 7 segments
module  tdm_mux(
    input logic                     clk_i, rstn_i,
    input logic [7:0]               data_i [0:7],
    output logic [7:0]   anode_o,    //enable
    output logic [7:0]              sseg_o      //led segments
    );

    localparam N = 19;  // 3 bits for muxing and 16 bit to count (2**16 * 10 ns = 1600 hz)
    logic [N-1:0] counter_q;
    always_ff @( posedge clk_i ) begin : nbit_counter
        if (!rstn_i) begin
            counter_q <= '0;
        end else begin
            counter_q <= counter_q + 1'b1;
        end
    end

    always_comb begin : mux
        case (counter_q[N-1:N-3]) 
                3'd0: begin
                    anode_o = 8'b1111_1110;
                    sseg_o = data_i[0];
                end 
                3'd1: begin
                    anode_o = 8'b1111_1101;
                    sseg_o = data_i[1];
                end 
                3'd2: begin
                    anode_o = 8'b1111_1011;
                    sseg_o = data_i[2];
                end 
                3'd3: begin
                    anode_o = 8'b1111_0111;
                    sseg_o = data_i[3];
                end 
                3'd4: begin
                    anode_o = 8'b1110_1111;
                    sseg_o = data_i[4];
                end 
                3'd5: begin
                    anode_o = 8'b1101_1111;
                    sseg_o = data_i[5];
                end 
                3'd6: begin
                    anode_o = 8'b1011_1111;
                    sseg_o = data_i[6];
                end 
                3'd7: begin
                    anode_o = 8'b0111_1111;
                    sseg_o = data_i[7];
                end 

        endcase
        
    end
endmodule