#include <systemc.h>

int sc_main(int argc, char* argv[]) {
    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> sig;
    cout << "Hello, SystemC!" << endl;
    return 0;
}
