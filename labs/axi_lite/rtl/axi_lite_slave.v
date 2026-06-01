// AXI4-Lite Slave - 16x32bit 寄存器
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
    reg [31:0] awaddr_latch;      // 锁存写地址
    reg [31:0] araddr_latch;      // 锁存读地址

    // 用 latch 标记：收到未完成，支持 AW/W 乱序
    reg        aw_latched;
    reg        w_latched;
    reg [31:0] wdata_latch;
    reg [3:0]  wstrb_latch;
    reg        ar_latched;

    // B/R 通道输出寄存器
    reg        bvalid_r;
    reg        rvalid_r;
    reg [31:0] rdata_r;

    integer i;

    // 组合逻辑：事务提交信号
    wire write_commit;
    wire read_start;
    wire [3:0] wr_idx;
    wire [3:0] rd_idx;
    wire [31:0] wstrb_mask;
    wire [31:0] merged_wdata;

    assign wr_idx      = awaddr_latch[5:2];
    assign rd_idx      = araddr_latch[5:2];
    assign write_commit= aw_latched && w_latched;
    assign read_start  = ar_latched && !rvalid_r;

    // 字节掩码处理（正确按字节写）
    assign wstrb_mask = {
        {8{wstrb_latch[3]}},
        {8{wstrb_latch[2]}},
        {8{wstrb_latch[1]}},
        {8{wstrb_latch[0]}}
    };
    assign merged_wdata = (regs[wr_idx] & ~wstrb_mask) | (wdata_latch & wstrb_mask);

    // --------------------------
    
    assign awready = !aw_latched && !bvalid_r;
    assign wready  = !w_latched  && !bvalid_r;
    assign arready = !ar_latched && !rvalid_r;

    assign bvalid  = bvalid_r;
    assign bresp   = 2'b00;
    assign rvalid  = rvalid_r;
    assign rdata   = rdata_r;
    assign rresp   = 2'b00;

    // 数据存储：复位+写提交更新
    always @(posedge aclk) begin
        if (!aresetn) begin
            for (i = 0; i < 16; i = i + 1) regs[i] <= 32'h0;
        end else if (write_commit) begin
            regs[wr_idx] <= merged_wdata;
        end
    end

    // AW 通道：握手锁存，提交后清标记
    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_latched     <= 1'b0;
            awaddr_latch   <= 32'd0;
        end else if (write_commit) begin
            aw_latched     <= 1'b0;
        end else if (awvalid && awready) begin
            awaddr_latch   <= awaddr;
            aw_latched     <= 1'b1;
        end
    end

    // W 通道：握手锁存，提交后清标记
    always @(posedge aclk) begin
        if (!aresetn) begin
            w_latched      <= 1'b0;
            wdata_latch    <= 32'd0;
            wstrb_latch    <= 4'd0;
        end else if (write_commit) begin
            w_latched      <= 1'b0;
        end else if (wvalid && wready) begin
            wdata_latch    <= wdata;
            wstrb_latch    <= wstrb;
            w_latched      <= 1'b1;
        end
    end

    // B 通道：提交发响应，握手后清
    always @(posedge aclk) begin
        if (!aresetn) begin
            bvalid_r <= 1'b0;
        end else if (write_commit) begin
            bvalid_r <= 1'b1;
        end else if (bvalid_r && bready) begin
            bvalid_r <= 1'b0;
        end
    end

    // AR 通道：握手锁存，读响应握手后清
    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_latched     <= 1'b0;
            araddr_latch   <= 32'd0;
        end else if (rvalid_r && rready) begin
            ar_latched     <= 1'b0;
        end else if (arvalid && arready) begin
            araddr_latch   <= araddr;
            ar_latched     <= 1'b1;
        end
    end

    // R 通道：地址锁存后发数据，握手后清
    always @(posedge aclk) begin
        if (!aresetn) begin
            rvalid_r <= 1'b0;
            rdata_r  <= 32'd0;
        end else if (read_start) begin
            rdata_r  <= regs[rd_idx];
            rvalid_r <= 1'b1;
        end else if (rvalid_r && rready) begin
            rvalid_r <= 1'b0;
        end
    end

endmodule