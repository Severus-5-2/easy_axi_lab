// Handshake Checker - valid/ready 协议检查
//   valid 拉高后必须保持到 ready=1 才能撤
//   valid 拉高期间 payload 不能变
//   复位时 valid 必须为 0

`timescale 1ns/1ps

module handshake_checker #(
    parameter DATA_WIDTH = 32
) (
    input wire                  clk,
    input wire                  rstn,

    input wire                  in_valid,  in_ready,
    input wire [DATA_WIDTH-1:0] in_data,
    input wire                  out_valid, out_ready,
    input wire [DATA_WIDTH-1:0] out_data,

    output reg                  violated
);

    initial violated = 1'b0;

    reg                  in_valid_q,  in_ready_q;
    reg                  out_valid_q, out_ready_q;
    reg [DATA_WIDTH-1:0] in_data_q,   out_data_q;

    always @(posedge clk) begin
        in_valid_q  <= in_valid;  in_ready_q  <= in_ready;  in_data_q  <= in_data;
        out_valid_q <= out_valid; out_ready_q <= out_ready; out_data_q <= out_data;
    end

    always @(posedge clk) begin
        if (!rstn) begin
            in_valid_q  <= 1'b0;
            out_valid_q <= 1'b0;
        end
    end

    task report_violation(input [255:0] msg);
        begin
            $display("[CHECKER] @ %0t ns: %0s", $time, msg);
            violated <= 1'b1;
        end
    endtask

    always @(posedge clk) begin
        if (!rstn) begin
            if (in_valid)  report_violation("in_valid high during reset (TB error)");
            if (out_valid) report_violation("out_valid high during reset (FIFO bug)");
        end
    end

    always @(posedge clk) begin
        if (rstn) begin
            if (in_valid_q && !in_ready_q) begin
                if (!in_valid)
                    report_violation("IN: in_valid dropped before handshake");
                if (in_valid && (in_data !== in_data_q))
                    report_violation("IN: in_data changed before handshake");
            end
            if (out_valid_q && !out_ready_q) begin
                if (!out_valid)
                    report_violation("OUT: out_valid dropped before handshake");
                if (out_valid && (out_data !== out_data_q))
                    report_violation("OUT: out_data changed before handshake");
            end
        end
    end

endmodule
