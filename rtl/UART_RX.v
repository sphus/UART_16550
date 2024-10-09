module UART_RX
    #(
         parameter CLK_FREQ     =   'd50_000_000
     )
     (
         input   wire           clk             ,       // 50MHz时钟
         input   wire   [19:0]  uart_buad       ,       // 收串口波特率
         input   wire           rx_rstn         ,       // 收串口复位
         input   wire           rx              ,       // 串口接收并行数据
         input   wire   [3:0]   data_length     ,       // 输入数据长度
         input   wire           check           ,       // 奇偶校验使能
         input   wire           st_check        ,       // 奇偶校验错误后停止位检查使能
         input   wire           parity          ,       // 奇偶校验位选择
         input   wire           p_error_ack     ,       // 接收错误   CPU回应
         input   wire           st_error_ack    ,       // 停止位错误 CPU回应
         input   wire           rx_fifo_read    ,       // FIFO读指令

         output  reg            st_error        ,       // 停止位错误
         output  reg            p_error         ,       // 奇偶校验位错误
         output  wire   [4:0]   rx_fifo_cnt     ,       // 收FIFO容量
         output  wire           rx_fifo_empty   ,       // 收FIFO空
         output  reg            rx_work         ,       // 收串口工作
         output  wire   [7:0]   data_to_reg             // 收串口FIFO输出
     );

    parameter IDLE  = 3'b000;
    parameter START = 3'b001;
    parameter RX    = 3'b011;
    parameter CHECK = 3'b010;
    parameter STOP  = 3'b110;
    parameter SEND  = 3'b100;

    //异步信号打拍至
    reg         rx_start            ;       // RX发送数据给FIFO起始信号
    reg         rx_ack              ;       // FIFO接收串口信号完毕反馈

    reg         rx_reg1             ;       // 串口接收信号打拍
    reg         rx_reg2             ;       // 串口接收信号打拍
    reg         check_reg1          ;       // 奇偶校验使能打拍
    reg         check_reg2          ;       // 奇偶校验使能打拍
    reg         st_check_reg1       ;       // 奇偶校验错误后停止位检查使能打拍
    reg         st_check_reg2       ;       // 奇偶校验错误后停止位检查使能打拍
    reg         parity_reg1         ;       // 奇偶校验位选择打拍
    reg         parity_reg2         ;       // 奇偶校验位选择打拍
    reg         p_error_ack_reg1    ;       // 接收错误   CPU回应打拍
    reg         p_error_ack_reg2    ;       // 接收错误   CPU回应打拍
    reg         st_error_ack_reg1   ;       // 停止位错误 CPU回应打拍
    reg         st_error_ack_reg2   ;       // 停止位错误 CPU回应打拍

    //FIFO信号
    reg         rx_fifo_write       ;       // 收FIFO写指令
    wire        rx_fifo_full        ;       // 收FIFO满

    //状态机
    reg     [2:0]   state               ;
    reg     [2:0]   nextstate           ;

    reg             fifo_state          ;
    reg     [14:0]  buad_cnt            ;
    reg             bit_flag            ;
    reg     [3:0]   bit_cnt             ;
    reg     [7:0]   rx_data             ;
    wire    [14:0]  buad_cnt_max        ;


    UART_FIFO_sync  RX_FIFO
                    (
                        .clk      (clk             ),       // 时钟
                        .rstn     (rx_rstn         ),       // 复位
                        .fifo_rstn(rx_rstn         ),       // FIFO 复位
                        .read     (rx_fifo_read    ),       // FIFO 读信号
                        .write    (rx_fifo_write   ),       // FIFO 写信号
                        .data_i   (rx_data         ),       // 数据输入

                        .wfull    (rx_fifo_full    ),       // FIFO 满标志位
                        .rempty   (rx_fifo_empty   ),       // FIFO 满标志位
                        .data_o   (data_to_reg     ),       // FIFO 输出数据
                        .fifo_cnt (rx_fifo_cnt     )        // FIFO 数据量
                    );

    //FIFO控制
    always @(posedge clk or negedge rx_rstn)
    begin
        if (!rx_rstn)
        begin
            rx_ack          <= 1'b0;
            rx_fifo_write   <= 1'b0;
            fifo_state      <= 1'b0;
        end
        else
        begin
            case (fifo_state)
                1'b0://FIFO没满，且接收到读信号
                begin
                    if (!rx_fifo_full && rx_start)
                    begin
                        rx_ack          <= 1'b1 ;
                        rx_fifo_write   <= 1'b1 ;
                        fifo_state      <= 1'b1 ;
                    end
                end
                1'b1://停止FIFO写，等待读信号拉低后停止串口读
                begin
                    rx_fifo_write <= 1'b0;
                    if (!rx_start)
                    begin
                        rx_ack <= 1'b0;
                        fifo_state <= 1'b0;
                    end
                end
                default:
                    fifo_state <= 1'b0;
            endcase
        end
    end

    //信号同步
    always @(posedge clk or negedge rx_rstn)
    begin
        if (rx_rstn == 1'b0)
        begin
            rx_reg1             <= 1'b1 ;
            rx_reg2             <= 1'b1 ;
            check_reg1          <= 1'b0 ;
            check_reg2          <= 1'b0 ;
            st_check_reg1       <= 1'b0 ;
            st_check_reg2       <= 1'b0 ;
            parity_reg1         <= 1'b0 ;
            parity_reg2         <= 1'b0 ;
            p_error_ack_reg1    <= 1'b0 ;
            p_error_ack_reg2    <= 1'b0 ;
            st_error_ack_reg1   <= 1'b0 ;
            st_error_ack_reg2   <= 1'b0 ;
        end
        else
        begin
            rx_reg1             <=  rx                  ;
            rx_reg2             <=  rx_reg1             ;
            check_reg1          <=  check               ;
            check_reg2          <=  check_reg1          ;
            st_check_reg1       <=  st_check            ;
            st_check_reg2       <=  st_check_reg1       ;
            parity_reg1         <=  parity              ;
            parity_reg2         <=  parity_reg1         ;
            p_error_ack_reg1    <=  p_error_ack         ;
            p_error_ack_reg2    <=  p_error_ack_reg1    ;
            st_error_ack_reg1   <=  st_error_ack        ;
            st_error_ack_reg2   <=  st_error_ack_reg1   ;
        end
    end

    //状态转换
    always @(posedge clk or negedge rx_rstn)
    begin
        if (!rx_rstn)
        begin
            state <= IDLE;
        end
        else
        begin
            state <= nextstate;
        end
    end

    //状态跳转
    always @(*)
    begin
        case (state)
            IDLE  :
            begin
                if(rx_reg1 == 1'b0 && rx_reg2 == 1'b1)//数据下降沿后为起始位
                    nextstate = START   ;
                else
                    nextstate = IDLE    ;
            end
            START :
            begin
                if (bit_flag)
                begin
                    if (!rx_reg2)
                        nextstate = RX  ;
                    else
                        nextstate = IDLE ;
                end
                else
                    nextstate = START   ;
            end
            RX    :
            begin
                if (bit_cnt < data_length)
                    nextstate = RX;
                else
                begin
                    if (check_reg2)
                    begin
                        nextstate = CHECK;
                    end
                    else
                    begin
                        nextstate = STOP;
                    end
                end
            end
            CHECK :
            begin
                if(p_error_ack_reg2)
                begin
                    nextstate = IDLE;
                end
                else
                begin
                    if(bit_flag)
                    begin
                        if(p_error)
                        begin
                            nextstate = CHECK;
                        end
                        else
                        begin
                            if(st_check_reg2)
                            begin
                                nextstate = STOP;
                            end
                            else
                            begin
                                nextstate = SEND;
                            end
                        end
                    end
                    else
                    begin
                        nextstate = CHECK;
                    end
                end
            end
            STOP  :
            begin
                if (st_error_ack_reg2)
                begin
                    nextstate = IDLE;
                end
                else
                begin
                    if (bit_flag)
                    begin
                        if (st_error)
                        begin
                            nextstate = STOP;
                        end
                        else
                        begin
                            nextstate = SEND;
                        end
                    end
                    else
                    begin
                        nextstate = STOP;
                    end
                end
            end
            SEND  :
            begin
                if(rx_start)
                begin
                    nextstate = IDLE;
                end
                else
                begin
                    nextstate = SEND;
                end
            end
            default:
                nextstate = IDLE;
        endcase
    end

    //信号输出
    always @(posedge clk or negedge rx_rstn)
    begin
        if (!rx_rstn)
        begin
            rx_work     <= 1'b0;
            bit_flag    <= 1'b0;
            rx_data     <= 8'd0;
            bit_cnt     <= 4'd0;
            p_error     <= 1'b0;
            st_error    <= 1'b0;
            rx_start    <= 1'b0;
        end
        else
        begin
            case (state)
                IDLE :
                begin
                    rx_work     <= 1'b0;
                    bit_flag    <= 1'b0;
                    bit_cnt     <= 4'd0;
                    p_error     <= 1'b0;
                    st_error    <= 1'b0;
                    rx_start    <= 1'b0;
                end
                START:
                    rx_work <= 1'b1;
                RX   :
                begin
                    if (bit_flag)
                    begin
                        rx_data[bit_cnt] <= rx_reg2;
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end
                CHECK:
                begin
                    if (bit_flag)
                    begin
                        if (parity_reg2)
                        begin
                            //奇校验
                            if (^rx_data == rx_reg2)
                            begin
                                p_error <= 1'b1;
                            end
                        end
                        else
                        begin
                            //偶校验
                            if (^rx_data == !rx_reg2)
                            begin
                                p_error <= 1'b1;
                            end
                        end
                    end
                end
                STOP :
                begin
                    if(bit_flag)
                    begin
                        if (rx_reg2 == 1'b0)
                        begin
                            st_error <= 1'b1;
                            rx_work  <= 1'b0;
                        end
                    end
                end
                SEND :
                begin
                    rx_start <= 1'b1;
                end
            endcase
        end
    end

    //波特计数器
    always @(posedge clk or negedge rx_rstn)
    begin
        if (rx_rstn == 1'b0)
            buad_cnt <= 14'd0;
        else if ((buad_cnt == buad_cnt_max - 1) || (rx_work == 1'b0))
            buad_cnt <= 14'd0;
        else
            buad_cnt <= buad_cnt + 1'b1;
    end

    //数据读取标志位
    always @(posedge clk or negedge rx_rstn)
    begin
        if (rx_rstn == 1'b0)
            bit_flag <= 1'd0;
        else if(buad_cnt == buad_cnt_max/2 - 1)
            bit_flag <= 1'b1;
        else
            bit_flag <= 1'd0;
    end

    assign  buad_cnt_max = CLK_FREQ / uart_buad;

endmodule

