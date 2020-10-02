module edgedet(clk, reset, in, p);
	input wire clk;
	input wire reset;
	input wire in;
	output wire p;

	reg [1:0] x;
	reg [1:0] init = 0;
	always @(posedge clk or negedge reset) begin
		if(reset)
			init <= 0;
		else begin
			x <= { x[0], in };
			init <= { init[0], 1'b1 };
		end
	end

	assign p = (&init) & x[0] & !x[1];
endmodule


module ww(
	input wire clk,
	input wire reset
);

	/* Switches */
	reg sw_reset = 0;
	reg sw_restart = 0;
	reg sw_enable_oscillator = 0;
	reg sw_pc_reset = 1;
	reg [5:15] sw_pc = 'o3740;
	reg [0:15] sw_ff_0 = 0;
	reg [0:15] sw_ff_1 = 0;
	reg [0:15] sw_ff_2 = 0;
	reg [0:15] sw_ff_3 = 0;
	reg [0:15] sw_ff_4 = 0;
	reg [0:15] sw_ts_0 = 0;
	reg [0:15] sw_ts_1 = 0;
	reg [0:15] sw_ts_2 = 0;
	reg [0:15] sw_ts_3 = 0;
	reg [0:15] sw_ts_4 = 0;
	reg [0:15] sw_ts_5 = 0;
	reg [0:15] sw_ts_6 = 0;
	reg [0:15] sw_ts_7 = 0;
	reg [0:15] sw_ts_8 = 0;
	reg [0:15] sw_ts_9 = 0;
	reg [0:15] sw_ts_10 = 0;
	reg [0:15] sw_ts_11 = 0;
	reg [0:15] sw_ts_12 = 0;
	reg [0:15] sw_ts_13 = 0;
	reg [0:15] sw_ts_14 = 0;
	reg [0:15] sw_ts_15 = 0;
	reg [0:15] sw_ts_16 = 0;
	reg [0:15] sw_ts_17 = 0;
	reg [0:15] sw_ts_18 = 0;
	reg [0:15] sw_ts_19 = 0;
	reg [0:15] sw_ts_20 = 0;
	reg [0:15] sw_ts_21 = 0;
	reg [0:15] sw_ts_22 = 0;
	reg [0:15] sw_ts_23 = 0;
	reg [0:15] sw_ts_24 = 0;
	reg [0:15] sw_ts_25 = 0;
	reg [0:15] sw_ts_26 = 0;

	parameter [5:15] addr_ff0 = 'o3740;
	parameter [5:15] addr_ff1 = 'o3741;
	parameter [5:15] addr_ff2 = 'o3742;
	parameter [5:15] addr_ff3 = 'o3743;
	parameter [5:15] addr_ff4 = 'o3744;
	parameter [5:15] addr_ts0 = 'o3745;
	parameter [5:15] addr_ts1 = 'o3746;
	parameter [5:15] addr_ts2 = 'o3747;
	parameter [5:15] addr_ts3 = 'o3750;
	parameter [5:15] addr_ts4 = 'o3751;
	parameter [5:15] addr_ts5 = 'o3752;
	parameter [5:15] addr_ts6 = 'o3753;
	parameter [5:15] addr_ts7 = 'o3754;
	parameter [5:15] addr_ts8 = 'o3755;
	parameter [5:15] addr_ts9 = 'o3756;
	parameter [5:15] addr_ts10 = 'o3757;
	parameter [5:15] addr_ts11 = 'o3760;
	parameter [5:15] addr_ts12 = 'o3761;
	parameter [5:15] addr_ts13 = 'o3762;
	parameter [5:15] addr_ts14 = 'o3763;
	parameter [5:15] addr_ts15 = 'o3764;
	parameter [5:15] addr_ts16 = 'o3765;
	parameter [5:15] addr_ts17 = 'o3766;
	parameter [5:15] addr_ts18 = 'o3767;
	parameter [5:15] addr_ts19 = 'o3770;
	parameter [5:15] addr_ts20 = 'o3771;
	parameter [5:15] addr_ts21 = 'o3772;
	parameter [5:15] addr_ts22 = 'o3773;
	parameter [5:15] addr_ts23 = 'o3774;
	parameter [5:15] addr_ts24 = 'o3775;
	parameter [5:15] addr_ts25 = 'o3776;
	parameter [5:15] addr_ts26 = 'o3777;

	wire restart = sw_restart;	// maybe make this a pulse?

	wire [0:15] bus =
		{11{pc_to_bus}}&pc |
		{16{pr_to_bus}}&pr |
		{16{cs_to_bus}}&{cs,11'b0} |
		{16{ss_to_bus}}&ss |
		{16{storage_to_bus}}&(out_ff|out_ts) |
		{16{sc_to_bus}}&sc |
		{16{ar_to_bus}}&ar |
		{16{ac_to_bus}}&ac;
	wire [0:15] check_bus =
		{11{pc_to_check}}&pc |
		{16{storage_to_check}}&(out_ff|out_ts) |
		{16{ac_to_check}}&ac;


	/****************************
	 * 100 - Control            *
	 ****************************/

	wire reset_pulse = sw_reset | pc_reset;

	/* 101 - Master Clock */
	reg [2:0] oscillator = 0;
	always @(posedge clk)
		if(sw_enable_oscillator)
			oscillator <= oscillator + 1;
	// TODO: single pulse
	wire hfcp = ~reset & oscillator[0];	// high freq 4MHz
	wire lfcp = ~reset & oscillator == 1;	// low freq 1Mhz

	/* 102 - Program Counter */
	reg [5:15] pc = 0;	// FF 102.01
	wire pc_from_bus;	// c
	wire pc_to_bus;		// GT 102.02	c
	reg pc_read_in_ff = 0;	// FF 102.02
	wire pc_to_check;	// GT 102.03	c
	wire pc_add;		// c
	wire pc_clear;		// c
	wire pc_end_carry = pc_add & (&pc);	// GT 102.05
	reg pc_add_dly = 0;	// DE 102.01
	reg [0:1] pc_end_carry_dly = 0;	// DE 102.02
	reg pc_read_in_dly = 0;	// DE 102.04
	wire pc_reset = pc_end_carry_dly[0] & sw_pc_reset;
	always @(posedge clk) begin
		pc_add_dly <= pc_add;
		pc_read_in_dly <= pc_from_bus;
		pc_end_carry_dly <= {pc_end_carry_dly[1], pc_end_carry};

		if(pc_from_bus) pc_read_in_ff <= 1;
		if(pc_read_in_dly) pc_read_in_ff <= 0;

		if(pc_clear | change_control) pc <= 0;
		if(pc_add_dly) pc <= pc + 1;
		if(pc_from_bus | pc_read_in_ff) pc <= pc | bus;	// GT 102.01
		if(reset_pulse) pc <= pc | sw_pc;
	end

	/* 103 - Program Register */
	reg [0:15] pr;		// FF 103.01
	wire pr_from_bus;	// GT 103.01	c
	wire pr_to_bus;		// GT 103.02	c
	wire pr_clear;		// c
	always @(posedge clk) begin
		if(pr_clear) pr <= 0;
		if(pr_from_bus) pr <= pr | bus;
	end

	/* 104 - Control Switch */
	reg [0:4] cs;		// FF 104.01-05
	wire cs_from_bus;	// GT 104.01	c
	wire cs_to_bus;		// GT 104.02	c
	wire cs_clear;		// c
	wire change_to_sp = change_control;
	always @(posedge clk) begin
		if(cs_clear) cs <= 0;
		if(cs_from_bus) cs <= cs | bus[0:4];
		if(change_to_sp) cs[4] <= 1;
	end
	wire cs_0 = cs == 'o0;
	wire cs_1 = cs == 'o1;
	wire cs_2 = cs == 'o2;
	wire cs_3 = cs == 'o3;
	wire cs_4 = cs == 'o4;
	wire cs_5 = cs == 'o5;
	wire cs_6 = cs == 'o6;
	wire cs_7 = cs == 'o7;
	wire cs_ts = cs == 'o10;
	wire cs_td = cs == 'o11;
	wire cs_12 = cs == 'o12;
	wire cs_13 = cs == 'o13;
	wire cs_14 = cs == 'o14;
	wire cs_15 = cs == 'o15;
	wire cs_cp = cs == 'o16;
	wire cs_sp = cs == 'o17;
	wire cs_ca = cs == 'o20;
	wire cs_cs = cs == 'o21;
	wire cs_ad = cs == 'o22;
	wire cs_su = cs == 'o23;
	wire cs_24 = cs == 'o24;
	wire cs_sa = cs == 'o25;
	wire cs_26 = cs == 'o26;
	wire cs_27 = cs == 'o27;
	wire cs_mr = cs == 'o30;
	wire cs_mh = cs == 'o31;
	wire cs_dv = cs == 'o32;
	wire cs_sl = cs == 'o33;
	wire cs_sr = cs == 'o34;
	wire cs_35 = cs == 'o35;
	wire cs_36 = cs == 'o36;
	wire cs_37 = cs == 'o37;
	wire cs_sd = 0;	// don't know the number

	/* 105 - Operation Matrix */
	wire stop_clock_tp1 = cs_mr | cs_mh | cs_sr | cs_sl;
	wire cr_from_bus_tp8 = cs_ad | cs_ca | cs_su | cs_cs |
		cs_mr | cs_mh | cs_ts | cs_sd | cs_sr | cs_sl |
		cs_td | cs_sa | cs_dv;
	wire bus_to_output_tp7 = cs_sd;
	wire pr_to_bus_tp7 = cs_sr | cs_sl | cs_sp;
	wire pc_clear_tp6 = cs_sp;
	wire pc_from_bus_tp7 = cs_sp;
	wire pc_to_bus_tp8 = 0;			// huh?
	wire storage_from_bus_tp7 = cs_ts | cs_sd | cs_td;
	wire storage_to_bus_tp8 = cs_ts | cs_sd | cs_td;
	wire storage_to_bus_tp7 = cs_ad | cs_ca | cs_su | cs_cs |
		cs_mr | cs_mh | cs_sa | cs_dv;
	wire storage_to_check_tp7 = cs_ad | cs_ca | cs_su | cs_cs |
		cs_mr | cs_mh | cs_sa | cs_dv;
	wire storage_clear_tp6 = cs_ts | cs_sd;
	wire stop_clock_tp2 = cs_dv;
	wire special_carry_tp7 = cs_ca;

	wire sub_ar_to_ac_tp1 = cs_dv;
	wire ar_from_bus_tp7 = cs_ad | cs_ca | cs_su | cs_cs |
		cs_mr | cs_mh | cs_sa | cs_dv;
	wire ar_to_bus_tp8 = cs_ad | cs_ca | cs_su | cs_cs |
		cs_mr | cs_mh | cs_sa | cs_dv;
	wire sub_ar_to_ac_tp8 = cs_su | cs_cs;
	wire add_ar_to_ac_tp8 = cs_ad | cs_ca | cs_sa;
	wire ac_to_bus_tp7 = cs_ts | cs_sd | cs_td;
	wire ac_to_check_tp7 = cs_ts | cs_sd | cs_td;
	wire ac_to_br_tp7 = cs_mr | cs_mh;
	wire carry_tp2 = cs_ad | cs_ca | cs_su | cs_mr | cs_mh | cs_sa;
	wire roundoff_tp2 = cs_mr | cs_sr | cs_sl;
	wire product_sign_tp4 = cs_mr | cs_mh | cs_sr | cs_sl | cs_dv;
	wire ac_sign_tp6 = cs_mr | cs_mh | cs_sr | cs_sl | cs_dv;
	wire ar_sign_tp8 = cs_mr | cs_mh | cs_dv;
	wire compare_tp6 = cs_cp;
	wire clear_br_tp3 = cs_mr | cs_sr | cs_sl;
	wire multiply_tp1 = cs_mr | cs_mh;
	wire shift_left_tp1 = cs_sl;
	wire shift_right_tp1 = cs_sr;
	wire divide_tp2 = cs_dv;
	wire special_add_tp3 = cs_sa;
	wire arithmetic_check_tp3 = cs_ad | cs_ca | cs_su | cs_cs | cs_sl;
	wire clear_ac_tp6 = cs_ca | cs_cs;
	wire clear_ac_tp3 = cs_dv;
	wire clear_br_tp6 = cs_mr | cs_mh;
	wire clear_ac_tp8 = cs_mr | cs_mh;

	/* 106 - Time Pulse Distributor */
	wire time_pulse = lfcp & ~clock_disabled;	// GT 106.18
	wire time_pulse_dly = lfcp & ~clock_no_dly;	// GT 106.19
	reg [0:2] pulse_cnt = 0;	// FF 106.01-03, BA 106.12-17
	reg clock_disabled = 0;		// FF 106.04
	reg clock_no_dly = 1;		// FF 106.05
	reg warning_signal = 0;		// FF 106.06
	reg [0:2] delay_counter = 0;	// unknown size
	wire tp1 = time_pulse & pulse_cnt == 0;	// GT 106.04
	wire tp2 = time_pulse & pulse_cnt == 1;	// GT 106.05
	wire tp3 = time_pulse & pulse_cnt == 2;	// GT 106.06
	wire tp4 = time_pulse & pulse_cnt == 3;	// GT 106.07
	wire tp5 = time_pulse & pulse_cnt == 4;	// GT 106.08
	wire tp6 = time_pulse & pulse_cnt == 5;	// GT 106.09
	wire tp7 = time_pulse & pulse_cnt == 6;	// GT 106.10
	wire tp8 = time_pulse & pulse_cnt == 7;	// GT 106.11
	wire start_delay = tp2 | tp5;
	wire delay_counter_end_carry = (&delay_counter) & time_pulse_dly;
	always @(posedge clk) begin
		if(time_pulse) pulse_cnt <= pulse_cnt + 1;
		if(start_delay) clock_no_dly <= 0;
		if(start_delay | stop_clock | alarm) clock_disabled <= 1;
		if(delay_counter_end_carry | sc_end_carry | restart) begin
			clock_disabled <= 0;
			clock_no_dly <= 1;
		end
		if(time_pulse_dly) delay_counter <= delay_counter + 1;
		if(restart) warning_signal <= 0;
		if(alarm) warning_signal <= 1;
	end

	/* 107 - Operation Timing Matrix */
	// some down below with 108
	// stopping at tp2 while starting the delay counter is bad
	// maybe something is wrong...
	wire stop_clock = stop_clock_tp1 & tp1 | stop_clock_tp2 & tp1;
//	wire stop_clock = stop_clock_tp1 & tp1 | stop_clock_tp2 & tp2;
	wire bus_to_output = bus_to_output_tp7 & tp7;
	assign pc_clear = pc_clear_tp6 & tp6;
	assign pc_from_bus = pc_from_bus_tp7 & tp7;
	assign storage_from_bus = storage_from_bus_tp7 & tp7;
	assign storage_clear = storage_clear_tp6 & tp6;
	// have to implement this somehow
	wire storage_clear_low = cs_td & tp6;
	assign ar_from_bus = ar_from_bus_tp7 & tp7;
	assign clear_ac = clear_ac_tp6 & tp6 | clear_ac_tp3 & tp3 | clear_ac_tp8 & tp8;
	wire start_multiply = multiply_tp1 & tp1;
	wire start_shift_left = shift_left_tp1 & tp1;
	wire start_shift_right = shift_right_tp1 & tp1;
	// also have to start divide earlier now
	wire start_divide = divide_tp2 & tp1;
//	wire start_divide = divide_tp2 & tp2;
	wire special_add = special_add_tp3 & tp3;
	wire special_carry = special_carry_tp7 & tp7;

	wire add_ar_to_ac_ctl = add_ar_to_ac_tp8 & tp8;
	wire sub_ar_to_ac_ctl = sub_ar_to_ac_tp8 & tp8 | sub_ar_to_ac_tp1 & tp1;
	assign ar_to_bus = ar_to_bus_tp8 & tp8;
	assign ac_to_bus = ac_to_bus_tp7 & tp7;
	assign ac_to_check = ac_to_check_tp7 & tp7;
	assign ac_to_br = ac_to_br_tp7 & tp7;
	wire carry_ctl = carry_tp2 & tp2;
	wire roundoff_ctl = roundoff_tp2 & tp2;
	wire product_sign_ctl = product_sign_tp4 & tp4;
	wire ac_sign_ctl = ac_sign_tp6 & tp6;
	wire ar_sign_ctl = ar_sign_tp8 & tp8;
	wire compare_ctl = compare_tp6 & tp6;
	assign clear_br = clear_br_tp3 & tp3 | clear_br_tp6 & tp6;



	/* 108 - Program Timing Matrix */
	assign pc_to_bus = tp2 | pc_to_bus_tp8&tp8;
	assign pc_to_check = tp2;
	assign pr_from_bus = tp4;
	assign pr_to_bus = tp5 | pr_to_bus_tp7 & tp7;
	assign cs_from_bus = tp5;
	assign cs_to_bus = tp6;
	assign ss_from_bus = tp2 | tp5;
	assign ss_to_bus = tp3 | tp6;
	assign storage_to_bus = tp4 | storage_to_bus_tp7 & tp7 | storage_to_bus_tp8 & tp8;
	assign storage_to_check = tp4 | storage_to_check_tp7 & tp7;
	assign sc_from_bus = tp5;
	assign sc_to_bus = tp6;
	assign cr_from_bus = tp3 | tp6 | cr_from_bus_tp8 & tp8;
	assign ss_clear = tp1 | tp4;
	assign cs_clear = tp4;
	assign pc_add = tp3;
	assign clear_ar = tp5;
	assign pr_clear = tp3;
	assign sc_clear = tp4;
	assign transfer_check = tp3 | tp6 | tp8;

	/* 109 - Repeat Switch (Removed) */


	/****************************
	 * 200 - Storage            *
	 ****************************/

	/* 201 - Storage Switch */
	// Actually this should be 5 bits only but then the check
	// gives trouble if the higher bits aren't all 0.
	// Maybe on ss_to_bus the higher bits are all forced to 0 or 1?
	reg [5:15] ss;		// FF 201.01-05
	wire ss_from_bus;	// GT 201.01	c
	wire ss_to_bus;		// GT 201.02	c
	wire ss_clear;		// c
	always @(posedge clk) begin
		if(ss_clear) ss <= 0;
		if(ss_from_bus) ss <= ss | bus;
	end

	/* 202 - Toggle Switch Storage */
	wire [0:15] out_ts =
		{16{ss == addr_ts0}}&sw_ts_0 |
		{16{ss == addr_ts1}}&sw_ts_1 |
		{16{ss == addr_ts2}}&sw_ts_2 |
		{16{ss == addr_ts3}}&sw_ts_3 |
		{16{ss == addr_ts4}}&sw_ts_4 |
		{16{ss == addr_ts5}}&sw_ts_5 |
		{16{ss == addr_ts6}}&sw_ts_6 |
		{16{ss == addr_ts7}}&sw_ts_7 |
		{16{ss == addr_ts8}}&sw_ts_8 |
		{16{ss == addr_ts9}}&sw_ts_9 |
		{16{ss == addr_ts10}}&sw_ts_10 |
		{16{ss == addr_ts11}}&sw_ts_11 |
		{16{ss == addr_ts12}}&sw_ts_12 |
		{16{ss == addr_ts13}}&sw_ts_13 |
		{16{ss == addr_ts14}}&sw_ts_14 |
		{16{ss == addr_ts15}}&sw_ts_15 |
		{16{ss == addr_ts16}}&sw_ts_16 |
		{16{ss == addr_ts17}}&sw_ts_17 |
		{16{ss == addr_ts18}}&sw_ts_18 |
		{16{ss == addr_ts19}}&sw_ts_19 |
		{16{ss == addr_ts20}}&sw_ts_20 |
		{16{ss == addr_ts21}}&sw_ts_21 |
		{16{ss == addr_ts22}}&sw_ts_22 |
		{16{ss == addr_ts23}}&sw_ts_23 |
		{16{ss == addr_ts24}}&sw_ts_24 |
		{16{ss == addr_ts25}}&sw_ts_25 |
		{16{ss == addr_ts26}}&sw_ts_26;

	/* 203 - Flip Flop Storage */
	ww_ff_storage ff0(.clk(clk),
		.sw_input(sw_ff_0),
		.initial_value(storage_reset),
		.clear(storage_clear),
		.clear_low(storage_clear_low),
		.select(ss == addr_ff0),
		.in(in_to_ff),
		.out(out_ff0)
	);
	ww_ff_storage ff1(.clk(clk),
		.sw_input(sw_ff_1),
		.initial_value(storage_reset),
		.clear(storage_clear),
		.clear_low(storage_clear_low),
		.select(ss == addr_ff1),
		.in(in_to_ff),
		.out(out_ff1)
	);
	ww_ff_storage ff2(.clk(clk),
		.sw_input(sw_ff_2),
		.initial_value(storage_reset),
		.clear(storage_clear),
		.clear_low(storage_clear_low),
		.select(ss == addr_ff2),
		.in(in_to_ff),
		.out(out_ff2)
	);
	ww_ff_storage ff3(.clk(clk),
		.sw_input(sw_ff_3),
		.initial_value(storage_reset),
		.clear(storage_clear),
		.clear_low(storage_clear_low),
		.select(ss == addr_ff3),
		.in(in_to_ff),
		.out(out_ff3)
	);
	ww_ff_storage ff4(.clk(clk),
		.sw_input(sw_ff_4),
		.initial_value(storage_reset),
		.clear(storage_clear),
		.clear_low(storage_clear_low),
		.select(ss == addr_ff4),
		.in(in_to_ff),
		.out(out_ff4)
	);

	wire storage_from_bus;	// GT 203.01	c
	wire storage_to_bus;	// GT 203.02	c
	wire storage_to_check;	// GT 203.03	c
	wire storage_clear;	// c
	reg storage_reset = 0;
	// Somehow have to implement only writing address part of word
//	wire [0:15] in_to_ff = {16{storage_from_bus}}&bus;
	wire [0:15] in_to_ff = {{5{storage_from_bus&~cs_td}}, {11{storage_from_bus}}}&bus;
	wire [0:15] out_ff0;
	wire [0:15] out_ff1;
	wire [0:15] out_ff2;
	wire [0:15] out_ff3;
	wire [0:15] out_ff4;
	wire [0:15] out_ff = out_ff0 | out_ff1 | out_ff2 | out_ff3 | out_ff4;


	/****************************
	 * 300 - Arithmetic Element *
	 ****************************/

	/* 301 - A-Register */
	reg [0:15] ar;
	wire [0:15] ar_neg = ~ar;
	wire ar_from_bus;	// GT 301.01	c
	wire ar_to_bus;		// GT 301.02	c
	wire add_ar_to_ac = add_ar_to_ac_ctl | from_br15_one | div_add_dly;	// GT 301.04	c
	wire sub_ar_to_ac = sub_ar_to_ac_ctl | div_sub_dly;	// GT 301.05	c
	wire clear_ar;		// c
	wire complement_ar = ar_sign;
	wire [0:15] ar_to_ac = {16{add_ar_to_ac}}&ar | {16{sub_ar_to_ac}}&~ar;
	// not in drawings but needed so carry comes out right timing is off
	reg div_add_dly = 0;
	reg div_sub_dly = 0;
	always @(posedge clk) begin
		div_add_dly <= divide_1;
		div_sub_dly <= divide_0;

		if(clear_ar) ar <= 0;
		if(complement_ar) ar <= ~ar;
		if(ar_from_bus) ar <= ar | bus;
	end

	/* 302 - Acumulator */
	wire [0:15] ac;
	wire [0:15] ac_neg = ~ac;
	wire [1:15] cry;
	wire ac_to_bus;		// GT 302.02	c
	wire ac_to_check;	// GT 302.03	c
	wire ac_to_br;		// GT 302.04	c
	wire carry = carry_ctl | div_carry_pulse;	// GT 302.20	c
	wire clear_ac;		// c
	wire complement_ac = product_sign | ac_sign;
	wire [0:15] ac_to_br16 = {16{ac_to_br}}&ac;

	wire left_digit_carry;
	wire [1:15] carry_out;
	wire end_around_carry = carry_to_left[0];	// also roundoff according to drawings but that sets ac0 carry
	wire [0:15] carry_to_left;
	wire [1:15] zero_to_left;
	wire [1:15] one_to_left;
	wire divide_0;
	wire divide_1;
	wire [0:15] shift_left_n = {16{div_shift_left_pulse}} | {14{shift_left_pulse}};
	wire ac_zero_to_br0 = shift_carry_pulse & ~ac[15];
	wire ac_one_to_br0 = shift_carry_pulse & ac[15];

	reg to_ac0_dly = 0;

	ww_ac0 ac_0(.clk(clk), .acn(ac[0]),
		.from_ar(ar_to_ac[0] | to_ac0_dly),
		.clear(clear_ac),
		.complement(complement_ac | neg1_special_add),
		.shift_left(shift_left_n[0]),
		.shift_carry(shift_carry_pulse),

		// divide 0/1 on AC0
		.zero_to_left(divide_0),
		.one_to_left(divide_1),

		.zero_from_right(zero_to_left[1]),
		.one_from_right(one_to_left[1]),
		.zero_from_left(1'b0),
		.one_from_left(1'b0),

		.carry_in(carry_out[1]),
		.carry_out(left_digit_carry),
		.carry_from_right(carry_to_left[1]),
		.carry_to_left(carry_to_left[0])
	);
	genvar i;
	generate
		for(i = 1; i < 15; i = i + 1) begin : acgen
			ww_ac_slice ac_n(.clk(clk), .acn(ac[i]), .cryn(cry[i]),
				.left_digit(ac[(i+15)%16]),
				.from_ar(ar_to_ac[i]),
				.clear(clear_ac),
				.carry_clear(carry),
				.complement(complement_ac | neg1_special_add),
				.shift_left(shift_left_n[i]),
				.shift_carry(shift_carry_pulse),

				.zero_to_left(zero_to_left[i]),
				.one_to_left(one_to_left[i]),

				.zero_from_right(zero_to_left[(i+1)%16]),
				.one_from_right(one_to_left[(i+1)%16]),

				.carry_in(carry_out[(i+1)%16]),
				.carry_out(carry_out[i]),
				.carry_from_right(carry_to_left[(i+1)%16]),
				.carry_to_left(carry_to_left[i])
			);
		end
	endgenerate
	ww_ac_slice ac_15(.clk(clk), .acn(ac[15]), .cryn(cry[15]),
		.left_digit(ac[14]),
		.from_ar(ar_to_ac[15]),
		.clear(clear_ac),
		.carry_clear(carry),
		.complement(complement_ac),
		.shift_left(shift_left_n[15]),
		.shift_carry(shift_carry_pulse),

		// divide 0/1
		.zero_to_left(zero_to_left[15]),
		.one_to_left(one_to_left[15]),

		.zero_from_right(br_zero_to_left[0]),
		.one_from_right(br_one_to_left[0]),

		.carry_in(1'b0),	// non-existant
		.carry_out(carry_out[15]),
		.carry_from_right(end_around_carry_roundoff),
		.carry_to_left(carry_to_left[15])
	);

	always @(posedge clk) begin
		to_ac0_dly <= special_add_ov;
	end

	/* 303 - B-Register */
	wire [0:15] br;		// FF 303.01
	wire roundoff = roundoff_ctl & br[0];		// GT 303.08	c
	wire clear_br;		// c
	wire from_br15_zero = multiply_pulse & ~br[15];
	wire from_br15_one = multiply_pulse & br[15];
	reg clear_br15_dly = 0;
	wire [0:14] br_zero_to_right;
	wire [0:14] br_one_to_right;
	wire [0:15] br_zero_to_left;
	wire [0:15] br_one_to_left;
	ww_br_slice br_0(.clk(clk), .brn(br[0]),
		.from_ac(ac_to_br16[0]),
		.clear(clear_br),
		.shift_left(shift_left_pulse),
		.shift_right(shift_carry_pulse),

		.zero_to_left(br_zero_to_left[0]),
		.one_to_left(br_one_to_left[0]),
		.zero_to_right(br_zero_to_right[0]),
		.one_to_right(br_one_to_right[0]),

		.zero_from_right(br_zero_to_left[1]),
		.one_from_right(br_one_to_left[1]),
		.zero_from_left(ac_zero_to_br0),
		.one_from_left(ac_one_to_br0)
	);
	generate
		for(i = 1; i < 15; i = i + 1) begin : brgen
			ww_br_slice br_n(.clk(clk), .brn(br[i]),
				.from_ac(ac_to_br16[i]),
				.clear(clear_br),
				.shift_left(shift_left_pulse | div_shift_left_pulse),
				.shift_right(shift_carry_pulse),

				.zero_to_left(br_zero_to_left[i]),
				.one_to_left(br_one_to_left[i]),
				.zero_to_right(br_zero_to_right[i]),
				.one_to_right(br_one_to_right[i]),

				.zero_from_right(br_zero_to_left[(i+1)%16]),
				.one_from_right(br_one_to_left[(i+1)%16]),
				.zero_from_left(br_zero_to_right[(i+15)%16]),
				.one_from_left(br_one_to_right[(i+15)%16])
			);
		end
	endgenerate
	ww_br_slice br_15(.clk(clk), .brn(br[15]),
		.from_ac(ac_to_br16[15]),
		.clear(clear_br),
		.shift_left(shift_left_pulse | div_shift_left_pulse),
		.shift_right(shift_carry_pulse),

		.zero_to_left(br_zero_to_left[15]),
		.one_to_left(br_one_to_left[15]),
	//	.zero_to_right(),
	//	.one_to_right(),

		.zero_from_right(clear_br15_dly | divide_1),
		.one_from_right(divide_0),
		.zero_from_left(br_zero_to_right[14]),
		.one_from_left(br_one_to_right[14])
	);
	always @(posedge clk)
		clear_br15_dly <= from_br15_one;

	/* 304 - Sign Control */
	reg sign_control = 0;	// FF 304.01
	wire product_sign = product_sign_ctl & sign_control;	// GT 304.04	c
	wire ac_sign = ac_sign_ctl & ac[0];		// GT 304.05	c
	wire ar_sign = ar_sign_ctl & ar[0];		// GT 304.07	c
	wire change_control = compare_ctl & ~ac[0];	// GT 304.08	c
	always @(posedge clk) begin
		if(complement_ac | complement_ar) sign_control <= ~sign_control;
	end

	/* 305 - Step Counter */
	reg [11:15] sc;		// FF 305.01-05
	wire sc_from_bus;	// GT 305.01	c
	wire sc_to_bus;		// GT 104.02	c
	wire sc_clear;		// c
	wire sc_add = shift_left_pulse | shift_carry_pulse | div_shift_left_pulse;
	wire sc_end_carry = ~(|sc) & sc_add;
	wire sc_reset_multiply = start_multiply;
	wire sc_reset_divide = start_divide;
	always @(posedge clk) begin
		if(sc_clear) sc <= 0;
		if(sc_from_bus) sc <= sc | bus;
		if(sc_add) sc <= sc + 1;
		// TODO: also these were maintenance switches
		if(sc_reset_multiply) sc <= 5'o22;
		if(sc_reset_divide) sc <= 5'o20;
	end

	/* 306 - Multiply */
	reg multiply = 0;	// FF 306.01	c
	wire multiply_pulse = multiply & hfcp;	// GT 306.04
	always @(posedge clk) begin
		if(start_multiply) multiply <= 1;
		if(sc_end_carry) multiply <= 0;
	end

	/* 307 - Shift */
	reg shift_left = 0;	// FF 307.01	c
	reg shift_right = 0;	// FF 307.02	c
	wire shift_left_pulse = shift_left & hfcp;	// GT 307.04
	wire shift_right_pulse = shift_right & hfcp;	// GT 307.05
	wire shift_carry_pulse = shift_right_pulse | from_br15_zero;
	always @(posedge clk) begin
		if(start_shift_left) shift_left <= 1;
		if(start_shift_right) shift_right <= 1;
		if(sc_end_carry) begin
			shift_left <= 0;
			shift_right <= 0;
		end
	end

	/* 308 - Divide */
	reg divide = 0;		// FF 308.01	c
	reg div_time_dist = 0;	// FF 308.02
	reg divide_error = 0;	// FF 308.03
	wire divide_pulse = divide & lfcp;	// GT 308.04
	wire div_carry_pulse = divide_pulse & ~div_time_dist;	// GT 308.05
	wire div_shift_left_pulse = divide_pulse & div_time_dist;	// GT 308.06
	reg divide_pulse_dly = 0;
	wire divide_alarm = divide_0 & divide_error;	// GT 308.07
	always @(posedge clk) begin
		divide_pulse_dly <= divide_pulse;

		if(start_divide) begin
			divide <= 1;
			div_time_dist <= 0;
		end
		if(sc_end_carry) divide <= 0;
		if(divide_pulse_dly)
			div_time_dist <= ~div_time_dist;
		if(ac_sign_ctl) divide_error <= 1;
		if(divide_1) divide_error <= 0;
	end

	/* 309 - Special Add Memory */
	reg ac0_carry = 0;	// FF 309.01
	reg special_add_mem = 0;	// FF 309.02
	wire add_ac0_carry = ac0_carry & (special_carry | carry);	// GT 309.04
	wire special_add_ov = special_add & ac0_carry;	// GT 309.06	c
	wire neg1_special_add = special_add_mem & special_carry; // GT 309.07
	wire end_around_carry_roundoff = end_around_carry | roundoff | add_ac0_carry;
	wire clear_c0_carry = div_shift_left_pulse | restart;	// not sure about restart

	reg clear_ac0_carry_dly = 0;
	reg clear_special_add_mem_dly = 0;
	reg left_digit_carry_dly = 0;
	reg [0:1] end_around_carry_dly = 0;
	always @(posedge clk) begin
		clear_ac0_carry_dly <= special_add_ov | special_carry;
		clear_special_add_mem_dly <= neg1_special_add;
		left_digit_carry_dly <= left_digit_carry;
		end_around_carry_dly <= {end_around_carry_dly[1], end_around_carry};

		if(clear_c0_carry | clear_ac0_carry_dly) ac0_carry <= 0;
		if(left_digit_carry_dly | end_around_carry_dly[0]) ac0_carry <= ~ac0_carry;
		if(left_digit_carry_dly | clear_special_add_mem_dly) special_add_mem <= 0;
		if(special_add_ov) special_add_mem <= 1;
	end

	/****************************
	 * 400 - Input              *
	 ****************************/

	/****************************
	 * 500 - Output             *
	 ****************************/

	/****************************
	 * 600 - Checking           *
	 ****************************/

	wire arithmetic_check = arithmetic_check_tp3 & tp3;
	wire arithmetic_alarm = arithmetic_check & ac0_carry;	// GT 600.04	c
	// TODO: check alarm
	wire alarm = arithmetic_alarm | divide_alarm;

	/* 601 - Check Register */
	reg [0:15] cr = 0;	// FF 601.01
	wire cr_clear = 0;
	wire cr_from_bus;	// GT 601.01 c
	wire transfer_check;	// c
	reg check_cr = 0;	// not sure what this is
	// not using that yet because checking doesn't work with TD
	wire cr_alarm = (|cr)&check_cr;
	always @(posedge clk) begin
		// not sure about this, but we need a delay here
		check_cr <= transfer_check;

		cr <= cr ^ check_bus;
		if(cr_from_bus) cr <= cr ^ bus;
		if(cr_clear) cr <= 0;
	end
endmodule

module ww_ac_slice(input wire clk,
	output wire acn,
	output wire cryn,
	// control signals  
	input wire left_digit,
	input wire from_ar,
	input wire clear,
	input wire carry_clear,
	input wire complement,
	input wire shift_left,
	input wire shift_carry,
	// shifting
	input wire zero_from_right,
	input wire one_from_right,
	output reg zero_to_left,
	output reg one_to_left,
	// immediate carry
	input wire carry_in,
	output wire carry_out,
	// carry that skipped a stage
	input wire carry_from_right,
	output wire carry_to_left
);
	reg ff01;	// the bit
	reg ff02 = 0;	// carry to the left
	wire carry_digit = from_ar & ff01;	// GT 06

	reg carry_clear_dly;
	reg comp_dly;		// DE 01

	wire carry = carry_from_right | carry_in;
	assign carry_to_left = carry & ff01;	// GT 05
	assign carry_out = carry_clear & ff02;	// GT 12

	initial zero_to_left = 0;
	initial one_to_left = 0;
	reg zero_from_left = 0;
	reg one_from_left = 0;

	always @(posedge clk) begin
		carry_clear_dly <= carry_out | (shift_carry&~left_digit);
		comp_dly <= from_ar | carry;
		zero_to_left <= shift_left & ~ff01;
		one_to_left <= shift_left & ff01;
		zero_from_left <= shift_carry & ~(left_digit^ff02);
		one_from_left <= shift_carry & (left_digit^ff02);

		if(clear) ff01 <= 0;
		if(complement | comp_dly) ff01 <= ~ff01;
		if(carry_clear_dly) ff02 <= 0;
		if(carry_digit) ff02 <= 1;
		if(zero_from_right | zero_from_left) ff01 <= 0;
		if(one_from_right | one_from_left) ff01 <= 1;
	end

	assign acn = ff01;
	assign cryn = ff02;
endmodule

module ww_ac0(input wire clk,
	output wire acn,
	// control signals  
	input wire from_ar,
	input wire clear,
	input wire complement,
	input wire shift_left,
	input wire shift_carry,
	// shifting
	input wire zero_from_right,
	input wire one_from_right,
	output reg zero_to_left,
	output reg one_to_left,
	// are these even used?
	input wire zero_from_left,
	input wire one_from_left,
	// immediate carry
	input wire carry_in,
	output wire carry_out,
	// carry that skipped a stage
	input wire carry_from_right,
	output wire carry_to_left
);
	reg ff01;	// the bit
	wire carry_digit = from_ar & ff01;	// GT 06

	reg comp_dly;		// DE 01

	wire carry = carry_from_right | carry_in;
	assign carry_to_left = carry & ff01;	// GT05

	assign carry_out = carry | carry_digit;

	initial zero_to_left = 0;
	initial one_to_left = 0;

	always @(posedge clk) begin
		comp_dly <= from_ar | carry;
		zero_to_left <= shift_left & ~ff01;
		one_to_left <= shift_left & ff01;

		if(clear) ff01 <= 0;
		if(complement | comp_dly) ff01 <= ~ff01;
		if(zero_from_right | zero_from_left) ff01 <= 0;
		if(one_from_right | one_from_left) ff01 <= 1;
	end

	assign acn = ff01;
endmodule

module ww_br_slice(input wire clk,
	output wire brn,
	// control signals 
	input wire from_ac,
	input wire clear,
	input wire shift_left,
	input wire shift_right,
	// shifting
	input wire zero_from_right,
	input wire one_from_right,
	output reg zero_to_right,
	output reg one_to_right,
	input wire zero_from_left,
	input wire one_from_left,
	output reg zero_to_left,
	output reg one_to_left
);
	reg ff01 = 0;

	initial begin
		zero_to_right <= 0;
		one_to_right <= 0;
		zero_to_left <= 0;
		one_to_left <= 0;
	end

	always @(posedge clk) begin
		if(clear | zero_from_right | zero_from_left) ff01 <= 0;
		if(from_ac | one_from_right | one_from_left) ff01 <= 1;
		zero_to_right <= shift_right & ~ff01;
		one_to_right <= shift_right & ff01;
		zero_to_left <= shift_left & ~ff01;
		one_to_left <= shift_left & ff01;
	end

	assign brn = ff01;
endmodule

module ww_ff_storage(input wire clk,
	input wire [0:15] sw_input,
	input wire initial_value,
	input wire clear,
	input wire clear_low,
	input wire select,
	input wire [0:15] in,
	output wire [0:15] out
);
	reg [0:15] storage_ff;	// FF 203.01

	always @(posedge clk) begin
		if(select) begin
			if(clear)
				storage_ff <= 0;
			else if(clear_low)
				storage_ff[5:15] <= 0;
			else
				storage_ff <= storage_ff | in;	// GT 203.05
		end
		if(initial_value)
			storage_ff <= sw_input;
	end
	assign out = {16{select}} & storage_ff;	// GT 203.04
endmodule
