#include "openddr_systemc_model.h"
#include <iostream>
#include <iomanip>

// AXI Write Address Channel Process
void OpenDDRSystemCModel::axi_write_addr_process() {
    if (!mc_rst_b.read()) {
        mc0_axi_awready_int.write(false);
        // Clear write address queue
        while (!write_addr_queue.empty()) {
            write_addr_queue.pop();
        }
        return;
    }

    // Handle AXI write address channel
    if (mc0_axi_awvalid.read() && !mc0_axi_awready_int.read()) {
        // Check if we can accept the transaction
        if (write_addr_queue.size() < 16) { // Limit queue depth
            AXITransaction trans;
            trans.id = mc0_axi_awid.read();
            trans.addr = mc0_axi_awaddr.read();
            trans.len = mc0_axi_awlen.read();
            trans.size = mc0_axi_awsize.read();
            trans.burst = mc0_axi_awburst.read();
            trans.is_write = true;
            trans.timestamp = sc_time_stamp();
            
            write_addr_queue.push(trans);
            mc0_axi_awready_int.write(true);
            total_write_transactions++;
            
            std::cout << "@" << sc_time_stamp() << " AXI Write Addr: ID=" 
                      << std::hex << trans.id << " Addr=0x" << trans.addr 
                      << " Len=" << std::dec << (int)trans.len << std::endl;
        }
    } else {
        mc0_axi_awready_int.write(false);
    }
}

// AXI Write Data Channel Process
void OpenDDRSystemCModel::axi_write_data_process() {
    if (!mc_rst_b.read()) {
        mc0_axi_wready_int.write(false);
        while (!write_data_queue.empty()) {
            write_data_queue.pop();
        }
        return;
    }

    // Handle AXI write data channel
    if (mc0_axi_wvalid.read() && !mc0_axi_wready_int.read()) {
        if (write_data_queue.size() < 16) {
            AXITransaction trans;
            trans.data = mc0_axi_wdata.read();
            trans.strb = mc0_axi_wstrb.read();
            trans.last = mc0_axi_wlast.read();
            trans.is_write = true;
            trans.timestamp = sc_time_stamp();
            
            write_data_queue.push(trans);
            mc0_axi_wready_int.write(true);
            
            std::cout << "@" << sc_time_stamp() << " AXI Write Data: Data=0x" 
                      << std::hex << trans.data << " Strb=0x" << (int)trans.strb 
                      << " Last=" << trans.last << std::endl;
        }
    } else {
        mc0_axi_wready_int.write(false);
    }
}

// AXI Write Response Channel Process
void OpenDDRSystemCModel::axi_write_resp_process() {
    if (!mc_rst_b.read()) {
        mc0_axi_bvalid_int.write(false);
        mc0_axi_bid.write(0);
        mc0_axi_bresp.write(0);
        while (!write_resp_queue.empty()) {
            write_resp_queue.pop();
        }
        return;
    }

    // Generate write responses
    if (!write_resp_queue.empty() && mc0_axi_bready.read()) {
        AXITransaction trans = write_resp_queue.front();
        write_resp_queue.pop();
        
        mc0_axi_bid.write(trans.id);
        mc0_axi_bresp.write(0); // OKAY response
        mc0_axi_bvalid_int.write(true);
        
        std::cout << "@" << sc_time_stamp() << " AXI Write Resp: ID=" 
                  << std::hex << trans.id << " Resp=OKAY" << std::endl;
    } else {
        mc0_axi_bvalid_int.write(false);
    }
}

