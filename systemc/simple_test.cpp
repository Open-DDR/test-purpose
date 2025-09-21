#include <systemc.h>
#include <iostream>

SC_MODULE(simple_counter) {
    sc_in<bool> clk;
    sc_in<bool> reset;
    sc_out<sc_uint<8>> count;
    
    sc_uint<8> counter_value;
    
    SC_CTOR(simple_counter) {
        SC_METHOD(count_process);
        sensitive << clk.pos();
        counter_value = 0;
    }
    
    void count_process() {
        if (reset.read()) {
            counter_value = 0;
        } else {
            counter_value++;
        }
        count.write(counter_value);
        
        if (counter_value % 10 == 0) {
            std::cout << "Counter: " << counter_value << " at " << sc_time_stamp() << std::endl;
        }
    }
};

SC_MODULE(testbench) {
    sc_clock clk;
    sc_signal<bool> reset;
    sc_signal<sc_uint<8>> count;
    
    simple_counter* dut;
    
    SC_CTOR(testbench) : clk("clk", sc_time(10, SC_NS)) {
        dut = new simple_counter("counter");
        dut->clk(clk);
        dut->reset(reset);
        dut->count(count);
        
        SC_THREAD(stimulus);
    }
    
    void stimulus() {
        reset.write(true);
        wait(25, SC_NS);
        reset.write(false);
        
        std::cout << "=== Simple SystemC Counter Test ===" << std::endl;
        std::cout << "Starting counter..." << std::endl;
        
        wait(200, SC_NS);
        
        std::cout << "Final count: " << count.read() << std::endl;
        std::cout << "✅ SystemC test completed successfully!" << std::endl;
        sc_stop();
    }
    
    ~testbench() { delete dut; }
};

int sc_main(int argc, char* argv[]) {
    std::cout << "=== SystemC Simple Test ===" << std::endl;
    testbench tb("tb");
    sc_start();
    return 0;
}
