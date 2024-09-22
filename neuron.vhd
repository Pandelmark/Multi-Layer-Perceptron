library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity neuron is
    Port (
        clk : in STD_LOGIC;
        inputs : in STD_LOGIC_VECTOR(511 downto 0); -- 64 inputs, 8 bits each
        weights : in signed(575 downto 0); -- 64 weights, 9 bits each
        bias : in signed(8 downto 0); -- 9 bits bias
        output : out signed(13 downto 0) -- 14 bits output
    );
end neuron;

architecture Behavioral of neuron is
    signal sum : signed(13 downto 0); -- Intermediate sum (Q6.8)
    signal partial_sum : signed(13 downto 0);
    signal bias_ext : signed(4 downto 0) := (others => bias(8)); -- 5 remaining to the sum bits
    signal sig_tmp : signed(16 downto 0) := (others => '0');
    signal reg1 : signed(13 downto 0);
BEGIN
    process(clk)
    begin
        if rising_edge(clk) then
            sum <= signed(std_logic_vector(bias & bias_ext)); -- Initialise with the value of bias and it's "padding" to fit sum, that way we also buy some time for later.
            for i in 0 to 63 loop
                -- Convert input from std_logic_vector to signed
                sig_tmp <= signed(inputs(i*8+7 downto i*8)) * weights(i*9+8 downto i*9); -- Here are calculated the parts of the sum multiplication result where it's double the bits+1 (1 is the extra sign)
                -- We create one extra temporary signal of 17-bit to store the above value and then
                partial_sum <= sig_tmp(15 downto 2); -- we keep only the nessessary bits by trimming 2 from the LSB side.
                reg1 <= resize(sum + partial_sum, sum'length); -- one extra sign. It is being removed by setting the length = sum
            end loop;
            output <= reg1;  -- This decreases WPWS by a lot!
        end if;
    end process;
end Behavioral;
