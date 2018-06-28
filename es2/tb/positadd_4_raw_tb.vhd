library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.posit_common.all;
use work.posit_package.all;

entity positadd_4_raw_tb is
end positadd_4_raw_tb;

architecture rtl of positadd_4_raw_tb is

  signal clk : std_logic := '0';

  signal add_truncated, add_truncated8                                           : std_logic;
  signal posit_raw                                                               : value         := (others => '0');
  signal posit_sum_raw, posit_sum8_raw                                           : value_sum     := (others => '0');
  signal posit_product_raw                                                       : value_product := (others => '0');
  signal posit_product, posit_sum, posit_sum8, posit_prod_sumval, posit_sum_prod : std_logic_vector(31 downto 0);
  signal posit_prod_sumval_raw                                                   : value_product;
  signal posit_sum_prod_raw                                                      : value_prod_sum;


begin

  clk <= not clk after 5 ns;

  extract : posit_extract_raw port map (
    in1      => x"303DB5C8",
    absolute => open,
    result   => posit_raw
    );

  add : positadd_4_raw port map (
    clk       => clk,
    in1       => posit_raw,
    in2       => posit_raw,
    start     => '1',
    result    => posit_sum_raw,
    done      => open,
    truncated => add_truncated
    );

  normalize_sum : posit_normalize port map (
    in1       => sum2val(posit_sum_raw),
    result    => posit_sum,             -- 383DB5C8
    inf       => open,
    zero      => open,
    truncated => add_truncated
    );

  add8 : positadd_8_raw port map (
    clk       => clk,
    in1       => posit_raw,
    in2       => posit_raw,
    start     => '1',
    result    => posit_sum8_raw,
    done      => open,
    truncated => add_truncated8
    );

  normalize_sum8 : posit_normalize port map (
    in1       => sum2val(posit_sum8_raw),
    result    => posit_sum8,            -- 383DB5C8
    inf       => open,
    zero      => open,
    truncated => add_truncated8
    );

  mul : positmult_4_raw port map (
    clk    => clk,
    in1    => posit_raw,
    in2    => posit_raw,
    start  => '1',
    result => posit_product_raw,
    done   => open
    );

  normalize : posit_normalize port map (
    in1       => prod2val(posit_product_raw),
    result    => posit_product,         -- 207D4794
    inf       => open,
    zero      => open,
    truncated => '0'
    );

  mul_sumval : positmult_4_raw_sumval port map (
    clk    => clk,
    in1    => posit_sum_raw,
    in2    => posit_raw,
    start  => '1',
    result => posit_prod_sumval_raw,
    done   => open
    );
  normalize_sumval : posit_normalize port map (
    in1       => prod2val(posit_prod_sumval_raw),
    result    => posit_prod_sumval,     -- 287D4794
    inf       => open,
    zero      => open,
    truncated => '0'
    );

  add_prod : positadd_prod_4_raw port map (
    clk    => clk,
    in1    => posit_product_raw,
    in2    => posit_product_raw,
    start  => '1',
    result => posit_sum_prod_raw,
    done   => open
    );
  normalize_sum_prod : posit_normalize port map (
    in1       => prodsum2val(posit_sum_prod_raw),
    result    => posit_sum_prod,        -- 287D4794
    inf       => open,
    zero      => open,
    truncated => '0'
    );



end rtl;
