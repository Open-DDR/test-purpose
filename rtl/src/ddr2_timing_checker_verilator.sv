// DDR2 Timing Checker Module - Verilator Compatible Version
// Monitors DDR2 timing parameters and reports violations

`timescale 1ns/1ps

module ddr2_timing_checker_verilator (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ddr_clk,
    input  logic        ddr_cke,
    input  logic        ddr_cs_n,
    input  logic        ddr_ras_n,
    input  logic        ddr_cas_n,
    input  logic        ddr_we_n,
    input  logic [2:0]  ddr_ba,
    input  logic [12:0] ddr_addr,
    output logic        violation_detected
);

    // DDR2 Timing Parameters
    parameter real tRC = 60.0;   // RAS cycle time
    parameter real tRAS = 45.0;  // RAS active time  
    parameter real tRP = 15.0;   // RAS precharge time
    parameter real tRCD = 15.0;  // RAS to CAS delay
    parameter real tRRD = 10.0;  // RAS to RAS delay
    parameter real tFAW = 50.0;  // Four activate window
    parameter real tWR = 15.0;   // Write recovery time
    parameter real tRTP = 7.5;   // Read to precharge
    parameter real tWTR = 7.5;   // Write to read delay

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
    
    assign is_activate = (!ddr_ras_n && ddr_cas_n && ddr_we_n && !ddr_cs_n);
    assign is_precharge = (!ddr_ras_n && ddr_cas_n && !ddr_we_n && !ddr_cs_n);
    assign is_read = (ddr_ras_n && !ddr_cas_n && ddr_we_n && !ddr_cs_n);
    assign is_write = (ddr_ras_n && !ddr_cas_n && !ddr_we_n && !ddr_cs_n);
    assign is_refresh = (!ddr_ras_n && !ddr_cas_n && ddr_we_n && !ddr_cs_n);
    assign current_bank = ddr_ba;

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
                if (ddr_addr[10]) begin // Precharge all
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
        if (is_precharge && !ddr_addr[10]) begin
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
        if (is_precharge && !ddr_addr[10]) begin
            twr_violation = ($realtime - last_write_time) < tWR;
        end
        
        // tRTP: Read to precharge
        trtp_violation = 1'b0;
        if (is_precharge && !ddr_addr[10]) begin
            trtp_violation = ($realtime - last_read_time) < tRTP;
        end
        
        // tWTR: Write to read delay
        twtr_violation = 1'b0;
        if (is_read) begin
            twtr_violation = ($realtime - last_write_time) < tWTR;
        end
    end

    assign violation_detected = trc_violation | tras_violation | trp_violation | 
                               trcd_violation | trrd_violation | tfaw_violation |
                               twr_violation | trtp_violation | twtr_violation;

    // Violation reporting
    always @(posedge clk) begin
        if (rst_n && violation_detected) begin
            if (trc_violation) 
                $display("tRC violation detected at time %0t, bank %0d", $realtime, current_bank);
            if (tras_violation) 
                $display("tRAS violation detected at time %0t, bank %0d", $realtime, current_bank);
            if (trp_violation) 
                $display("tRP violation detected at time %0t, bank %0d", $realtime, current_bank);
            if (trcd_violation) 
                $display("tRCD violation detected at time %0t, bank %0d", $realtime, current_bank);
            if (trrd_violation) 
                $display("tRRD violation detected at time %0t", $realtime);
            if (tfaw_violation) 
                $display("tFAW violation detected at time %0t", $realtime);
            if (twr_violation) 
                $display("tWR violation detected at time %0t, bank %0d", $realtime, current_bank);
            if (trtp_violation) 
                $display("tRTP violation detected at time %0t, bank %0d", $realtime, current_bank);
            if (twtr_violation) 
                $display("tWTR violation detected at time %0t", $realtime);
        end
    end

endmodule : ddr2_timing_checker_verilator