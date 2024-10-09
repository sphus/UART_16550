`timescale 1ns/1ps
module UART_FIFO_sync
    #(
         parameter DEPTH = 16,
         parameter WIDTH = 8
     )
     (
         input                          clk         ,       // 时钟
         input                          rstn        ,       // 复位
         input                          fifo_rstn   ,       // FIFO 复位
         input                          read        ,       // FIFO 读信号
         input                          write       ,       // FIFO 写信号
         input       [WIDTH-1:0]        data_i      ,       // 数据输入

         output                         wfull       ,       // FIFO 满标志位
         output                         rempty      ,       // FIFO 满标志位
         output reg  [WIDTH-1:0]        data_o      ,       // FIFO 输出数据
         output reg  [$clog2(DEPTH):0]  fifo_cnt            // FIFO 数据量

     );

    reg [$clog2(DEPTH):0]   wptr            ;           // 写指针
    reg [$clog2(DEPTH):0]   rptr            ;           // 读指针
    reg [WIDTH-1:0]         ram [DEPTH-1:0] ;           // FIFO 存储

    //读数据
    always @(posedge clk or negedge rstn)
    begin
        if (!rstn)
        begin
            data_o  <=  'd0;
            rptr    <=  'd0;
        end
        else
        begin
            if (!fifo_rstn)
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


    //写数据
    always @(posedge clk or negedge rstn)
    begin
        if (!rstn)
        begin
            wptr    <=  'd0;
        end
        else
        begin
            if (!fifo_rstn)
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

    //FIFO数据量指示
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

    //FIFO空满指示
    assign  wfull   = ({!wptr[$clog2(DEPTH)],wptr[$clog2(DEPTH) -1:0]} == rptr) ? 1'b1:1'b0;
    assign  rempty  = (wptr == rptr) ? 1'b1:1'b0;

endmodule
