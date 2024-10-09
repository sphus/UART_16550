`timescale 1ns/1ns

module tb_UART_TX ();

    parameter CLK_FREQ     =   'd50_000_000;

    reg           clk             ;
    reg   [19:0]  uart_buad       ;
    reg           tx_rstn         ;
    reg   [7:0]   tx_in_data      ;
    reg   [3:0]   data_length     ;
    reg           check           ;
    reg           parity          ;
    reg           tx_fifo_write   ;

    wire   [4:0]  tx_fifo_cnt     ;
    wire          tx_fifo_full    ;
    wire          tx_work         ;
    wire          tx              ;


    initial
    begin
        clk             <= 1'b1;
        tx_rstn         <= 1'b0;
        # 20;
        tx_rstn         <= 1'b1;
    end

    initial
    begin
        tx_in_data      <= 8'b0;
        data_length     <= 4'd8;
        uart_buad       <= 20'd115200;
        check           <= 1'b1;
        parity          <= 1'b0;
        tx_fifo_write   <= 1'b0;
    end

    always #10
    begin
        clk = ~clk;
    end

    integer data_in;

    initial
    begin
        for (data_in = 8;data_in <24 ;data_in = data_in + 1 )
        begin
            #100;
            tx_byte(data_in);
        end
    end

    task tx_byte
        (
            input [7:0] data
        );
        begin
            #20;
            tx_in_data <= data;
            #20;
            tx_fifo_write <= 1'b1;
            #20;
            tx_fifo_write <= 1'b0;
        end
    endtask


    UART_TX
        #(
            .CLK_FREQ(CLK_FREQ)
        )
        UART_TX_inst
        (
            .clk          (clk          )   ,       // 50MHz时钟
            .uart_buad    (uart_buad    )   ,       // 收串口波特率
            .tx_rstn      (tx_rstn      )   ,       // 发串口复位
            .tx_in_data   (tx_in_data   )   ,       // 并行数据输入
            .data_length  (data_length  )   ,       // 输入数据长度
            .check        (check        )   ,       // 奇偶校验使能
            .parity       (parity       )   ,       // 奇偶校验位选择
            .tx_fifo_write(tx_fifo_write)   ,       // FIFO写指令

            .tx_fifo_cnt  (tx_fifo_cnt  )   ,       // 发FIFO容量
            .tx_fifo_full (tx_fifo_full )   ,       // 发FIFO满
            .tx_work      (tx_work      )   ,       // 发串口工作
            .tx           (tx           )           // 发串口发送数据
        );


endmodule
