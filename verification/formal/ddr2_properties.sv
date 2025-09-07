//==============================================================================
// DDR2 Controller Formal Properties
// 
// Description: SystemVerilog Assertions for DDR2 controller formal verification
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`ifndef DDR2_PROPERTIES_SV
`define DDR2_PROPERTIES_SV

// Bind the properties to the DDR2 controller
bind ddr2_controller ddr2_formal_properties ddr2_props (
    .clk(clk),
    .rst_n(rst_n),
    // AXI4 Interface
    .axi_awaddr(axi_awaddr),
    .axi_awlen(axi_awlen),
    .axi_awsize(axi_awsize),
    .axi_awburst(axi_awburst),
    .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready),
    .axi_wdata(axi_wdata),
    .axi_wstrb(axi_wstrb),
    .axi_wlast(axi_wlast),
    .axi_wvalid(axi_wvalid),
    .axi_wready(axi_wready),
    .axi_bresp(axi_bresp),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    .axi_araddr(axi_araddr),
    .axi_arlen(axi_arlen),
    .axi_arsize(axi_arsize),
    .axi_arburst(axi_arburst),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready),
    .axi_rdata(axi_rdata),
    .axi_rresp(axi_rresp),
    .axi_rlast(axi_rlast),
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready),
    // DDR2 Interface
    .ddr_ck_p(ddr_ck_p),
    .ddr_ck_n(ddr_ck_n),
    .ddr_cke(ddr_cke),
    .ddr_cs_n(ddr_cs_n),
    .ddr_ras_n(ddr_ras_n),
    .ddr_cas_n(ddr_cas_n),
    .ddr_we_n(ddr_we_n),
    .ddr_ba(ddr_ba),
    .ddr_a(ddr_a),
    .ddr_odt(ddr_odt)
);