// AXI Read Address Channel Process
void OpenDDRSystemCModel::axi_read_addr_process() {
    if (!mc_rst_b.read()) {
        mc0_axi_arready_int.write(false);
        while (!read_addr_queue.empty()) {
            read_addr_queue.pop();
        }
        return;
    }

    // Handle AXI read address channel
    if (mc0_axi_arvalid.read() && !mc0_axi_arready_int.read()) {
        if (read_addr_queue.size() < 16) {
            AXITransaction trans;
            trans.id = mc0_axi_arid.read();
            trans.addr = mc0_axi_araddr.read();
            trans.len = mc0_axi_arlen.read();
            trans.size = mc0_axi_arsize.read();
            trans.burst = mc0_axi_arburst.read();
            trans.is_write = false;
            trans.timestamp = sc_time_stamp();
            
            read_addr_queue.push(trans);
            mc0_axi_arready_int.write(true);
            total_read_transactions++;
            
            std::cout << "@" << sc_time_stamp() << " AXI Read Addr: ID=" 
                      << std::hex << trans.id << " Addr=0x" << trans.addr 
                      << " Len=" << std::dec << (int)trans.len << std::endl;
        }
    } else {
        mc0_axi_arready_int.write(false);
    }
}

// AXI Read Data Channel Process
void OpenDDRSystemCModel::axi_read_data_process() {
    if (!mc_rst_b.read()) {
        mc0_axi_rvalid_int.write(false);
        mc0_axi_rid.write(0);
        mc0_axi_rdata.write(0);
        mc0_axi_rresp.write(0);
        mc0_axi_rlast.write(false);
        while (!read_resp_queue.empty()) {
            read_resp_queue.pop();
        }
        return;
    }

    // Generate read responses
    if (!read_resp_queue.empty() && mc0_axi_rready.read()) {
        AXITransaction trans = read_resp_queue.front();
        read_resp_queue.pop();
        
        mc0_axi_rid.write(trans.id);
        mc0_axi_rdata.write(trans.data);
        mc0_axi_rresp.write(0); // OKAY response
        mc0_axi_rlast.write(trans.last);
        mc0_axi_rvalid_int.write(true);
        
        std::cout << "@" << sc_time_stamp() << " AXI Read Data: ID=" 
                  << std::hex << trans.id << " Data=0x" << trans.data 
                  << " Last=" << trans.last << std::endl;
    } else {
        mc0_axi_rvalid_int.write(false);
    }
}

// APB Register Interface Process
void OpenDDRSystemCModel::apb_process() {
    if (!mc_rst_b.read()) {
        mc_prdata_int.write(0);
        mc_pready_int.write(false);
        mc_pslverr.write(false);
        return;
    }

    if (mc_psel.read() && mc_penable.read()) {
        sc_uint<10> addr = mc_paddr.read();
        
        if (mc_pwr.read()) {
            // Write operation
            sc_uint<32> data = mc_pwdata.read();
            write_register(addr, data);
            std::cout << "@" << sc_time_stamp() << " APB Write: Addr=0x" 
                      << std::hex << addr << " Data=0x" << data << std::endl;
        } else {
            // Read operation
            sc_uint<32> data = read_register(addr);
            mc_prdata_int.write(data);
            std::cout << "@" << sc_time_stamp() << " APB Read: Addr=0x" 
                      << std::hex << addr << " Data=0x" << data << std::endl;
        }
        
        mc_pready_int.write(true);
        mc_pslverr.write(false);
    } else {
        mc_pready_int.write(false);
    }
}

