// AXI4-Lite Slave Testbench
//   vvp build/sim +TC=N    跑第 N 个 case (1..5)
//   输出 TEST_RESULT: PASS 或 TEST_RESULT: FAIL <reason>

`timescale 1ns/1ps

module tb_top;

    reg aclk = 1'b0;
    reg aresetn = 1'b0;
    always #5 aclk = ~aclk;

    reg         awvalid;
    wire        awready;
    reg  [31:0] awaddr;
    reg  [2:0]  awprot;

    reg         wvalid;
    wire        wready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;

    wire        bvalid;
    reg         bready;
    wire [1:0]  bresp;

    reg         arvalid;
    wire        arready;
    reg  [31:0] araddr;
    reg  [2:0]  arprot;

    wire        rvalid;
    reg         rready;
    wire [31:0] rdata;
    wire [1:0]  rresp;

    axi_lite_slave u_dut (
        .aclk   (aclk),
        .aresetn(aresetn),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awprot(awprot),
        .wvalid (wvalid),  .wready (wready),  .wdata (wdata),  .wstrb (wstrb),
        .bvalid (bvalid),  .bready (bready),  .bresp (bresp),
        .arvalid(arvalid), .arready(arready), .araddr(araddr), .arprot(arprot),
        .rvalid (rvalid),  .rready (rready),  .rdata (rdata),  .rresp (rresp)
    );

    wire chk_violated;
    axi_protocol_checker u_chk (
        .aclk   (aclk),
        .aresetn(aresetn),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr),
        .wvalid (wvalid),  .wready (wready),  .wdata (wdata),  .wstrb (wstrb),
        .bvalid (bvalid),  .bready (bready),  .bresp (bresp),
        .arvalid(arvalid), .arready(arready), .araddr(araddr),
        .rvalid (rvalid),  .rready (rready),  .rdata (rdata),  .rresp (rresp),
        .violated(chk_violated)
    );

    // reference model
    reg [31:0] ref_regs [0:15];

    task ref_write(input [31:0] addr, input [31:0] data, input [3:0] strb);
        integer idx;
        idx = addr[5:2];
        if (strb[0]) ref_regs[idx][ 7: 0] = data[ 7: 0];
        if (strb[1]) ref_regs[idx][15: 8] = data[15: 8];
        if (strb[2]) ref_regs[idx][23:16] = data[23:16];
        if (strb[3]) ref_regs[idx][31:24] = data[31:24];
    endtask

    function [31:0] ref_read(input [31:0] addr);
        ref_read = ref_regs[addr[5:2]];
    endfunction

    integer fail_count;
    reg [2047:0] fail_msg;

    task record_fail(input [1023:0] msg);
        if (fail_count == 0) fail_msg = msg;
        fail_count = fail_count + 1;
        $display("[FAIL @ %0t ns] %0s", $time, msg);
    endtask

    task do_reset;
        aresetn = 1'b0;
        awvalid = 0; awaddr = 0; awprot = 0;
        wvalid  = 0; wdata  = 0; wstrb  = 0;
        bready  = 0;
        arvalid = 0; araddr = 0; arprot = 0;
        rready  = 0;
        repeat (5) @(posedge aclk);
        #1 aresetn = 1'b1;
        @(posedge aclk);
    endtask

    task aw_send(input [31:0] addr);
        @(posedge aclk); #1;
        awvalid = 1'b1; awaddr = addr; awprot = 3'b0;
        while (!awready) @(posedge aclk);
        @(posedge aclk); #1;
        awvalid = 1'b0; awaddr = 32'h0;
    endtask

    task w_send(input [31:0] data, input [3:0] strb);
        @(posedge aclk); #1;
        wvalid = 1'b1; wdata = data; wstrb = strb;
        while (!wready) @(posedge aclk);
        @(posedge aclk); #1;
        wvalid = 1'b0; wdata = 32'h0; wstrb = 4'h0;
    endtask

    task b_wait(output [1:0] resp);
        while (!bvalid) @(posedge aclk);
        while (!(bvalid && bready)) @(posedge aclk);
        resp = bresp;
        @(posedge aclk);
    endtask

    task ar_send(input [31:0] addr);
        @(posedge aclk); #1;
        arvalid = 1'b1; araddr = addr; arprot = 3'b0;
        while (!arready) @(posedge aclk);
        @(posedge aclk); #1;
        arvalid = 1'b0; araddr = 32'h0;
    endtask

    task r_wait(output [31:0] data, output [1:0] resp);
        while (!rvalid) @(posedge aclk);
        while (!(rvalid && rready)) @(posedge aclk);
        data = rdata;
        resp = rresp;
        @(posedge aclk);
    endtask

    task axi_write(input [31:0] addr, input [31:0] data, input [3:0] strb);
        reg [1:0] resp;
        fork
            aw_send(addr);
            w_send(data, strb);
        join
        b_wait(resp);
        ref_write(addr, data, strb);
        if (resp !== 2'b00)
            record_fail("bresp != OKAY");
    endtask

    task axi_read_check(input [31:0] addr);
        reg [31:0] got;
        reg [1:0]  resp;
        reg [31:0] expect_data;
        ar_send(addr);
        r_wait(got, resp);
        expect_data = ref_read(addr);
        if (resp !== 2'b00) begin
            record_fail("rresp != OKAY");
        end else if (got !== expect_data) begin
            $display("[FAIL] addr=0x%08h expect=0x%08h got=0x%08h",
                     addr, expect_data, got);
            fail_count = fail_count + 1;
            if (fail_msg == 0) fail_msg = "read mismatch";
        end
    endtask

    integer bready_mode, rready_mode;
    integer bready_delay, rready_delay;
    integer bready_seed,  rready_seed;

    initial begin
        bready_mode = 0; rready_mode = 0;
        bready_delay = 0; rready_delay = 0;
        bready_seed = 32'h5a5a_5a5a; rready_seed = 32'ha5a5_a5a5;
    end

    integer b_cnt;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            bready <= 1'b0;
            b_cnt  <= 0;
        end else begin
            case (bready_mode)
                0: bready <= 1'b1;
                1: bready <= 1'b0;
                2: begin
                    if (bvalid) begin
                        if (b_cnt >= bready_delay) bready <= 1'b1;
                        else b_cnt <= b_cnt + 1;
                    end else begin
                        bready <= 1'b0;
                        b_cnt  <= 0;
                    end
                    if (bvalid && bready) begin
                        bready <= 1'b0;
                        b_cnt  <= 0;
                    end
                end
                3: begin
                    bready_seed <= {bready_seed[30:0], bready_seed[30]^bready_seed[27]};
                    bready <= bready_seed[0];
                end
                default: bready <= 1'b1;
            endcase
        end
    end

    integer r_cnt;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rready <= 1'b0;
            r_cnt  <= 0;
        end else begin
            case (rready_mode)
                0: rready <= 1'b1;
                1: rready <= 1'b0;
                2: begin
                    if (rvalid) begin
                        if (r_cnt >= rready_delay) rready <= 1'b1;
                        else r_cnt <= r_cnt + 1;
                    end else begin
                        rready <= 1'b0;
                        r_cnt  <= 0;
                    end
                    if (rvalid && rready) begin
                        rready <= 1'b0;
                        r_cnt  <= 0;
                    end
                end
                3: begin
                    rready_seed <= {rready_seed[30:0], rready_seed[30]^rready_seed[27]};
                    rready <= rready_seed[0];
                end
                default: rready <= 1'b1;
            endcase
        end
    end

    initial begin
        #100_000;
        $display("[FAIL] global timeout");
        $display("TEST_RESULT: FAIL global_timeout");
        $finish;
    end

    // test cases

    task test_01;
        do_reset();
        repeat (5) @(posedge aclk);
        if (bvalid) record_fail("bvalid high without any AW/W");
        if (rvalid) record_fail("rvalid high without any AR");
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_02;
        do_reset();
        axi_write(32'h0000_0000, 32'hDEAD_BEEF, 4'hF);
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_03;
        do_reset();
        axi_write(32'h0000_0004, 32'h1234_5678, 4'hF);
        axi_read_check(32'h0000_0004);
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_04;
        reg [1:0] resp;
        do_reset();
        fork
            aw_send(32'h0000_0008);
            begin repeat (3) @(posedge aclk); w_send(32'hAAAA_5555, 4'hF); end
        join
        b_wait(resp);
        ref_write(32'h0000_0008, 32'hAAAA_5555, 4'hF);
        axi_read_check(32'h0000_0008);
        if (chk_violated) record_fail("protocol violated");
    endtask

    task test_05;
        reg [1:0] resp;
        do_reset();
        fork
            begin repeat (3) @(posedge aclk); aw_send(32'h0000_000C); end
            w_send(32'h5555_AAAA, 4'hF);
        join
        b_wait(resp);
        ref_write(32'h0000_000C, 32'h5555_AAAA, 4'hF);
        axi_read_check(32'h0000_000C);
        if (chk_violated) record_fail("protocol violated");
    endtask

    integer tc_id;
    initial begin
        integer i;
        fail_count = 0;
        fail_msg = "";
        for (i = 0; i < 16; i = i + 1) ref_regs[i] = 32'h0;

        if (!$value$plusargs("TC=%d", tc_id)) tc_id = 0;

        if ($test$plusargs("DUMP")) begin
            $dumpfile("build/wave.vcd");
            $dumpvars(0, tb_top);
        end

        awvalid = 0; awaddr = 0; awprot = 0;
        wvalid  = 0; wdata  = 0; wstrb  = 0;
        bready  = 0;
        arvalid = 0; araddr = 0; arprot = 0;
        rready  = 0;

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