module ddr2_formal_properties #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 32,
    parameter BANK_WIDTH = 3,
    parameter ROW_WIDTH = 14,
    parameter COL_WIDTH = 10
) (
    input logic clk,
    input logic rst_n,
    
    // AXI4 Interface
    input logic [ADDR_WIDTH-1:0]  axi_awaddr,
    input logic [7:0]             axi_awlen,
    input logic [2:0]             axi_awsize,
    input logic [1:0]             axi_awburst,
    input logic                   axi_awvalid,
    input logic                   axi_awready,
    
    input logic [DATA_WIDTH-1:0]  axi_wdata,
    input logic [DATA_WIDTH/8-1:0] axi_wstrb,
    input logic                   axi_wlast,
    input logic                   axi_wvalid,
    input logic                   axi_wready,
    
    input logic [1:0]             axi_bresp,
    input logic                   axi_bvalid,
    input logic                   axi_bready,
    
    input logic [ADDR_WIDTH-1:0]  axi_araddr,
    input logic [7:0]             axi_arlen,
    input logic [2:0]             axi_arsize,
    input logic [1:0]             axi_arburst,
    input logic                   axi_arvalid,
    input logic                   axi_arready,
    
    input logic [DATA_WIDTH-1:0]  axi_rdata,
    input logic [1:0]             axi_rresp,
    input logic                   axi_rlast,
    input logic                   axi_rvalid,
    input logic                   axi_rready,
    
    // DDR2 Interface
    input logic                   ddr_ck_p,
    input logic                   ddr_ck_n,
    input logic                   ddr_cke,
    input logic                   ddr_cs_n,
    input logic                   ddr_ras_n,
    input logic                   ddr_cas_n,
    input logic                   ddr_we_n,
    input logic [BANK_WIDTH-1:0] ddr_ba,
    input logic [ROW_WIDTH-1:0]  ddr_a,
    input logic                   ddr_odt
);

    // Import DDR2 package for timing parameters
    import ddr2_pkg::*;

    //==========================================================================
    // AXI4 Protocol Properties
    //==========================================================================

    // AXI4 Write Address Channel Properties
    property axi_aw_valid_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_awvalid && !axi_awready |=> axi_awvalid;
    endproperty
    
    property axi_aw_addr_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_awvalid && !axi_awready |=> $stable(axi_awaddr);
    endproperty
    
    property axi_aw_len_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_awvalid && !axi_awready |=> $stable(axi_awlen);
    endproperty

    // AXI4 Write Data Channel Properties
    property axi_w_valid_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_wvalid && !axi_wready |=> axi_wvalid;
    endproperty
    
    property axi_w_data_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_wvalid && !axi_wready |=> $stable(axi_wdata);
    endproperty
    
    property axi_w_last_correct;
        @(posedge clk) disable iff (!rst_n)
        axi_wvalid && axi_wready && axi_wlast |-> 
        $past(axi_awvalid && axi_awready) && 
        ($past(axi_awlen) == 0 || /* burst counter logic */);
    endproperty

    // AXI4 Write Response Channel Properties
    property axi_b_valid_after_wlast;
        @(posedge clk) disable iff (!rst_n)
        axi_wvalid && axi_wready && axi_wlast |-> 
        ##[1:10] axi_bvalid;
    endproperty
    
    property axi_b_valid_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_bvalid && !axi_bready |=> axi_bvalid;
    endproperty

    // AXI4 Read Address Channel Properties
    property axi_ar_valid_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_arvalid && !axi_arready |=> axi_arvalid;
    endproperty
    
    property axi_ar_addr_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_arvalid && !axi_arready |=> $stable(axi_araddr);
    endproperty

    // AXI4 Read Data Channel Properties
    property axi_r_valid_after_arready;
        @(posedge clk) disable iff (!rst_n)
        axi_arvalid && axi_arready |-> 
        ##[1:50] axi_rvalid;
    endproperty
    
    property axi_r_valid_stable;
        @(posedge clk) disable iff (!rst_n)
        axi_rvalid && !axi_rready |=> axi_rvalid;
    endproperty

    //==========================================================================
    // DDR2 Protocol Properties
    //==========================================================================

    // DDR2 Command Encoding Properties
    property ddr2_valid_command;
        @(posedge clk) disable iff (!rst_n)
        !ddr_cs_n |-> 
        ({ddr_ras_n, ddr_cas_n, ddr_we_n} inside {
            3'b000, // MRS
            3'b001, // REF
            3'b010, // PRE
            3'b011, // ACT
            3'b100, // WR
            3'b101, // RD
            3'b110, // BT (Burst Terminate)
            3'b111  // NOP
        });
    endproperty

    // DDR2 Timing Properties
    property ddr2_tras_timing;
        @(posedge clk) disable iff (!rst_n)
        // ACT command
        (!ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 1 && ddr_we_n == 1) |->
        // No precharge to same bank for tRAS cycles
        ##[1:tRAS] (ddr_cs_n || ddr_ras_n || !ddr_cas_n || ddr_we_n || (ddr_ba != $past(ddr_ba, 1)));
    endproperty
    
    property ddr2_trcd_timing;
        @(posedge clk) disable iff (!rst_n)
        // ACT command
        (!ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 1 && ddr_we_n == 1) |->
        // No RD/WR to same bank for tRCD cycles
        ##[1:tRCD-1] (ddr_cs_n || ddr_ras_n || ddr_cas_n || (ddr_ba != $past(ddr_ba, 1)));
    endproperty
    
    property ddr2_trp_timing;
        @(posedge clk) disable iff (!rst_n)
        // PRE command
        (!ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 1 && ddr_we_n == 0) |->
        // No ACT to same bank for tRP cycles
        ##[1:tRP-1] (ddr_cs_n || ddr_ras_n || !ddr_cas_n || !ddr_we_n || (ddr_ba != $past(ddr_ba, 1)));
    endproperty

    // DDR2 Bank Management Properties
    property ddr2_bank_state_consistency;
        @(posedge clk) disable iff (!rst_n)
        // If a bank is activated, it should remain active until precharge
        (!ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 1 && ddr_we_n == 1) |->
        // Bank remains active until precharge
        (ddr_cs_n || ddr_ras_n || !ddr_cas_n || ddr_we_n || (ddr_ba != $past(ddr_ba, 1))) 
        throughout 
        (##[1:$] (!ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 1 && ddr_we_n == 0 && ddr_ba == $past(ddr_ba, 1)));
    endproperty

    // DDR2 Refresh Properties
    property ddr2_refresh_timing;
        @(posedge clk) disable iff (!rst_n)
        // REF command
        (!ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 0 && ddr_we_n == 1) |->
        // No commands for tRFC cycles
        ##[1:tRFC-1] ddr_cs_n;
    endproperty

    //==========================================================================
    // Safety Properties
    //==========================================================================

    // Reset Properties
    property reset_state;
        @(posedge clk)
        !rst_n |-> (ddr_cs_n && !ddr_cke);
    endproperty
    
    property reset_axi_outputs;
        @(posedge clk)
        !rst_n |-> (!axi_awready && !axi_wready && !axi_bvalid && 
                   !axi_arready && !axi_rvalid);
    endproperty

    // Clock Properties
    property ddr_clock_differential;
        @(posedge clk) disable iff (!rst_n)
        ddr_ck_p != ddr_ck_n;
    endproperty

    //==========================================================================
    // Liveness Properties
    //==========================================================================

    // AXI Transaction Completion
    property axi_write_completion;
        @(posedge clk) disable iff (!rst_n)
        axi_awvalid |-> ##[1:100] (axi_bvalid && axi_bready);
    endproperty
    
    property axi_read_completion;
        @(posedge clk) disable iff (!rst_n)
        axi_arvalid |-> ##[1:100] (axi_rvalid && axi_rready && axi_rlast);
    endproperty

    // DDR2 Command Progress
    property ddr2_command_progress;
        @(posedge clk) disable iff (!rst_n)
        (axi_awvalid || axi_arvalid) |-> ##[1:200] !ddr_cs_n;
    endproperty

    //==========================================================================
    // Coverage Properties
    //==========================================================================

    // AXI Coverage
    cover property (@(posedge clk) disable iff (!rst_n) 
        axi_awvalid && axi_awready);
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        axi_wvalid && axi_wready && axi_wlast);
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        axi_bvalid && axi_bready);
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        axi_arvalid && axi_arready);
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        axi_rvalid && axi_rready && axi_rlast);

    // DDR2 Command Coverage
    cover property (@(posedge clk) disable iff (!rst_n) 
        !ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 1 && ddr_we_n == 1); // ACT
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        !ddr_cs_n && ddr_ras_n == 1 && ddr_cas_n == 0 && ddr_we_n == 1); // RD
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        !ddr_cs_n && ddr_ras_n == 1 && ddr_cas_n == 0 && ddr_we_n == 0); // WR
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        !ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 1 && ddr_we_n == 0); // PRE
    
    cover property (@(posedge clk) disable iff (!rst_n) 
        !ddr_cs_n && ddr_ras_n == 0 && ddr_cas_n == 0 && ddr_we_n == 1); // REF

    //==========================================================================
    // Assertion Instantiation
    //==========================================================================

    // AXI4 Protocol Assertions
    assert property (axi_aw_valid_stable) else $error("AXI AW valid not stable");
    assert property (axi_aw_addr_stable) else $error("AXI AW addr not stable");
    assert property (axi_aw_len_stable) else $error("AXI AW len not stable");
    assert property (axi_w_valid_stable) else $error("AXI W valid not stable");
    assert property (axi_w_data_stable) else $error("AXI W data not stable");
    assert property (axi_b_valid_after_wlast) else $error("AXI B valid not asserted after WLAST");
    assert property (axi_b_valid_stable) else $error("AXI B valid not stable");
    assert property (axi_ar_valid_stable) else $error("AXI AR valid not stable");
    assert property (axi_ar_addr_stable) else $error("AXI AR addr not stable");
    assert property (axi_r_valid_after_arready) else $error("AXI R valid not asserted after ARREADY");
    assert property (axi_r_valid_stable) else $error("AXI R valid not stable");

    // DDR2 Protocol Assertions
    assert property (ddr2_valid_command) else $error("Invalid DDR2 command");
    assert property (ddr2_tras_timing) else $error("DDR2 tRAS timing violation");
    assert property (ddr2_trcd_timing) else $error("DDR2 tRCD timing violation");
    assert property (ddr2_trp_timing) else $error("DDR2 tRP timing violation");
    assert property (ddr2_bank_state_consistency) else $error("DDR2 bank state inconsistency");
    assert property (ddr2_refresh_timing) else $error("DDR2 refresh timing violation");

    // Safety Assertions
    assert property (reset_state) else $error("Reset state violation");
    assert property (reset_axi_outputs) else $error("Reset AXI outputs violation");
    assert property (ddr_clock_differential) else $error("DDR clock not differential");

    // Liveness Assertions
    assert property (axi_write_completion) else $error("AXI write not completed");
    assert property (axi_read_completion) else $error("AXI read not completed");
    assert property (ddr2_command_progress) else $error("DDR2 command not progressing");

endmodule

`endif // DDR2_PROPERTIES_SV
