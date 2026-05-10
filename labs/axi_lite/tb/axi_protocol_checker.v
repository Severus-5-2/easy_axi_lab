// AXI4-Lite Protocol Checker
//   valid 拉高后必须保持到 ready=1 才能撤
//   valid 拉高期间 payload 不能变
//   复位时所有 valid 必须为 0

`timescale 1ns/1ps

module axi_protocol_checker (
    input wire        aclk,
    input wire        aresetn,

    input wire        awvalid, awready,
    input wire [31:0] awaddr,
    input wire        wvalid,  wready,
    input wire [31:0] wdata,
    input wire [3:0]  wstrb,
    input wire        bvalid,  bready,
    input wire [1:0]  bresp,
    input wire        arvalid, arready,
    input wire [31:0] araddr,
    input wire        rvalid,  rready,
    input wire [31:0] rdata,
    input wire [1:0]  rresp,

    output reg        violated
);

    initial violated = 1'b0;

    reg        awvalid_q, wvalid_q, bvalid_q, arvalid_q, rvalid_q;
    reg        awready_q, wready_q, bready_q, arready_q, rready_q;
    reg [31:0] awaddr_q,  wdata_q,  araddr_q, rdata_q;
    reg [3:0]  wstrb_q;
    reg [1:0]  bresp_q,   rresp_q;

    always @(posedge aclk) begin
        awvalid_q <= awvalid; awready_q <= awready; awaddr_q <= awaddr;
        wvalid_q  <= wvalid;  wready_q  <= wready;  wdata_q  <= wdata;  wstrb_q <= wstrb;
        bvalid_q  <= bvalid;  bready_q  <= bready;  bresp_q  <= bresp;
        arvalid_q <= arvalid; arready_q <= arready; araddr_q <= araddr;
        rvalid_q  <= rvalid;  rready_q  <= rready;  rdata_q  <= rdata; rresp_q <= rresp;
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            awvalid_q <= 1'b0; wvalid_q <= 1'b0; bvalid_q <= 1'b0;
            arvalid_q <= 1'b0; rvalid_q <= 1'b0;
        end
    end

    task report_violation(input [255:0] msg);
        begin
            $display("[CHECKER] @ %0t ns: %0s", $time, msg);
            violated <= 1'b1;
        end
    endtask

    always @(posedge aclk) begin
        if (!aresetn) begin
            if (awvalid) report_violation("awvalid high during reset");
            if (wvalid)  report_violation("wvalid high during reset");
            if (bvalid)  report_violation("bvalid high during reset");
            if (arvalid) report_violation("arvalid high during reset");
            if (rvalid)  report_violation("rvalid high during reset");
        end
    end

    always @(posedge aclk) begin
        if (aresetn) begin
            if (awvalid_q && !awready_q) begin
                if (!awvalid)
                    report_violation("AW: awvalid dropped before handshake");
                if (awvalid && (awaddr !== awaddr_q))
                    report_violation("AW: awaddr changed before handshake");
            end
            if (wvalid_q && !wready_q) begin
                if (!wvalid)
                    report_violation("W: wvalid dropped before handshake");
                if (wvalid && ((wdata !== wdata_q) || (wstrb !== wstrb_q)))
                    report_violation("W: wdata/wstrb changed before handshake");
            end
            if (bvalid_q && !bready_q) begin
                if (!bvalid)
                    report_violation("B: bvalid dropped before handshake");
                if (bvalid && (bresp !== bresp_q))
                    report_violation("B: bresp changed before handshake");
            end
            if (arvalid_q && !arready_q) begin
                if (!arvalid)
                    report_violation("AR: arvalid dropped before handshake");
                if (arvalid && (araddr !== araddr_q))
                    report_violation("AR: araddr changed before handshake");
            end
            if (rvalid_q && !rready_q) begin
                if (!rvalid)
                    report_violation("R: rvalid dropped before handshake");
                if (rvalid && ((rdata !== rdata_q) || (rresp !== rresp_q)))
                    report_violation("R: rdata/rresp changed before handshake");
            end
        end
    end

endmodule