// Scheduler Process - Manages buffer access and command scheduling
void OpenDDRSystemCModel::scheduler_process() {
    if (!mc_rst_b.read()) {
        bufacc_cycle_en = false;
        bufacc_cycle_mode_wr = false;
        return;
    }

    // Simple scheduler logic
    bool has_write_work = !write_addr_queue.empty() && !write_data_queue.empty();
    bool has_read_work = !read_addr_queue.empty();
    
    if (has_write_work || has_read_work) {
        bufacc_cycle_en = true;
        
        // Alternate between write and read cycles
        static bool last_was_write = false;
        if (has_write_work && (!has_read_work || !last_was_write)) {
            bufacc_cycle_mode_wr = true;
            last_was_write = true;
            
            // Process write transaction
            if (!write_addr_queue.empty() && !write_data_queue.empty()) {
                AXITransaction addr_trans = write_addr_queue.front();
                AXITransaction data_trans = write_data_queue.front();
                write_addr_queue.pop();
                write_data_queue.pop();
                
                // Create DDR command
                DDRCommand ddr_cmd;
                int rank, bank;
                sc_uint<ROW_WIDTH> row;
                sc_uint<10> col;
                decode_address(addr_trans.addr, rank, bank, row, col);
                
                // Check for page hit/miss
                if (check_page_hit(bank, row)) {
                    page_hits++;
                    ddr_cmd.cmd_type = DDRCommand::CMD_WRITE;
                } else {
                    page_misses++;
                    // Need activate first, then write
                    DDRCommand act_cmd;
                    act_cmd.cmd_type = DDRCommand::CMD_ACT;
                    act_cmd.rank = rank;
                    act_cmd.bank = bank;
                    act_cmd.row = row;
                    schedule_ddr_command(act_cmd);
                    
                    ddr_cmd.cmd_type = DDRCommand::CMD_WRITE;
                    update_page_table(bank, row, true);
                }
                
                ddr_cmd.rank = rank;
                ddr_cmd.bank = bank;
                ddr_cmd.row = row;
                ddr_cmd.col = col;
                
                // Convert 64-bit AXI data to 16x32-bit DFI data
                for (int i = 0; i < 8; i++) {
                    ddr_cmd.data[i] = (data_trans.data >> (i * 8)) & 0xFF;
                }
                
                schedule_ddr_command(ddr_cmd);
                
                // Add to write response queue
                AXITransaction resp_trans;
                resp_trans.id = addr_trans.id;
                write_resp_queue.push(resp_trans);
            }
        } else if (has_read_work) {
            bufacc_cycle_mode_wr = false;
            last_was_write = false;
            
            // Process read transaction
            if (!read_addr_queue.empty()) {
                AXITransaction addr_trans = read_addr_queue.front();
                read_addr_queue.pop();
                
                // Create DDR command
                DDRCommand ddr_cmd;
                int rank, bank;
                sc_uint<ROW_WIDTH> row;
                sc_uint<10> col;
                decode_address(addr_trans.addr, rank, bank, row, col);
                
                // Check for page hit/miss
                if (check_page_hit(bank, row)) {
                    page_hits++;
                    ddr_cmd.cmd_type = DDRCommand::CMD_READ;
                } else {
                    page_misses++;
                    // Need activate first, then read
                    DDRCommand act_cmd;
                    act_cmd.cmd_type = DDRCommand::CMD_ACT;
                    act_cmd.rank = rank;
                    act_cmd.bank = bank;
                    act_cmd.row = row;
                    schedule_ddr_command(act_cmd);
                    
                    ddr_cmd.cmd_type = DDRCommand::CMD_READ;
                    update_page_table(bank, row, true);
                }
                
                ddr_cmd.rank = rank;
                ddr_cmd.bank = bank;
                ddr_cmd.row = row;
                ddr_cmd.col = col;
                ddr_cmd.buf_index = 0; // Simplified
                
                schedule_ddr_command(ddr_cmd);
                
                // Generate read data (simplified - pattern based on address)
                AXITransaction resp_trans;
                resp_trans.id = addr_trans.id;
                resp_trans.data = addr_trans.addr ^ 0xDEADBEEF; // Simple pattern
                resp_trans.last = true; // Simplified - single beat
                read_resp_queue.push(resp_trans);
            }
        }
    } else {
        bufacc_cycle_en = false;
    }
}

