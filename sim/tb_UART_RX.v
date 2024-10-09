`timescale 1ns/1ns

module tb_uart_rx ();

    parameter UART_BPS      = 1000000      ;
    parameter CLK_FREQ      = 50_000_000   ;



    reg             clk             ;
    reg [19:0]      uart_buad       ;
    reg             rx_rstn         ;
    reg             rx              ;
    reg             check           ;
    reg             st_check        ;
    reg             parity          ;
    reg             p_error_ack     ;
    reg             st_error_ack    ;
    reg             rx_fifo_read    ;
    reg  [3:0]      data_length     ;

    wire            st_error        ;
    wire            p_error         ;
    wire [4:0]      rx_fifo_cnt     ;
    wire            rx_fifo_empty   ;
    wire            rx_work         ;
    wire [7:0]      data_to_reg     ;


    //参数定义
    initial
    begin
        data_length <=  4'd8;
    end

    //信号初始化
    initial
    begin
        uart_buad   <=  UART_BPS;
        clk         <=  1'b1;
        rx          <=  1'b1;
        rx_rstn     <=  1'b0;
        check       <=  1'b1;
        st_check    <=  1'b1;
        parity      <=  1'b0;
        p_error_ack <=  1'b0;
        st_error_ack<=  1'b0;
        rx_fifo_read<=  1'b0;
        #20;
        rx_rstn     <=  1'b1;
    end


    integer dat_in;

    initial
    begin
        #100;
        for (dat_in = 0; dat_in < 18 ; dat_in = dat_in + 1)
        begin
            rx_bit(dat_in);
        end
    end

    always #10 clk = ~clk;

    // 若串口发出奇偶校验错误信号后,立即回复
    always @(posedge clk or negedge rx_rstn)
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
    always @(posedge clk or negedge rx_rstn)
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

    task rx_bit
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

    uart_rx
        #(
            .CLK_FREQ(CLK_FREQ)
        )
        uart_rx_inst
        (
            .clk            (clk            )   ,       // 50MHz时钟
            .uart_buad      (uart_buad      )   ,       // 收串口波特率
            .rx_rstn        (rx_rstn        )   ,       // 收串口复位
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

endmodule
