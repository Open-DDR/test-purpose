// DDR2 Timing Checker Module
// Monitors DDR2 timing parameters and reports violations

`timescale 1ns/1ps

import ddr2_pkg::*;
import openddr_pkg::*;

module ddr2_timing_checker (
    input  logic        clk,
    input  logic        rst_n,
    input  ddr2_interface_t ddr_if,
    input  ddr2_state_t current_state,
    output timing_violations_t violations,
    output logic        violation_detected
);

    // Timing tracking variables
    real last_activate_time[8]; // Per bank
    real last_precharge_time[8]; // Per bank
    real last_read_time;
    real last_write_time;
    real last_refresh_time;
    real activate_window[4]; // For tFAW checking
    int  activate_index;
    
    // Violation detection
    logic trc_violation, tras_violation, trp_violation;
    logic trcd_violation, trrd_violation, tfaw_violation;
    logic twr_violation, trtp_violation, twtr_violation;

    // Command decode
    logic is_activate, is_precharge, is_read, is_write, is_refresh;
    logic [2:0] current_bank;
    
    assign is_activate = (!ddr_if.ras_n && ddr_if.cas_n && ddr_if.we_n && !ddr_if.cs_n);
    assign is_precharge = (!ddr_if.ras_n && ddr_if.cas_n && !ddr_if.we_n && !ddr_if.cs_n);
    assign is_read = (ddr_if.ras_n && !ddr_if.cas_n && ddr_if.we_n && !ddr_if.cs_n);
    assign is_write = (ddr_if.ras_n && !ddr_if.cas_n && !ddr_if.we_n && !ddr_if.cs_n);
    assign is_refresh = (!ddr_if.ras_n && !ddr_if.cas_n && ddr_if.we_n && !ddr_if.cs_n);
    assign current_bank = ddr_if.ba;

    // Update timing tracking
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 8; i++) begin
                last_activate_time[i] <= 0.0;
                last_precharge_time[i] <= 0.0;
            end
            last_read_time <= 0.0;
            last_write_time <= 0.0;
            last_refresh_time <= 0.0;
            activate_index <= 0;
            for (int i = 0; i < 4; i++) begin
                activate_window[i] <= 0.0;
            end
        end else begin
            if (is_activate) begin
                last_activate_time[current_bank] <= $realtime;
                activate_window[activate_index % 4] <= $realtime;
                activate_index <= activate_index + 1;
            end
            
            if (is_precharge) begin
                if (ddr_if.addr[10]) begin // Precharge all
                    for (int i = 0; i < 8; i++) begin
                        last_precharge_time[i] <= $realtime;
                    end
                end else begin
                    last_precharge_time[current_bank] <= $realtime;
                end
            end
            
            if (is_read) begin
                last_read_time <= $realtime;
            end
            
            if (is_write) begin
                last_write_time <= $realtime;
            end
            
            if (is_refresh) begin
                last_refresh_time <= $realtime;
            end
        end
    end

    // Timing violation checking
    always_comb begin
        // tRC: RAS cycle time
        trc_violation = 1'b0;
        if (is_activate) begin
            trc_violation = ($realtime - last_activate_time[current_bank]) < tRC;
        end
        
        // tRAS: RAS active time
        tras_violation = 1'b0;
        if (is_precharge && !ddr_if.addr[10]) begin
            tras_violation = ($realtime - last_activate_time[current_bank]) < tRAS;
        end
        
        // tRP: RAS precharge time
        trp_violation = 1'b0;
        if (is_activate) begin
            trp_violation = ($realtime - last_precharge_time[current_bank]) < tRP;
        end
        
        // tRCD: RAS to CAS delay
        trcd_violation = 1'b0;
        if (is_read || is_write) begin
            trcd_violation = ($realtime - last_activate_time[current_bank]) < tRCD;
        end
        
        // tRRD: RAS to RAS delay (different banks)
        trrd_violation = 1'b0;
        if (is_activate) begin
            for (int i = 0; i < 8; i++) begin
                if (i != current_bank) begin
                    if (($realtime - last_activate_time[i]) < tRRD && last_activate_time[i] > 0) begin
                        trrd_violation = 1'b1;
                    end
                end
            end
        end
        
        // tFAW: Four activate window
        tfaw_violation = 1'b0;
        if (is_activate && activate_index >= 4) begin
            tfaw_violation = ($realtime - activate_window[(activate_index-4) % 4]) < tFAW;
        end
        
        // tWR: Write recovery time
        twr_violation = 1'b0;
        if (is_precharge && !ddr_if.addr[10]) begin
            twr_violation = ($realtime - last_write_time) < tWR;
        end
        
        // tRTP: Read to precharge
        trtp_violation = 1'b0;
        if (is_precharge && !ddr_if.addr[10]) begin
            trtp_violation = ($realtime - last_read_time) < tRTP;
        end
        
        // tWTR: Write to read delay
        twtr_violation = 1'b0;
        if (is_read) begin
            twtr_violation = ($realtime - last_write_time) < tWTR;
        end
    end

    // Pack violations into output structure
    assign violations.trc_violation = trc_violation;
    assign violations.tras_violation = tras_violation;
    assign violations.trp_violation = trp_violation;
    assign violations.trcd_violation = trcd_violation;
    assign violations.trrd_violation = trrd_violation;
    assign violations.tfaw_violation = tfaw_violation;
    assign violations.twr_violation = twr_violation;
    assign violations.trtp_violation = trtp_violation;
    assign violations.twtr_violation = twtr_violation;
    
    assign violation_detected = |violations;

    // Assertion-based checking (disabled during violation injection)
`ifndef TIMING_VIOLATION_TEST
    property p_tRC;
        @(posedge clk) disable iff (!rst_n)
        is_activate |-> ($realtime - last_activate_time[current_bank] >= tRC);
    endproperty
    
    property p_tRAS;
        @(posedge clk) disable iff (!rst_n)
        (is_precharge && !ddr_if.addr[10]) |-> 
        ($realtime - last_activate_time[current_bank] >= tRAS);
    endproperty
    
    property p_tRP;
        @(posedge clk) disable iff (!rst_n)
        is_activate |-> ($realtime - last_precharge_time[current_bank] >= tRP);
    endproperty
    
    property p_tRCD;
        @(posedge clk) disable iff (!rst_n)
        (is_read || is_write) |-> 
        ($realtime - last_activate_time[current_bank] >= tRCD);
    endproperty
    
    property p_tFAW;
        @(posedge clk) disable iff (!rst_n)
        (is_activate && activate_index >= 4) |-> 
        ($realtime - activate_window[(activate_index-4) % 4] >= tFAW);
    endproperty

    assert_tRC: assert property (p_tRC)
        else $error("tRC violation detected at time %0t, bank %0d", $realtime, current_bank);
        
    assert_tRAS: assert property (p_tRAS)
        else $error("tRAS violation detected at time %0t, bank %0d", $realtime, current_bank);
        
    assert_tRP: assert property (p_tRP)
        else $error("tRP violation detected at time %0t, bank %0d", $realtime, current_bank);
        
    assert_tRCD: assert property (p_tRCD)
        else $error("tRCD violation detected at time %0t, bank %0d", $realtime, current_bank);
        
    assert_tFAW: assert property (p_tFAW)
        else $error("tFAW violation detected at time %0t", $realtime);
`endif

    // Coverage collection
    covergroup cg_violations @(posedge clk);
        cp_trc: coverpoint trc_violation;
        cp_tras: coverpoint tras_violation;
        cp_trp: coverpoint trp_violation;
        cp_trcd: coverpoint trcd_violation;
        cp_trrd: coverpoint trrd_violation;
        cp_tfaw: coverpoint tfaw_violation;
        cp_twr: coverpoint twr_violation;
        cp_trtp: coverpoint trtp_violation;
        cp_twtr: coverpoint twtr_violation;
        
        // Cross coverage for multiple violations
        cx_violations: cross cp_trc, cp_tras, cp_trp, cp_trcd;
    endgroup
    
    cg_violations cg_inst = new();

endmodule : ddr2_timing_checker