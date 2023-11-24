module matrix_3x3_16bit(
	input				clk,
	input				rst_n,

	input           	vsync_i,    //vsync信号
    input           	hsync_i,     //hsync信号
	input				clk_en_i,
	input   [15:0] 		data_i,

    output              matrix_frame_vsync,
    output              matrix_frame_hsync,
    output              matrix_frame_clken,
    
	output reg [15:0] 	matrix_11,
	output reg [15:0] 	matrix_12,
	output reg [15:0] 	matrix_13,
	output reg [15:0] 	matrix_21,
	output reg [15:0] 	matrix_22,
	output reg [15:0] 	matrix_23,
	output reg [15:0] 	matrix_31,
	output reg [15:0] 	matrix_32,
	output reg [15:0] 	matrix_33
);

wire [15:0] row1_data;
wire [15:0] row2_data;

wire	   read_hsync;
wire       read_clken;

reg [15:0] row3_data;
reg [1:0] vsync_i_r;
reg [1:0] hsync_i_r;
reg [1:0] clk_en_i_r;

assign read_hsync = hsync_i_r[0];
assign read_clken = clk_en_i_r[0];
assign matrix_frame_clken = clk_en_i_r[1];
assign matrix_frame_hsync = hsync_i_r[1];
assign matrix_frame_vsync = vsync_i_r[1];


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		row3_data <= 0;
	else begin
		if(clk_en_i)
			row3_data <= data_i;
		else 
			row3_data <= row3_data;
	end
end

shift_ip	shift_ip_inst (
	.clken ( clk_en_i),
	.clock ( clk ),
	.shiftin ( data_i ),
	.shiftout (  ),
	.taps0x ( row2_data ),
	.taps1x ( row1_data )
	);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		{matrix_11,matrix_12,matrix_13} <= 48'h0;
		{matrix_21,matrix_22,matrix_23} <= 48'h0;
		{matrix_31,matrix_32,matrix_33} <= 48'h0;
	end
	else if(read_hsync) begin
		if(read_clken) begin
			{matrix_11,matrix_12,matrix_13} <= {matrix_12,matrix_13,row1_data};
			{matrix_21,matrix_22,matrix_23} <= {matrix_22,matrix_23,row2_data};
			{matrix_31,matrix_32,matrix_33} <= {matrix_32,matrix_33,row3_data};
		end
		else begin
			{matrix_11,matrix_12,matrix_13} <= {matrix_11,matrix_12,matrix_13};
			{matrix_21,matrix_22,matrix_23} <= {matrix_21,matrix_22,matrix_23};
			{matrix_31,matrix_32,matrix_33} <= {matrix_31,matrix_32,matrix_33};
		end
	end
	else begin
		{matrix_11,matrix_12,matrix_13} <= 48'h0;
		{matrix_21,matrix_22,matrix_23} <= 48'h0;
		{matrix_31,matrix_32,matrix_33} <= 48'h0;
	end
end

//将同步信号延迟两拍，做到同步
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		vsync_i_r <= 0;
		hsync_i_r <= 0;
		clk_en_i_r <= 0;
	end
	else begin
		vsync_i_r <= {vsync_i_r[0],vsync_i};
		hsync_i_r <= {hsync_i_r[0],hsync_i};
		clk_en_i_r <= {clk_en_i_r[0],clk_en_i};
	end
end

endmodule