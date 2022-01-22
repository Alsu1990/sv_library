`default_nettype none
module Pipeline_Skid_Buffer #(
    parameter WIDTH = 32
) (
    input wire              clk_i,
    input wire              clear_i,

    input wire              input_valid_i,
    output wire             input_ready_o,
    input wire [WIDTH-1:0]  input_data_i,

    output wire             output_valid_o,
    input wire              output_ready_i,
    output logic [WIDTH-1:0] output_data_o
);
    always_ff @(posedge clk_i) begin
        output_data_o <= input_data_i;
    end
endmodule