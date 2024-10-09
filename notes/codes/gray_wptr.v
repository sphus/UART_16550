
parameter SIZE = 4
          ) (
              input  clk,
              input  rstn,

          );
reg [SIZE :
     0]   wbin,wbnext;
reg [SIZE :
     0]   wptr,wgnext;

always @(posedge clk or negedge rstn)
begin
    if (!rstn)
    begin
        wbin    <= 'd0;
        wptr    <=  'd0;
    end
    else
    begin
        wbin <= wbnext;
        wptr[SIZE-1:0]    <= wgnext[SIZE-1:0];
    end
end

always@(*)  wptr[SIZE]  = wbin[SIZE];

    assign wbnext = !wfull ? wbin + winc : wbin;
    assign wgnext[SIZE-1:
              0] = (wbnext[SIZE-1:0]>>1) ^ wbnext[SIZE-1:
                                                      0];

