module lcd_driver(
    input              lcd_clk,      //lcd模块驱动时钟
	input              sys_rst_n,    //复位信号
	input      [15:0]  lcd_id,       //LCD屏ID
	input      [15:0]  pixel_data,   //像素点数据
	output             data_req  ,   //请求像素点颜色数据输入 
	output     [10:0]  pixel_xpos,   //像素点横坐标
	output     [10:0]  pixel_ypos,   //像素点纵坐标
	output reg [10:0]  h_disp,       //LCD屏水平分辨率
	output reg [10:0]  v_disp,       //LCD屏垂直分辨率 
	output             out_vsync,    //帧复位，高有效   
	//RGB LCD接口                          
	output             lcd_hs,       //LCD 行同步信号
	output             lcd_vs,       //LCD 场同步信号
	output reg         lcd_de,       //LCD 数据输入使能
	output reg [15:0]  lcd_rgb,      //LCD RGB565颜色数据
	output             lcd_bl,       //LCD 背光控制信号
	output             lcd_rst,      //LCD 复位信号
	output             lcd_pclk      //LCD 采样时钟   
    );

//parameter define  
// 4.3' 480*272
parameter  H_SYNC_4342   =  11'd41;     //行同步
parameter  H_BACK_4342   =  11'd2;      //行显示后沿
parameter  H_DISP_4342   =  11'd480;    //行有效数据
parameter  H_FRONT_4342  =  11'd2;      //行显示前沿
parameter  H_TOTAL_4342  =  11'd525;    //行扫描周期
   
parameter  V_SYNC_4342   =  11'd10;     //场同步
parameter  V_BACK_4342   =  11'd2;      //场显示后沿
parameter  V_DISP_4342   =  11'd272;    //场有效数据
parameter  V_FRONT_4342  =  11'd2;      //场显示前沿
parameter  V_TOTAL_4342  =  11'd286;    //场扫描周期
  
// 4.3' 800*480   
parameter  H_SYNC_4384   =  11'd128;    //行同步
parameter  H_BACK_4384   =  11'd88;     //行显示后沿
parameter  H_DISP_4384   =  11'd800;    //行有效数据
parameter  H_FRONT_4384  =  11'd40;     //行显示前沿
parameter  H_TOTAL_4384  =  11'd1056;   //行扫描周期
   
parameter  V_SYNC_4384   =  11'd2;      //场同步
parameter  V_BACK_4384   =  11'd33;     //场显示后沿
parameter  V_DISP_4384   =  11'd480;    //场有效数据
parameter  V_FRONT_4384  =  11'd10;     //场显示前沿
parameter  V_TOTAL_4384  =  11'd525;    //场扫描周期    

//reg define
reg  [10:0] h_sync ;
reg  [10:0] h_back ;
reg  [10:0] h_total;
reg  [10:0] v_sync ;
reg  [10:0] v_back ;
reg  [10:0] v_total;
reg  [10:0] h_cnt  ;
reg  [10:0] v_cnt  ;

//wire define    
wire       lcd_en;


//*****************************************************
//**                    main code
//*****************************************************
assign lcd_bl   = 1'b1;           //RGB LCD显示模块背光控制信号
assign lcd_rst  = 1'b1;           //RGB LCD显示模块系统复位信号
assign lcd_pclk = lcd_clk;        //RGB LCD显示模块采样时钟

//RGB LCD 采用数据输入使能信号同步时，行场同步信号需要拉高
assign lcd_hs  = h_cnt >= h_sync;
assign lcd_vs  = v_cnt >= v_sync;

//使能RGB565数据输出
assign  lcd_en = ((h_cnt >= h_sync + h_back) && (h_cnt < h_sync + h_back + h_disp)
				&& (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp)) 
				? 1'b1 : 1'b0;

//帧复位，高有效               
assign out_vsync = ((h_cnt <= 100) && (v_cnt == 1)) ? 1'b1 : 1'b0;
				
//请求像素点颜色数据输入,从sdram读取数据  
assign data_req = ((h_cnt >= h_sync + h_back - 1'b1) && (h_cnt < h_sync + h_back + h_disp - 1'b1)
				&& (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp)) 
				? 1'b1 : 1'b0;

//像素点坐标  
assign pixel_xpos = data_req ? (h_cnt - (h_sync + h_back - 1'b1)) : 11'd0;
assign pixel_ypos = data_req ? (v_cnt - (v_sync + v_back - 1'b1)) : 11'd0;


//LCD输入的颜色数据采用数据输入使能信号同步
always@ (posedge lcd_clk or negedge sys_rst_n) begin
	if(!sys_rst_n) 
		lcd_de <= 11'd0;
	else begin
		lcd_de <= lcd_en;  
	end    
end

//RGB565数据输出 
always@ (posedge lcd_clk or negedge sys_rst_n) begin
	if(!sys_rst_n) 
		lcd_rgb <= 16'd0;
	else begin
		if(lcd_en)
			lcd_rgb <= pixel_data;	
		else
			lcd_rgb <= 16'd0;		
	end    
end

//行场时序参数
always @(posedge lcd_pclk) begin
    case(lcd_id)
        16'h4342 : begin
            h_sync  <= H_SYNC_4342; 
            h_back  <= H_BACK_4342; 
            h_disp  <= H_DISP_4342; 
            h_total <= H_TOTAL_4342;
            v_sync  <= V_SYNC_4342; 
            v_back  <= V_BACK_4342; 
            v_disp  <= V_DISP_4342; 
            v_total <= V_TOTAL_4342;            
        end
        16'h4384 : begin
            h_sync  <= H_SYNC_4384; 
            h_back  <= H_BACK_4384; 
            h_disp  <= H_DISP_4384; 
            h_total <= H_TOTAL_4384;
            v_sync  <= V_SYNC_4384; 
            v_back  <= V_BACK_4384; 
            v_disp  <= V_DISP_4384; 
            v_total <= V_TOTAL_4384;             
        end        
        default : begin
            h_sync  <= H_SYNC_4384; 
            h_back  <= H_BACK_4384; 
            h_disp  <= H_DISP_4384; 
            h_total <= H_TOTAL_4384;
            v_sync  <= V_SYNC_4384; 
            v_back  <= V_BACK_4384; 
            v_disp  <= V_DISP_4384; 
            v_total <= V_TOTAL_4384;        
        end
    endcase
end


//行计数器对像素时钟计数
always@ (posedge lcd_pclk or negedge sys_rst_n) begin
	if(!sys_rst_n) 
		h_cnt <= 11'd0;
	else begin
		if(h_cnt == h_total - 1'b1)
			h_cnt <= 11'd0;
		else
			h_cnt <= h_cnt + 1'b1;           
	end
end

//场计数器对行计数
always@ (posedge lcd_clk or negedge sys_rst_n) begin
	if(!sys_rst_n) 
		v_cnt <= 11'd0;
	else begin
		if(h_cnt == h_total - 1'b1) begin
			if(v_cnt == v_total - 1'b1)
				v_cnt <= 11'd0;
			else
				v_cnt <= v_cnt + 1'b1;    
		end
	end    
end

endmodule
