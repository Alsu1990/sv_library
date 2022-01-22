module debouncer #(
    parameter PORT_WIDTH = 5,
    parameter DEBOUNCING_TIME = 2_000_000  // by default debouncing time = 2e6 * 10 ns = 20ms
) (
    input logic clk_i,
    input logic [PORT_WIDTH-1:0] sig_i,
    output logic [PORT_WIDTH-1:0] debounced_sig_o
);
    //syncing sig_i to clk_i domain (2 stage)
    logic [PORT_WIDTH-1:0] sig_q;
    logic [PORT_WIDTH-1:0] sig_q1;
    logic [PORT_WIDTH-1:0] sig_last;
    always_ff @(posedge clk_i) begin : sync
        {sig_last, sig_q1, sig_q} <= {sig_q1, sig_q, sig_i};
    end
    //debouncing counter
    logic diff = 0;
    logic zero_timer = 0;
    logic [$bits(DEBOUNCING_TIME)-1:0] dbc_timer;
    
    always_ff @(posedge clk_i) begin : timer_logic
        if (zero_timer && diff) begin
            // reseting dbc_timer everytime when input signas changes
            dbc_timer <= DEBOUNCING_TIME;
            zero_timer <= 0;
        end else if (!zero_timer) begin
            //timer running
            dbc_timer <= dbc_timer - 1;
            zero_timer <= (dbc_timer[$bits(DEBOUNCING_TIME)-1:1] == 0);
        end else begin
            dbc_timer <= 0;
            zero_timer <= 1;
        end    
    end

    // tracking on changes in input signals
    always_ff @(posedge clk_i) begin : diff_logic
        //diff signals goes to 1 when last registered input differs from output
        // and/or remains 1 if timer not reached 0
        diff <= (diff && !zero_timer) || (sig_last != debounced_sig_o);
    end

    always_ff @(posedge clk_i) begin : output_logic
        if (zero_timer) debounced_sig_o <= sig_last;
    end

endmodule