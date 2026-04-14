module lcd_hd44780 #(
    parameter integer CLK_HZ = 50000000
) (
    input  wire       clk,
    input  wire       resetn,
    input  wire       cmd_wr,
    input  wire [7:0] cmd_data,
    input  wire       data_wr,
    input  wire [7:0] data_data,
    output wire       busy,
    output wire [7:0] lcd_data,
    output wire       lcd_en,
    output wire       lcd_rw,
    output wire       lcd_rs,
    output wire       lcd_on
);
    localparam integer T_POWERUP_20MS = CLK_HZ / 50;
    localparam integer T_INIT_5MS     = CLK_HZ / 200;
    localparam integer T_INIT_100US   = CLK_HZ / 10000;
    localparam integer T_ENABLE_1US   = CLK_HZ / 1000000;
    localparam integer T_CMD_50US     = CLK_HZ / 20000;
    localparam integer T_CLEAR_2MS    = CLK_HZ / 500;

    localparam [2:0] ST_RESET_WAIT = 3'd0;
    localparam [2:0] ST_IDLE       = 3'd1;
    localparam [2:0] ST_E_HIGH     = 3'd2;
    localparam [2:0] ST_E_LOW      = 3'd3;
    localparam [2:0] ST_POST_WAIT  = 3'd4;

    reg [2:0]  state;
    reg [2:0]  init_index;
    reg        init_active;
    reg [31:0] counter;
    reg [31:0] post_delay;
    reg [7:0]  lcd_data_reg;
    reg        lcd_en_reg;
    reg        lcd_rs_reg;

    assign busy     = (state != ST_IDLE) || init_active;
    assign lcd_data = lcd_data_reg;
    assign lcd_en   = lcd_en_reg;
    assign lcd_rw   = 1'b0;
    assign lcd_rs   = lcd_rs_reg;
    assign lcd_on   = 1'b1;

    always @(posedge clk) begin
        if (!resetn) begin
            state       <= ST_RESET_WAIT;
            init_index  <= 3'd0;
            init_active <= 1'b1;
            counter     <= T_POWERUP_20MS;
            post_delay  <= 32'd0;
            lcd_data_reg <= 8'h00;
            lcd_en_reg  <= 1'b0;
            lcd_rs_reg  <= 1'b0;
        end else begin
            case (state)
                ST_RESET_WAIT: begin
                    if (counter != 0) begin
                        counter <= counter - 32'd1;
                    end else begin
                        state <= ST_IDLE;
                    end
                end

                ST_IDLE: begin
                    lcd_en_reg <= 1'b0;

                    if (init_active) begin
                        case (init_index)
                            3'd0: begin
                                lcd_data_reg <= 8'h38;
                                lcd_rs_reg   <= 1'b0;
                                post_delay   <= T_INIT_5MS;
                                init_index   <= 3'd1;
                            end
                            3'd1: begin
                                lcd_data_reg <= 8'h38;
                                lcd_rs_reg   <= 1'b0;
                                post_delay   <= T_INIT_100US;
                                init_index   <= 3'd2;
                            end
                            3'd2: begin
                                lcd_data_reg <= 8'h38;
                                lcd_rs_reg   <= 1'b0;
                                post_delay   <= T_CMD_50US;
                                init_index   <= 3'd3;
                            end
                            3'd3: begin
                                lcd_data_reg <= 8'h0C;
                                lcd_rs_reg   <= 1'b0;
                                post_delay   <= T_CMD_50US;
                                init_index   <= 3'd4;
                            end
                            3'd4: begin
                                lcd_data_reg <= 8'h01;
                                lcd_rs_reg   <= 1'b0;
                                post_delay   <= T_CLEAR_2MS;
                                init_index   <= 3'd5;
                            end
                            default: begin
                                lcd_data_reg <= 8'h06;
                                lcd_rs_reg   <= 1'b0;
                                post_delay   <= T_CMD_50US;
                                init_active  <= 1'b0;
                            end
                        endcase
                        counter      <= T_ENABLE_1US;
                        lcd_en_reg   <= 1'b1;
                        state        <= ST_E_HIGH;
                    end else if (cmd_wr || data_wr) begin
                        lcd_data_reg <= cmd_wr ? cmd_data : data_data;
                        lcd_rs_reg   <= data_wr;
                        post_delay   <= (cmd_wr && (cmd_data == 8'h01 || cmd_data == 8'h02)) ? T_CLEAR_2MS : T_CMD_50US;
                        counter      <= T_ENABLE_1US;
                        lcd_en_reg   <= 1'b1;
                        state        <= ST_E_HIGH;
                    end
                end

                ST_E_HIGH: begin
                    if (counter != 0) begin
                        counter <= counter - 32'd1;
                    end else begin
                        lcd_en_reg <= 1'b0;
                        counter    <= T_ENABLE_1US;
                        state      <= ST_E_LOW;
                    end
                end

                ST_E_LOW: begin
                    if (counter != 0) begin
                        counter <= counter - 32'd1;
                    end else begin
                        counter <= post_delay;
                        state   <= ST_POST_WAIT;
                    end
                end

                default: begin
                    if (counter != 0) begin
                        counter <= counter - 32'd1;
                    end else begin
                        state <= ST_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
