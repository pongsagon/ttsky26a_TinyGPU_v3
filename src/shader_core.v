//`timescale 1ns / 1ps

/* Matt pongsagon

    Shader instruction
        - shader_instr, reverse file byte order
            b1 in file = 0001_1011 here
        - 0000_0000: nop, fall in default case
        - 4 pixel pipeline, SIMD lock step
        - SIMD branching using masked execution
            normal
                if(a<b)
                    c = x...
                else
                    c = y...
            SIMD 
                c = x...
                d = y...
                if(a<b) // set 4-bit mask
                c = (mask)? c : d


*/


module shader_core (
    input   wire        clk,     
    input   wire        reset,  

    input   wire        exec,           // vsfs.v  send true for 1 clk
    input   wire [7:0]  shader_instr,
    output  reg  [3:0]  shader_addr,

    input   wire [3:0]  texel_0,
    input   wire [3:0]  texel_1,
    input   wire [3:0]  texel_2,
    input   wire [3:0]  texel_3,
    input   wire [7:0]  pixel_x,        // truncate to 0-255
    input   wire [7:0]  pixel_y,
    input   wire [7:0]  tri_idx,        // truncate to 0-255
    input   wire [3:0]  shade_color,
    input   wire [7:0]  frame_num,      // only count 0-255
    input   wire [7:0]  pixel_u_0,     
    input   wire [7:0]  pixel_v_0,
    input   wire [7:0]  pixel_u_1,
    input   wire [7:0]  pixel_v_1,
    input   wire [7:0]  pixel_u_2,
    input   wire [7:0]  pixel_v_2,
    input   wire [7:0]  pixel_u_3,
    input   wire [7:0]  pixel_v_3,

    output  reg  [3:0]  shader_color_0,
    output  reg  [3:0]  shader_color_1,
    output  reg  [3:0]  shader_color_2,
    output  reg  [3:0]  shader_color_3
    );

    // 8-bit registers x4 for x4 pixels
    reg [7:0] reg_p0 [3:0];     // for pixel 0
    reg [7:0] reg_p1 [3:0];
    reg [7:0] reg_p2 [3:0];
    reg [7:0] reg_p3 [3:0];

    // Conditional bit masking
    reg [3:0] mask;             // for pixel 0-3

    // Register arguments
    wire [1:0] arg0;
    wire [1:0] arg1;
    
    assign arg0 = shader_instr[1:0];
    assign arg1 = shader_instr[3:2];
    
    // Immediate value
    wire [3:0] imm;
    assign imm = shader_instr[3:0];

    // Program control
    reg fsm_state;

    always @(posedge clk) begin
        if(!reset) begin
            fsm_state <= 0;
            shader_addr <= 0;
            shader_color_0 <= 0;
            shader_color_0 <= 1;
            shader_color_0 <= 2;
            shader_color_0 <= 3;
            reg_p1[0] <= 0;
            reg_p1[1] <= 0;
            reg_p1[2] <= 0;
            reg_p1[3] <= 0;
            reg_p2[0] <= 0;
            reg_p2[1] <= 0;
            reg_p2[2] <= 0;
            reg_p2[3] <= 0;
            reg_p3[0] <= 0;
            reg_p3[1] <= 0;
            reg_p3[2] <= 0;
            reg_p3[3] <= 0;
            reg_p0[0] <= 0;
            reg_p0[1] <= 0;
            reg_p0[2] <= 0;
            reg_p0[3] <= 0;
            mask <= 0;
        end else begin
            case(fsm_state)
                // wait
                0: begin
                    if (exec) begin
                        shader_addr <= 0;
                        fsm_state <= 1;
                    end
                end
                // run
                1: begin
                    shader_addr <= shader_addr + 1;
                    if (shader_addr == 12) begin
                        fsm_state <= 0;
                    end else begin    
                        casez (shader_instr)
                        
                            // format 00_xx_???? used 2 free 2
                            // reg[0].lo <= imm
                            8'b00_01_????: begin    
                                reg_p0[0][3:0] <= imm;
                                reg_p1[0][3:0] <= imm;
                                reg_p2[0][3:0] <= imm;
                                reg_p3[0][3:0] <= imm;
                            end
                            // reg[0].hi <= imm
                            8'b00_10_????: begin    
                                reg_p0[0][7:4] <= imm;
                                reg_p1[0][7:4] <= imm;
                                reg_p2[0][7:4] <= imm;
                                reg_p3[0][7:4] <= imm;
                            end

                            // format 11_xxxx_?? used 16 free 0
                            // color <= reg[arg0]
                            8'b11_0000_??: begin    
                                shader_color_0 <= reg_p0[arg0][3:0];
                                shader_color_1 <= reg_p1[arg0][3:0];
                                shader_color_2 <= reg_p2[arg0][3:0];
                                shader_color_3 <= reg_p3[arg0][3:0];
                            end
                            //  reg[arg0] <= texel
                            8'b11_0001_??: begin    
                                reg_p0[arg0][3:0] <= texel_0;
                                reg_p1[arg0][3:0] <= texel_1;
                                reg_p2[arg0][3:0] <= texel_2;
                                reg_p3[arg0][3:0] <= texel_3;
                            end
                            //  reg[arg0] <= frame_num
                            8'b11_0010_??: begin    
                                reg_p0[arg0] <= frame_num;
                                reg_p1[arg0] <= frame_num;
                                reg_p2[arg0] <= frame_num;
                                reg_p3[arg0] <= frame_num;
                            end
                            //  reg[arg0] <= tri_idx
                            8'b11_0011_??: begin    
                                reg_p0[arg0] <= tri_idx;
                                reg_p1[arg0] <= tri_idx;
                                reg_p2[arg0] <= tri_idx;
                                reg_p3[arg0] <= tri_idx;
                            end
                            //  reg[arg0] <= shade_color
                            8'b11_0100_??: begin    
                                reg_p0[arg0][3:0] <= shade_color;
                                reg_p1[arg0][3:0] <= shade_color;
                                reg_p2[arg0][3:0] <= shade_color;
                                reg_p3[arg0][3:0] <= shade_color;
                            end
                            //  reg[arg0] <= pixel_x
                            8'b11_0101_??: begin    
                                reg_p0[arg0] <= pixel_x;
                                reg_p1[arg0] <= pixel_x + 1;
                                reg_p2[arg0] <= pixel_x + 2;
                                reg_p3[arg0] <= pixel_x + 3;
                            end
                            //  reg[arg0] <= pixel_y
                            8'b11_0110_??: begin    
                                reg_p0[arg0] <= pixel_y;
                                reg_p1[arg0] <= pixel_y;
                                reg_p2[arg0] <= pixel_y;
                                reg_p3[arg0] <= pixel_y;
                            end
                            //  reg[arg0] <= pixel_u
                            8'b11_0111_??: begin    
                                reg_p0[arg0] <= pixel_u_0;
                                reg_p1[arg0] <= pixel_u_1;
                                reg_p2[arg0] <= pixel_u_2;
                                reg_p3[arg0] <= pixel_u_3;
                            end
                            //  reg[arg0] <= pixel_v
                            8'b11_1000_??: begin    
                                reg_p0[arg0] <= pixel_v_0;
                                reg_p1[arg0] <= pixel_v_1;
                                reg_p2[arg0] <= pixel_v_2;
                                reg_p3[arg0] <= pixel_v_3;
                            end
                            //  reg[arg0] <= reg[arg0] * 2
                            8'b11_1001_??: begin    
                                reg_p0[arg0] <= reg_p0[arg0] << 1;
                                reg_p1[arg0] <= reg_p1[arg0] << 1;
                                reg_p2[arg0] <= reg_p2[arg0] << 1;
                                reg_p3[arg0] <= reg_p3[arg0] << 1;
                            end
                            //  reg[arg0] <= reg[arg0] / 2
                            8'b11_1010_??: begin    
                                reg_p0[arg0] <= reg_p0[arg0] >> 1;
                                reg_p1[arg0] <= reg_p1[arg0] >> 1;
                                reg_p2[arg0] <= reg_p2[arg0] >> 1;
                                reg_p3[arg0] <= reg_p3[arg0] >> 1;
                            end
                            //  reg[arg0] <= 0
                            8'b11_1011_??: begin    
                                reg_p0[arg0] <= 0;
                                reg_p1[arg0] <= 0;
                                reg_p2[arg0] <= 0;
                                reg_p3[arg0] <= 0;
                            end
                            //  if (reg[arg0] == reg[0])
                            8'b11_1100_??: begin    
                                mask[0] <= (reg_p0[arg0] == reg_p0[0]);
                                mask[1] <= (reg_p1[arg0] == reg_p1[0]);
                                mask[2] <= (reg_p2[arg0] == reg_p2[0]);
                                mask[3] <= (reg_p3[arg0] == reg_p3[0]);
                            end
                            //  if (reg[arg0] != reg[0])
                            8'b11_1101_??: begin    
                                mask[0] <= (reg_p0[arg0] != reg_p0[0]);
                                mask[1] <= (reg_p1[arg0] != reg_p1[0]);
                                mask[2] <= (reg_p2[arg0] != reg_p2[0]);
                                mask[3] <= (reg_p3[arg0] != reg_p3[0]);
                            end
                            //  if (reg[arg0] >= reg[0])
                            8'b11_1110_??: begin    
                                mask[0] <= (reg_p0[arg0] >= reg_p0[0]);
                                mask[1] <= (reg_p1[arg0] >= reg_p1[0]);
                                mask[2] <= (reg_p2[arg0] >= reg_p2[0]);
                                mask[3] <= (reg_p3[arg0] >= reg_p3[0]);
                            end
                            //  if (reg[arg0] < reg[0])
                            8'b11_1111_??: begin    
                                mask[0] <= (reg_p0[arg0] < reg_p0[0]);
                                mask[1] <= (reg_p1[arg0] < reg_p1[0]);
                                mask[2] <= (reg_p2[arg0] < reg_p2[0]);
                                mask[3] <= (reg_p3[arg0] < reg_p3[0]);
                            end

                            // format 01/10_xx_??_?? used 7 free 1
                            // mask mov
                            8'b01_00_??_??: begin    
                                reg_p0[arg0] <= (mask[0])? reg_p0[arg0]:reg_p0[arg1];
                                reg_p1[arg0] <= (mask[1])? reg_p1[arg0]:reg_p1[arg1];
                                reg_p2[arg0] <= (mask[2])? reg_p2[arg0]:reg_p2[arg1];
                                reg_p3[arg0] <= (mask[0])? reg_p3[arg0]:reg_p3[arg1];
                            end
                            // mov
                            8'b01_01_??_??: begin    
                                reg_p0[arg0] <= reg_p0[arg1];
                                reg_p1[arg0] <= reg_p1[arg1];
                                reg_p2[arg0] <= reg_p2[arg1];
                                reg_p3[arg0] <= reg_p3[arg1];
                            end
                            // add
                            8'b01_10_??_??: begin    
                                reg_p0[arg0] <= reg_p0[arg0] + reg_p0[arg1];
                                reg_p1[arg0] <= reg_p1[arg0] + reg_p1[arg1];
                                reg_p2[arg0] <= reg_p2[arg0] + reg_p2[arg1];
                                reg_p3[arg0] <= reg_p3[arg0] + reg_p3[arg1];
                            end
                            // and
                            8'b01_11_??_??: begin    
                                reg_p0[arg0] <= reg_p0[arg0] & reg_p0[arg1];
                                reg_p1[arg0] <= reg_p1[arg0] & reg_p1[arg1];
                                reg_p2[arg0] <= reg_p2[arg0] & reg_p2[arg1];
                                reg_p3[arg0] <= reg_p3[arg0] & reg_p3[arg1];
                            end
                            // or
                            8'b10_00_??_??: begin    
                                reg_p0[arg0] <= reg_p0[arg0] | reg_p0[arg1];
                                reg_p1[arg0] <= reg_p1[arg0] | reg_p1[arg1];
                                reg_p2[arg0] <= reg_p2[arg0] | reg_p2[arg1];
                                reg_p3[arg0] <= reg_p3[arg0] | reg_p3[arg1];
                            end
                            // not
                            8'b10_01_??_??: begin    
                                reg_p0[arg0] <= ~reg_p0[arg1];
                                reg_p1[arg0] <= ~reg_p1[arg1];
                                reg_p2[arg0] <= ~reg_p2[arg1];
                                reg_p3[arg0] <= ~reg_p3[arg1];
                            end
                            // xor
                            8'b10_10_??_??: begin    
                                reg_p0[arg0] <= reg_p0[arg0] ^ reg_p0[arg1];
                                reg_p1[arg0] <= reg_p1[arg0] ^ reg_p1[arg1];
                                reg_p2[arg0] <= reg_p2[arg0] ^ reg_p2[arg1];
                                reg_p3[arg0] <= reg_p3[arg0] ^ reg_p3[arg1];
                            end

                            default: begin
                            
                            end
                        endcase
                    end
                end
            endcase //fsm_state
        end // reset
    end  // always


endmodule