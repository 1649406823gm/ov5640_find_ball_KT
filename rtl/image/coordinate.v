//目标物体坐标提取模块,接受来自lcd的输出时序
module coordinate(
    input           clk,
    input           rst_n,

    //图像处理前的数据接口
    //来自lcd的时序信号
    input           vsync_i,
    input           hsync_i,
    input           data_en_i,
    
    input           data_i,
    
    //串口测试接口
    // output  reg [15:0] valid_num_cnt,
    
    //图像处理后的数据接口,提供给舵机
    output  [9:0]   x_coor,
    output  [9:0]   y_coor,
    output          coor_valid_flag
);

reg data_en_i_pos	;
reg data_en_i_r1	;

reg vsync_i_pos		;
reg vsync_i_neg		;
reg vsync_i_r1		;


//有效像素点计数和有效物体有效标志
reg [15:0] valid_num_cnt;
reg 	   valid_flag;

//x和y坐标总和
reg	[31:0] x_coor_all;
reg	[31:0] y_coor_all;

//行和列计数
reg [9:0]  row_cnt;
reg [9:0]  col_cnt;	


always @(posedge clk or negedge rst_n) begin
    data_en_i_r1 <= data_en_i;
end
//数据有效上升沿,对列计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_en_i_pos <= 1'b0;
    else if(~data_en_i_r1 && data_en_i)
        data_en_i_pos <= 1'b1;
    else
        data_en_i_pos <= 1'b0;
end


always @ (posedge clk) begin	
	vsync_i_r1 <= vsync_i;
end
//场有效上降沿
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n)
		vsync_i_pos <= 1'b0;
	else if (~vsync_i_r1 && vsync_i)
	    vsync_i_pos <= 1'b1;    
	else	
        vsync_i_pos <= 1'b0;
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n)
		vsync_i_neg <= 1'b0;
	else if (vsync_i_r1 && ~vsync_i)
	    vsync_i_neg <= 1'b1;    
	else	
        vsync_i_neg <= 1'b0;
end


//列计数
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		col_cnt <= 10'd0;
	else if(data_en_i)
		col_cnt <= col_cnt + 1'b1;
	else 	
		col_cnt <= 10'd0;
end

//行计数
//always @(posedge clk or negedge rst_n) begin
//	if(!rst_n)
//		row_cnt <= 10'd0;
//	else if(vsync_i_neg)
//		row_cnt <= 10'd0;
//	else if (data_en_i_pos)	
//		row_cnt <= row_cnt + 1'b1;
//end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		row_cnt <= 10'd0;
	else if(col_cnt == 10'd800 - 1'b1)
		row_cnt <= row_cnt + 1'b1;
	else if(row_cnt == 10'd480)	
		row_cnt <= 10'd0;
end



//目标数据计数
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n)
		valid_num_cnt <= 16'd0;
	else if (vsync_i_neg == 1'b1)
		valid_num_cnt <= 16'd0;   
	else if (data_en_i == 1'b1 && data_i == 1'b1)
		valid_num_cnt <= valid_num_cnt + 1'b1;   
end


//目标有效标志
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        valid_flag <= 1'b0;
    else if(vsync_i_neg == 1'b1)
        valid_flag <= 1'b0;
    else if(valid_num_cnt >= 16'd1500)
        valid_flag <= 1'b1;
end     

//x坐标求和
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n)
		x_coor_all <= 32'd0;
	else if (data_en_i == 1'b1 && data_i == 1'b1)
	    x_coor_all <=  x_coor_all +  col_cnt;  
	else if (vsync_i_neg == 1'b1)
	    x_coor_all <= 32'd0;    	   
end


//y坐标求和
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n)
		y_coor_all <= 32'd0;
	else if (data_en_i == 1'b1 && data_i == 1'b1)
	    y_coor_all <=  y_coor_all +  row_cnt;  
	else if (vsync_i_neg == 1'b1)
	    y_coor_all <= 32'd0;    	   
end

assign x_coor =  (vsync_i == 1'b1 ) ? x_coor_all / valid_num_cnt : 10'd0;
assign y_coor =  (vsync_i == 1'b1 ) ? y_coor_all / valid_num_cnt : 10'd0;
assign coor_valid_flag = valid_flag && vsync_i;

endmodule