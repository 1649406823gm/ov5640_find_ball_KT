//串口顶层模块,方便数据调试
module rs232(
    input   wire    clk,
    input   wire    rst_n,
        
    input   wire    rx,
    output  wire    tx,

    //作为坐标处理的接口
    input [7:0] tx_data,
    input       tx_trig,

    //调整目标图像的阈值接口
    output reg [7:0] data1_up,
    output reg [7:0] data1_down,
    output reg [7:0] data2_up,
    output reg [7:0] data2_down
);


parameter  UART_BPS = 14'd9600;
parameter  CLK_FREQ = 26'd50_000_000;

wire [7:0] po_data;
wire       po_flag;

reg [1:0]  byte_cnt;
reg [7:0]  cmd_data0;
reg [7:0]  cmd_data1;
reg [7:0]  uart_data_o;

uart_tx #(
    .UART_BPS(UART_BPS),
    .CLK_FREQ(CLK_FREQ)
) uart_tx_inst(
    .sys_clk(clk),
    .sys_rst_n(rst_n),
    .pi_data(tx_data),
    .pi_flag(tx_flag),
    .tx(tx)
);

uart_rx #(
    .UART_BPS(UART_BPS),
    .CLK_FREQ(CLK_FREQ)
) uart_rx_inst(
    .sys_clk(clk),
    .sys_rst_n(rst_n),
    .rx(rx),
    .po_data(po_data),
    .po_flag(po_flag)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        byte_cnt <= 2'd0;
    else if(po_flag)
        byte_cnt <= byte_cnt + 1'b1;
    else if(byte_cnt == 2'd4)
        byte_cnt <= 2'd0;     
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data1_up <= 8'd0;
        data1_down <= 8'd0;
        data2_up <= 8'd0;
        data2_down <= 8'd0;
    end
    else if(byte_cnt == 2'd0 && po_flag)
        data1_up <= po_data;
    else if(byte_cnt == 2'd1 && po_flag)
        data1_down <= po_data;
    else if(byte_cnt == 2'd2 && po_flag)
        data2_up <= po_data;
    else if(byte_cnt == 2'd3 && po_flag)
        data2_down <= po_data; 
end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n)
//         byte_cnt <= 2'd0;
//     else if(byte_cnt == 2'd2 && po_flag == 1'b1)
//         byte_cnt <= 2'd0;
//     else if(po_flag)
//         byte_cnt <= byte_cnt + 1'b1;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         cmd_data0 <= 8'd0;
//         cmd_data1 <= 8'd0;
//         uart_data_o <= 8'd0;
//     end    
//     else if(byte_cnt == 2'd0)
//         cmd_data0 <= po_data;
//     else if(byte_cnt == 2'd1)
//         uart_data_o <= po_data;
//     else if(byte_cnt == 2'd2)
//         cmd_data1 <= po_data;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n)
//         data1_up <= 8'd0;
//     else if(cmd_data0 == 8'h01 && cmd_data1 == 8'h01 && byte_cnt == 2'd2)
//         data1_up <= uart_data_o;
//     else
//         data1_up <= data1_up;
// end

// always @(posedge clk or negedge rst_n) begin 
// 	if(!rst_n)
// 		data1_down <= 8'd0;
// 	else if(cmd_data0 == 8'h02 && cmd_data1 == 8'h02 && byte_cnt == 2'd2)
// 		data1_down <= uart_data_o;
// 	else 
// 		data1_down <= data1_down;   
// end


// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		data2_up <= 8'd0;
// 	else if(cmd_data0 == 8'h03 && cmd_data1 == 8'h03 && byte_cnt == 2'd2)
// 		data2_up <= uart_data_o;
// 	else 
// 		data2_up <= data2_up;   
// end


// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		data2_down <= 8'd0;
// 	else if(cmd_data0 == 8'h04 && cmd_data1 == 8'h04 && byte_cnt == 2'd2)
// 		data2_down <= uart_data_o;
// 	else 
// 		data2_down <= data2_down;   
// end

endmodule