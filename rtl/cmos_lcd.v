module cmos_lcd(
    input   wire            sys_clk,
    input   wire            sys_rst_n,

	//按键接口
	input  [3:0]   			key_i,

    //串口部分
    input   wire            rx,
    output  wire            tx,

	//舵机
	output  wire            x_pwm,
	output  wire            y_pwm,

    //摄像头 
	input         cam_pclk   ,  //cmos 数据像素时钟
	input         cam_vsync  ,  //cmos 场同步信号
	input         cam_href   ,  //cmos 行同步信号
	input  [7:0]  cam_data   ,  //cmos 数据  
	output        cam_rst_n  ,  //cmos 复位信号，低电平有效
	output        cam_pwdn   ,  //cmos 电源休眠模式选择信号
	output        cam_scl    ,  //cmos SCCB_SCL线
	inout         cam_sda    ,  //cmos SCCB_SDA线
    
	//SDRAM 
	output        sdram_clk  ,  //SDRAM 时钟
	output        sdram_cke  ,  //SDRAM 时钟有效
	output        sdram_cs_n ,  //SDRAM 片选
	output        sdram_ras_n,  //SDRAM 行有效
	output        sdram_cas_n,  //SDRAM 列有效
	output        sdram_we_n ,  //SDRAM 写有效
	output [1:0]  sdram_ba   ,  //SDRAM Bank地址
	output [1:0]  sdram_dqm  ,  //SDRAM 数据掩码
	output [12:0] sdram_addr ,  //SDRAM 地址
	inout  [15:0] sdram_data ,  //SDRAM 数据    
	//LCD                   
	output        lcd_hs     ,  //LCD 行同步信号
	output        lcd_vs     ,  //LCD 场同步信号
	output        lcd_de     ,  //LCD 数据输入使能
	inout  [15:0] lcd_rgb    ,  //LCD RGB565颜色数据
	output        lcd_bl     ,  //LCD 背光控制信号
	output        lcd_rst    ,  //LCD 复位信号
	output        lcd_pclk      //LCD 采样时钟       
);
    
//物体坐标
wire [9:0] x_coor;
wire [9:0] y_coor;
    
parameter SLAVE_ADDR = 7'h3c          ; //OV5640的器件地址7'h3c
parameter BIT_CTRL   = 1'b1           ; //OV5640的字节地址为16位  0:8位 1:16位
parameter CLK_FREQ   = 27'd50_000_000 ; //i2c_dri模块的驱动时钟频率 
parameter I2C_FREQ   = 18'd250_000    ; //I2C的SCL时钟频率,不超过400KHz

wire        clk_100m       ;  //100mhz时钟,SDRAM操作时钟
wire        clk_100m_shift ;  //100mhz时钟,SDRAM相位偏移时钟
wire        clk_50m_lcd   ;   //100mhz时钟,LCD顶层模块时钟
wire        clk_lcd        ;  
wire        locked         ;
wire        rst_n          ;
wire        sys_init_done  ;  //系统初始化完成(sdram初始化+摄像头初始化)

wire        i2c_exec       ;  //I2C触发执行信号
wire [23:0] i2c_data       ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire        i2c_done       ;  //I2C寄存器配置完成信号
wire        i2c_dri_clk    ;  //I2C操作时钟
wire [ 7:0] i2c_data_r     ;  //I2C读出的数据
wire        i2c_rh_wl      ;  //I2C读写控制信号
wire        cam_init_done  ;  //摄像头初始化完成
						
wire        wr_en          ;  //sdram_ctrl模块写使能
wire [15:0] wr_data        ;  //sdram_ctrl模块写数据
wire        rd_en          ;  //sdram_ctrl模块读使能
wire [15:0] rd_data        ;  //sdram_ctrl模块读数据
wire        sdram_init_done;  //SDRAM初始化完成

wire [15:0] lcd_id         ;  //LCD的ID
wire [12:0] cmos_h_pixel   ;  //CMOS水平方向像素个数 
wire [12:0] cmos_v_pixel   ;  //CMOS垂直方向像素个数
wire [12:0] total_h_pixel  ;  //水平总像素大小
wire [12:0] total_v_pixel  ;  //垂直总像素大小
wire [23:0] sdram_max_addr ;  //sdram读写的最大地址

