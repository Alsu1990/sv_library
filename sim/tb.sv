`include "../rtl/skid_buffer.sv"
`default_nettype none
timeunit 1ns/1ps;

module tb_skid_buffer;
localparam WIDTH = 32;
logic               clk_i=0;
logic               clear_i;
logic               input_valid_i;
logic               input_ready_o;
logic [WIDTH-1:0]   input_data_i;
logic               output_valid_o;
logic               output_ready_i;
logic [WIDTH-1:0]   output_data_o;

skid_buffer dut
(
    .*
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk_i=~clk_i;

initial begin
    $dumpfile("tb_skid_buffer.vcd");
    $dumpvars(0, tb_skid_buffer);
end

initial begin
    #1 clear_i<=1'bx;clk_i<=1'bx;
    #(CLK_PERIOD*3) clear_i<=1;
    #(CLK_PERIOD*3) clear_i<=0;clk_i<=0;
    repeat(5) @(posedge clk_i);
    clear_i<=1;
    @(posedge clk_i);
    repeat(2) @(posedge clk_i);
    $finish(2);
end

endmodule
`default_nettype wire