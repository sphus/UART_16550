`timescale 1ns/1ns

module tb_UART_TOP ();

    parameter CLK_FREQ     =   'd50_000_000 ;
    parameter UART_BPS     =    20'd115200  ;
    parameter DATA_LENGTH  =    4'd8        ;

    reg             clk             ;
    reg [19:0]      uart_buad       ;
    reg             rstn            ;
    reg             rx              ;
    reg             check           ;
    reg             st_check        ;
    reg             parity          ;
    reg             p_error_ack     ;
    reg             st_error_ack    ;
    reg             rx_fifo_read    ;
    reg  [3:0]      data_length     ;
    reg  [7:0]      tx_in_data      ;
    reg             tx_fifo_write   ;

    wire            st_error        ;
    wire            p_error         ;
    wire [4:0]      rx_fifo_cnt     ;
    wire            rx_fifo_empty   ;
    wire            rx_work         ;
    wire [7:0]      data_to_reg     ;
    wire [4:0]      tx_fifo_cnt     ;
    wire            tx_fifo_full    ;
    wire            tx_work         ;
    wire            tx              ;


    //复位
    initial
    begin
        clk             <= 1'b1;
        rstn            <= 1'b0;
        # 20;
        rstn            <= 1'b1;
    end

    // 数据初始化
    initial
    begin
        tx_in_data      <= 8'b0;
        tx_fifo_write   <= 1'b0;
        rx              <= 1'b1;
        p_error_ack     <= 1'b0;
        st_error_ack    <= 1'b0;
        rx_fifo_read    <= 1'b0;
    end

    // 参数初始化
    initial
    begin
        data_length     <= DATA_LENGTH  ;
        uart_buad       <= UART_BPS     ;
        check           <= 1'b1         ;
        st_check        <= 1'b1         ;
        parity          <= 1'b0         ;
    end

    //时钟
    always #10
    begin
        clk = ~clk;
    end


    //串口发送
    integer data_to_tx;

    initial
    begin
        for (data_to_tx = 8;data_to_tx <24 ;data_to_tx = data_to_tx + 1 )
        begin
            #100;
            tx_byte(data_to_tx);
        end
    end

    task tx_byte
        (
            input [7:0] data
        );
        begin
            tx_in_data <= data;
            #20;
            tx_fifo_write <= 1'b1;
            #20;
            tx_fifo_write <= 1'b0;
        end
    endtask

    //串口接收
    integer data_to_rx;

    initial
    begin
        #100;
        for (data_to_rx = 0; data_to_rx < 18 ; data_to_rx = data_to_rx + 1)
        begin
            rx_byte(data_to_rx);
        end
    end


    // 若串口发出奇偶校验错误信号后,立即回复
    always @(posedge clk or negedge rstn)
    begin
        if (p_error == 1'b1)
        begin
            p_error_ack <= 1'b1;
        end
        else
        begin
            p_error_ack <= 1'b0;
        end
    end

    // 若串口发出停止位校验错误信号后,立即回复
    always @(posedge clk or negedge rstn)
    begin
        if (st_error == 1'b1)
        begin
            st_error_ack <= 1'b1;
        end
        else
        begin
            st_error_ack <= 1'b0;
        end
    end

    integer i;

    task rx_byte
        (
            input [7:0] data
        );
        begin
            //起始位
            rx    <=  1'b0;
            #(CLK_FREQ / UART_BPS * 20);

            //数据位
            for (i = 0;i < data_length ; i = i + 1)
            begin
                rx    <=  data[i];
                #(CLK_FREQ / UART_BPS * 20);
            end
            //奇偶校验位
            if (check == 1'b1)
            begin
                if (parity)
                begin
                    case (data_length)
                        4'd8:
                            rx    <=  ^~data[7:0];
                        4'd7:
                            rx    <=  ^~data[6:0];
                        4'd6:
                            rx    <=  ^~data[5:0];
                        4'd5:
                            rx    <=  ^~data[4:0];
                        default:
                            rx    <=  1'bx;
                    endcase
                end
                else
                begin
                    case (data_length)
                        4'd8:
                            rx    <=  ^data[7:0];
                        4'd7:
                            rx    <=  ^data[6:0];
                        4'd6:
                            rx    <=  ^data[5:0];
                        4'd5:
                            rx    <=  ^data[4:0];
                        default:
                            rx    <=  1'bx;
                    endcase
                end
                #(CLK_FREQ / UART_BPS * 20);
            end

            //停止位
            rx    <=  1'b1;
            #(CLK_FREQ / UART_BPS * 20);
        end
    endtask


    UART_TOP #(
                 .CLK_FREQ(CLK_FREQ)
             )
             UART_TOP_inst
             (
                 .clk          (clk          )   ,
                 .uart_buad    (uart_buad    )   ,
                 .rstn         (rstn         )   ,
                 .rx           (rx           )   ,
                 .check        (check        )   ,
                 .st_check     (st_check     )   ,
                 .parity       (parity       )   ,
                 .p_error_ack  (p_error_ack  )   ,
                 .st_error_ack (st_error_ack )   ,
                 .rx_fifo_read (rx_fifo_read )   ,
                 .data_length  (data_length  )   ,
                 .tx_in_data   (tx_in_data   )   ,
                 .tx_fifo_write(tx_fifo_write)   ,

                 .st_error     (st_error     )   ,
                 .p_error      (p_error      )   ,
                 .rx_fifo_cnt  (rx_fifo_cnt  )   ,
                 .rx_fifo_empty(rx_fifo_empty)   ,
                 .rx_work      (rx_work      )   ,
                 .data_to_reg  (data_to_reg  )   ,
                 .tx_fifo_cnt  (tx_fifo_cnt  )   ,
                 .tx_fifo_full (tx_fifo_full )   ,
                 .tx_work      (tx_work      )   ,
                 .tx           (tx           )
             );

endmodule
