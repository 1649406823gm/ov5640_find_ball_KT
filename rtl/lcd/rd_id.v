//根据不同的屏幕输出不同的lcd_id
module rd_id(
    input   wire        clk,
    input   wire        rst_n,
    input   wire [15:0] lcd_rgb,
    output  reg  [15:0] lcd_id
);

reg rd_flag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_flag <= 1'b0;
        lcd_id  <= 16'd0;
    end
    else begin
        if(rd_flag == 1'b0) begin //只获取一次id
            rd_flag <= 1'b1;
            case({lcd_rgb[4],lcd_rgb[10],lcd_rgb[15]})
                3'b000:lcd_id <= 16'h4342;      //4.3寸,480*272
                3'b100:lcd_id <= 16'h4384;      //4.3寸,800*480
                default :lcd_id <= 16'h0;
            endcase
        end
    end
end

endmodule