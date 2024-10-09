module UART_TOP
    #(
         parameter CLK_FREQ     =   'd50_000_000
     )
     (
         input  wire            clk             ,
         input  wire [19:0]     uart_buad       ,
         input  wire            rstn            ,
         input  wire            rx              ,
         input  wire            check           ,
         input  wire            st_check        ,
         input  wire            parity          ,
         input  wire            p_error_ack     ,
         input  wire            st_error_ack    ,
         input  wire            rx_fifo_read    ,
         input  wire [3:0]      data_length     ,
         input  wire [7:0]      tx_in_data      ,
         input  wire            tx_fifo_write   ,

         output wire            st_error        ,
         output wire            p_error         ,
         output wire [4:0]      rx_fifo_cnt     ,
         output wire            rx_fifo_empty   ,
         output wire            rx_work         ,
         output wire [7:0]      data_to_reg     ,
         output wire [4:0]      tx_fifo_cnt     ,
         output wire            tx_fifo_full    ,
         output wire            tx_work         ,
         output wire            tx
     );




    UART_RX
        #(
            .CLK_FREQ(CLK_FREQ)
        )
        UART_RX_inst
        (
            .clk            (clk            )   ,       // 50MHz时钟
            .uart_buad      (uart_buad      )   ,       // 收串口波特率
            .rx_rstn        (rstn           )   ,       // 收串口复位
            .rx             (rx             )   ,       // 串口接收并行数据
            .data_length    (data_length    )   ,       // 输入数据长度
            .check          (check          )   ,       // 奇偶校验使能
            .st_check       (st_check       )   ,       // 奇偶校验错误后停止位检查使能
            .parity         (parity         )   ,       // 奇偶校验位选择
            .p_error_ack    (p_error_ack    )   ,       // 接收错误   CPU回应
            .st_error_ack   (st_error_ack   )   ,       // 停止位错误 CPU回应
            .rx_fifo_read   (rx_fifo_read   )   ,       // FIFO读指令

            .st_error       (st_error       )   ,       // 停止位错误
            .p_error        (p_error        )   ,       // 奇偶校验位错误
            .rx_fifo_cnt    (rx_fifo_cnt    )   ,       // 收FIFO容量
            .rx_fifo_empty  (rx_fifo_empty  )   ,       // 收FIFO空
            .rx_work        (rx_work        )   ,       // 收串口工作
            .data_to_reg    (data_to_reg    )           // 收串口FIFO输出
        );

    UART_TX
        #(
            .CLK_FREQ(CLK_FREQ)
        )
        UART_TX_inst
        (
            .clk          (clk          )   ,       // 50MHz时钟
            .uart_buad    (uart_buad    )   ,       // 收串口波特率
            .tx_rstn      (rstn         )   ,       // 发串口复位
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
