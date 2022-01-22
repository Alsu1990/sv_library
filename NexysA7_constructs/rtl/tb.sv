
`default_nettype none

module tb_7seg;
logic           clk_i, rstn_i;
logic [7:0]     data_i [0:7];
logic [7:0]     anode_o;    //enable
logic [7:0]     sseg_o;    //led segments
tdm_mux dut
(
    .*
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk_i=~clk_i;

initial begin
    $dumpfile("tb_7seg.vcd");
    $dumpvars(0, tb_7seg);
end

initial begin
    foreach (data_i[i]) data_i[i] = 0;
    #1 rstn_i<=1'bx;clk_i<=1'bx;
    #(CLK_PERIOD*3) rstn_i<=1;
    #(CLK_PERIOD*3) rstn_i<=0;clk_i<=0;
    repeat(5) @(posedge clk_i);
    rstn_i<=1;
    @(posedge clk_i);
    foreach (data_i[i]) data_i[i] = $urandom();
    repeat(2) @(posedge clk_i);
    $finish();
end

endmodule
`default_nettype wire