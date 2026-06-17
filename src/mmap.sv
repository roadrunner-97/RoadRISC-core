import definitions::*;

module mmap #(
    parameter int RAM_SIZE = 1024,
    parameter string FILE = "src/program.hex"
)(
    input logic clock,
    mem_bus_if.slave  bus,
    vga_bus_if.provider vga_bus
);

    word_t memory [RAM_SIZE];
    initial $readmemh(FILE, memory);

    always_ff @(posedge clock) begin
        if (bus.address < RAM_SIZE) begin
            if(bus.write_enable) begin
                memory[bus.address] <= bus.write_data;
            end else begin
                bus.read_data <= memory[bus.address];
            end
        end
        if (vga_bus.address < RAM_SIZE)
            vga_bus.data <= memory[vga_bus.address];
    end

endmodule
