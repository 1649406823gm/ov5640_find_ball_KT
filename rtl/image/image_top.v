//图像处理顶层模块
module image_top(
    input               clk,
    input               rst_n,
    
    //串口时钟
    input               uart_clk,
    
    //串口
    input               rx,
    output              tx,

    //按键接口
    input       [3:0]   key_i,
    //图像处理前的数据接口
    input               pre_frame_vsync,    //vsync信号
    input               pre_frame_hsync,     //hsync信号
    input               pre_frame_de,       //数据使能信号
    input       [15:0]  pre_rgb,

    //图像处理后的数据接口
    output  reg         post_frame_vsync,  //vsync信号
    output  reg         post_frame_hsync,   //hsync信号
    output  reg         post_frame_de,     //数据使能信号
    output  reg [15:0]  post_rgb, 

    //坐标提取后的数据接口
    output      [9:0]   x_coor,
    output      [9:0]   y_coor,
    output              coor_valid_flag
);

//按键接口
wire [3:0] key_o;

//转灰度图接口
wire [7:0] img_y;
wire [7:0] img_cb;
wire [7:0] img_cr;
wire ycbcr_vsync;
wire ycbcr_hsync;
wire ycbcr_de;

//二值化接口
wire monoc;
wire binarization_vsync;
wire binarization_hsync;
wire binarization_de;
// wire [7:0] binarization_data_o;

//图像腐蚀接口
wire [15:0] erode_data;
wire erode_vsync;
wire erode_hsync;
wire erode_de;

//图像膨胀接口
wire [15:0] dialate_data;
wire dialate_vsync;
wire dialate_hsync;
wire dialate_de;

//阈值调试接口
wire [7:0] data1_up;
wire [7:0] data1_down;
wire [7:0] data2_up;
wire [7:0] data2_down;

//坐标调试接口
wire [15:0] valid_num_cnt;
wire [9:0]  row_cnt;
wire [9:0]  col_cnt;
//形成rgb564的16位数据
// assign post_rgb = {2{binarization_data_o}};
// assign post_rgb = dialate_data;
// assign post_rgb = erode_data;
// assign post_rgb = {16{monoc}};
//assign post_rgb = {img_y[7:3],img_y[7:2],img_y[7:3]};

rs232 rs232_inst(
   .clk                 (uart_clk),
   .rst_n               (rst_n),

   .rx                  (rx),
   .tx                  (tx),
   
   .tx_data             (y_coor[7:0]),
   .tx_trig             (coor_valid_flag),

   .data1_up            (data1_up),
   .data1_down          (data1_down),
   .data2_up            (data2_up),
   .data2_down          (data2_down)
);

key key_inst(
    .sys_clk            (clk),
    .sys_rst_n          (rst_n),
    .key_i              (key_i),
    .key_o              (key_o)
);

ycbcr_disp ycbcr_disp_inst(
    .clk                (clk),
    .rst_n              (rst_n),

    //图像处理前的数据接口
    .pre_frame_vsync    (pre_frame_vsync),    //vsync信号
    .pre_frame_hsync    (pre_frame_hsync),     //hsync信号
    .pre_frame_de       (pre_frame_de),       //数据使能信号
    .img_red            (pre_rgb[15:11]),            //红色数据
    .img_green          (pre_rgb[10:5]),          //绿色数据
    .img_blue           (pre_rgb[4:0]),           //蓝色数据

    //图像处理后的数据接口
    .post_frame_vsync   (ycbcr_vsync),  //vsync信号
    .post_frame_hsync   (ycbcr_hsync),   //hsync信号
    .post_frame_de      (ycbcr_de),     //数据使能信号
    .img_y              (img_y),
    .img_cb             (img_cb),
    .img_cr             (img_cr)
);

// //二值化测试接口
// binarization binarization_inst(
//     .clk                (clk),
//     .rst_n              (rst_n),

//     //图像处理前的数据接口
//     .ycbcr_vsync        (ycbcr_vsync),    //vsync信号
//     .ycbcr_hsync        (ycbcr_hsync),     //hsync信号
//     .ycbcr_de           (ycbcr_de),       //数据使能信号
//     .luminance          (img_y),
//     .cb_data            (img_cb),
//     .cr_data            (img_cr),

//     //图像处理后的数据接口
//     .post_vsync         (post_frame_vsync),  //vsync信号
//     .post_hsync         (post_frame_hsync),   //hsync信号
//     .post_de            (post_frame_de),     //数据使能信号
//     .binarization_data_o (binarization_data_o),
//     .monoc              (monoc)
// );


