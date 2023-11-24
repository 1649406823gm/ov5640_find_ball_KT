module ycbcr_disp(
    input           clk,
    input           rst_n,

    //图像处理前的数据接口
    input           pre_frame_vsync,    //vsync信号
    input           pre_frame_hsync,     //hsync信号
    input           pre_frame_de,       //数据使能信号
    input   [4:0]   img_red,            //红色数据
    input   [5:0]   img_green,          //绿色数据
    input   [4:0]   img_blue,           //蓝色数据

    //图像处理后的数据接口
    output           post_frame_vsync,  //vsync信号
    output           post_frame_hsync,   //hsync信号
    output           post_frame_de,     //数据使能信号
    output   [7:0]   img_y,             
    output   [7:0]   img_cb,
    output   [7:0]   img_cr
);

reg [15:0] rgb_r_m0, rgb_r_m1, rgb_r_m2;
reg [15:0] rgb_g_m0, rgb_g_m1, rgb_g_m2;
reg [15:0] rgb_b_m0, rgb_b_m1, rgb_b_m2;

reg [15:0] img_y0;
reg [15:0] img_cb0;
reg [15:0] img_cr0;
reg [15:0] img_y1;
reg [15:0] img_cb1;
reg [15:0] img_cr1;

reg [2:0] pre_frame_vsync_d;
reg [2:0] pre_frame_hsync_d;
reg [2:0] pre_frame_de_d;

wire[7:0] rgb888_r, rgb888_g, rgb888_b;

//RGB565 to RGB 888
assign rgb888_r         = {img_red  , img_red[4:2]  };
assign rgb888_g         = {img_green, img_green[5:4]};
assign rgb888_b         = {img_blue , img_blue[4:2] };

//同步输出数据接口信号
assign post_frame_vsync = pre_frame_vsync_d[2];
assign post_frame_hsync = pre_frame_hsync_d[2];
assign post_frame_de    = pre_frame_de_d[2];

//localparam              cb_up   =       8'h80   ;
//localparam              cb_down =       8'h30   ;
//localparam              cr_up   =       8'hff   ;
//localparam              cr_down =       8'hc8   ;
//
//assign data_o           = (img_cb1 > cb_down && img_cb1 < cb_up && img_cr1 > cr_down && img_cr1 < cr_up) ? 8'hff : 8'h00 ;  //红色

assign img_y            = post_frame_hsync ? img_y1 : 8'd0;
assign img_cb           = post_frame_hsync ? img_cb1 : 8'd0;
assign img_cr           = post_frame_hsync ? img_cr1 : 8'd0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rgb_r_m0 <= 16'd0;
        rgb_r_m1 <= 16'd0;
        rgb_r_m2 <= 16'd0;
        rgb_g_m0 <= 16'd0;
        rgb_g_m1 <= 16'd0;
        rgb_g_m2 <= 16'd0;
        rgb_b_m0 <= 16'd0;
        rgb_b_m1 <= 16'd0;
        rgb_b_m2 <= 16'd0;
    end
    else begin //rgb888转化为ycbcr
        rgb_r_m0 <= rgb888_r * 8'd77;
        rgb_r_m1 <= rgb888_r * 8'd43;
        rgb_r_m2 <= rgb888_r << 3'd7;
        rgb_g_m0 <= rgb888_g * 8'd150;
        rgb_g_m1 <= rgb888_g * 8'd85;
        rgb_g_m2 <= rgb888_g * 8'd107;
        rgb_b_m0 <= rgb888_b * 8'd29;
        rgb_b_m1 <= rgb888_b << 3'd7;
        rgb_b_m2 <= rgb888_b * 8'd21;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img_y0  <= 16'd0;
        img_cb0 <= 16'd0;
        img_cr0 <= 16'd0;
    end
    else begin
        img_y0  <= rgb_r_m0 + rgb_g_m0 + rgb_b_m0;
        img_cb0 <= rgb_r_m1 - rgb_g_m1 - rgb_b_m1 + 16'd32768;
        img_cr0 <= rgb_r_m2 - rgb_g_m2 - rgb_b_m2 + 16'd32768;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img_y1  <= 8'd0;
        img_cb1 <= 8'd0;
        img_cr1 <= 8'd0;
    end
    else begin
        img_y1  <= img_y0[15:8];
        img_cb1 <= img_cb0[15:8];
        img_cr1 <= img_cr0[15:8];
    end
end
    
//同步信号延时,将各个信号延时3个周期
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin      
        pre_frame_hsync_d <= 3'd0;
        pre_frame_vsync_d <= 3'd0;
        pre_frame_de_d    <= 3'd0;
    end
    else begin
        pre_frame_hsync_d <= {pre_frame_hsync_d[1:0], pre_frame_hsync};
        pre_frame_vsync_d <= {pre_frame_vsync_d[1:0], pre_frame_vsync};
        pre_frame_de_d    <= {pre_frame_de_d[1:0], pre_frame_de};
    end
end
    
endmodule