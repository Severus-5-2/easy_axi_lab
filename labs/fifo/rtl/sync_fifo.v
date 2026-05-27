`timescale 1ns/1ps

module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 8
) (
    input  wire                         clk                        ,
    input  wire                         rstn                       ,

    input  wire                         in_valid                   ,
    output wire                         in_ready                   ,
    input  wire          [DATA_WIDTH-1: 0]in_data                  ,

    output wire                         out_valid                  ,
    input  wire                         out_ready                  ,
    output wire          [DATA_WIDTH-1: 0]out_data                    
);

    localparam ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // TODO 1：读写指针，建议用 ADDR_W+1 位，最高位区分空满
    reg [ADDR_W:0] wptr;  // 写指针，位宽是 ADDR_W+1
    reg [ADDR_W:0] rptr;  // 读指针，位宽是 ADDR_W+1

    // TODO 2：empty / full 信号
    wire empty = (wptr == rptr);
    wire full  = (wptr[ADDR_W] != rptr[ADDR_W]) && 
                 (wptr[ADDR_W-1:0] == rptr[ADDR_W-1:0]);

    // TODO 3：握手输出信号
    // in_ready：FIFO没满的时候，都可以接收数据
    assign in_ready  = ~full;

    // out_valid：FIFO没空的时候，都有数据可以输出
    assign out_valid = ~empty;

    // out_data：直接把读指针指向的内存数据输出
    assign out_data  = mem[rptr[ADDR_W-1:0]];

    // 先把 mem 的复位逻辑写对
    integer i;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
        // 复位时清空所有内存
           for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] <= {DATA_WIDTH{1'b0}};
           end
        // 复位时指针都清零
           wptr <= 0;
           rptr <= 0;
    end else begin
        // 写操作：握手成功时写入数据并更新写指针
        if (in_valid && in_ready) begin
            mem[wptr[ADDR_W-1:0]] <= in_data;
            wptr <= wptr + 1'b1;
        end

        // 读操作：握手成功时更新读指针
        if (out_valid && out_ready) begin
            rptr <= rptr + 1'b1;
        end
        end
    end

endmodule
