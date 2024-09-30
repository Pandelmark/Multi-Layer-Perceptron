library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mlp_top is
end tb_mlp_top;

architecture test_b of tb_mlp_top is

    -- Component declaration for mlp_top
    component mlp_top
        Port (
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            start : in STD_LOGIC;
            inputs : in STD_LOGIC_VECTOR(511 downto 0); -- 64 inputs, 8 bits each
            outputs : out STD_LOGIC_VECTOR(139 downto 0); -- 10 outputs, 14 bits each
            end_signal : out STD_LOGIC
        );
    end component;

    signal clk : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '0';
    signal start : STD_LOGIC := '0';
    signal inputs : STD_LOGIC_VECTOR(511 downto 0) := (others => '0');
    signal outputs : STD_LOGIC_VECTOR(139 downto 0);
    signal end_signal : STD_LOGIC;

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin

    uut: mlp_top
        Port map (
            clk => clk,
            reset => reset,
            start => start,
            inputs => inputs,
            outputs => outputs,
            end_signal => end_signal
        );

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        start <= '1';

        for i in 0 to 63 loop
            if i mod 2 = 0 then
                inputs(i*8+7 downto i*8) <= "00000000"; -- Alternating bits 00000000
            else
                inputs(i*8+7 downto i*8) <= "11111111"; -- Alternating bits 11111111
            end if;
        end loop;

        wait for 1000 ns;
        -- Wait for the end signal
        wait until end_signal = '1';

    end process;
end test_b;
