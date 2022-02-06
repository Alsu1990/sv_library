`include "..\rtl\axi4_master.sv"
`default_nettype none
timeunit 1ns/1ns;

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
logic                         rx;     
logic                         tx;     
logic                         interrupt;     
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
axi_uartlite_0 uart (
  .s_axi_aclk(clk),        // input wire s_axi_aclk
  .s_axi_aresetn(rst_n),  // input wire s_axi_aresetn
  .interrupt(interrupt),          // output wire interrupt
  .s_axi_awaddr(m_axi_awaddr[3:0]),    // input wire [3 : 0] s_axi_awaddr
  .s_axi_awvalid(m_axi_awvalid),  // input wire s_axi_awvalid
  .s_axi_awready(m_axi_awready),  // output wire s_axi_awready
  .s_axi_wdata(m_axi_wdata),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(m_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(m_axi_wvalid),    // input wire s_axi_wvalid
  .s_axi_wready(m_axi_wready),    // output wire s_axi_wready
  .s_axi_bresp(m_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(m_axi_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(m_axi_bready),    // input wire s_axi_bready
  .s_axi_araddr(m_axi_araddr[3:0]),    // input wire [3 : 0] s_axi_araddr
  .s_axi_arvalid(m_axi_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(m_axi_arready),  // output wire s_axi_arready
  .s_axi_rdata(m_axi_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(m_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(m_axi_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(m_axi_rready),    // input wire s_axi_rready
  .rx(rx),                        // input wire rx
  .tx(tx)                        // output wire tx
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
    @(posedge clk);
    wb_cyc_i = 0;
    wb_stb_i = 0;
    wb_we_i = 0;
    wb_addr_i = 0;
    wb_data_i = 0;
    $display("T=[%t]. Transaction ended",$time);
endtask //automatic





initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);
    write(32'h4,32'hAF);
    repeat(100) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire