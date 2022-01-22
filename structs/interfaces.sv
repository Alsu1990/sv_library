interface axi4_stream_int #(
    parameter DATA_WIDTH = 32,
    parameter TID_WIDTH = 4
    )
    (
    input logic     axis_aclk,
    input logic     axis_aresetn
    ); 
    logic [DATA_WIDTH-1:0] axis_tdata;
    logic [TID_WIDTH-1:0] axis_tid;
    logic axis_tvalid;
    logic axis_tready;

    // master direction
    modport master (
    input axis_tready,
    output axis_tdata, axis_tvalid, axis_tid
    );
    // slave direction
    modport slave (
    output axis_tready,
    input axis_tdata, axis_tvalid, axis_tid
    );
endinterface : axi4_stream_int