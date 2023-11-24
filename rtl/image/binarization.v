//二值化操作
module binarization(
    input           clk,
    input           rst_n,

    //图像处理前的数据接口
    input           ycbcr_vsync,    //vsync信号
    input           ycbcr_hsync,     //hsync信号
    input           ycbcr_de,       //数据使能信号
    input   [7:0]   luminance,      //亮度数据
    input   [7:0]   cb_data,
    input   [7:0]   cr_data,

    //图像处理后的数据接口
    output          post_vsync,
    output          post_hsync,
    output          post_de,     
    output reg      monoc, //1=白，0=黑

    //串口阈值调试接口
    input  [7:0]    data1_up,
    input  [7:0]    data1_down,
    input  [7:0]    data2_up,
    input  [7:0]    data2_down
);


reg ycbcr_vsync_d;
reg ycbcr_hsync_d;
reg ycbcr_de_d;

assign post_vsync = ycbcr_vsync_d;
assign post_hsync = ycbcr_hsync_d;
assign post_de = ycbcr_de_d;


//阈值
localparam              cb_up   =       8'hff ;
localparam              cb_down =       8'h00  ;
localparam              cr_up   =       8'hff ;
localparam              cr_down =       8'haf ;



//二值化
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        monoc <= 1'b0;
    else if((cb_data > cb_down) && (cb_data < cb_up) && (cr_data > cr_down) && (cr_data < cr_up)) //阈值
        monoc <= 1'b1;
    else
        monoc <= 1'b0;
end

// //二值化阈值调试
//always @(posedge clk or negedge rst_n) begin
//    if(!rst_n)
//        monoc <= 1'b0;
//    else if((cb_data > data1_down) && (cb_data < data1_up) && (cr_data > data2_down) && (cr_data < data2_up)) //阈值
//        monoc <= 1'b1;
//    else
//        monoc <= 1'b0;
//end

//延时一拍同步时钟信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ycbcr_hsync_d <= 1'b0;
        ycbcr_vsync_d <= 1'b0;
        ycbcr_de_d <= 1'b0;
    end
    else begin
        ycbcr_hsync_d <= ycbcr_hsync;
        ycbcr_vsync_d <= ycbcr_vsync;
        ycbcr_de_d <= ycbcr_de;
    end
end

endmodule