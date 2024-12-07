library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mlp_top is
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        start : in STD_LOGIC;
        inputs : in STD_LOGIC_VECTOR(511 downto 0); -- 64 inputs, 8 bits each
        outputs : out STD_LOGIC_VECTOR(139 downto 0); -- 10 outputs, 14 bits each
        end_signal : out STD_LOGIC
    );
end mlp_top;

architecture Behavioral of mlp_top is
    -- Constants
    constant INPUT_SIZE : integer := 64;
    constant HIDDEN_SIZE : integer := 32;
    constant OUTPUT_SIZE : integer := 10;

    constant WEIGHT_WIDTH : integer := 9; -- Q1.8 1-bit for the integer part, 8-bits for the fraction part
    constant INTERMEDIATE_WIDTH : integer := 14; -- Q6.8 6-bits for the integer part, 8-bits for the fraction part

    -- Signals
    signal hidden_layer_outputs : signed(511 downto 0);
    signal hidden_layer_outputs_slv : STD_LOGIC_VECTOR(511 downto 0);
    signal output_layer_outputs : signed((OUTPUT_SIZE * INTERMEDIATE_WIDTH) - 1 downto 0);

    -- FSM states
    type state_type is (IDLE, PROCESS_HIDDEN, PROCESS_OUTPUT, DONE);
    signal state : state_type := IDLE;

    -- Counters
    signal input_index : integer := 0;
    signal hidden_index : integer := 0;
    signal output_index : integer := 0;
    signal rom_addr : integer := 0;

    -- Component declaration for ROM
    component mlp_rom
        Port (
            addr : in integer;
            data_out : out signed(8 downto 0)
        );
    end component;

    -- Signals for weights, biases and ROM data
    signal current_hidden_weights : signed(INPUT_SIZE * WEIGHT_WIDTH-1 downto 0); -- 64 inputs * 9 weights = 576 bits total
    --signal current_hidden_weights_reg :  signed(INPUT_SIZE * WEIGHT_WIDTH-1 downto 0);
    
    signal current_output_weights : signed(576 - 1 downto 0);
    
    signal current_bias : signed(WEIGHT_WIDTH - 1 downto 0);
    --signal current_bias_reg : signed(WEIGHT_WIDTH - 1 downto 0);
    
    signal current_output_weights_reg : signed(576 - 1 downto 0);
    signal current_bias_output_reg : signed(WEIGHT_WIDTH - 1 downto 0);
    
    signal rom_data : signed(8 downto 0);

begin

    -- Instantiate the ROM
    rom_inst: mlp_rom
        port map (
            addr => rom_addr,
            data_out => rom_data
        );

    -- FSM process
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            end_signal <= '0';
            rom_addr <= 0;
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= PROCESS_HIDDEN;
                        input_index <= 0;
                        hidden_index <= 0;
                        rom_addr <= 0;
                    end if;

                when PROCESS_HIDDEN => -- Compute hidden layer outputs
                    if hidden_index < HIDDEN_SIZE then -- Read weights for current hidden neuron
                        for j in 0 to INPUT_SIZE - 1 loop
                            current_hidden_weights(j * WEIGHT_WIDTH + WEIGHT_WIDTH - 1 downto j * WEIGHT_WIDTH) <= rom_data;
                            rom_addr <= rom_addr + 1;
                        end loop;
                        -- Read bias for current hidden neuron
                        current_bias <= rom_data;
                        rom_addr <= rom_addr + 1;

                        hidden_index <= hidden_index + 1;
                        
                        -- Register the current weights and bias
                        --current_hidden_weights_reg <= current_hidden_weights;
                        --current_bias_reg <= current_bias;
                    else
                        state <= PROCESS_OUTPUT;
                        output_index <= 0;
                    end if;

                when PROCESS_OUTPUT =>
                    -- Compute output layer outputs
                    if output_index < OUTPUT_SIZE then
                        -- Read weights for current output neuron
                        for j in 0 to HIDDEN_SIZE - 1 loop
                            current_output_weights(j * WEIGHT_WIDTH + WEIGHT_WIDTH - 1 downto j * WEIGHT_WIDTH) <= rom_data;
                            rom_addr <= rom_addr + 1;
                        end loop;
                        -- Read bias for current output neuron
                        current_bias <= rom_data;
                        rom_addr <= rom_addr + 1;

                        -- Register the current weights and bias
                        current_output_weights_reg <= current_output_weights;
                        current_bias_output_reg <= current_bias;
                    
                        output_index <= output_index + 1;
                    else
                        state <= DONE;
                    end if;

                when DONE =>
                    end_signal <= '1';
                    state <= IDLE;  -- Return to IDLE state after completion
            end case;
        end if;
    end process;

    -- Convert hidden layer outputs to STD_LOGIC_VECTOR
    hidden_layer_outputs_slv <= std_logic_vector(hidden_layer_outputs);

    -- Instantiate hidden neurons
    hidden_neurons: for i in 0 to HIDDEN_SIZE - 1 generate
        hidden_neuron_inst: entity work.Neuron
            port map (
                clk => clk,
                inputs => inputs,
                weights => current_hidden_weights,
                bias => current_bias,
                output => hidden_layer_outputs(i * INTERMEDIATE_WIDTH + INTERMEDIATE_WIDTH - 1 downto i * INTERMEDIATE_WIDTH)
            );
    end generate;

    -- Instantiate output neurons
    output_neurons: for i in 0 to OUTPUT_SIZE - 1 generate
        output_neuron_inst: entity work.Neuron
            port map (
                clk => clk,
                inputs => hidden_layer_outputs_slv,
                weights => current_output_weights_reg,
                bias => current_bias_output_reg,
                output => output_layer_outputs(i * INTERMEDIATE_WIDTH + INTERMEDIATE_WIDTH - 1 downto i * INTERMEDIATE_WIDTH)
            );
    end generate;
    
    -- Assign final outputs
    outputs <= std_logic_vector(output_layer_outputs);
end Behavioral;
