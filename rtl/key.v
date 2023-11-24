//按键消抖模块,对板载按键消抖
module key(
    input   wire    sys_clk,
    input   wire    sys_rst_n,
    input   wire    [3:0]   key_i,
    output  reg     [3:0]   key_o
);

reg [19:0] cnt_20ms;
reg        key_flag;

localparam CNT_MAX = 20'd999_999;


always@(posedge sys_clk,negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        cnt_20ms <= 20'b0;
    else if(key_i == 4'b1111)
        cnt_20ms <= 20'b0;
    else if(cnt_20ms == CNT_MAX && key_i != 4'b1111) //如果抖动，计数器继续清零
        cnt_20ms <= cnt_20ms;
    else 
        cnt_20ms <= cnt_20ms + 1;
end

always@(posedge sys_clk,negedge sys_rst_n)  begin
    if(sys_rst_n == 1'b0)
        key_flag <=1'b0;
    else if(cnt_20ms == CNT_MAX-1'b1)
        key_flag <=1'b1;
    else 
        key_flag <=1'b0;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        key_o <= 4'b0;
    else if(key_flag) begin
        if(!key_i[0])
            key_o <= 4'd3;
        else if(!key_i[1])
            key_o <= 4'd2;
        else if(!key_i[2])
            key_o <= 4'd1;
        else if(!key_i[3])
            key_o <= 4'd0;
        else
            key_o <= key_o;
    end
end

endmodule