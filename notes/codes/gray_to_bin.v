module gray_to_bin#(
        parameter SIZE  =   4
    )(
        input  wire     [SIZE-1:0]   gray,
        output reg      [SIZE-1:0]   bin
    );
    integer i;
    always @(*)
    begin
        for(i=0;i<=SIZE;i=i+1)
            bin = ^(gray>i);
    end
endmodule
