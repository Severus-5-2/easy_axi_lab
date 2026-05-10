// Sync FIFO Testbench
//   vvp build/sim +TC=N    跑第 N 个 case (1..5)
//   输出 TEST_RESULT: PASS 或 TEST_RESULT: FAIL <reason>

`timescale 1ns/1ps

module tb_top;

    parameter DATA_WIDTH = 32;
    parameter DEPTH      = 8;

    reg clk = 1'b0;
    reg rstn = 1'b0;
    always #5 clk = ~clk;

    reg                   in_valid;
    wire                  in_ready;
    reg  [DATA_WIDTH-1:0] in_data;
    wire                  out_valid;
    reg                   out_ready;
    wire [DATA_WIDTH-1:0] out_data;

    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH     )
    ) u_dut (
        .clk       (clk      ),
        .rstn      (rstn     ),
        .in_valid  (in_valid ),
        .in_ready  (in_ready ),
        .in_data   (in_data  ),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .out_data  (out_data )
    );

    wire chk_violated;

    handshake_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_chk (
        .clk      (clk         ),
        .rstn     (rstn        ),
        .in_valid (in_valid    ),
        .in_ready (in_ready    ),
        .in_data  (in_data     ),
        .out_valid(out_valid   ),
        .out_ready(out_ready   ),
        .out_data (out_data    ),
        .violated (chk_violated)
    );

    // reference model
    reg [DATA_WIDTH-1:0] ref_q [0:1023];
    integer ref_head, ref_tail;

    integer fail_count;
    reg [1023:0] fail_msg;

    task record_fail(input [1023:0] m);
        if (fail_count == 0) fail_msg = m;
        fail_count = fail_count + 1;
        $display("[FAIL @ %0t ns] %0s", $time, m);
    endtask

    task do_reset;
        rstn = 0;
        in_valid = 0; in_data = 0; out_ready = 0;
        repeat (5) @(posedge clk);
        #1 rstn = 1;
        @(posedge clk);
    endtask

    task push(input [DATA_WIDTH-1:0] d);
        @(posedge clk); #1;
        in_valid = 1;
        in_data = d;
        @(posedge clk);
        while (!in_ready) @(posedge clk);
        #1;
        in_valid = 0;
        ref_q[ref_tail] = d;
        ref_tail = ref_tail + 1;
    endtask

    task pop_check;
        reg [DATA_WIDTH-1:0] expected, got;
        @(posedge clk); #1;
        out_ready = 1;
        @(posedge clk);
        while (!out_valid) @(posedge clk);
        got = out_data;
        #1;
        out_ready = 0;
        expected = ref_q[ref_head];
        ref_head = ref_head + 1;
        if (got !== expected) begin
            $display("[FAIL] pop expect=0x%h got=0x%h", expected, got);
            record_fail("pop data mismatch");
        end
    endtask

    initial begin
        #100_000;
        $display("[FAIL] global timeout");
        $display("TEST_RESULT: FAIL global_timeout");
        $finish;
    end

    // test cases

    task test_01;
        do_reset();
        repeat (5) @(posedge clk);
        if (out_valid) record_fail("out_valid high after reset with no data");
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_02;
        do_reset();
        push(32'hDEAD_BEEF);
        pop_check();
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_03;
        integer k;
        do_reset();
        for (k = 0; k < 20; k = k + 1) begin
            if (out_valid) record_fail("out_valid asserted while empty");
            @(posedge clk);
        end
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_04;
        integer k;
        do_reset();
        for (k = 0; k < DEPTH; k = k + 1) push(32'h1000_0000 + k);
        for (k = 0; k < DEPTH; k = k + 1) pop_check();
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_05;
        integer k;
        do_reset();
        for (k = 0; k < DEPTH; k = k + 1) push(32'h2000_0000 + k);
        in_valid = 0; in_data = 0; out_ready = 0;
        repeat (10) begin
            @(posedge clk); #1;
            if (in_ready) record_fail("in_ready high while FIFO is full");
        end
        for (k = 0; k < DEPTH; k = k + 1) pop_check();
        if (chk_violated) record_fail("protocol violated");
    endtask

    integer tc_id;
    initial begin
        fail_count = 0;
        fail_msg = "";
        ref_head = 0;
        ref_tail = 0;

        if (!$value$plusargs("TC=%d", tc_id)) tc_id = 0;
        if ($test$plusargs("DUMP")) begin
            $dumpfile("build/wave.vcd");
            $dumpvars(0, tb_top);
        end
        in_valid = 0; in_data = 0; out_ready = 0;

        case (tc_id)
            1: test_01();
            2: test_02();
            3: test_03();
            4: test_04();
            5: test_05();
            default: begin
                $display("ERROR: invalid +TC=%0d", tc_id);
                $display("TEST_RESULT: FAIL invalid_tc");
                $finish;
            end
        endcase

        if (chk_violated && fail_count == 0) begin
            fail_count = 1;
            fail_msg = "protocol violated";
        end
        if (fail_count == 0) $display("TEST_RESULT: PASS");
        else                 $display("TEST_RESULT: FAIL %0s", fail_msg);
        $finish;
    end

endmodule
