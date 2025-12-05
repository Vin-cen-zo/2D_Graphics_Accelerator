library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath_char is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        en_char    : in  STD_LOGIC;
        instruction: in  STD_LOGIC_VECTOR(63 downto 0);
        
        char_we    : out STD_LOGIC;
        char_addr  : out STD_LOGIC_VECTOR(16 downto 0);
        char_done  : out STD_LOGIC
    );
end datapath_char;

architecture Behavioral of datapath_char is

    component char_rom is
        Port ( 
            addr : in STD_LOGIC_VECTOR(7 downto 0);
            row  : in STD_LOGIC_VECTOR(2 downto 0);
            data : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    signal char_ascii : std_logic_vector(7 downto 0);
    signal start_x, start_y : unsigned(9 downto 0);
    
    -- Counters
    signal curr_row : unsigned(2 downto 0) := (others => '0'); -- 0 to 7
    signal curr_col : integer range 0 to 7 := 0;
    
    -- Font Data
    signal font_row_data : std_logic_vector(7 downto 0);
    
    type state_type is (IDLE, LOAD, FETCH_ROW, DRAW_PIXELS, NEXT_ROW, FINISHED);
    signal state : state_type := IDLE;

begin

    -- Instansiasi ROM
    inst_rom: char_rom port map (
        addr => char_ascii,
        row  => std_logic_vector(curr_row),
        data => font_row_data
    );

    process(clk)
        variable calc_y : unsigned(9 downto 0);
        variable calc_x : unsigned(9 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                char_we <= '0'; char_done <= '0';
            else
                case state is
                    when IDLE =>
                        char_we <= '0'; char_done <= '0';
                        if en_char = '1' then state <= LOAD; end if;

                    when LOAD =>
                        char_ascii <= instruction(59 downto 52);
                        start_x    <= unsigned(instruction(51 downto 42));
                        start_y    <= unsigned(instruction(41 downto 32));
                        curr_row   <= (others => '0');
                        state <= FETCH_ROW;

                    when FETCH_ROW =>
                        curr_col <= 0;
                        state <= DRAW_PIXELS;

                    when DRAW_PIXELS =>
                        -- Cek bit font
                        if font_row_data(7 - curr_col) = '1' then
                            char_we <= '1';
                            
                            -- Hitung alamat VRAM
                            calc_y := start_y + resize(curr_row, 10);
                            calc_x := start_x + to_unsigned(curr_col, 10);
                            char_addr <= std_logic_vector(calc_y(7 downto 0)) & std_logic_vector(calc_x(8 downto 0));
                        else
                            char_we <= '0';
                        end if;

                        if curr_col < 7 then
                            curr_col <= curr_col + 1;
                        else
                            state <= NEXT_ROW;
                            char_we <= '0';
                        end if;

                    when NEXT_ROW =>
                        if curr_row < 7 then
                            curr_row <= curr_row + 1;
                            state <= FETCH_ROW;
                        else
                            state <= FINISHED;
                        end if;

                    when FINISHED =>
                        char_we <= '0';
                        char_done <= '1';
                        if en_char = '0' then state <= IDLE; end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;