// Sequencer Process - Executes DDR commands
void OpenDDRSystemCModel::sequencer_process() {
    if (!mc_rst_b.read()) {
        seq_state = SEQ_IDLE;
        total_ddr_commands = 0;
        return;
    }

    // Simple sequencer state machine
    switch (seq_state) {
        case SEQ_IDLE:
            if (!ddr_cmd_queue.empty()) {
                DDRCommand cmd = ddr_cmd_queue.front();
                ddr_cmd_queue.pop();
                execute_ddr_command(cmd);
                total_ddr_commands++;
                
                // Transition to appropriate wait state
                switch (cmd.cmd_type) {
                    case DDRCommand::CMD_ACT:
                        seq_state = SEQ_W_ACT;
                        break;
                    case DDRCommand::CMD_WRITE:
                        seq_state = SEQ_W_WR;
                        break;
                    case DDRCommand::CMD_READ:
                        seq_state = SEQ_W_RD;
                        break;
                    case DDRCommand::CMD_PRE:
                    case DDRCommand::CMD_PREA:
                        seq_state = SEQ_W_PRE;
                        break;
                    case DDRCommand::CMD_REF:
                        seq_state = SEQ_W_REF;
                        break;
                    default:
                        seq_state = SEQ_IDLE;
                        break;
                }
            }
            break;
            
        case SEQ_W_ACT:
            // Wait for tRCD (simplified - 1 cycle)
            seq_state = SEQ_IDLE;
            break;
            
        case SEQ_W_WR:
            // Wait for write completion
            seq_state = SEQ_IDLE;
            break;
            
        case SEQ_W_RD:
            // Wait for read completion
            seq_state = SEQ_IDLE;
            break;
            
        case SEQ_W_PRE:
            // Wait for tRP
            seq_state = SEQ_IDLE;
            break;
            
        case SEQ_W_REF:
            // Wait for tRFC
            seq_state = SEQ_IDLE;
            break;
            
        default:
            seq_state = SEQ_IDLE;
            break;
    }
}

// DFI Command Process - Outputs DDR commands to DFI interface
void OpenDDRSystemCModel::dfi_command_process() {
    if (!mc_rst_b.read()) {
        dfi_cs_0_p0.write(0);
        dfi_cs_0_p1.write(0);
        dfi_cs_1_p2.write(0);
        dfi_cs_1_p3.write(0);
        dfi_address_0_p0.write(0);
        dfi_address_0_p1.write(0);
        dfi_address_1_p2.write(0);
        dfi_address_1_p3.write(0);
        dfi_reset_n.write(false);
        dfi_dram_clk_disable_0.write(3);
        dfi_dram_clk_disable_1.write(3);
        dfi_dram_ca_disable.write(true);
        return;
    }

    // Enable clocks and CA after reset
    dfi_reset_n.write(true);
    dfi_dram_clk_disable_0.write(0);
    dfi_dram_clk_disable_1.write(0);
    dfi_dram_ca_disable.write(false);

    // Default NOP command
    dfi_cs_0_p0.write(0);
    dfi_cs_0_p1.write(0);
    dfi_cs_1_p2.write(0);
    dfi_cs_1_p3.write(0);
    dfi_address_0_p0.write(0);
    dfi_address_0_p1.write(0);
    dfi_address_1_p2.write(0);
    dfi_address_1_p3.write(0);
}

// DFI Write Data Process
void OpenDDRSystemCModel::dfi_write_data_process() {
    if (!mc_rst_b.read()) {
        // Reset all write data outputs
        for (int i = 0; i < 16; i++) {
            // Would need to set each dfi_wrdata_X to 0
            // Simplified for this example
        }
        dfi_wrdata_0.write(0);
        dfi_wrdata_1.write(0);
        dfi_wrdata_2.write(0);
        dfi_wrdata_3.write(0);
        return;
    }

    // Write data handling would be implemented here
    // For now, just clear outputs
    dfi_wrdata_0.write(0);
    dfi_wrdata_1.write(0);
    dfi_wrdata_2.write(0);
    dfi_wrdata_3.write(0);
}

// DFI Read Data Process
void OpenDDRSystemCModel::dfi_read_data_process() {
    if (!mc_rst_b.read()) {
        mc_rdrst_b.write(false);
        mc_rcv_en.write(false);
        dfi_rddata_en.write(false);
        return;
    }

    // Read data handling
    mc_rdrst_b.write(true);
    mc_rcv_en.write(true);
    dfi_rddata_en.write(false); // Controlled by sequencer
}