wire [15:0] color_rgb      ;

//图像处理后的数据接口
wire 		post_frame_hsync; //图像处理后的行同步信号
wire 		post_frame_vsync; //图像处理后的场同步信号
wire		post_frame_de;	    //图像处理后的数据使能信号
wire [15:0] post_rgb;			//图像处理后的数据

//输出 LOCK 信号，LOCK 信号拉高表示锁相环开始稳定输出时钟信号
//输出的 locked 信号与模拟生成的复位信号 sys_rst_n 取与，得到初始化模块复位信号
//rst_n，loclked 信号有效说明 IP 核输出时钟稳定，使用 rst_n 做复位信号可以保证模块正常
//工作时，输入时钟稳定；
assign  rst_n = sys_rst_n & locked;

//待 PLL 输出稳定之后，停止系统复位
//系统初始化完成：SDRAM和摄像头都初始化完成
//避免了在SDRAM初始化过程中向里面写入数据
assign  sys_init_done = sdram_init_done & cam_init_done;

//电源休眠模式选择 0：正常模式 1：电源休眠模式
assign  cam_pwdn  = 1'b0;
assign  cam_rst_n = 1'b1;

/**************************************************/
//锁相环
//产生时钟100mhz和100mhz -75度偏移时钟,50mhz时钟
pll pll_inst(
	.areset             (~sys_rst_n    ),
	.inclk0             (sys_clk       ),
			
	.c0                 (clk_100m      ),
	.c1                 (clk_100m_shift),
	.c2                 (clk_50m_lcd   ),
    //.c3                 (lcd_clk       ),
	.locked             (locked        )
);
/**************************************************/


/**************************************************/
//摄像头图像分辨率设置模块
//total_h_pixel/total_v_pixel:参数影响摄像头输出图像的帧率
//coms_h_pixel/cmos_v_pixel:参数影响摄像头输出图像的分辨率,与屏幕分辨率一致
//兼容不同分辨率屏幕
picture_size picture_size_inst (
	.clk                (clk_50m_lcd   ),
	.rst_n              (rst_n         ),
	.lcd_id             (lcd_id        ),   //LCD的ID，用于配置摄像头的图像大小                        
	.cmos_h_pixel       (cmos_h_pixel  ),   //摄像头水平方向分辨率 
	.cmos_v_pixel       (cmos_v_pixel  ),   //摄像头垂直方向分辨率  
	.total_h_pixel      (total_h_pixel ),   //用于配置HTS寄存器
	.total_v_pixel      (total_v_pixel ),   //用于配置VTS寄存器
	.sdram_max_addr     (sdram_max_addr)    //sdram读写的最大地址
);
/**************************************************/


/**************************************************/
//I2C配置模块
ov5640_cfg ov5640_cfg_inst(
	.clk                (i2c_dri_clk   ),
	.rst_n              (rst_n         ),
			
	.i2c_exec           (i2c_exec      ),
	.i2c_data           (i2c_data      ),
	.i2c_rh_wl          (i2c_rh_wl     ),  //I2C读写控制信号
	.i2c_done           (i2c_done      ), 
	.i2c_data_r         (i2c_data_r    ),   
				
	.cmos_h_pixel       (cmos_h_pixel  ),  //CMOS水平方向像素个数
	.cmos_v_pixel       (cmos_v_pixel  ),  //CMOS垂直方向像素个数
	.total_h_pixel      (total_h_pixel ),  //水平总像素大小
	.total_v_pixel      (total_v_pixel ),  //垂直总像素大小
		
	.init_done          (cam_init_done ) 
);   
/**************************************************/

