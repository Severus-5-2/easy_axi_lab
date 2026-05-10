// AXI4-Lite Slave - 16x32bit 寄存器，在 TODO 处填入实现

`timescale 1ns/1ps

module axi_lite_slave (
    input  wire        aclk,
    input  wire        aresetn,

    // AW
    input  wire        awvalid,
    output wire        awready,
    input  wire [31:0] awaddr,
    input  wire [2:0]  awprot,

    // W
    input  wire        wvalid,
    output wire        wready,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,

    // B
    output wire        bvalid,
    input  wire        bready,
    output wire [1:0]  bresp,

    // AR
    input  wire        arvalid,
    output wire        arready,
    input  wire [31:0] araddr,
    input  wire [2:0]  arprot,

    // R
    output wire        rvalid,
    input  wire        rready,
    output wire [31:0] rdata,
    output wire [1:0]  rresp
);

    reg [31:0] regs [0:15];

    integer i;
    always @(posedge aclk) begin
        if (!aresetn) begin
            for (i = 0; i < 16; i = i + 1) regs[i] <= 32'h0;
        end else begin
            // TODO: AW + W 都握手后，按 wstrb 写入 regs[idx]
        end
    end

    // TODO 1 : AW 通道，awready 握手并锁存 awaddr
    assign awready = 1'b0;

    // TODO 2 : W 通道，wready 握手并锁存 wdata 和 wstrb
    assign wready = 1'b0;

    // TODO 3 : 写提交 + B 通道
    assign bvalid = 1'b0;
    assign bresp  = 2'b00;

    // TODO 4 : AR 通道，arready 握手并锁存 araddr
    assign arready = 1'b0;

    // TODO 5 : R 通道
    assign rvalid = 1'b0;
    assign rdata  = 32'h0;
    assign rresp  = 2'b00;

endmodule