// Refresh Timer Process
void OpenDDRSystemCModel::refresh_timer_process() {
    if (!porst_b.read()) {
        refresh_counter = 0;
        refresh_pending_counter = 0;
        return;
    }

    // Simple refresh timer (7.8us for DDR)
    refresh_counter++;
    if (refresh_counter >= 1950) { // Assuming 25MHz slow clock
        refresh_counter = 0;
        if (refresh_pending_counter < 255) {
            refresh_pending_counter++;
            
            // Schedule refresh command
            DDRCommand ref_cmd;
            ref_cmd.cmd_type = DDRCommand::CMD_REF;
            schedule_ddr_command(ref_cmd);
        }
    }
}

// Helper Functions Implementation

void OpenDDRSystemCModel::reset_model() {
    seq_state = SEQ_IDLE;
    ddr_init_done = false;
    bufacc_cycle_en = false;
    bufacc_cycle_mode_wr = false;
    refresh_counter = 0;
    refresh_pending_counter = 0;
    
    // Clear all queues
    while (!write_addr_queue.empty()) write_addr_queue.pop();
    while (!write_data_queue.empty()) write_data_queue.pop();
    while (!write_resp_queue.empty()) write_resp_queue.pop();
    while (!read_addr_queue.empty()) read_addr_queue.pop();
    while (!read_resp_queue.empty()) read_resp_queue.pop();
    while (!ddr_cmd_queue.empty()) ddr_cmd_queue.pop();
    
    // Clear buffers
    std::fill(wbuf_cmd_vld_memory.begin(), wbuf_cmd_vld_memory.end(), false);
    std::fill(rbuf_cmd_vld_memory.begin(), rbuf_cmd_vld_memory.end(), false);
    std::fill(page_table_vld_memory.begin(), page_table_vld_memory.end(), false);
    
    // Reset statistics
    total_write_transactions = 0;
    total_read_transactions = 0;
    total_ddr_commands = 0;
    page_hits = 0;
    page_misses = 0;
}

void OpenDDRSystemCModel::update_page_table(int bank, sc_uint<ROW_WIDTH> row, bool open) {
    if (bank < PAGE_TABLE_DEPTH) {
        page_table_vld_memory[bank] = open;
        if (open) {
            page_table_row_memory[bank] = row;
        }
    }
}

bool OpenDDRSystemCModel::check_page_hit(int bank, sc_uint<ROW_WIDTH> row) {
    if (bank < PAGE_TABLE_DEPTH && page_table_vld_memory[bank]) {
        return (page_table_row_memory[bank] == row);
    }
    return false;
}

void OpenDDRSystemCModel::schedule_ddr_command(const DDRCommand& cmd) {
    ddr_cmd_queue.push(cmd);
    std::cout << "@" << sc_time_stamp() << " DDR Cmd Scheduled: Type=" 
              << cmd.cmd_type << " Rank=" << cmd.rank << " Bank=" << cmd.bank 
              << " Row=0x" << std::hex << cmd.row << " Col=0x" << cmd.col << std::endl;
}

void OpenDDRSystemCModel::execute_ddr_command(const DDRCommand& cmd) {
    std::cout << "@" << sc_time_stamp() << " DDR Cmd Executed: Type=" 
              << cmd.cmd_type << " Rank=" << cmd.rank << " Bank=" << cmd.bank 
              << " Row=0x" << std::hex << cmd.row << " Col=0x" << cmd.col << std::endl;
              
    // Update timing counters and page table as needed
    switch (cmd.cmd_type) {
        case DDRCommand::CMD_ACT:
            update_page_table(cmd.bank, cmd.row, true);
            break;
        case DDRCommand::CMD_PRE:
            update_page_table(cmd.bank, 0, false);
            break;
        case DDRCommand::CMD_PREA:
            for (int i = 0; i < PAGE_TABLE_DEPTH; i++) {
                update_page_table(i, 0, false);
            }
            break;
        case DDRCommand::CMD_REF:
            if (refresh_pending_counter > 0) {
                refresh_pending_counter--;
            }
            break;
        default:
            break;
    }
}