binarization binarization_inst(
    .clk                (clk),
    .rst_n              (rst_n),

    //图像处理前的数据接口
    .ycbcr_vsync        (ycbcr_vsync),    //vsync信号
    .ycbcr_hsync        (ycbcr_hsync),     //hsync信号
    .ycbcr_de           (ycbcr_de),       //数据使能信号
    .luminance          (img_y),
    .cb_data            (img_cb),
    .cr_data            (img_cr),

    //图像处理后的数据接口
    .post_vsync         (binarization_vsync),  //vsync信号
    .post_hsync         (binarization_hsync),   //hsync信号
    .post_de            (binarization_de),     //数据使能信号
    .monoc              (monoc),

    //串口阈值调试接口
    .data1_up           (data1_up),
    .data1_down         (data1_down),
    .data2_up           (data2_up),
    .data2_down         (data2_down)
);

erode_disp erode_disp_inst(
    .clk                (clk),
    .rst_n              (rst_n),

    //图像处理前的数据接口
    .vsync_i            (binarization_vsync),    //vsync信号
    .hsync_i            (binarization_hsync),     //hsync信号
    .data_en_i          (binarization_de),       //数据使能信号
    .erode_data_i       ({16{monoc}}),

    //图像处理后的数据接口
    .vsync_o            (erode_vsync),
    .hsync_o            (erode_hsync),
    .data_en_o          (erode_de),
    .erode_data_o       (erode_data)
);


// dialate_disp dialate_disp_inst(
//     .clk                (clk),
//     .rst_n              (rst_n),

//     //图像处理前的数据接口
//     .vsync_i            (erode_vsync),    //vsync信号
//     .hsync_i            (erode_hsync),     //hsync信号
//     .data_en_i          (erode_de),       //数据使能信号
//     .erode_data_i       (erode_data),

//     //图像处理后的数据接口
//     .vsync_o            (post_frame_vsync),
//     .hsync_o            (post_frame_hsync),
//     .data_en_o          (post_frame_de),
//     .dialate_data_o     (dialate_data)
// );



//test
dialate_disp dialate_disp_inst(
    .clk                (clk),
    .rst_n              (rst_n),

    //图像处理前的数据接口
    .vsync_i            (erode_vsync),    //vsync信号
    .hsync_i            (erode_hsync),     //hsync信号
    .data_en_i          (erode_de),       //数据使能信号
    .erode_data_i       (erode_data),

    //图像处理后的数据接口
    .vsync_o            (dialate_vsync),
    .hsync_o            (dialate_hsync),
    .data_en_o          (dialate_de),
    .dialate_data_o     (dialate_data)
);

coordinate coordinate_inst(
     .clk               (clk),
     .rst_n             (rst_n),

     //图像处理前的数据接口
     .vsync_i           (dialate_vsync),    //vsync信号
     .hsync_i           (dialate_hsync),     //hsync信号
     .data_en_i         (dialate_de),       //数据使能信号
     .data_i            (dialate_data[0:0]),

     // .valid_num_cnt      (valid_num_cnt),
//     .row_cnt           (row_cnt),
//     .col_cnt           (col_cnt),

     //图像处理后的数据接口
     .x_coor            (x_coor),
     .y_coor            (y_coor),
     .coor_valid_flag   (coor_valid_flag)
);


//通过按键切换lcd不同输出,原图,二值化图,腐蚀图,膨胀图
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        post_rgb <= 16'b0;
        post_frame_vsync <= 1'b0;
        post_frame_hsync <= 1'b0;
        post_frame_de <= 1'b0;
    end
    else 
        case(key_o)
            4'd0: begin
                post_rgb         <= pre_rgb;
                post_frame_vsync <= pre_frame_vsync;
                post_frame_hsync <= pre_frame_hsync;
                post_frame_de    <= pre_frame_de;
            end
            4'd1: begin
                post_rgb         <= {16{monoc}};
                post_frame_vsync <= binarization_vsync;
                post_frame_hsync <= binarization_hsync;
                post_frame_de    <= binarization_de;
            end
            4'd2: begin
                post_rgb         <= erode_data;
                post_frame_vsync <= erode_vsync;
                post_frame_hsync <= erode_hsync;
                post_frame_de    <= erode_de;
            end
            4'd3: begin
                post_rgb         <= dialate_data;
                post_frame_vsync <= dialate_vsync;
                post_frame_hsync <= dialate_hsync;
                post_frame_de    <= dialate_de;
            end
            default : begin
                post_rgb         <= pre_rgb;
                post_frame_vsync <= pre_frame_vsync;
                post_frame_hsync <= pre_frame_hsync;
                post_frame_de    <= pre_frame_de;
            end
        endcase
end
endmodule