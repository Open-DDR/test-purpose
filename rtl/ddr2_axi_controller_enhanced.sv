// DDR2 AXI Memory Controller
// Connects AXI4 interface to DDR2 memory interface

`timescale 1ns/1ps

import ddr2_pkg::*;
import openddr_pkg::*;

module ddr2_axi_controller #(
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64,
    parameter int AXI_ID_WIDTH = 4,
    parameter int DDR_ADDR_WIDTH = 13,
    parameter int DDR_DATA_WIDTH = 64,
    parameter int DDR_BANK_WIDTH = 3
)(
    // Clock and Reset
    input  logic                        axi_aclk,
    input  logic                        axi_aresetn,
    input  logic                        ddr_clk,
    input  logic                        ddr_rst_n,

    // AXI4 Slave Interface
    // Write Address Channel
    input  logic [AXI_ID_WIDTH-1:0]    s_axi_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  logic [7:0]                 s_axi_awlen,
    input  logic [2:0]                 s_axi_awsize,
    input  logic [1:0]                 s_axi_awburst,
    input  logic                       s_axi_awlock,
    input  logic [3:0]                 s_axi_awcache,
    input  logic [2:0]                 s_axi_awprot,
    input  logic                       s_axi_awvalid,
    output logic                       s_axi_awready,

    // Write Data Channel
    input  logic [AXI_DATA_WIDTH-1:0]  s_axi_wdata,
    input  logic [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  logic                       s_axi_wlast,
    input  logic                       s_axi_wvalid,
    output logic                       s_axi_wready,

    // Write Response Channel
    output logic [AXI_ID_WIDTH-1:0]    s_axi_bid,
    output logic [1:0]                 s_axi_bresp,
    output logic                       s_axi_bvalid,
    input  logic                       s_axi_bready,

    // Read Address Channel
    input  logic [AXI_ID_WIDTH-1:0]    s_axi_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]  s_axi_araddr,
    input  logic [7:0]                 s_axi_arlen,
    input  logic [2:0]                 s_axi_arsize,
    input  logic [1:0]                 s_axi_arburst,
    input  logic                       s_axi_arlock,
    input  logic [3:0]                 s_axi_arcache,
    input  logic [2:0]                 s_axi_arprot,
    input  logic                       s_axi_arvalid,
    output logic                       s_axi_arready,

    // Read Data Channel
    output logic [AXI_ID_WIDTH-1:0]    s_axi_rid,
    output logic [AXI_DATA_WIDTH-1:0]  s_axi_rdata,
    output logic [1:0]                 s_axi_rresp,
    output logic                       s_axi_rlast,
    output logic                       s_axi_rvalid,
    input  logic                       s_axi_rready,

    // DDR2 Memory Interface
    output logic                       ddr2_clk,
    output logic                       ddr2_clk_n,
    output logic                       ddr2_cke,
    output logic                       ddr2_cs_n,
    output logic                       ddr2_ras_n,
    output logic                       ddr2_cas_n,
    output logic                       ddr2_we_n,
    output logic [DDR_BANK_WIDTH-1:0]  ddr2_ba,
    output logic [DDR_ADDR_WIDTH-1:0]  ddr2_addr,
    output logic [DDR_DATA_WIDTH/8-1:0] ddr2_dm,
    inout  wire  [DDR_DATA_WIDTH-1:0]  ddr2_dq,
    inout  wire  [DDR_DATA_WIDTH/8-1:0] ddr2_dqs,
    inout  wire  [DDR_DATA_WIDTH/8-1:0] ddr2_dqs_n,
    output logic                       ddr2_odt
);

    // Internal Signals
    ddr2_interface_t ddr_if;
    ddr2_state_t current_state, next_state;
    timing_violations_t violations;
    
    // Timing tracking for violation detection
    real last_activate_time;
    real last_precharge_time;
    real last_read_time;
    real last_write_time;
    real last_refresh_time;
    
    // Command and address tracking
    logic [3:0] activate_count_window;
    real activate_timestamps[4];
    
    // Performance monitoring
    performance_counters_t perf_counters;
    
    // Violation injection configuration
    violation_config_t violation_cfg;

`ifdef TIMING_VIOLATION_TEST
    // Override timing parameters for violation testing
    parameter real tRC_VIOLATION   = tRC * `VIOLATION_FACTOR;
    parameter real tRAS_VIOLATION  = tRAS * `VIOLATION_FACTOR;
    parameter real tRP_VIOLATION   = tRP * `VIOLATION_FACTOR;
    parameter real tRCD_VIOLATION  = tRCD * `VIOLATION_FACTOR;
    parameter real tFAW_VIOLATION  = tFAW * `VIOLATION_FACTOR;
`endif

    // Clock generation for DDR2
    assign ddr2_clk = ddr_clk;
    assign ddr2_clk_n = ~ddr_clk;

    // State machine for DDR2 control
    always_ff @(posedge ddr_clk or negedge ddr_rst_n) begin
        if (!ddr_rst_n) begin
            current_state <= IDLE;
            last_activate_time <= 0.0;
            last_precharge_time <= 0.0;
            last_read_time <= 0.0;
            last_write_time <= 0.0;
            last_refresh_time <= 0.0;
            activate_count_window <= 0;
            perf_counters <= '0;
        end else begin
            current_state <= next_state;
            
            // Update timing tracking
            case (current_state)
                ACTIVE: begin
                    last_activate_time <= $realtime;
                    activate_timestamps[activate_count_window % 4] <= $realtime;
                    activate_count_window <= activate_count_window + 1;
                end
                PRECHARGE: last_precharge_time <= $realtime;
                READ: begin
                    last_read_time <= $realtime;
                    perf_counters.read_count <= perf_counters.read_count + 1;
                end
                WRITE: begin
                    last_write_time <= $realtime;
                    perf_counters.write_count <= perf_counters.write_count + 1;
                end
                REFRESH: begin
                    last_refresh_time <= $realtime;
                    perf_counters.refresh_count <= perf_counters.refresh_count + 1;
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        violations = check_timing_violations($realtime, last_activate_time, 
                                           last_precharge_time, last_read_time, last_write_time);
        
        case (current_state)
            IDLE: begin
                if (s_axi_arvalid || s_axi_awvalid) begin
                    next_state = ACTIVE;
                end
            end
            
            ACTIVE: begin
                if (s_axi_arvalid && s_axi_arready) begin
                    next_state = READ;
                end else if (s_axi_awvalid && s_axi_awready) begin
                    next_state = WRITE;
                end
            end
            
            READ: begin
                if (s_axi_rlast && s_axi_rvalid && s_axi_rready) begin
                    next_state = PRECHARGE;
                end
            end
            
            WRITE: begin
                if (s_axi_wlast && s_axi_wvalid && s_axi_wready) begin
                    next_state = PRECHARGE;
                end
            end
            
            PRECHARGE: begin
                next_state = IDLE;
            end
            
            REFRESH: begin
                next_state = IDLE;
            end
        endcase
        
        // Check for timing violations and assert errors
        if (violations != '0) begin
            perf_counters.timing_violation_count <= perf_counters.timing_violation_count + 1;
            
            // Assert specific timing violation errors
            if (violations.tfaw_violation) begin
                $error("tFAW timing violation detected at time %0t", $realtime);
            end
            if (violations.trcd_violation) begin
                $error("tRCD timing violation detected at time %0t", $realtime);
            end
            if (violations.trp_violation) begin
                $error("tRP timing violation detected at time %0t", $realtime);
            end
        end
    end

    // DDR2 command generation
    always_ff @(posedge ddr_clk) begin
        if (!ddr_rst_n) begin
            ddr2_cs_n  <= 1'b1;
            ddr2_ras_n <= 1'b1;
            ddr2_cas_n <= 1'b1;
            ddr2_we_n  <= 1'b1;
            ddr2_cke   <= 1'b0;
            ddr2_ba    <= '0;
            ddr2_addr  <= '0;
            ddr2_odt   <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    ddr2_cs_n  <= 1'b1;
                    ddr2_ras_n <= 1'b1;
                    ddr2_cas_n <= 1'b1;
                    ddr2_we_n  <= 1'b1;
                    ddr2_cke   <= 1'b1;
                end
                
                ACTIVE: begin
                    ddr2_cs_n  <= 1'b0;
                    ddr2_ras_n <= 1'b0;
                    ddr2_cas_n <= 1'b1;
                    ddr2_we_n  <= 1'b1;
                    // Extract bank and row address from AXI address
                    ddr2_ba    <= s_axi_awvalid ? s_axi_awaddr[DDR_BANK_WIDTH+DDR_ADDR_WIDTH-1:DDR_ADDR_WIDTH] :
                                                 s_axi_araddr[DDR_BANK_WIDTH+DDR_ADDR_WIDTH-1:DDR_ADDR_WIDTH];
                    ddr2_addr  <= s_axi_awvalid ? s_axi_awaddr[DDR_ADDR_WIDTH-1:0] :
                                                 s_axi_araddr[DDR_ADDR_WIDTH-1:0];
                end
                
                READ: begin
                    ddr2_cs_n  <= 1'b0;
                    ddr2_ras_n <= 1'b1;
                    ddr2_cas_n <= 1'b0;
                    ddr2_we_n  <= 1'b1;
                    ddr2_odt   <= 1'b0;
                end
                
                WRITE: begin
                    ddr2_cs_n  <= 1'b0;
                    ddr2_ras_n <= 1'b1;
                    ddr2_cas_n <= 1'b0;
                    ddr2_we_n  <= 1'b0;
                    ddr2_odt   <= 1'b1;
                end
                
                PRECHARGE: begin
                    ddr2_cs_n  <= 1'b0;
                    ddr2_ras_n <= 1'b0;
                    ddr2_cas_n <= 1'b1;
                    ddr2_we_n  <= 1'b0;
                    ddr2_addr[10] <= 1'b1; // Precharge all banks
                end
                
                REFRESH: begin
                    ddr2_cs_n  <= 1'b0;
                    ddr2_ras_n <= 1'b0;
                    ddr2_cas_n <= 1'b0;
                    ddr2_we_n  <= 1'b1;
                end
            endcase
        end
    end

    // AXI Response generation (simplified)
    assign s_axi_awready = (current_state == IDLE) && !s_axi_arvalid;
    assign s_axi_wready = (current_state == WRITE);
    assign s_axi_bvalid = (current_state == PRECHARGE) && (last_write_time > last_read_time);
    assign s_axi_bresp = 2'b00; // OKAY response
    assign s_axi_bid = s_axi_awid;

    assign s_axi_arready = (current_state == IDLE) && !s_axi_awvalid;
    assign s_axi_rvalid = (current_state == READ);
    assign s_axi_rresp = 2'b00; // OKAY response
    assign s_axi_rid = s_axi_arid;
    assign s_axi_rlast = s_axi_rvalid; // Simplified - single beat
    assign s_axi_rdata = 64'h0; // Placeholder data

    // Violation injection interface
`ifdef TIMING_VIOLATION_TEST
    initial begin
        violation_cfg.enable = 1'b1;
        violation_cfg.test_type = TEST_VIOLATION;
        violation_cfg.severity = `VIOLATION_SEVERITY;
        violation_cfg.violation_type = `VIOLATION_TYPE;
        violation_cfg.violation_factor = `VIOLATION_FACTOR;
        
        $display("Timing violation injection enabled:");
        $display("  Type: %s", get_violation_name(violation_cfg.violation_type));
        $display("  Severity: %0d", violation_cfg.severity);
        $display("  Factor: %0.2f", violation_cfg.violation_factor);
    end
`endif

    // Assertions for timing violations
    property tFAW_check;
        @(posedge ddr_clk) disable iff (!ddr_rst_n)
        (current_state == ACTIVE) |-> 
        ($realtime - activate_timestamps[(activate_count_window-4) % 4] >= tFAW);
    endproperty
    
    property tRCD_check;
        @(posedge ddr_clk) disable iff (!ddr_rst_n)
        (current_state == READ || current_state == WRITE) |->
        ($realtime - last_activate_time >= tRCD);
    endproperty
    
    property tRP_check;
        @(posedge ddr_clk) disable iff (!ddr_rst_n)
        (current_state == ACTIVE) |->
        ($realtime - last_precharge_time >= tRP);
    endproperty

    // Only enable assertions when not in violation test mode
`ifndef TIMING_VIOLATION_TEST
    assert_tFAW: assert property (tFAW_check)
        else $error("tFAW violation: Four activates within %0.1f ns", tFAW);
        
    assert_tRCD: assert property (tRCD_check)
        else $error("tRCD violation: RAS to CAS delay %0.1f ns not met", tRCD);
        
    assert_tRP: assert property (tRP_check)
        else $error("tRP violation: RAS precharge time %0.1f ns not met", tRP);
`endif

endmodule : ddr2_axi_controller