sc_uint<32> OpenDDRSystemCModel::read_register(sc_uint<10> addr) {
    // Simplified register map
    switch (addr.to_uint()) {
        case 0x000: return seq_control_reg;
        case 0x004: return buf_config_reg;
        case 0x008: return ddr_config_reg;
        case 0x00C: return ddr_adr_config_reg;
        case 0x010: return pmu_cmd_reg;
        case 0x014: return pmu_mrs_reg;
        case 0x018: return pmu_mpc_reg;
        case 0x01C: return pmu_status_reg;
        case 0x020: return ac_timing_reg1;
        case 0x024: return ac_timing_reg2;
        case 0x028: return ac_timing_reg3;
        case 0x02C: return ac_timing_reg4;
        case 0x030: return ac_timing_reg5;
        case 0x034: return ac_timing_reg6;
        case 0x038: return ac_timing_reg7;
        case 0x03C: return ac_timing_reg8;
        case 0x040: return ac_timing_reg9;
        case 0x044: return ac_timing_reg10;
        case 0x048: return refresh_cntrl_reg;
        case 0x04C: return test_config_reg;
        default: return 0xDEADBEEF;
    }
}

void OpenDDRSystemCModel::write_register(sc_uint<10> addr, sc_uint<32> data) {
    // Simplified register map
    switch (addr.to_uint()) {
        case 0x000: seq_control_reg = data; break;
        case 0x004: buf_config_reg = data; break;
        case 0x008: ddr_config_reg = data; break;
        case 0x00C: ddr_adr_config_reg = data; break;
        case 0x010: pmu_cmd_reg = data; break;
        case 0x014: pmu_mrs_reg = data; break;
        case 0x018: pmu_mpc_reg = data; break;
        case 0x020: ac_timing_reg1 = data; break;
        case 0x024: ac_timing_reg2 = data; break;
        case 0x028: ac_timing_reg3 = data; break;
        case 0x02C: ac_timing_reg4 = data; break;
        case 0x030: ac_timing_reg5 = data; break;
        case 0x034: ac_timing_reg6 = data; break;
        case 0x038: ac_timing_reg7 = data; break;
        case 0x03C: ac_timing_reg8 = data; break;
        case 0x040: ac_timing_reg9 = data; break;
        case 0x044: ac_timing_reg10 = data; break;
        case 0x048: refresh_cntrl_reg = data; break;
        case 0x04C: test_config_reg = data; break;
        default: break;
    }
}

void OpenDDRSystemCModel::decode_address(sc_uint<40> addr, int& rank, int& bank, 
                                        sc_uint<ROW_WIDTH>& row, sc_uint<10>& col) {
    // DDR address mapping (simplified)
    // Addr[31] = CS, Addr[30:15] = ROW, Addr[14:12] = BANK, Addr[11:2] = COL
    rank = (addr >> 31) & 0x1;
    bank = (addr >> 12) & 0x7;
    row = (addr >> 15) & 0xFFFF;
    col = (addr >> 2) & 0x3FF;
}

void OpenDDRSystemCModel::print_statistics() {
    std::cout << "\n=== OpenDDR SystemC Model Statistics ===" << std::endl;
    std::cout << "Total Write Transactions: " << total_write_transactions << std::endl;
    std::cout << "Total Read Transactions:  " << total_read_transactions << std::endl;
    std::cout << "Total DDR Commands:       " << total_ddr_commands << std::endl;
    std::cout << "Page Hits:                " << page_hits << std::endl;
    std::cout << "Page Misses:              " << page_misses << std::endl;
    if (page_hits + page_misses > 0) {
        double hit_rate = (double)page_hits / (page_hits + page_misses) * 100.0;
        std::cout << "Page Hit Rate:            " << std::fixed << std::setprecision(2) 
                  << hit_rate << "%" << std::endl;
    }
    std::cout << "========================================\n" << std::endl;
}