/**************************************************/
//I2C驱动模块
i2c_dri #(
	.SLAVE_ADDR         (SLAVE_ADDR    ), //参数传递
	.CLK_FREQ           (CLK_FREQ      ),              
	.I2C_FREQ           (I2C_FREQ      ) 
)i2c_dri_inst(
	.clk                (clk_50m_lcd   ),
	.rst_n              (rst_n         ),

	.i2c_exec           (i2c_exec      ),   
	.bit_ctrl           (BIT_CTRL      ),   
	.i2c_rh_wl          (i2c_rh_wl     ), //固定为0，只用到了IIC驱动的写操作   
	.i2c_addr           (i2c_data[23:8]),   
	.i2c_data_w         (i2c_data[7:0] ),   
	.i2c_data_r         (i2c_data_r    ),   
	.i2c_done           (i2c_done      ),
	
	.scl                (cam_scl       ),   
	.sda                (cam_sda       ),   

	.dri_clk            (i2c_dri_clk   )  //I2C操作时钟
);
/**************************************************/

/**************************************************/
//CMOS图像数据采集模块
//VSYNC：场同步信号，由摄像头输出，用于标志一帧数据的开始与结束。
//VSYNC 的高电平作为一帧的同步信号，在低电平时输出的数据有效
//HREF 格式输出，当 HREF为高电平时，图像输出有效
ov5640_data ov5640_data_inst(    //系统初始化完成之后再开始采集数据 
	.rst_n              (rst_n & sys_init_done),
	
	.cam_pclk           (cam_pclk ),
	.cam_vsync          (cam_vsync),
	.cam_href           (cam_href ),
	.cam_data           (cam_data ),         
	
	.cmos_frame_vsync   (cmos_frame_vsync),
	.cmos_frame_href    (cmos_frame_href),
	.cmos_frame_valid   (wr_en    ),    //数据有效使能信号
	.cmos_frame_data    (wr_data  )     //有效数据 
);
/**************************************************/


