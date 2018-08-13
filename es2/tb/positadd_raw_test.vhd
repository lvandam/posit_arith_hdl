library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pe_package.all;

entity positadd_raw_test is
end positadd_raw_test;

architecture rtl of positadd_raw_test is

  constant POSIT_NBITS                        : natural := 32;
  constant POSIT_ES                           : natural := 3;
  constant POSIT_SERIALIZED_WIDTH_ES2         : natural := 1+8+27+1+1;
  constant POSIT_SERIALIZED_WIDTH_SUM_ES2     : natural := 1+8+31+1+1;
  constant POSIT_SERIALIZED_WIDTH_PRODUCT_ES2 : natural := 1+9+56+1+1;

  subtype value is std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
  subtype value_sum is std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
  subtype value_product is std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);

  component posit_normalize_sum
    port (
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      result : out std_logic_vector(POSIT_NBITS-1 downto 0);
      inf    : out std_logic;
      zero   : out std_logic
      );
  end component;

  component posit_extract_raw
    port (
      in1      : in  std_logic_vector(POSIT_NBITS-1 downto 0);
      absolute : out std_logic_vector(31-1 downto 0);
      result   : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0)
      );
  end component;

  component positadd_4_raw
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      done   : out std_logic
      );
  end component;

  component posit_normalize
    port (
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      result : out std_logic_vector(POSIT_NBITS-1 downto 0);
      inf    : out std_logic;
      zero   : out std_logic
      );
  end component;

  component positadd_8_raw
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positmult_4_raw
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positmult_4_raw_sumval
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      done   : out std_logic
      );
  end component;

  signal clk : std_logic := '0';

  signal posit_gadtl      : value     := (others => '0');
  signal posit_sum        : value_sum := (others => '0');
  signal posit_product    : value_product := (others => '0');
  signal posit_normalized, posit_sum_real : std_logic_vector(31 downto 0);

begin

  clk <= not clk after 5 ns;

  extract : posit_extract_raw port map (
    in1      => x"303DB5C8",
    absolute => open,
    result   => posit_gadtl
    );

  add : positadd_4_raw port map (
    clk    => clk,
    in1    => posit_gadtl,--"01111110111111100100010111000010000001",
    in2    => posit_gadtl,
    start  => '1',
    result => posit_sum,
    done   => open
    );

  normalize_sum : posit_normalize port map (
    in1    => sum2val(posit_sum),
    result => posit_sum_real,
    inf    => open,
    zero   => open
    );

  mul : positmult_4_raw_sumval port map (
    clk    => clk,
    in1    => posit_sum,
    in2    => posit_gadtl,
    start  => '1',
    result => posit_product,
    done   => open
    );

  normalize : posit_normalize port map (
    in1    => prod2val(posit_product),
    result => posit_normalized,
    inf    => open,
    zero   => open
    );

end rtl;
