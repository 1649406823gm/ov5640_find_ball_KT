//图像膨胀算法
module dialate_disp(
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
    output  [15:0]  dialate_data_o
);


wire matrix_11,matrix_12,matrix_13,matrix_21,matrix_22,matrix_23,matrix_31,matrix_32,matrix_33;

reg dialate,dialate_1,dialate_2,dialate_3;

reg [2:0] vsync_i_r;
reg [2:0] hsync_i_r;
reg [2:0] data_en_i_r;


matrix_3x3_16bit matrix_3x3_16bit_inst(
    .clk                (clk),
    .rst_n              (rst_n),

    //图像处理前的数据接口
    .vsync_i            (vsync_i),    //vsync信号
    .hsync_i            (hsync_i),     //hsync信号
    .clk_en_i           (data_en_i),
    .data_i             (erode_data_i),           //之前的数据

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
        dialate_1 <= 'd0;
        dialate_2 <= 'd0;
        dialate_3 <= 'd0;
    end
    else begin
        dialate_1 <= matrix_11 || matrix_12 || matrix_13;
        dialate_2 <= matrix_21 || matrix_22 || matrix_23;
        dialate_3 <= matrix_31 || matrix_32 || matrix_33;
    end
end

always @ (posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        dialate <= 'd0;
    end
    else begin
        dialate <= dialate_1 || dialate_2 || dialate_3;
    end
end

assign dialate_data_o = dialate ? 16'hffff : 16'h0000;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_en_i_r <= 0;
        hsync_i_r <= 0;
        vsync_i_r <= 0; 
    end
    else begin
        data_en_i_r <= {data_en_i_r[1:0],data_en_i};
        hsync_i_r <= {hsync_i_r[1:0],hsync_i};
        vsync_i_r <= {vsync_i_r[1:0],vsync_i};
    end
end

assign data_en_o = data_en_i_r[2];
assign hsync_o = hsync_i_r[2];
assign vsync_o = vsync_i_r[2];




endmodule