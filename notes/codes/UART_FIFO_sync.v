`timescale 1ns/1ps
module UART_FIFO_sync
    #(
         parameter DEPTH = 16,
         parameter WIDTH = 8
     )
     (
         input                          clk     ,       // ARM clock
         input                          rstn    ,       // ARM reset
         input                          fifo_rst,       // FIFO reset control signal.high active
         input                          read    ,       // FIFO read enable signal
         input                          write   ,       // FIFO write enable signal
         input       [WIDTH:0]          data_i  ,       // in data line

         output                         wfull   ,       // write full signal
         output                         rempty  ,       // read empty signal
         output reg  [WIDTH:0]          data_o  ,       // FIFO out data
         output reg  [$clog2(DEPTH):0]  fifo_cnt        // FIFO statu register

     );

    reg [$clog2(DEPTH):0]   wptr            ;           // write pointer
    reg [$clog2(DEPTH):0]   rptr            ;           // read pointer
    reg [WIDTH:0]           ram [DEPTH-1:0] ;           // ram in FIFO

    //read data from ram
    always @(posedge clk or negedge rstn)
    begin
        if (!rstn)
        begin
            data_o  <=  'd0;
            rptr    <=  'd0;
        end
        else
        begin
            if (!fifo_rst)
            begin
                rptr  <=    'd0;
            end
            else
            begin
                if (read && !rempty)
                begin
                    data_o  <=  ram[rptr[$clog2(DEPTH) -1:0]];
                    rptr    <=  rptr+1'b1;
                end
            end
        end
    end


    //write data in ram
    always @(posedge clk or negedge rstn)
    begin
        if (!rstn)
        begin
            wptr    <=  'd0;
        end
        else
        begin
            if (!fifo_rst)
            begin
                wptr  <=    'd0;
            end
            else
            begin
                if (write && !wfull)
                begin
                    ram[wptr[$clog2(DEPTH) -1:0]]  <=  data_i;
                    wptr    <=  wptr+1'b1;
                end
            end
        end
    end

    //the number of data in the FIFO
    always @(posedge clk or negedge rstn)
    begin
        if (!rstn)
        begin
            fifo_cnt <= 'd0;
        end
        else
        begin
            fifo_cnt <= wptr - rptr;
        end
    end

    //produce full and empty signal
    assign  wfull   = ({!wptr[$clog2(DEPTH)],wptr[$clog2(DEPTH) -1:0]} == rptr) ? 1'b1:1'b0;
    assign  rempty  = (wptr == rptr) ? 1'b1:1'b0;

endmodule
