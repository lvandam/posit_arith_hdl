// Laurens van Dam
// Delft University of Technology
// August 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines::*;

module positaccum_accumprod_16_raw (clk, rst, in1, start, result, done, truncated);

    input wire clk, rst, start;
    input wire [POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1:0] in1;
    output wire [POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1:0] result;
    output wire done, truncated;

    value_accum_prod out_accum;

    //   ___
    //  / _ \
    // | | | |
    // | | | |
    // | |_| |
    //  \___/
    logic r0_start;

    value_accum_prod r0_a, r0_accum;
    logic r0_operation;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r0_accum.sgn <= '0;
            r0_accum.scale <= '0;
            r0_accum.fraction <= '0;
            r0_accum.inf <= '0;
            r0_accum.zero <= '1;

            r0_a.sgn <= '0;
            r0_a.scale <= '0;
            r0_a.fraction <= '0;
            r0_a.inf <= '0;
            r0_a.zero <= '1;
        end
        else
        begin
            if (in1[0] == 1'b1 | ~start)
            begin
                r0_a.sgn <= '0;
                r0_a.scale <= '0;
                r0_a.fraction <= '0;
                r0_a.inf <= '0;
                r0_a.zero <= '1;
            end
            else
            begin
                r0_a.sgn <= in1[158];
                r0_a.scale <= in1[157:149];
                r0_a.fraction <= in1[148:2];
                r0_a.inf <= in1[1];
                r0_a.zero <= in1[0];
            end

            if(out_accum.scale === 'x)
            begin
                r0_accum.sgn <= '0;
                r0_accum.scale <= '0;
                r0_accum.fraction <= '0;
                r0_accum.inf <= '0;
                r0_accum.zero <= '1;
            end
            else
            begin
                r0_accum <= out_accum;
            end
        end

        r0_start <= (start === 'x) ? '0 : start;
    end

    value_accum_prod r0_low, r0_hi;

    logic r0_a_lt_b; // A larger than B
    assign r0_a_lt_b = r0_accum.zero ? '1 : (r0_a.zero ? '0 : ((r0_a.scale > r0_accum.scale) ? '1 : (r0_a.scale < r0_accum.scale ? '0 : (r0_a.fraction >= r0_accum.fraction ? '1 : '0))));
    // assign r0_a_lt_b = r0_accum.zero ? (r0_a.sgn ? '0 : '1) :
    //                         (r0_a.zero ? (r0_accum.sgn ? '1 : '0) :
    //                             ((r0_accum.sgn & ~r0_a.sgn) ? '1 :
    //                                 ((r0_a.sgn & ~r0_accum.sgn) ? '0 :
    //                                     ((r0_a.scale > r0_accum.scale) ? '1 :
    //                                         ((r0_a.scale < r0_accum.scale) ? '0 :
    //                                             (r0_a.fraction >= r0_accum.fraction ? '1 : '0)
    //                                         )
    //                                     )
    //                                 )
    //                             )
    //                         );

    assign r0_operation = r0_a.sgn ~^ r0_accum.sgn; // 1 = equal signs = add, 0 = unequal signs = subtract
    assign r0_low = r0_a_lt_b ? r0_accum : r0_a;
    assign r0_hi = r0_a_lt_b ? r0_a : r0_accum;


    //  __
    // /_ |
    //  | |
    //  | |
    //  | |
    //  |_|
    logic r1_start;

    value_accum_prod r1_low, r1_hi;

    logic r1_operation;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r1_start <= '0;

            r1_operation <= '0;

            r1_hi.sgn <= '0;
            r1_hi.scale <= '0;
            r1_hi.fraction <= '0;
            r1_hi.inf <= '0;
            r1_hi.zero <= '1;

            r1_low.sgn <= '0;
            r1_low.scale <= '0;
            r1_low.fraction <= '0;
            r1_low.inf <= '0;
            r1_low.zero <= '1;
        end
        else
        begin
            r1_start <= r0_start;

            r1_low <= r0_low;
            r1_hi <= r0_hi;
            r1_operation <= r0_operation;
        end
    end

    // Difference in scales (regime and exponent)
    // Amount the smaller input has to be shifted (everything of the scale difference that the regime cannot cover)
    logic unsigned [8:0] r1_scale_diff;
    assign r1_scale_diff = r1_hi.scale - r1_low.scale; // TODO this is dirty


    //  __
    // /_ |
    //  | |
    //  | |
    //  | |
    //  |_| AA
    logic r1aa_start, r1aa_operation;
    value_accum_prod r1aa_low, r1aa_hi;
    logic unsigned [8:0] r1aa_scale_diff;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r1aa_start <= '0;

            r1aa_operation <= '0;

            r1aa_hi.sgn <= '0;
            r1aa_hi.scale <= '0;
            r1aa_hi.fraction <= '0;
            r1aa_hi.inf <= '0;
            r1aa_hi.zero <= '1;

            r1aa_low.sgn <= '0;
            r1aa_low.scale <= '0;
            r1aa_low.fraction <= '0;
            r1aa_low.inf <= '0;
            r1aa_low.zero <= '1;

            r1aa_scale_diff <= '0;
        end
        else
        begin
            r1aa_start <= r1_start;

            r1aa_operation <= r1_operation;
            r1aa_hi <= r1_hi;
            r1aa_low <= r1_low;
            r1aa_scale_diff <= r1_scale_diff;
        end
    end

    // Shift smaller magnitude based on scale difference
    logic [2*ABITS_ACCUM-1:0] r1aa_low_fraction_shifted; // TODO We lose some bits here
    shift_right #(
        .N(2*ABITS_ACCUM),
        .S(9)
    ) scale_matching_shift (
        .a({~r1aa_low.zero, r1aa_low.fraction, {ABITS_ACCUM+3{1'b0}}}),
        .b(r1aa_scale_diff), // Shift to right by scale difference
        .c(r1aa_low_fraction_shifted)
    );

    logic r1aa_truncated_after_equalizing;
    assign r1aa_truncated_after_equalizing = |r1aa_low_fraction_shifted[ABITS_ACCUM-1:0];


    //  __
    // /_ |     /\
    //  | |    /  \
    //  | |   / /\ \
    //  | |  / ____ \
    //  |_| /_/    \_\
    logic r1a_start, r1a_operation;
    value_accum_prod r1a_low, r1a_hi;
    logic [2*ABITS_ACCUM-1:0] r1a_low_fraction_shifted; // TODO We lose some bits here
    logic unsigned [ABITS_ACCUM:0] r1a_fraction_sum_raw;
    logic r1a_truncated_after_equalizing;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r1a_start <= '0;

            r1a_operation <= '0;

            r1a_hi.sgn <= '0;
            r1a_hi.scale <= '0;
            r1a_hi.fraction <= '0;
            r1a_hi.inf <= '0;
            r1a_hi.zero <= '1;

            r1a_low.sgn <= '0;
            r1a_low.scale <= '0;
            r1a_low.fraction <= '0;
            r1a_low.inf <= '0;
            r1a_low.zero <= '1;

            r1a_low_fraction_shifted <= '0;
        end
        else
        begin
            r1a_start <= r1aa_start;

            r1a_operation <= r1aa_operation;
            r1a_hi <= r1aa_hi;
            r1a_low <= r1aa_low;
            r1a_low_fraction_shifted <= r1aa_low_fraction_shifted;
            r1a_truncated_after_equalizing <= r1aa_truncated_after_equalizing;
        end
    end

    // Add the fractions
    ADDSUB151_8 frac_add_sub (
        .CLK(clk),
        .SCLR(rst),
        .ADD(r1a_operation),
        .A({~r1a_hi.zero, r1a_hi.fraction, {3{1'b0}}}),
        .B(r1a_low_fraction_shifted[2*ABITS_ACCUM-1:ABITS_ACCUM]),
        .S(r1a_fraction_sum_raw)
    );


    //  __   ____
    // /_ | |  _ \
    //  | | | |_) |
    //  | | |  _ <
    //  | | | |_) |
    //  |_| |____/
    logic r1b_start;

    value_accum_prod r1b_low, r1b_hi;
    logic unsigned [ABITS_ACCUM:0] r1b_fraction_sum_raw;

    value_accum_prod r1b_lowShiftReg[7:0], r1b_hiShiftReg[7:0];
    logic [7:0] r1b_startShiftReg, r1b_truncated_after_equalizingShiftReg;
    logic r1b_truncated_after_equalizing;
    integer i;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            for(i = 0; i < 8; i = i + 1)
            begin
                r1b_startShiftReg[i] <= '0;

                r1b_hiShiftReg[i].sgn <= '0;
                r1b_hiShiftReg[i].scale <= '0;
                r1b_hiShiftReg[i].fraction <= '0;
                r1b_hiShiftReg[i].inf <= '0;
                r1b_hiShiftReg[i].zero <= '1;

                r1b_lowShiftReg[i].sgn <= '0;
                r1b_lowShiftReg[i].scale <= '0;
                r1b_lowShiftReg[i].fraction <= '0;
                r1b_lowShiftReg[i].inf <= '0;
                r1b_lowShiftReg[i].zero <= '1;

                r1b_truncated_after_equalizingShiftReg[i] <= '0;
            end
        end
        else
        begin
            // Delay for 8 cycles until add/subtract result is ready
            r1b_startShiftReg[0] <= r1a_start;
            r1b_lowShiftReg[0] <= r1a_low;
            r1b_hiShiftReg[0] <= r1a_hi;
            r1b_truncated_after_equalizingShiftReg[0] <= r1a_truncated_after_equalizing;

            for(i = 1; i < 8; i = i + 1)
            begin
                r1b_startShiftReg[i] <= r1b_startShiftReg[i - 1];
                r1b_lowShiftReg[i] <= r1b_lowShiftReg[i - 1];
                r1b_hiShiftReg[i] <= r1b_hiShiftReg[i - 1];
                r1b_truncated_after_equalizingShiftReg[i] <= r1b_truncated_after_equalizingShiftReg[i - 1];
            end
        end
    end

    assign r1b_fraction_sum_raw = r1a_fraction_sum_raw;

    assign r1b_start = r1b_startShiftReg[7];
    assign r1b_low = r1b_lowShiftReg[7];
    assign r1b_hi = r1b_hiShiftReg[7];
    assign r1b_truncated_after_equalizing = r1b_truncated_after_equalizingShiftReg[7];

    // Result normalization: shift until normalized (and fix the sign)
    // Find the hidden bit (leading zero counter)
    logic [7:0] r1b_hidden_pos;
    LOD_N #(
        .N(256)
    ) hidden_bit_counter(
        .in({r1b_fraction_sum_raw[ABITS_ACCUM:0], {256-ABITS_ACCUM-1{1'b0}}}),
        .out(r1b_hidden_pos)
    );


    //  ___
    // |__ \
    //    ) |
    //   / /
    //  / /_
    // |____| AA
    logic r2aa_start;

    value_accum_prod r2aa_sum, r2aa_hi, r2aa_low;
    logic unsigned [ABITS_ACCUM:0] r2aa_fraction_sum_raw;
    logic [7:0] r2aa_hidden_pos;
    logic r2aa_truncated_after_equalizing;
    logic r2aa_operation;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r2aa_start <= '0;

            r2aa_hi.sgn <= '0;
            r2aa_hi.scale <= '0;
            r2aa_hi.fraction <= '0;
            r2aa_hi.inf <= '0;
            r2aa_hi.zero <= '1;

            r2aa_low.sgn <= '0;
            r2aa_low.scale <= '0;
            r2aa_low.fraction <= '0;
            r2aa_low.inf <= '0;
            r2aa_low.zero <= '1;

            r2aa_fraction_sum_raw <= '0;
            r2aa_hidden_pos <= '0;
            r2aa_truncated_after_equalizing <= '0;
        end
        else
        begin
            r2aa_start <= r1b_start;

            r2aa_hi <= r1b_hi;
            r2aa_low <= r1b_low;

            r2aa_fraction_sum_raw <= r1b_fraction_sum_raw;
            r2aa_hidden_pos <= r1b_hidden_pos;
            r2aa_truncated_after_equalizing <= r1b_truncated_after_equalizing;
        end
    end

    assign r2aa_operation = r2aa_hi.sgn ~^ r2aa_low.sgn;

    logic signed [8:0] r2aa_scale_sum;
    assign r2aa_scale_sum = r2aa_fraction_sum_raw[ABITS_ACCUM] ? (r2aa_hi.scale + 1) : ((~r2aa_fraction_sum_raw[ABITS_ACCUM-1] & ~(r2aa_hi.zero & r2aa_low.zero)) ? (r2aa_hi.scale - r2aa_hidden_pos + 1) : r2aa_hi.scale);
    assign r2aa_sum.sgn = r2aa_hi.sgn;
    assign r2aa_sum.scale = r2aa_scale_sum;
    assign r2aa_sum.zero = (r2aa_operation == 1'b0 && r2aa_hi.scale == r2aa_low.scale && r2aa_hi.fraction == r2aa_low.fraction) ? '1 : (r2aa_hi.zero & r2aa_low.zero);
    assign r2aa_sum.inf = r2aa_hi.inf | r2aa_low.inf;


    //  ___
    // |__ \
    //    ) |
    //   / /
    //  / /_
    // |____| A
    logic r2a_start;

    value_accum_prod r2a_sum;
    logic unsigned [ABITS_ACCUM:0] r2a_fraction_sum_raw;
    logic [7:0] r2a_shift_amount_hiddenbit_out;
    logic [7:0] r2a_hidden_pos;
    logic r2a_truncated_after_equalizing;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r2a_start <= '0;

            r2a_sum.sgn <= '0;
            r2a_sum.scale <= '0;
            r2a_sum.fraction <= '0;
            r2a_sum.inf <= '0;
            r2a_sum.zero <= '1;

            r2a_fraction_sum_raw <= '0;
            r2a_truncated_after_equalizing <= '0;
            r2a_hidden_pos <= '0;
        end
        else
        begin
            r2a_start <= r2aa_start;

            r2a_sum.sgn <= r2aa_sum.sgn;
            r2a_sum.scale <= r2aa_sum.scale;
            r2a_sum.fraction <= '0;
            r2a_sum.inf <= r2aa_sum.inf;
            r2a_sum.zero <= r2aa_sum.zero;

            r2a_fraction_sum_raw <= r2aa_fraction_sum_raw;
            r2a_hidden_pos <= r2aa_hidden_pos;
            r2a_truncated_after_equalizing <= r2aa_truncated_after_equalizing;
        end
    end

    assign r2a_shift_amount_hiddenbit_out = r2a_hidden_pos + 1;

    //  ___
    // |__ \
    //    ) |
    //   / /
    //  / /_
    // |____|
    logic r2_start;

    value_accum_prod r2_sum;
    logic unsigned [ABITS_ACCUM:0] r2_fraction_sum_raw;
    logic [7:0] r2_shift_amount_hiddenbit_out;
    logic r2_truncated_after_equalizing;
    logic [FBITS_ACCUM-1:0] r2_trunc_frac;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r2_start <= '0;

            r2_sum.sgn = '0;
            r2_sum.scale = '0;
            r2_sum.fraction <= '0;
            r2_sum.inf = '0;
            r2_sum.zero = '1;

            r2_fraction_sum_raw <= '0;
            r2_shift_amount_hiddenbit_out <= '0;
            r2_truncated_after_equalizing <= '0;
        end
        else
        begin
            r2_start <= r2a_start;

            r2_sum.sgn <= r2a_sum.sgn;
            r2_sum.scale <= r2a_sum.scale;
            r2_sum.fraction <= '0;
            r2_sum.inf <= r2a_sum.inf;
            r2_sum.zero <= r2a_sum.zero;

            r2_fraction_sum_raw <= r2a_fraction_sum_raw;
            r2_shift_amount_hiddenbit_out <= r2a_shift_amount_hiddenbit_out;
            r2_truncated_after_equalizing <= r2a_truncated_after_equalizing;
        end
    end

    // Normalize the sum output (shift left)
    logic [ABITS_ACCUM:0] r2_fraction_sum_normalized;
    shift_left #(
        .N(ABITS_ACCUM+1),
        .S(8) // The hidden bit is shifted out of range, our sum becomes 0 (when truncated)
    ) ls (
        .a(r2_fraction_sum_raw[ABITS_ACCUM:0]),
        .b(r2_shift_amount_hiddenbit_out),
        .c(r2_fraction_sum_normalized)
    );

    assign r2_trunc_frac = r2_fraction_sum_normalized[ABITS_ACCUM:(ABITS_ACCUM-FBITS_ACCUM+1)];


    //   ___     ___
    //  / _ \   / _ \
    // | (_) | | (_) |
    //  \__, |  \__, |
    //    / /     / /
    //   /_/     /_/
    logic r99_start;
    value_accum_prod r99_sum;
    logic r99_truncated_after_equalizing;

    always @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            r99_start <= '0;

            r99_sum.sgn = '0;
            r99_sum.scale = '0;
            r99_sum.fraction = '0;
            r99_sum.inf = '0;
            r99_sum.zero = '1;

            r99_truncated_after_equalizing = '0;
        end
        else
        begin
            r99_start <= r2_start;

            r99_sum.sgn <= r2_sum.sgn;
            r99_sum.scale <= r2_sum.scale;
            r99_sum.fraction <= r2_trunc_frac;
            r99_sum.inf <= r2_sum.inf;
            r99_sum.zero <= r2_sum.zero;

            r99_truncated_after_equalizing <= r2_truncated_after_equalizing;
        end
    end


    //  _____                         _   _
    // |  __ \                       | | | |
    // | |__) |   ___   ___   _   _  | | | |_
    // |  _  /   / _ \ / __| | | | | | | | __|
    // | | \ \  |  __/ \__ \ | |_| | | | | |_
    // |_|  \_\  \___| |___/  \__,_| |_|  \__|

    // Final output
    assign out_accum = r99_sum;

    assign result = {r99_sum.sgn, r99_sum.scale, r99_sum.fraction, r99_sum.inf, r99_sum.zero};
    assign done = r99_start;
    assign truncated = r99_truncated_after_equalizing;
endmodule
