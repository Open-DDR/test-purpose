//==============================================================================
// OpenDDR DFI Data Path
// 
// Description: Handles DFI data interface for DDR read/write operations
// Author: Open DDR Project
// Date: 2025
//==============================================================================
`timescale 1ns/1ps

`include "openddr_pkg.sv"

module openddr_dfi_datapath #(
    parameter DATA_WIDTH = 64
) (
    input  logic                        clk,
    input  logic                        rst_n,
    
    // AXI Write Data
    input  logic [DATA_WIDTH-1:0]      axi_wdata,
    input  logic [DATA_WIDTH/8-1:0]    axi_wstrb,
    
    // DFI Write Data Interface
    output logic [DATA_WIDTH-1:0]      dfi_wrdata_0_p0,
    output logic [DATA_WIDTH-1:0]      dfi_wrdata_0_p1,
    output logic [DATA_WIDTH-1:0]      dfi_wrdata_1_p2,
    output logic [DATA_WIDTH-1:0]      dfi_wrdata_1_p3,
    output logic [DATA_WIDTH/8-1:0]    dfi_wrdata_mask_0_p0,
    output logic [DATA_WIDTH/8-1:0]    dfi_wrdata_mask_0_p1,
    output logic [DATA_WIDTH/8-1:0]    dfi_wrdata_mask_1_p2,
    output logic [DATA_WIDTH/8-1:0]    dfi_wrdata_mask_1_p3,
    output logic                        dfi_wrdata_en_0_p0,
    output logic                        dfi_wrdata_en_0_p1,
    output logic                        dfi_wrdata_en_1_p2,
    output logic                        dfi_wrdata_en_1_p3,
    
    // DFI Read Data Interface
    input  logic [DATA_WIDTH-1:0]      dfi_rddata_0_p0,
    input  logic [DATA_WIDTH-1:0]      dfi_rddata_0_p1,
    input  logic [DATA_WIDTH-1:0]      dfi_rddata_1_p2,
    input  logic [DATA_WIDTH-1:0]      dfi_rddata_1_p3,
    input  logic                        dfi_rddata_valid_0_p0,
    input  logic                        dfi_rddata_valid_0_p1,
    input  logic                        dfi_rddata_valid_1_p2,
    input  logic                        dfi_rddata_valid_1_p3,
    
    // AXI Read Data output
    output logic [DATA_WIDTH-1:0]      axi_rdata
);

    import openddr_pkg::*;

    // Write data pipeline stages
    logic [DATA_WIDTH-1:0]      write_data_pipeline [4];
    logic [DATA_WIDTH/8-1:0]    write_mask_pipeline [4];
    logic [3:0]                 write_enable_pipeline;
    
    // Read data selection
    logic [DATA_WIDTH-1:0]      read_data_mux;
    logic [3:0]                 read_valid;

    // Write data pipeline - distribute across 4 phases
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i++) begin
                write_data_pipeline[i] <= 0;
                write_mask_pipeline[i] <= 0;
            end
            write_enable_pipeline <= 4'b0000;
        end else begin
            // Pipeline write data across 4 phases for DDR operation
            write_data_pipeline[0] <= axi_wdata;
            write_data_pipeline[1] <= write_data_pipeline[0];
            write_data_pipeline[2] <= write_data_pipeline[1];
            write_data_pipeline[3] <= write_data_pipeline[2];
            
            // Convert write strobe to data mask (inverted)
            write_mask_pipeline[0] <= ~axi_wstrb;
            write_mask_pipeline[1] <= write_mask_pipeline[0];
            write_mask_pipeline[2] <= write_mask_pipeline[1];
            write_mask_pipeline[3] <= write_mask_pipeline[2];
            
            // Enable signals pipeline
            write_enable_pipeline <= {write_enable_pipeline[2:0], |axi_wstrb};
        end
    end

    // DFI Write Data assignments
    assign dfi_wrdata_0_p0      = write_data_pipeline[0];
    assign dfi_wrdata_0_p1      = write_data_pipeline[1];
    assign dfi_wrdata_1_p2      = write_data_pipeline[2];
    assign dfi_wrdata_1_p3      = write_data_pipeline[3];
    
    assign dfi_wrdata_mask_0_p0 = write_mask_pipeline[0];
    assign dfi_wrdata_mask_0_p1 = write_mask_pipeline[1];
    assign dfi_wrdata_mask_1_p2 = write_mask_pipeline[2];
    assign dfi_wrdata_mask_1_p3 = write_mask_pipeline[3];
    
    assign dfi_wrdata_en_0_p0   = write_enable_pipeline[0];
    assign dfi_wrdata_en_0_p1   = write_enable_pipeline[1];
    assign dfi_wrdata_en_1_p2   = write_enable_pipeline[2];
    assign dfi_wrdata_en_1_p3   = write_enable_pipeline[3];

    // Read data valid signals
    assign read_valid = {dfi_rddata_valid_1_p3, dfi_rddata_valid_1_p2, 
                        dfi_rddata_valid_0_p1, dfi_rddata_valid_0_p0};

    // Read data multiplexer - select from valid phase
    always_comb begin
        read_data_mux = 0;
        
        // Priority-based selection of read data
        if (dfi_rddata_valid_0_p0)
            read_data_mux = dfi_rddata_0_p0;
        else if (dfi_rddata_valid_0_p1)
            read_data_mux = dfi_rddata_0_p1;
        else if (dfi_rddata_valid_1_p2)
            read_data_mux = dfi_rddata_1_p2;
        else if (dfi_rddata_valid_1_p3)
            read_data_mux = dfi_rddata_1_p3;
    end

    // Register read data output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_rdata <= 0;
        end else if (|read_valid) begin
            axi_rdata <= read_data_mux;
        end
    end

endmodule
