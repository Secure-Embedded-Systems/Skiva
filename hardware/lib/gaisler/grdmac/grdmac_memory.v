// Memory Wrapper for GRDMAC

module grdmac_memory #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
) (
    input clk,
    input [ADDR_WIDTH-1:0] address,
    input [DATA_WIDTH-1:0] datain,
    input [3:0] enable,
    input [3:0] write,
    output [DATA_WIDTH-1:0] dataout
);

    wire csn, wen, oen;  // Active low Chip select and write enable 

    assign csn = ~(&enable);
    assign wen = ~(&write);
    assign oen = 1'b0;

    // Instantiate memory
    sram8x32 dma_mem (
        .CLK (clk),
        .CEN (csn),
        .WEN (wen),
        .A   (address),
        .D   (datain),
        .OEN (oen),
        .Q   (dataout)
    );    

endmodule
