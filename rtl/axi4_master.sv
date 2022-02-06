timeunit 1ns/1ns;


module axi4_master #(
    AXI_WIDTH = 32,
    AXI_DEPTH = 32) (
    //control wishbone interface
    input logic                         wb_rst_i,   // reset signal (active high)
    input logic                         wb_clk_i,   // clock signal
    input logic                         wb_cyc_i,   // bus cycle signal
    input logic                         wb_stb_i,   // slave select signal
    input logic                         wb_we_i,    // high for write request
    input logic [AXI_DEPTH-1:0]         wb_addr_i,  // address request
    input logic [AXI_WIDTH-1:0]         wb_data_i,  // data input


    output logic                        wb_stall_o,    // high when can't accept request
    input logic [AXI_WIDTH-1:0]         wb_data_o,  // data output
    output logic                        wb_ack_o,
    //AXI4 MASTER (Lite) interface Vivado-style naming
    input logic                         m_axi_aresetn,     
    input logic                         m_axi_aclk,     
    output logic                        m_axi_awvalid,
    input logic                         m_axi_awready,
    output logic [AXI_DEPTH-1:0]        m_axi_awaddr,
    output logic                        m_axi_wvalid,
    input logic                         m_axi_wready,
    output logic [AXI_WIDTH-1:0]        m_axi_wdata,
    output logic [3:0]                  m_axi_wstrb,
    input logic                         m_axi_bvalid,
    output logic                        m_axi_bready,
    input logic  [1:0]                  m_axi_bresp,
    output logic                        m_axi_arvalid,
    input logic                         m_axi_arready,
    output logic [AXI_DEPTH-1:0]        m_axi_araddr,
    input logic                         m_axi_rvalid,
    output logic                        m_axi_rready,
    input logic  [AXI_WIDTH-1:0]        m_axi_rdata,
    input logic  [1:0]                  m_axi_rresp);
    
//////////////////////////////////////////////////////////////////////////////////
    logic [AXI_WIDTH-1:0] data_q;
    logic [AXI_DEPTH-1:0] addr_q;
    logic read_command, write_command;

    assign read_command = ((wb_cyc_i)&&(wb_stb_i)&&(!wb_we_i));
    assign write_command = ((wb_cyc_i)&&(wb_stb_i)&&(wb_we_i));
// Wishbone interface
    // data and address for AXI WRITE
    always_ff @(posedge wb_clk_i) begin : write_to_slave
        if ((wb_cyc_i)&&(wb_stb_i)&&(wb_we_i)&&(!wb_stall_o)) begin
            data_q <= wb_data_i;
            addr_q <= wb_addr_i;
        end
    end

   always_ff @(posedge wb_clk_i) begin : read_from_slave
        if ((!wb_we_i)&&(m_axi_rvalid)) begin
            
        end
    end

    always_ff @(posedge wb_clk_i) begin : ack_logic
        if (wb_rst_i) wb_ack_o <= 1'b0;
        else wb_ack_o <= ((wb_stb_i)&&(!wb_stall_o)&&(m_axi_bvalid||m_axi_rvalid));
    end


    assign wb_stall_o = 1'b0;
//////////////////////////////////////////////////////////////////////////////////
// axi4 interface
    typedef enum logic [2:0] { 
		SET_READ_ADDR = 3'b000,
		DO_READ = 3'b001,
		SET_WRITE_ADDR = 3'b010,
		DO_WRITE = 3'b011,
		FINISH_WRITE = 3'b100,
        IDLE = 3'b101	
	} axi_state_t;

    axi_state_t state_q, next_state_q;
   always_ff @(posedge m_axi_aclk) begin : current_state
        if (!m_axi_aresetn) begin
            state_q <= IDLE;
        end else begin
            state_q <= next_state_q;
        end
    end 

    always_comb begin : next_state
        unique case (state_q)
            IDLE: begin
                if (write_command) begin
                    next_state_q <= DO_WRITE;
                end else if (read_command) begin
                    next_state_q <= DO_READ; 
                end else 
                    next_state_q <= IDLE;
            end 
            DO_WRITE: begin
                if (m_axi_wready) begin
                    next_state_q <= FINISH_WRITE;
                end else
                    next_state_q <= DO_WRITE;
            end
            FINISH_WRITE: begin
                if (m_axi_bvalid) begin
                    next_state_q <= IDLE;
                end else
                    next_state_q <= FINISH_WRITE;
            end

        endcase
    end

    always_comb begin : output_logic
        unique case (state_q)
            IDLE: begin
                m_axi_awvalid <= 1'b0;
                m_axi_wvalid <= 1'b0;
                m_axi_bready <= 1'b0;
                m_axi_arvalid <= 1'b0;
                m_axi_rready <= 1'b0;
            end 
            DO_WRITE: begin
                m_axi_wdata <= data_q;
                m_axi_awaddr <= addr_q;
                m_axi_awvalid <= 1'b1; 
                m_axi_wvalid <= 1'b1; 
                m_axi_bready <= 1'b1;
                    

            end
            FINISH_WRITE: begin
                m_axi_awvalid <= 1'b0;
                m_axi_wvalid <= 1'b0; 
            end
        endcase
    end
endmodule