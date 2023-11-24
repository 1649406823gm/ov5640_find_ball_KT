//rgb_lcd显示驱动,接受来自图像处理后的数据
module lcd_rgb_top(
    input           sys_clk      ,  //系统时钟
    input           sys_rst_n,      //复位信号  
    input           sys_init_done, 
    //lcd接口  
    output          lcd_clk,        //LCD驱动时钟    
    output          lcd_hs,         //LCD 行同步信号
    output          lcd_vs,         //LCD 场同步信号
    output          lcd_de,         //LCD 数据输入使能
    inout   [15:0]  lcd_rgb,        //LCD RGB颜色数据
    output          lcd_bl,         //LCD 背光控制信号
    output          lcd_rst,        //LCD 复位信号
    output          lcd_pclk,       //LCD 采样时钟
    output  [15:0]  lcd_id,         //LCD屏ID  
    output          out_vsync,      //lcd场信号 
    output  [10:0]  pixel_xpos,     //像素点横坐标
    output  [10:0]  pixel_ypos,     //像素点纵坐标        
    output  [10:0]  h_disp,         //LCD屏水平分辨率
    output  [10:0]  v_disp,         //LCD屏垂直分辨率 
    
    //图像处理部分
    output  [15:0]  pre_rgb, 
	input   [15:0]  post_rgb,
    input           post_de,
    
    input   [15:0]  data_in,        //数据输入   
    output          data_req       //请求数据输入
    );

//wire define
wire  [15:0] colour_rgb;            //输出的16位lcd数据
wire  [15:0] lcd_rgb_o ;            //LCD 输出颜色数据
wire  [15:0] lcd_rgb_i ;            //LCD 输入颜色数据
//*****************************************************
//**                    main code
//***************************************************** 
//RGB565数据输出    
assign lcd_rgb_o = post_de ? post_rgb   : 16'd0;
assign pre_rgb = lcd_de  ? colour_rgb : 16'd0;

//像素数据方向切换
assign lcd_rgb = post_de ?  lcd_rgb_o :  {16{1'bz}};
assign lcd_rgb_i = lcd_rgb;
            
//时钟分频模块  
//输入时钟为50Mhz，提供给lcd，lcd自带分频模块根据不同的lcd尺寸产生不同的时钟  
clk_div clk_div_inst(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_id                 (lcd_id   ),
    .lcd_pclk               (lcd_clk  )
    );  

//读LCD ID模块
rd_id rd_id_inst(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_rgb                (lcd_rgb_i),
    .lcd_id                 (lcd_id   )
    );  

//lcd驱动模块
lcd_driver lcd_driver_inst(           
    .lcd_clk        (lcd_clk),    
    .sys_rst_n      (sys_rst_n & sys_init_done), 
    .lcd_id         (lcd_id),   

    .lcd_hs         (lcd_hs),       
    .lcd_vs         (lcd_vs),       
    .lcd_de         (lcd_de),       
    .lcd_rgb        (colour_rgb),
    .lcd_bl         (lcd_bl),
    .lcd_rst        (lcd_rst),
    .lcd_pclk       (lcd_pclk),
    
    .pixel_data     (data_in), 
    .data_req       (data_req),
    .out_vsync      (out_vsync),
    .h_disp         (h_disp),
    .v_disp         (v_disp), 
    .pixel_xpos     (pixel_xpos), 
    .pixel_ypos     (pixel_ypos)
    ); 
                 
endmodule 