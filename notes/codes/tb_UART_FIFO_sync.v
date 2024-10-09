`timescale 1ns/1ps

module tb_UART_FIFO_sync();

    parameter DEPTH = 16;
    parameter WIDTH = 8;
    //input
    reg                         clk     ;
    reg                         rstn    ;
    reg                         fifo_rst;
    reg                         read    ;
    reg                         write   ;
    reg     [WIDTH-1:0]         data_i  ;
    //output    
    wire                        wfull   ;
    wire                        rempty  ;
    wire    [WIDTH-1:0]         data_o  ;
    wire    [$clog2(DEPTH):0]   fifo_cnt;

    reg     [WIDTH-1:0]         data_input;

    initial
    begin
        clk         =  1'b1;
        rstn        <= 1'b0;
        fifo_rst    <= 1'b0;
        read        <= 1'b0;
        write       <= 1'b0;
        data_i      <= 8'b0;
        data_input  <= 8'b0;
        #20;
        rstn        <= 1'b1;
        fifo_rst    <= 1'b1;

    end

    always #10 clk = ~clk;//20ns,50MHz


    always #20
    begin
        write       <= 1'b1;
        data_i      <= data_input;
        data_input  <= data_input +1'b1;
    end

    always #20
    begin
        read <= 1'b1;
        #20;
        read <= 1'b0;

    end

    UART_FIFO_sync UART_FIFO_sync_inst
                   (
                       //input
                       .clk     (clk     ),
                       .rstn    (rstn    ),
                       .fifo_rst(fifo_rst),
                       .read    (read    ),
                       .write   (write   ),
                       .data_i  (data_i  ),
                       //output
                       .wfull   (wfull   ),
                       .rempty  (rempty  ),
                       .data_o  (data_o  ),
                       .fifo_cnt(fifo_cnt)
                   );
endmodule
