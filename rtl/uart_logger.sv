`include "C:\Xilinx\sv_library\rtl\axi4_master.sv"
`include "C:\Xilinx\sv_library\structs\packages.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2022 08:53:00 PM
// Design Name: 
// Module Name: uart_logger
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_logger import functions_pkg::*;
    #(
    PROBE_WIDTH = 32,
    AXI_ADDR_WIDTH = 4,
    AXI_DATA_WIDTH = 32)
    (
    // debug interface 
    // [27:12] 16 bit audio sample
    input logic [PROBE_WIDTH-1:0]       debug_probe_i, 
    input logic                         debug_trig_i,
    input logic                         debug_clk_i,
    input logic                         debug_rstn_i,

    input logic                         rx,
    output logic                        tx,
    // axi_lite interface to UART/ETHERNET
    input logic                         m_axi_aclk,
    input logic                         m_axi_aresetn
    );
    // AXI interface instantination
    logic m_axi_awvalid;
    logic m_axi_awready;
    logic [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr;
    logic m_axi_wvalid;
    logic m_axi_wready;
    logic [AXI_DATA_WIDTH-1:0]  m_axi_wdata;
    logic [3:0] m_axi_wstrb;
    logic m_axi_bvalid;
    logic m_axi_bready;
    logic [1:0] m_axi_bresp;
    logic m_axi_arvalid;
    logic m_axi_arready;
    logic [AXI_ADDR_WIDTH-1:0]  m_axi_araddr;
    logic m_axi_rvalid;
    logic m_axi_rready;
    logic [AXI_DATA_WIDTH-1:0]  m_axi_rdata;
    logic [1:0] m_axi_rresp;

    //////////////////////////////////////////////////////////////////////////////////
    //debug clock domain
    logic [1:0] debug_trig_q;
    logic trig_rising_edge;
    assign trig_rising_edge = ~debug_trig_q[1] & debug_trig_q[0];
    assign trig_falling_edge = debug_trig_q[1] & ~debug_trig_q[0];

    logic [PROBE_WIDTH-1:0] debug_data_q;
    logic debug_data_valid;

    always_ff @(posedge debug_clk_i) begin : edge_detect
        if (!debug_rstn_i) begin
            debug_trig_q <= '0;   
        end else begin 
            debug_trig_q <= {debug_trig_q[0], debug_trig_i};    
        end 
    end

    always_ff @(posedge debug_clk_i) begin : debug_data_valid_logic
        if (!debug_rstn_i) begin
            debug_data_q <= '0;   
            debug_data_valid <= '0;   
        end else begin 
            if (trig_rising_edge) begin
                debug_data_q <= debug_probe_i;
                debug_data_valid <= 1'b1;
            end else if (trig_falling_edge) begin
                debug_data_valid <= '0;
            end    
        end 
    end

    
    //////////////////////////////////////////////////////////////////////////////////
    // main fsm
    // deviding fetched data (default 16 bit) to 4 bit chunks
    // convert each chunk to ascii
    // send chunks to UART
    //////////////////////////////////////////////////////////////////////////////////
    // wishbone master interface instantination 
        logic                       wb_cyc_o;  
        logic                       wb_stb_o;  
        logic                       wb_we_o;   
        logic [AXI_ADDR_WIDTH-1:0]  wb_addr_o; 
        logic [AXI_DATA_WIDTH-1:0]  wb_data_o; 
        logic                       wb_stall_i;
        logic [AXI_DATA_WIDTH-1:0]  wb_data_i; 
        logic                       wb_ack_i;
    // axi4lite master instantination
    axi4_master #(
        .AXI_WIDTH(AXI_DATA_WIDTH), 
        .AXI_DEPTH(AXI_ADDR_WIDTH))
    uart_axi_ctrl (
        .wb_rst_i(~debug_rstn_i), 
        .wb_clk_i(debug_clk_i), 
        .wb_cyc_i(wb_cyc_o), 
        .wb_stb_i(wb_stb_o), 
        .wb_we_i(wb_we_o),  
        .wb_addr_i(wb_addr_o),
        .wb_data_i(wb_data_o),
        .wb_stall_o(wb_stall_i),
        .wb_data_o(wb_data_i), 
        .wb_ack_o(wb_ack_i),
        .m_axi_aresetn, 
        .m_axi_aclk,    
        .m_axi_awvalid,
        .m_axi_awready,
        .m_axi_awaddr,
        .m_axi_wvalid,
        .m_axi_wready,
        .m_axi_wdata,
        .m_axi_wstrb,
        .m_axi_bvalid,
        .m_axi_bready,
        .m_axi_bresp,
        .m_axi_arvalid,
        .m_axi_arready,
        .m_axi_araddr,
        .m_axi_rvalid,
        .m_axi_rready,
        .m_axi_rdata,
        .m_axi_rresp
    );
    //////////////////////////////////////////////////////////////////////////////////
    // uart_lite instantination
    //Baud Rate = 230400, Data Bits = 8, No Parity
    axi_uartlite_0 uart (
        .s_axi_aclk(m_axi_aclk),        // input logic wire s_axi_aclk
        .s_axi_aresetn(m_axi_aresetn),  // input logic wire s_axi_aresetn
        .s_axi_awaddr(m_axi_awaddr),    // input logic wire [3 : 0] s_axi_awaddr
        .s_axi_awvalid(m_axi_awvalid),  // input logic wire s_axi_awvalid
        .s_axi_awready(m_axi_awready),  // output wire s_axi_awready
        .s_axi_wdata(m_axi_wdata),      // input logic wire [31 : 0] s_axi_wdata
        .s_axi_wstrb(m_axi_wstrb),      // input logic wire [3 : 0] s_axi_wstrb
        .s_axi_wvalid(m_axi_wvalid),    // input logic wire s_axi_wvalid
        .s_axi_wready(m_axi_wready),    // output wire s_axi_wready
        .s_axi_bresp(m_axi_bresp),      // output wire [1 : 0] s_axi_bresp
        .s_axi_bvalid(m_axi_bvalid),    // output wire s_axi_bvalid
        .s_axi_bready(m_axi_bready),    // input logic wire s_axi_bready
        .s_axi_araddr(m_axi_araddr),    // input logic wire [3 : 0] s_axi_araddr
        .s_axi_arvalid(m_axi_arvalid),  // input logic wire s_axi_arvalid
        .s_axi_arready(m_axi_arready),  // output wire s_axi_arready
        .s_axi_rdata(m_axi_rdata),      // output wire [31 : 0] s_axi_rdata
        .s_axi_rresp(m_axi_rresp),      // output wire [1 : 0] s_axi_rresp
        .s_axi_rvalid(m_axi_rvalid),    // output wire s_axi_rvalid
        .s_axi_rready(m_axi_rready),    // input logic wire s_axi_rready
        .interrupt(interrupt),          // output wire interrupt
        .rx(rx),                        // input logic wire rx
        .tx(tx)                        // output wire tx
    );
    //////////////////////////////////////////////////////////////////////////////////
    // uartlite register space
    localparam UART_RX_FIFO_ADDR = 4'h0;  
    localparam UART_TX_FIFO_ADDR = 4'h4;
    localparam UART_STAT_REG_ADDR = 4'h8;   // Status Register
    localparam UART_CTRL_REG_ADDR = 4'hC;   // Control Register
    //////////////////////////////////////////////////////////////////////////////////
    localparam EOL_ASCII = 8'h0D;           // end of line character

    typedef enum logic [1:0]  {
		IDLE = 2'b00,
		CHUNK_TX = 2'b01,
		VERIFY_TX = 2'b10,
		EOL_TX = 2'b11
	} state_t;
    state_t state_q;

    logic [3:0] uart_chunk [0:3];
    logic [1:0] chunk_ptr;


    // if debug data valid -> devide to 4 chunks
    always_ff @(posedge debug_clk_i) begin 
        if (!debug_rstn_i) begin
            foreach (uart_chunk[i])
            uart_chunk[i] <= '0;
        end else if (debug_data_valid) begin
            {uart_chunk[0], uart_chunk[1], uart_chunk[2], uart_chunk[3]} = debug_data_q;
        end    
    end
                
    always_ff @(posedge debug_clk_i) begin : current_state
        if (!debug_rstn_i) begin
            state_q <= IDLE;
        end else begin
            unique case (state_q)
                IDLE: begin
                    if (trig_rising_edge) begin
                        state_q <= CHUNK_TX;
                    end else 
                        state_q <= IDLE;
                end 
                CHUNK_TX: begin
                    if (chunk_ptr == 2'b11 && ((wb_ack_i) && (wb_stb_o))) begin
                        state_q <= EOL_TX;
                    end else
                        state_q <= CHUNK_TX;
                end
                EOL_TX: begin
                    if (((wb_ack_i) && (wb_stb_o))) begin
                        state_q <= IDLE;
                    end else
                        state_q <= EOL_TX;
                end
                // VERIFY_TX: begin
                //     if (m_axi_bvalid) begin
                //         state_q = IDLE;
                //     end else
                //         state_q = FINISH_WRITE;
                // end
                default: state_q <= IDLE;
            endcase
        end
    end     
     
    always_ff @(posedge debug_clk_i) begin : output_logic
        unique case (state_q)
            IDLE: begin
                wb_addr_o <= '0;
                wb_data_o <= '0;
                wb_cyc_o <= '0;
                wb_stb_o <= '0;
                wb_we_o <= '0;
                chunk_ptr <= '0;
            end  
            CHUNK_TX: begin
                wb_data_o <= hex_to_ascii(uart_chunk[chunk_ptr]);
                wb_addr_o <= UART_TX_FIFO_ADDR;
                if(!wb_ack_i) begin
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    wb_we_o <= 1'b1;
                end else if((wb_ack_i)&&(wb_stb_o)) begin
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    wb_we_o <= 1'b0;
                    chunk_ptr <= chunk_ptr + 1;
                end
            end
            VERIFY_TX: begin
                if (wb_ack_i) begin  // wishbone slave acknowledgeW
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    wb_we_o <= 1'b0;
                    chunk_ptr <= chunk_ptr + 1;
                end
            end
            EOL_TX: begin
                wb_data_o <= EOL_ASCII;
                wb_addr_o <= UART_TX_FIFO_ADDR;
                if(!wb_ack_i) begin
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    wb_we_o <= 1'b1;
                end else if((wb_ack_i)&&(wb_stb_o)) begin
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    wb_we_o <= 1'b0;
                end
            end
        endcase
    end
endmodule