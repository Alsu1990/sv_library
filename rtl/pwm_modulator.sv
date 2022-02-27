
module pwm_modulator (
    // AXI_S INTERFACE
    input  logic            m_axis_aud_aclk,
    input  logic            m_axis_aud_tvalid,
    input  logic [2:0]      m_axis_aud_tid,
    input  logic [31:0]     m_axis_aud_tdata,
    input  logic            m_axis_aud_aresetn,
    output logic            m_axis_aud_tready,
    output logic            pwm_out);

    //////////////////////counter/////////////////////////////////////
    // localparam  PWM_FRAME = 16'd2268;       // 44.1 kHz 100Mhz clock
    localparam  PWM_FRAME = 16'd100;       // 44.1 kHz 100Mhz clock
    logic [15:0] pwm_counter;            // PWM counter
    logic [15:0] period_counter_reversed;   // PWM counter bit reversed

    always_ff @( posedge m_axis_aud_aclk ) begin : pwm_period_counter
        if (!m_axis_aud_aresetn) begin
            pwm_counter <= 0;
        end else begin
            pwm_counter <= pwm_counter + 1;
        end
    end
    always_comb begin : bit_reversal_counter
        period_counter_reversed = {<<{pwm_counter}};
    end
    // genvar k;
    // generate
    //     for ( k = 0; k < 16; k++ ) begin : bit_reversal_loop
    //         assign period_counter_reversed[k] = pwm_counter[15-k];
    //     end
    // endgenerate

    //////////////////////AXIS && New samples logic ///////////////////////////////////
    // when timer hits zero, zero_timer flag indicates that system ready for new sample
    logic zero_timer;   
    logic [15:0] timer;
        
    // flag raises one clock (timer == 16'h0001) before timer reaches zero
    always_ff @( posedge m_axis_aud_aclk ) begin
        if ((!m_axis_aud_aresetn) || (zero_timer)) begin
            timer <= PWM_FRAME;
        end else begin
            timer <= timer - 1;
        end
    end

    always_ff @( posedge m_axis_aud_aclk ) zero_timer <= (!m_axis_aud_aresetn) ? 0 : (timer == 16'h0001);

    // when the timer runs out => accept next value
    logic [15:0] sample_out;
    logic [15:0] next_sample;
    logic next_valid;

    // reload sample with timer reaches zero
    always_ff @( posedge m_axis_aud_aclk ) if (zero_timer) sample_out <= next_sample;

    // pwm module ready for next sample
    always_ff @( posedge m_axis_aud_aclk ) m_axis_aud_tready <= (zero_timer) ? 1 : 0;

    always_ff @( posedge m_axis_aud_aclk ) begin : next_sample_logic
        if (!m_axis_aud_aresetn) begin
            next_sample <= 0;
            next_valid <= 0;
        end else begin
            // (| m_axis_aud_tdata[27:12]) ORing relevant bits to check if channel not NULL
            if (( | m_axis_aud_tdata[27:12]) && (m_axis_aud_tvalid) ) begin
                // convert 2's complement to unsigned binary offset
                // relevant 24 bit axis data [27:4]
                // trunk it to 16 bit axis_aud_tdata [27:12]
                next_sample <= {!m_axis_aud_tdata[27], m_axis_aud_tdata[26:12]};
                next_valid <= 1;
            end else next_valid <= 0;
        end
    end

    always_ff @( posedge m_axis_aud_aclk ) pwm_out <= ( sample_out >= period_counter_reversed ) ? 1'b1 : 1'b0 ;
    // logic pwm_out_register;
    // always_ff @( posedge m_axis_aud_aclk ) pwm_out_register <= ( sample_out >= period_counter_reversed ) ? 1'b1 : 1'b0 ;
 
//  OBUFT #(
//     .DRIVE(12),
//     .IOSTANDARD("DEFAULT"),
//     .SLEW("SLOW"))
//     OBUFT_inst (
//         .O(pwm_out),     // Buffer output (connect directly to top-level port)
//         .I(pwm_out_register),     // Buffer input
//         .T(pwm_out_register));      // 3-state enable input
    
endmodule