//双时钟 FIFO 常用于跨时钟域的数据信号的传递
/**************************************************/
//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top sdram_top_inst(
	.ref_clk            (clk_100m),         //sdram 控制器参考时钟
	.out_clk            (clk_100m_shift),   //用于输出的相位偏移时钟
	.rst_n              (rst_n),            //系统复位
											
	//用户写端口                              
	.wr_clk             (cam_pclk),         //写端口FIFO: 写时钟
	.wr_en              (wr_en),            //写端口FIFO: 写使能
	.wr_data            (wr_data),          //写端口FIFO: 写数据
	.wr_min_addr        (24'd0),            //写SDRAM的起始地址
	.wr_max_addr        (sdram_max_addr),   //写SDRAM的结束地址
	.wr_len             (10'd512),          //写SDRAM时的数据突发长度
	.wr_load            (~rst_n),           //写端口复位: 复位写地址,清空写FIFO
											
	//用户读端口                              
	.rd_clk             (lcd_clk),          //读端口FIFO: 读时钟
	.rd_en              (rd_en),            //读端口FIFO: 读使能
	.rd_data            (rd_data),          //读端口FIFO: 读数据
	.rd_min_addr        (24'd0),            //读SDRAM的起始地址
	.rd_max_addr        (sdram_max_addr),   //读SDRAM的结束地址
	.rd_len             (10'd512),          //从SDRAM中读数据时的突发长度
	.rd_load            (~rst_n),           //读端口复位: 复位读地址,清空读FIFO
												
	//用户控制端口                                
	.sdram_read_valid   (1'b1),             //SDRAM 读使能
	.sdram_pingpang_en  (1'b1),             //SDRAM 乒乓操作使能
	.sdram_init_done    (sdram_init_done),  //SDRAM 初始化完成标志
											
	//SDRAM 芯片接口                                
	.sdram_clk          (sdram_clk),        //SDRAM 芯片时钟
	.sdram_cke          (sdram_cke),        //SDRAM 时钟有效
	.sdram_cs_n         (sdram_cs_n),       //SDRAM 片选
	.sdram_ras_n        (sdram_ras_n),      //SDRAM 行有效
	.sdram_cas_n        (sdram_cas_n),      //SDRAM 列有效
	.sdram_we_n         (sdram_we_n),       //SDRAM 写有效
	.sdram_ba           (sdram_ba),         //SDRAM Bank地址
	.sdram_addr         (sdram_addr),       //SDRAM 行/列地址
	.sdram_data         (sdram_data),       //SDRAM 数据
	.sdram_dqm          (sdram_dqm)         //SDRAM 数据掩码
);
/**************************************************/


/**************************************************/    
//lcd例化
//输入时钟为50Mhz，提供给lcd，lcd自带分频模块根据不同的lcd尺寸产生不同的时钟
//输出lcd时序信号,DE同步模式时,de为高时数据传输
lcd_rgb_top lcd_rgb_top_inst(
    .sys_clk               (clk_50m_lcd  ),
	.sys_rst_n             (rst_n ),
	.sys_init_done         (sys_init_done),		
						
	//lcd接口 				           
	.lcd_id                (lcd_id),                //LCD屏的ID号 
	.lcd_hs                (lcd_hs),                //LCD 行同步信号
	.lcd_vs                (lcd_vs),                //LCD 场同步信号
	.lcd_de                (lcd_de),                //LCD 数据输入使能
	.lcd_rgb               (lcd_rgb),               //LCD 颜色数据
	.lcd_bl                (lcd_bl),                //LCD 背光控制信号
	.lcd_rst               (lcd_rst),               //LCD 复位信号
	.lcd_pclk              (lcd_pclk),              //LCD 采样时钟
	.lcd_clk               (lcd_clk), 	            //LCD 驱动时钟
	//用户接口			           
	.out_vsync             (),                      //lcd场信号
	.h_disp                (),                      //行分辨率  
	.v_disp                (),                      //场分辨率  
	.pixel_xpos            (),
	.pixel_ypos            (),
    
    //输出给图像处理
    .pre_rgb               (color_rgb),
   
    //图像处理输入
	.post_rgb              (post_rgb),
	.post_de               (post_frame_de),
    
	.data_in               (rd_data),	            //rfifo输出数据
	.data_req              (rd_en)                  //请求数据输入
);
/**************************************************/


/**************************************************/
//串口例化    
// rs232 rs232_inst(
//     .sys_clk    (sys_clk),
//     .sys_rst_n  (sys_rst_n),
//     .send_data  (x_pos),
//     .rx         (rx),
//     .tx         (tx)
// );
/**************************************************/

/**************************************************/
//图像处理模块
//对存入sdarm的摄像头原始数据进行处理
image_top image_top_inst(    
	.clk				(lcd_clk),
	.rst_n				(rst_n),
    
    //输入串口时钟,需要50Mhz
    .uart_clk           (clk_50m_lcd),
    
    //串口
    .tx                 (tx),
    .rx                 (rx),
    
	//按键接口
	.key_i				(key_i),

	//图像处理前的数据接口
	.pre_frame_vsync	(lcd_vs),	//vsync信号,来自摄像头输出
	.pre_frame_hsync	(lcd_hs),	//hsync信号,来自摄像头输出
	.pre_frame_de		(lcd_de),	//数据使能信号
	.pre_rgb			(color_rgb),	//rgb888数据
   
	//图像处理后的数据接口
	.post_frame_vsync	(),	//vsync信号
	.post_frame_hsync	(),					//hsync信号
	.post_frame_de		(post_frame_de),	//数据使能信号
	.post_rgb			(post_rgb),			//rgb888数据

    //舵机接口，输出
    .x_coor				(x_coor),					//x坐标
	.y_coor				(y_coor),					//y坐标
    .coor_valid_flag    (coor_valid_flag)
);


/**************************************************/
//舵机控制模块
//输入来自坐标处理模块的坐标
servo_dri servo_dri_inst(
	.clk			    (sys_clk),
	.rst_n			    (rst_n),

	//输入坐标
	.x_pos			    (x_coor),
	.y_pos			    (y_coor),
	.coor_valid_flag    (coor_valid_flag),

	//舵机pwm
	.x_pwm		        (x_pwm),
	.y_pwm		        (y_pwm)
);
/**************************************************/



endmodule