library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package fft_types is
	attribute delay: integer;
	constant COMPLEXWIDTH: integer := 32;
	type complex is record
		re: signed(COMPLEXWIDTH-1 downto 0);
		im: signed(COMPLEXWIDTH-1 downto 0);
    end record;
    function "+" (Left, Right: complex) return complex;
    function "-" (Left, Right: complex) return complex;
    function "-" (Right: complex) return complex;
    function "*" (Left: complex; Right: integer) return complex;
    function "/" (Left: complex; Right: integer) return complex;
    function to_complex (re,im: integer) return complex;
    function to_complex (re,im: signed) return complex;
    function complex_re(val: complex; bits: integer) return signed;
    function complex_im(val: complex; bits: integer) return signed;
    
    function saturate (val: complex; bits: integer) return complex;
    function keepNBits (val: complex; bits: integer) return complex;
    function shift_left(val: complex; N: integer) return complex;
    function shift_right(val: complex; N: integer) return complex;
    function rotate_quarter(val: complex) return complex;
    function rotate_mquarter(val: complex) return complex;
    
    
	type complexArray is array(integer range<>) of complex;
	
	function reverse_bits(val: unsigned) return unsigned;
	function reverse_bits(val, bits: integer) return integer;
	
	
	function complex_str(val: complex) return String;
	
	function iif(Cond: BOOLEAN; If_True, If_False: integer) return integer;
	
	type scalingModes is (SCALE_DIV_N, SCALE_DIV_SQRT_N, SCALE_NONE);
	
	function scalingShift(scale: scalingModes; order: integer) return integer;
end package;

package body fft_types is
	function "+" (Left, Right: complex) return complex is
		variable res: complex;
	begin
		res.re := Left.re + Right.re;
		res.im := Left.im + Right.im;
		return res;
	end function;
	
	function "-" (Left, Right: complex) return complex is
		variable res: complex;
	begin
		res.re := Left.re - Right.re;
		res.im := Left.im - Right.im;
		return res;
	end function;
	
	function "-" (Right: complex) return complex is
		variable res: complex;
	begin
		res.re := -Right.re;
		res.im := -Right.im;
		return res;
	end function;
	
	function "*" (Left: complex; Right: integer) return complex is
		variable res: complex;
	begin
		res.re := Left.re * Right;
		res.im := Left.im * Right;
		return res;
	end function;
	
    function "/" (Left: complex; Right: integer) return complex is
		variable res: complex;
	begin
		res.re := Left.re / Right;
		res.im := Left.im / Right;
		return res;
	end function;
    
	function to_complex (re,im: integer) return complex is
		variable res: complex;
	begin
		res.re := to_signed(re, COMPLEXWIDTH);
		res.im := to_signed(im, COMPLEXWIDTH);
		return res;
	end function;
	
	function to_complex (re,im: signed) return complex is
		variable res: complex;
	begin
		res.re := resize(re, COMPLEXWIDTH);
		res.im := resize(im, COMPLEXWIDTH);
		return res;
	end function;
	
	function complex_re(val: complex; bits: integer) return signed is
	begin
		return val.re(bits-1 downto 0); --to_signed(val.re, bits);
	end function;
    function complex_im(val: complex; bits: integer) return signed is
	begin
		return val.im(bits-1 downto 0); --to_signed(val.im, bits);
	end function;
	
	function saturate(val: complex; bits: integer) return complex is
		variable res: complex;
		--variable max1: integer := (2**(bits-1))-1;
		--variable min1: integer := 1-(2**(bits-1));
		
		variable max1: signed(COMPLEXWIDTH-1 downto 0) := to_signed((2**(bits-1))-1, COMPLEXWIDTH);
		variable min1: signed(COMPLEXWIDTH-1 downto 0) := to_signed((2**(bits-1))-1, COMPLEXWIDTH);
	begin
		res := val;
		if(res.re > max1) then
			res.re := max1;
		end if;
		if(res.re < min1) then
			res.re := min1;
		end if;
		if(res.im > max1) then
			res.im := max1;
		end if;
		if(res.im < min1) then
			res.im := min1;
		end if;
		return res;
	end function;
	
	function keepNBits(val: complex; bits: integer) return complex is
		variable re1, im1: signed(COMPLEXWIDTH-1 downto 0);
		variable res: complex;
	begin
		re1 := val.re; --to_signed(val.re, 32);
		im1 := val.im; --to_signed(val.im, 32);
		res.re := resize(re1(bits-1 downto 0), COMPLEXWIDTH);
		res.im := resize(im1(bits-1 downto 0), COMPLEXWIDTH);
		return res;
	end function;
	
	function shift_left(val: complex; N: integer) return complex is
		variable res: complex;
	begin
		res.re := shift_left(val.re, N);
		res.im := shift_left(val.im, N);
		return res;
	end function;
	
    function shift_right(val: complex; N: integer) return complex is
		variable res: complex;
	begin
		res.re := shift_right(val.re, N);
		res.im := shift_right(val.im, N);
		return res;
	end function;
	
	
	function rotate_quarter(val: complex) return complex is
		variable res: complex;
	begin
		res.im := val.re;
		res.re := -val.im;
		return res;
	end function;
	
	function rotate_mquarter(val: complex) return complex is
		variable res: complex;
	begin
		res.im := -val.re;
		res.re := val.im;
		return res;
	end function;
	
	
	function reverse_bits(val: unsigned) return unsigned is
		variable res: unsigned(val'RANGE);
	begin
		for i in val'RANGE loop
			res(i) := val(val'left + val'right - i);
		end loop;
		return res;
	end function;
	
	function reverse_bits(val, bits: integer) return integer is
	begin
		return to_integer(reverse_bits(to_unsigned(val, bits)));
	end function;
	
	
	function complex_str(val: complex) return String is
	begin
		return integer'image(to_integer(val.re))
				& " "
				& integer'image(to_integer(val.im));
	end function;
	
	function iif(Cond: BOOLEAN; If_True, If_False: integer) return integer is
	begin
		if (Cond = TRUE) then
			return(If_True);
		else
			return(If_False);
		end if;
	end function iif;
	
	
	function scalingShift(scale: scalingModes; order: integer) return integer is
	begin
		if scale=SCALE_DIV_N then
			return order;
		elsif scale=SCALE_DIV_SQRT_N then
			return order/2;
		else
			return 0;
		end if;
	end function;
	

end package body;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.fft_types.all;
-- shift register of len stages
entity sr_complex is
	generic(len: integer := 8);
	Port (clk : in  STD_LOGIC;
			din : in  complex;
			dout : out  complex);
end;
architecture a of sr_complex is
	type arr_t is array(len downto 0) of complex;
	signal arr: arr_t;
begin
g:	for I in 0 to len-1 generate
		arr(I) <= arr(I+1) when rising_edge(clk);
	end generate;
	arr(len) <= din;
	dout <= arr(0);
end a;


