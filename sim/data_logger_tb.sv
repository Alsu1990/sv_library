timeunit 1ns/1ns;



module data_logger_tb();
    logic [31:0]    debug_probe_i;
    logic           debug_trig_i;
    logic           debug_clk_i;
    logic           debug_rstn_i;
    logic           rx;
    logic           tx;
    logic           m_axi_aclk;
    logic           m_axi_aresetn;

    assign debug_rstn_i = m_axi_aresetn;

    uart_logger dut (.*);
    //////////////////////////////////////////////////////////////
    // error handler
    event error;
    integer error_count = 0;


    always @(error) begin
        error_count++;
        $display("T=[%t]. Error recieved!", $time);
    end

    always @(negedge dut.m_axi_bvalid) begin
        if(dut.m_axi_bresp == 2'b10) begin
            ->error;
            $display("T=[%t]. Error. FIFO_TX full!.", $time);
        end else begin
            $display("T=[%t]. Write to FIFO_TX Good.", $time); 
        end
    end
    //////////////////////////////////////////////////////////////
    localparam PERIOD = 10;
    localparam IDLE = 19200;

    always #(PERIOD/2) debug_clk_i = ~debug_clk_i;
    always #(PERIOD/2) m_axi_aclk = ~m_axi_aclk;

    task automatic set_prob_data();
        @(posedge debug_clk_i);
        debug_probe_i = 32'h0000ffff & $urandom;
        $display("T=%t, probe_data = 0x%h", $time, debug_probe_i);
        debug_trig_i = 1;
        #760; // valid time
        debug_trig_i = 0;
    endtask //automatic

    initial begin
        $display("T=%t, starting simulation", $time);
        debug_clk_i = 0;
        m_axi_aclk = 0;
        debug_probe_i = 0;
        debug_trig_i = 0;
        m_axi_aresetn = 0;
        #(PERIOD*10);
        m_axi_aresetn = 1;
        #(PERIOD);

        repeat(10) begin //every 19.2 us (IDLE=19200)
            set_prob_data();
            #(IDLE); 
        end
        $display("T=[%t]. Error found %d", $time, error_count);
        $display("T=%t, simulation ended", $time);
        $finish;
    end
endmodule

