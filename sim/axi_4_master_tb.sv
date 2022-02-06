`include "C:\Xilinx\sv_library\rtl\axi4_master.sv"
`default_nettype none

module tb_axi4_master();
///////////////////////////////////////////////////
localparam  AXI_DEPTH = 32, AXI_WIDTH = 32;
logic                         wb_rst_i; 
logic                         wb_clk_i; 
logic                         wb_cyc_i; 
logic                         wb_stb_i; 
logic                         wb_we_i;  
logic [AXI_DEPTH-1:0]         wb_addr_i;
logic [AXI_WIDTH-1:0]         wb_data_i;
logic                        wb_stall_o;
logic                        wb_ack_o;
logic [AXI_WIDTH-1:0]         wb_data_o; 
logic                         m_axi_aresetn;
logic                         m_axi_aclk;   
logic                        m_axi_awvalid;
logic                         m_axi_awready;
logic [AXI_DEPTH-1:0]        m_axi_awaddr;
logic                        m_axi_wvalid;
logic                         m_axi_wready;
logic [AXI_WIDTH-1:0]        m_axi_wdata;
logic [3:0]                  m_axi_wstrb;
logic                         m_axi_bvalid;
logic                        m_axi_bready;
logic  [1:0]                  m_axi_bresp;
logic                        m_axi_arvalid;
logic                         m_axi_arready;
logic [AXI_DEPTH-1:0]        m_axi_araddr;
logic                         m_axi_rvalid;
logic                        m_axi_rready;
logic  [AXI_WIDTH-1:0]        m_axi_rdata;
logic  [1:0]                  m_axi_rresp;
/////////////////////////////////////////////

logic clk;
logic rst_n;

axi4_master DUT 
(
    .wb_rst_i(~rst_n),
    .m_axi_aresetn(rst_n),
    .wb_clk_i(clk),
    .m_axi_aclk(clk),
    .*
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("tb_axi4_master.vcd");
    $dumpvars(0, tb_axi4_master);
end

task automatic write(   input logic [31:0] addr,
                        input logic [31:0] data);
    $display("T=[%t] WB Write Transaction. ADDR=0x%h, DATA=0x%h,",$time, addr, data);
    wb_cyc_i = 0;
    wb_stb_i = 0;
    wb_we_i = 0;
    wb_addr_i = 0;
    wb_data_i = 0;
    @(posedge clk);
    wb_cyc_i = 1;
    wb_stb_i = 1;
    wb_we_i = 1;
    wb_addr_i = addr;
    wb_data_i = data;
    @(posedge wb_ack_o);
    @(negedge clk);
    wb_cyc_i = 0;
    wb_stb_i = 0;
    wb_we_i = 0;
    wb_addr_i = 0;
    wb_data_i = 0;
    $$display("T=[%t]. Transaction ended",$time);
endtask //automatic



//axi4 slave
always_ff @(m_axi_aclk) begin : axi4_slave
    if (!m_axi_aresetn) begin
        m_axi_wready <= 1'b0;
        m_axi_awready <= 1'b0;
    end else begin
        if (m_axi_awvalid && m_axi_wvalid) begin
            
        end
    end
end
initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);
    write(32'hAA,32'hDEADBEAF);
    repeat(100) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire