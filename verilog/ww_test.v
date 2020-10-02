`default_nettype none
`timescale 1ns/1ns

module clock(output reg clk, output reg reset);
	initial begin
		clk = 0;
		reset = 1;
		#500 reset = 0;
	end

	always #10 clk = ~clk;
endmodule

module ww1_test;
	wire clk, reset;
	clock clock(clk, reset);

	ww ww(
		.clk(clk),
		.reset(reset)
	);

	initial begin
		@(reset);
/*
	// add test
		ww.sw_pc <= 'o3775;
		ww.sw_ts_24 <= 'o103743;
//		ww.sw_ts_25 <= 'o113744;	// ad
		ww.sw_ts_25 <= 'o127744;	// sa
//		ww.sw_ts_26 <= 'o103740;	// ca
//		ww.sw_ff_3 <= 'o177776;
//		ww.sw_ff_4 <= 'o100000;
		ww.sw_ff_3 <= 'o040000;
		ww.sw_ff_4 <= 'o040000;
*/

	// shift test
		ww.sw_pc <= 'o3776;
		ww.sw_ts_25 <= 'o103743;
		ww.sw_ts_26 <= 'o154040;	// sl
//		ww.sw_ts_26 <= 'o160040;	// sr
		ww.sw_ff_3 <= 'o011111;

/*
	// mult test
		ww.sw_pc <= 'o3776;
		ww.sw_ts_25 <= 'o103743;
		ww.sw_ts_26 <= 'o147744;	// mh
//		ww.sw_ts_26 <= 'o143744;	// mr
		ww.sw_ff_3 <= 'o050000;
		ww.sw_ff_4 <= 'o060000;
*/
/*
	// div test
		// 0.11 * 0.101 = 0.01111
		ww.sw_pc <= 'o3775;
		ww.sw_ts_24 <= 'o103743;
		ww.sw_ts_25 <= 'o153744;	// dv
		ww.sw_ts_26 <= 'o154022;	// sl
		ww.sw_ff_3 <= 'o036000;
		ww.sw_ff_4 <= 'o060000;
*/
/*
	// sp/cp test
		ww.sw_pc <= 'o3776;
		ww.sw_ts_25 <= 'o103744;
//		ww.sw_ts_26 <= 'o074123;	// sp
		ww.sw_ts_26 <= 'o070123;	// cp
		ww.sw_ff_4 <= 'o100000;
*/
/*
	// ts/td test
		ww.sw_pc <= 'o3776;
		ww.sw_ts_25 <= 'o103744;
//		ww.sw_ts_26 <= 'o043743;	// ts
		ww.sw_ts_26 <= 'o047743;	// td
		ww.sw_ff_3 <= 'o177777;
		ww.sw_ff_4 <= 'o000000;
*/


		#100;
		ww.sw_reset <= 1;
		#100;
		ww.sw_reset <= 0;
		@(clk);
		ww.sw_enable_oscillator <= 1;

		#10;
		ww.storage_reset <= 1;
		#200;
		ww.storage_reset <= 0;
/*
		ww.clock_disabled <= 0;
		#200;
		btn_test <= 1;
		#200;
		btn_test <= 0;
*/
	end

/*
	initial begin: initmem
		integer i;
		for(i = 0; i < 'o200000; i = i+1)
			tx0.core[i] = 19'o1000000;
		for(i = 'o100; i < 'o200000; i = i+1)
			tx0.core[i] = 19'o1630000;	// halt
		for(i = 0; i < 'o20; i = i+1)
			tss[i] = 18'o10100 + i;
		for(i = 0; i < 'o20; i = i+1)
			tss_cmlr[i] = 2'b10;
		tx0.core[0] = 19'o0123456;
		tx0.core['o40] = 19'o1_445566;
		tx0.core['o100] = 19'o1_200040;
		tx0.core['o101] = 19'o1_000041;
	end
*/

	initial begin
		$dumpfile("dump.vcd");
		$dumpvars();

		#20000 $finish;
	end
endmodule
