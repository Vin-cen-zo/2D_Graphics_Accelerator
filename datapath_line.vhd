library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath_line is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        en_line    : in  STD_LOGIC;
        instruction: in  STD_LOGIC_VECTOR(63 downto 0);
        
        line_we    : out STD_LOGIC;
        line_addr  : out STD_LOGIC_VECTOR(16 downto 0);
        line_done  : out STD_LOGIC
    );
end datapath_line;

architecture Behavioral of datapath_line is

    signal x0, y0, x1, y1 : signed(11 downto 0);
    signal dx, dy : signed(11 downto 0);
    signal sx, sy : signed(11 downto 0); 
    signal err    : signed(13 downto 0); -- 14-bit
    
    signal curr_x, curr_y : signed(11 downto 0);
    
    type state_type is (IDLE, LOAD, SETUP, DRAWING, FINISHED);
    signal state : state_type := IDLE;

begin

    process(clk)
        variable e2 : signed(13 downto 0);
        variable v_err : signed(13 downto 0);
        variable v_x, v_y : signed(11 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                line_we <= '0'; line_done <= '0';
            else
                case state is
                    when IDLE =>
                        line_we <= '0'; line_done <= '0';
                        if en_line = '1' then state <= LOAD; end if;

                    when LOAD =>
                        x0 <= signed("00" & instruction(59 downto 50));
                        y0 <= signed("00" & instruction(49 downto 40));
                        x1 <= signed("00" & instruction(39 downto 30));
                        y1 <= signed("00" & instruction(29 downto 20));
                        state <= SETUP;

                    when SETUP =>
                        -- [FIX] Gunakan abs() dan resize()
                        dx <= abs(x1 - x0);
                        dy <= -abs(y1 - y0);
                        
                        if x0 < x1 then sx <= to_signed(1, 12); else sx <= to_signed(-1, 12); end if;
                        if y0 < y1 then sy <= to_signed(1, 12); else sy <= to_signed(-1, 12); end if;
                        
                        -- [FIX] Resize ke 14-bit
                        err <= resize(abs(x1 - x0) - abs(y1 - y0), 14);
                        
                        curr_x <= x0; curr_y <= y0;
                        state <= DRAWING;

                    when DRAWING =>
                        line_we <= '1';
                        line_addr <= std_logic_vector(curr_y(7 downto 0)) & std_logic_vector(curr_x(8 downto 0));
                        
                        if (curr_x = x1) and (curr_y = y1) then
                            state <= FINISHED;
                            line_we <= '0';
                        else
                            -- Kalkulasi Next Step
                            v_err := err;
                            v_x := curr_x;
                            v_y := curr_y;
                            
                            -- Shift aman
                            e2 := shift_left(v_err, 1);
                            
                            -- [FIX] Resize operand pembanding ke 14-bit
                            if e2 >= resize(dy, 14) then
                                v_err := v_err + resize(dy, 14);
                                v_x := v_x + sx;
                            end if;
                            
                            if e2 <= resize(dx, 14) then
                                v_err := v_err + resize(dx, 14);
                                v_y := v_y + sy;
                            end if;
                            
                            err <= v_err;
                            curr_x <= v_x;
                            curr_y <= v_y;
                        end if;

                    when FINISHED =>
                        line_we <= '0';
                        line_done <= '1';
                        if en_line = '0' then state <= IDLE; end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;