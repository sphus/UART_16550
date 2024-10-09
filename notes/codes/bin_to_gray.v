module bin_to_gary
    #(
         parameter SIZE = 4
     )
     (
         input  wire [SIZE-1:0]  bin,
         input  wire [SIZE-1:0]  gray
     );
    assign gray = {bin<<1}^bin;
endmodule
