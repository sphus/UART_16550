module UART_TX
    #(
         parameter CLK_FREQ     =   'd50_000_000
     )
     (
         input   wire           clk             ,       // 50MHz时钟
         input   wire   [19:0]  uart_buad       ,       // 收串口波特率
         input   wire           tx_rstn         ,       // 发串口复位
         input   wire   [7:0]   tx_in_data      ,       // 并行数据输入
         input   wire   [3:0]   data_length     ,       // 输入数据长度
         input   wire           check           ,       // 奇偶校验使能
         input   wire           parity          ,       // 奇偶校验位选择
         input   wire           tx_fifo_write   ,       // FIFO写指令

         output  wire   [4:0]   tx_fifo_cnt     ,       // 发FIFO容量
         output  wire           tx_fifo_full    ,       // 发FIFO满
         output  reg            tx_work         ,       // 发串口工作
         output  reg            tx                      // 发串口发送数据
     );

    parameter IDLE  = 3'b000;
    parameter START = 3'b001;
    parameter TX    = 3'b011;
    parameter CHECK = 3'b010;
    parameter STOP  = 3'b110;

    reg             tx_start            ;       // TX发送数据给FIFO起始信号
    reg             tx_ack              ;       // FIFO接收串口信号完毕反馈
    //异步信号打拍
    reg             check_reg1          ;       // 奇偶校验使能打拍
    reg             check_reg2          ;       // 奇偶校验使能打拍
    reg             parity_reg1         ;       // 奇偶校验位选择打拍
    reg             parity_reg2         ;       // 奇偶校验位选择打拍

    //FIFO信号
    reg             tx_fifo_read        ;       // 发FIFO读指令
    wire            tx_fifo_empty       ;       // 发FIFO空
    wire     [7:0]  tx_out_data         ;       // 发串口FIFO输出并行数据

    //状态机
    reg     [2:0]   state               ;       // 发串口状态
    reg             fifo_state          ;       // 发串口FIFO状态
    reg     [14:0]  buad_cnt            ;       // 波特率计数器
    reg             bit_flag            ;       // 发送标志位
    reg     [3:0]   bit_cnt             ;       // 串行数据发送位数
    wire    [14:0]  buad_cnt_max        ;       // 波特率计数器计数上限

    //异步信号打拍
    always @(posedge clk or negedge tx_rstn)
    begin
        if (!tx_rstn)
        begin
            check_reg1      <= 1'b0;
            check_reg2      <= 1'b0;
            parity_reg1     <= 1'b0;
            parity_reg2     <= 1'b0;
        end
        else
        begin

            check_reg1      <= check            ;
            check_reg2      <= check_reg1       ;
            parity_reg1     <= parity           ;
            parity_reg2     <= parity_reg1      ;
        end
    end

    UART_FIFO_sync  RX_FIFO
                    (
                        .clk      (clk             ),       // 时钟
                        .rstn     (tx_rstn         ),       // 复位
                        .fifo_rstn(tx_rstn         ),       // FIFO 复位
                        .read     (tx_fifo_read    ),       // FIFO 读信号
                        .write    (tx_fifo_write   ),       // FIFO 写信号
                        .data_i   (tx_in_data      ),       // 数据输入

                        .wfull    (tx_fifo_full    ),       // FIFO 满标志位
                        .rempty   (tx_fifo_empty   ),       // FIFO 满标志位
                        .data_o   (tx_out_data     ),       // FIFO 输出数据
                        .fifo_cnt (tx_fifo_cnt     )        // FIFO 数据量
                    );

    // 发串口状态机
    always@(posedge clk or negedge tx_rstn)
    begin
        if(!tx_rstn)
        begin
            tx_ack       <= 1'b0;
            tx_fifo_read <= 1'b0;
            fifo_state   <= 1'b0;
        end
        else
        begin
            case(fifo_state)
                1'b0:
                begin
                    if(!tx_fifo_empty && tx_start)
                    begin
                        tx_ack       <= 1'b1    ;
                        tx_fifo_read <= 1'b1    ;
                        fifo_state   <= 1'b1    ;
                    end
                end
                1'b1:
                begin
                    tx_fifo_read <= 1'b0;
                    if(!tx_start)
                    begin
                        tx_ack      <= 1'b0 ;
                        fifo_state  <= 1'b0 ;
                    end
                end
            endcase
        end
    end

    // 状态跳转
    always @(posedge clk or negedge tx_rstn)
    begin
        if (!tx_rstn)
        begin
            state <= IDLE;
        end
        begin
            case (state)
                IDLE :
                begin
                    if (tx_ack)
                    begin
                        state <= START;
                    end
                    else
                    begin
                        state <= IDLE;
                    end
                end
                START:
                begin
                    if (bit_flag)
                    begin
                        state <= TX;
                    end
                    else
                    begin
                        state <= START;
                    end
                end
                TX   :
                begin
                    if (bit_cnt < data_length)
                    begin
                        state <= TX;
                    end
                    else
                    begin
                        if (check_reg2)
                        begin
                            state <= CHECK;
                        end
                        else
                        begin
                            state <= STOP;
                        end
                    end
                end
                CHECK:
                begin
                    if (bit_flag)
                    begin
                        state <= STOP;
                    end
                    else
                    begin
                        state <= CHECK;
                    end
                end
                STOP :
                begin
                    if (bit_flag)
                    begin
                        state <= IDLE;
                    end
                end
                default:
                    state <= IDLE;
            endcase
        end
    end

    // 信号定义
    always @(posedge clk or negedge tx_rstn)
    begin
        if (!tx_rstn)
        begin
            tx_start <= 1'b1;
            bit_cnt <= 4'b0;
            tx <= 1'b1;
            tx_work <= 1'b0;
        end
        begin
            case (state)
                IDLE :
                begin
                    tx_start    <= 1'b1;
                    tx_work     <= 1'b0;
                    tx          <= 1'b1;
                    bit_cnt     <= 4'b0;
                end
                START:
                begin
                    tx_start    <= 1'b0;
                    tx_work     <= 1'b1;
                    tx          <= 1'b0;
                end
                TX   :
                begin
                    if (bit_flag)
                    begin
                        bit_cnt <= bit_cnt + 1'b1;
                        tx <= tx_out_data[bit_cnt[3:0]];
                    end
                end
                CHECK:
                begin
                    if (check_reg2)
                    begin
                        if (parity_reg2)
                        begin
                            case (data_length)
                                4'd8:
                                    tx    <=  ^~tx_out_data[7:0];
                                4'd7:
                                    tx    <=  ^~tx_out_data[6:0];
                                4'd6:
                                    tx    <=  ^~tx_out_data[5:0];
                                4'd5:
                                    tx    <=  ^~tx_out_data[4:0];
                                default:
                                    tx    <=  1'bx;
                            endcase
                        end
                        else
                        begin
                            case (data_length)
                                4'd8:
                                    tx    <=  ^tx_out_data[7:0];
                                4'd7:
                                    tx    <=  ^tx_out_data[6:0];
                                4'd6:
                                    tx    <=  ^tx_out_data[5:0];
                                4'd5:
                                    tx    <=  ^tx_out_data[4:0];
                                default:
                                    tx    <=  1'bx;
                            endcase
                        end
                    end
                end
                STOP :
                begin
                    tx <= 1'b1;
                end
                default:
                    tx <= 1'b0;
            endcase
        end
    end


    //波特计数器
    always @(posedge clk or negedge tx_rstn)
    begin
        if (tx_rstn == 1'b0)
            buad_cnt <= 14'd0;
        else if ((buad_cnt == buad_cnt_max - 1) || (tx_work == 1'b0))
            buad_cnt <= 14'd0;
        else
            buad_cnt <= buad_cnt + 1'b1;
    end

    //数据读取标志位
    always @(posedge clk or negedge tx_rstn)
    begin
        if (tx_rstn == 1'b0)
            bit_flag <= 1'd0;
        else if(buad_cnt == buad_cnt_max/2 - 1)
            bit_flag <= 1'b1;
        else
            bit_flag <= 1'd0;
    end

    assign  buad_cnt_max = CLK_FREQ / uart_buad;
endmodule
