
# UART设计与验证

# 项目概述

实现一个UART模块（Universal Asynchronous Receiver/Transmitter）模块，包括设计与验证两部分

## 项目需求

> - 具有系统和功能时钟域的复位功能
> - 数据传输满足通用串口时序，奇偶校验功能可配置
> - 波特率可任意配置,最高可配置为115200
> - 接收和发送FIFO复位单独可控，触发深度可配置
> - 数据收发中断功能可配置
> - 具有状态指示功能
> - 具有FIFO数据量指示功能

## 系统框图
![frame](https://github.com/sphus/UART_16550/blob/main/notes/images/frame.png)

## 设计

- **数据接收**
    - 根据波特率,奇偶校验设置,UART_RX接收数据，存放数据到RX FIFO，内含接收数据状态机。
- **数据发送**
    - 将需要发送的数据放到TX FIFO，根据波特率设置,UART_TX发送数据。内含发送数据状态机。

## 验证

- **数据接收**
    - 仿真环境的接收数据模型。
- **数据发送**
    - 仿真环境的发送数据模型。

# 信号同步部分

## 接收信号采用两级同步

- 两级同步
    - 方法：跨时钟域的信号上加上两级或多级同步触发器

## FIFO与串口信号传输采用握手信号法
 ![Handshake](https://github.com/sphus/UART_16550/blob/main/notes/images/Handshake.png)


# FIFO设计

First In First Out
先入先出队列

## 同步FIFO
框图

![FIFO_sync_frame](https://github.com/sphus/UART_16550/blob/main/notes/images/FIFO_sync_frame.png)
- FIFO深度
    - 深度设置为15
    - 数据宽度8bit
- 读写指针
    - rptr为读指针，指向下一个要读的地址
    - wptr为写指针，同样指向下一个要写的地址。
    - 有效的读写使能使读写指针递增。
- 空满信号产生
    - FIFO为空状态：rempty信号会拉起
    - 为了区分空满状态，将读写指针设置多1bit作为扩展位
        - 当FIFO为空时，读写指针完全相等；
        - 当FIFO为满时，读写指针最高位相反，低4位相等。
- FIFO数据状态指示
    - fifo_cnt，它的值为写指针与读指针的差值。表示FIFO中剩余的数据量

对应代码[UART_FIFO_sync.v](https://github.com/sphus/UART_16550/blob/main/notes/codes/UART_FIFO_sync.v)

# 格雷码实现状态机,读写指针
格雷码从一个数变为下一个数时只有一位发生变化，避免产生错误的空满标志。

格雷码与8421码的转换可见于[格雷码.md](https://github.com/sphus/UART_16550/blob/main/notes/格雷码.md)

# 串口接收部分

- 实现
    - 使用波特率计数器，计算发送数据频率
    - 接收状态机
    - 接收数据FIFO控制
        - 接收数据FIFO控制部分将接收完成的数据写入到RX_FIFO，在需要读取RX_FIFO时将FIFO数据读出
## 接收状态机

- IDLE
    - 状态机从IDLE状态开始，检测到uart_i的下降沿，进入START状态。
- START
    - START状态起始位是否为低（避免毛刺触发状态机），起始位正常即进入RX开始接收数据。
- RX
    - 接收满8bit后判断是否使能校验位，如使能，进入CHECK状态进行奇偶校验的判断；如不使能，直接进入停止状态STOP。
- CHECK
    - CHECK状态判断奇偶校验是否正确，不正确则发出p_error信号，在状态寄存器指示校验错误，待CPU处理返回p_error_ack后回到IDLE状态。如果正确，判断是否使能停止位检查；使能停止位检查则跳转到STOP状态；不使能则跳转到SEND状态。
- STOP
    - 在STOP状态检测停止位是否是高电平。如果是，表示停止位正确，跳转到SEND状态；如果不是，则发出st_error信号，在状态寄存器指示停止位错误，待CPU处理返回st_error_ack后回到IDLE状态。
- SEND
    - SEND状态主要是产生rx_start信号表示8bits数据接收正确，可以将数据写到接收FIFO。


<details>
    <summary>
    接收状态机框图
    </summary>
    <img src="https://github.com/sphus/UART_16550/blob/main/notes/images/UART_RX_state.png"/> 
</details>

## 接收FIFO部分

<details>
    <summary>
    接收FIFO状态机框图
    </summary>
    <img src="https://github.com/sphus/UART_16550/blob/main/notes/images/RX_FIFO_state.png"/> 
</details>

# 串口发送部分

- 实现
    - 使用波特率计数器，计算发送数据频率
    - 发送状态机
    - 发送数据FIFO控制
        - 发送数据FIFO控制部分将需要发送的数据写入到TX_FIFO，在TX_FIFO不为空时，将TX_FIFO数据按照发送位数与奇偶校验位设置，发送至TX输出串行数据。

## 发送状态机

- IDLE
    - 状态机从IDLE状态开始，检测到发TX_FIFO发出的tx_ack的信号，进入START状态。
- START
    - START状态等待波特率计数器产生的bit_flag，随后发送起始位低电平数据，进入RX状态。
- RX
    - 发送满data_length后判断是否使能校验位，如使能，进入CHECK状态进行奇偶校验发送；如不使能，直接进入停止状态STOP。
- CHECK
    - CHECK状态依据parity判断奇偶校验位，如果是1则输出奇校验位，如果是0则输出偶校验位。等待波特率计数器产生的bit_flag，随后发送数据，进入STOP状态。
- STOP
    - START状态等待波特率计数器产生的bit_flag，随后发送停止位高电平数据，回到IDLE状态。

<details>
    <summary>
    发送状态机框图
    </summary>
    <img src="https://github.com/sphus/UART_16550/blob/main/notes/images/UART_TX_state.png"/> 
</details>

## 发送FIFO部分

<details>
    <summary>
    发送FIFO状态机框图
    </summary>
    <img src="https://github.com/sphus/UART_16550/blob/main/notes/images/TX_FIFO_state.png"/> 
</details>

# 待完成功能

- APB总线
    - 用寄存器配置串口模块,使用APB总线规范,实现实际芯片级的应用
    - 类似使用IIC配置寄存器,初始化OV2640,OV5640摄像头
- Testcase产生
    - 通过不同的激励或配置产生不同的case,验证时序和功能是否符合。