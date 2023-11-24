//图像腐蚀算法
module erode_disp(
    input           clk,
    input           rst_n,
    
    //图像处理前的数据接口
    input           vsync_i,    //vsync信号
    input           hsync_i,     //hsync信号
    input           data_en_i,       //数据使能信号
    input   [15:0]  erode_data_i,           //之前的数据
    
    //图像处理后的数据接口
    output          vsync_o,  //vsync信号
    output          hsync_o,   //hsync信号
    output          data_en_o,     //数据使能信号
    output  [15:0]  erode_data_o
);


wire matrix_11,matrix_12,matrix_13,matrix_21,matrix_22,matrix_23,matrix_31,matrix_32,matrix_33;

reg erode,erode_1,erode_2,erode_3;

reg [2:0] vsync_i_r;
reg [2:0] hsync_i_r;
reg [2:0] data_en_i_r;

wire matrix_frame_vsync;
wire matrix_frame_hsync;
wire matrix_frame_clken;

matrix_3x3_16bit matrix_3x3_16bit_inst(
    .clk                (clk),
    .rst_n              (rst_n),

    //图像处理前的数据接口
    .vsync_i            (vsync_i),    //vsync信号
    .hsync_i            (hsync_i),     //hsync信号
    .clk_en_i           (data_en_i),
    .data_i             (erode_data_i),           //之前的数据
    
    .matrix_frame_vsync (matrix_frame_vsync),
    .matrix_frame_hsync (matrix_frame_hsync),
    .matrix_frame_clken (matrix_frame_clken),

    //图像处理后的数据接口
    .matrix_11          (matrix_11),
    .matrix_12          (matrix_12),
    .matrix_13          (matrix_13),
    .matrix_21          (matrix_21),
    .matrix_22          (matrix_22),
    .matrix_23          (matrix_23),
    .matrix_31          (matrix_31),
    .matrix_32          (matrix_32),    
    .matrix_33          (matrix_33)
);    

always @ (posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        erode_1 <= 1'd0;
        erode_2 <= 1'd0;
        erode_3 <= 1'd0;
    end
    else begin
        erode_1 <= matrix_11 && matrix_12 && matrix_13;
        erode_2 <= matrix_21 && matrix_22 && matrix_23;
        erode_3 <= matrix_31 && matrix_32 && matrix_33;
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        erode <= 1'd0;
    end
    else begin
        erode <= erode_1 && erode_2 && erode_3;
    end
end

assign erode_data_o = erode ? 16'hffff : 16'h0000;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_en_i_r <= 0;
        hsync_i_r <= 0;
        vsync_i_r <= 0; 
    end
    else begin
        data_en_i_r <= {data_en_i_r[1:0],matrix_frame_clken};
        hsync_i_r   <= {hsync_i_r[1:0],matrix_frame_hsync};
        vsync_i_r   <= {vsync_i_r[1:0],matrix_frame_vsync};
    end
end

assign data_en_o = data_en_i_r[2];
assign hsync_o   = hsync_i_r[2];
assign vsync_o   = vsync_i_r[2];


// reg matrix_11,matrix_12,matrix_13,matrix_21,matrix_22,matrix_23,matrix_31,matrix_32,matrix_33;

// wire row1,row2,row3;

// reg data_flag;

// reg [2:0] vsync_i_r;
// reg [2:0] hsync_i_r;
// reg [2:0] data_en_i_r;



// shift_ip	shift_ip_inst (
// 	.clken ( data_en_i ),
// 	.clock ( clk ),
// 	.shiftin ( erode_data_i ),
// 	.shiftout (  ),
// 	.taps0x ( row1 ),
// 	.taps1x ( row2 ),
// 	.taps2x ( row3 )
// 	);

// always @(posedge clk) begin
//     matrix_11 <= row1;
//     matrix_12 <= matrix_11;
//     matrix_13 <= matrix_12;
// end
    
// always @(posedge clk) begin
//     matrix_21 <= row2;
//     matrix_22 <= matrix_21;
//     matrix_23 <= matrix_22;
// end

// always @(posedge clk) begin
//     matrix_31 <= row3;
//     matrix_32 <= matrix_31;
//     matrix_33 <= matrix_32;
// end

// //腐蚀
// always @(posedge clk or negedge rst_n) begin 
//     if(!rst_n)
//         data_flag <= 0;
//     else if((matrix_11 || matrix_12 ||
//        matrix_13 || matrix_21 || matrix_22 ||
//        matrix_23 || matrix_31 || matrix_32 || matrix_33) && data_en_i_r[2])
//         data_flag <= 1'b1;
//     else
//         data_flag <= 1'b0;    
// end
    
// always @(posedge clk) begin
//     data_en_i_r[0] <= data_en_i;
//     data_en_i_r[1] <= data_en_i_r[0];
//     data_en_i_r[2] <= data_en_i_r[1];
//     data_en_o <= data_en_i_r[2];
// end

// always @(posedge clk) begin
//     hsync_i_r[0] <= hsync_i;
//     hsync_i_r[1] <= hsync_i_r[0];
//     hsync_i_r[2] <= hsync_i_r[1];
//     hsync_o <= hsync_i_r[2];
// end

// always @(posedge clk) begin
//     vsync_i_r[0] <= vsync_i;
//     vsync_i_r[1] <= vsync_i_r[0];
//     vsync_i_r[2] <= vsync_i_r[1];
//     vsync_o <= vsync_i_r[2];
// end

// assign erode_data_o = data_flag ? 16'hFFFF : 16'h0000;

endmodule