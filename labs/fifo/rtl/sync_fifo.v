`timescale 1ns/1ps

module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 8
) (
    input  wire                         clk                        ,
    input  wire                         rstn                       ,

    input  wire                         in_valid                   ,
    output wire                         in_ready                   ,
    input  wire          [DATA_WIDTH-1: 0]in_data                    ,

    output wire                         out_valid                  ,
    input  wire                         out_ready                  ,
    output wire          [DATA_WIDTH-1: 0]out_data                    
);

    localparam ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // TODO 1 : 读写指针，建议用 ADDR_W+1 位，最高位区分空满

    // TODO 2 : empty / full

    // TODO 3 : 握手输出信号
    assign in_ready  = 1'b0;
    assign out_valid = 1'b0;
    assign out_data  = {DATA_WIDTH{1'b0}};

    // TODO 4 : 时序逻辑，写握手存数据并更新读写指针
    integer i;
    always @(posedge clk) begin
        if (!rstn) begin
            for (i = 0; i < DEPTH; i = i + 1) mem[i] <= {DATA_WIDTH{1'b0}};
        end else begin
        end
    end

endmodule
