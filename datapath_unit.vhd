library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath_unit is
    Port ( 
        clk, reset    : in  STD_LOGIC;
        instruction   : in  STD_LOGIC_VECTOR(63 downto 0);
        
        -- Inputs Enable
        en_clear, en_rect, en_tri, en_line, en_circ, en_char : in STD_LOGIC; -- Enable untuk masing-masing engine
        reg_color_we  : in  STD_LOGIC; -- Write Enable untuk Register Warna
        
        -- Outputs Done
        clear_done, rect_done, tri_done, line_done, circ_done, char_done : out STD_LOGIC; -- Done untuk masing-masing engine
        
        -- Output VRAM
        vram_we       : out STD_LOGIC; -- Write Enable ke VRAM
        vram_addr     : out STD_LOGIC_VECTOR(16 downto 0); -- Alamat VRAM
        vram_data     : out STD_LOGIC_VECTOR(23 downto 0) -- Data Warna ke VRAM
    );
end datapath_unit;

architecture Behavioral of datapath_unit is

    -- Komponen-komponen
    component datapath_rectangle is
        Port ( 
            clk, reset, en_rect : in  STD_LOGIC; 
            instruction         : in  STD_LOGIC_VECTOR(63 downto 0);
            rect_we             : out STD_LOGIC;
            rect_addr           : out STD_LOGIC_VECTOR(16 downto 0);
            rect_done           : out STD_LOGIC 
        );
    end component;

    component datapath_triangle is
        Port ( 
            clk, reset, en_tri : in  STD_LOGIC; 
            instruction        : in  STD_LOGIC_VECTOR(63 downto 0);
            tri_we             : out STD_LOGIC; 
            tri_addr           : out STD_LOGIC_VECTOR(16 downto 0); 
            tri_done           : out STD_LOGIC
        );
    end component;
    
    component datapath_line is
        Port ( 
            clk, reset, en_line : in  STD_LOGIC; 
            instruction         : in  STD_LOGIC_VECTOR(63 downto 0);
            line_we             : out STD_LOGIC;
            line_addr           : out STD_LOGIC_VECTOR(16 downto 0);
            line_done           : out STD_LOGIC
        );
    end component;

    component datapath_circle is
        Port ( 
            clk, reset, en_circ : in  STD_LOGIC; 
            instruction         : in  STD_LOGIC_VECTOR(63 downto 0);
            circ_we             : out STD_LOGIC; 
            circ_addr           : out STD_LOGIC_VECTOR(16 downto 0); 
            circ_done           : out STD_LOGIC
        );
    end component;

    component datapath_char is
        Port ( 
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            en_char    : in  STD_LOGIC;
            instruction: in  STD_LOGIC_VECTOR(63 downto 0);
            
            char_we    : out STD_LOGIC;
            char_addr  : out STD_LOGIC_VECTOR(16 downto 0);
            char_done  : out STD_LOGIC
        );
    end component;

    signal active_color : std_logic_vector(23 downto 0); -- Register Warna Aktif
    
    -- Internal Signals
    signal clear_counter : unsigned(16 downto 0); -- Counter untuk Clear Engine
    signal clear_we_int : std_logic; -- Write Enable untuk Clear Engine
    signal clear_addr_int : std_logic_vector(16 downto 0); -- Alamat untuk Clear Engine
    
    signal rect_we_int, tri_we_int, line_we_int, circ_we_int, char_we_int : std_logic; -- Write Enable untuk masing-masing engine
    signal rect_addr_int, tri_addr_int, line_addr_int, circ_addr_int, char_addr_int : std_logic_vector(16 downto 0); -- Alamat untuk masing-masing engine
    
begin

    -- Register Warna
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then 
                active_color <= (others => '0'); -- Reset ke hitam
            elsif reg_color_we = '1' then 
                active_color <= instruction(23 downto 0); -- Update warna dari instruksi
            end if;
        end if;
    end process;
    vram_data <= active_color; -- Output warna ke VRAM

    -- Engine 1: Clear
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then -- Reset asynchronous
                clear_counter <= (others => '0'); 
                clear_we_int <= '0'; 
                clear_done <= '0'; 
            else
                clear_done <= '0';
                if en_clear = '1' then
                    clear_we_int <= '1';
                    clear_addr_int <= std_logic_vector(clear_counter);
                    if clear_counter < 131071 then 
                        clear_counter <= clear_counter + 1; -- Increment counter jika belum selesai
                    else -- Sudah selesai clear seluruh VRAM
                        clear_we_int <= '0'; 
                        clear_done <= '1'; 
                    end if;
                else
                    clear_we_int <= '0'; clear_counter <= (others => '0'); -- Reset counter saat tidak di-enable
                end if;
            end if;
        end if;
    end process;

    -- Instansiasi Engine Lainnya
    inst_rect: datapath_rectangle 
    port map (
        clk => clk, 
        reset => reset, 
        en_rect => en_rect, 
        instruction => instruction,
        rect_we => rect_we_int, 
        rect_addr => rect_addr_int, 
        rect_done => rect_done
    );

    inst_tri: datapath_triangle 
    port map (
        clk => clk, 
        reset => reset, 
        en_tri => en_tri, 
        instruction => instruction,
        tri_we => tri_we_int, 
        tri_addr => tri_addr_int, 
        tri_done => tri_done
    );
    --
    inst_line: datapath_line 
    port map ( 
        clk => clk, 
        reset => reset, 
        en_line => en_line, 
        instruction => instruction,
        line_we => line_we_int, 
        line_addr => line_addr_int, 
        line_done => line_done
    );

    inst_circ: datapath_circle 
    port map (
        clk => clk, 
        reset => reset, 
        en_circ => en_circ, 
        instruction => instruction,
        circ_we => circ_we_int, 
        circ_addr => circ_addr_int, 
        circ_done => circ_done
    );

    inst_char: datapath_char 
    port map (
        clk => clk, 
        reset => reset, 
        en_char => en_char, 
        instruction => instruction,
        char_we => char_we_int, 
        char_addr => char_addr_int, 
        char_done => char_done
    );

    -- MUX untuk VRAM Output
    process(en_clear, 
            en_rect, 
            en_tri, 
            en_line, 
            en_circ,
            en_char,
            clear_we_int, 
            clear_addr_int, 
            rect_we_int, 
            rect_addr_int, 
            tri_we_int, 
            tri_addr_int, 
            line_we_int, 
            line_addr_int,
            circ_we_int, 
            circ_addr_int,
            char_we_int,
            char_addr_int
    )
    begin
        -- Prioritas Clear > Rectangle > Triangle > Line > Circle
        if en_clear = '1' then
            vram_we <= clear_we_int; 
            vram_addr <= clear_addr_int;
        elsif en_rect = '1' then
            vram_we <= rect_we_int; 
            vram_addr <= rect_addr_int;
        elsif en_tri = '1' then
            vram_we <= tri_we_int; 
            vram_addr <= tri_addr_int;
        elsif en_line = '1' then
            vram_we <= line_we_int; 
            vram_addr <= line_addr_int;
        elsif en_circ = '1' then
            vram_we <= circ_we_int; 
            vram_addr <= circ_addr_int;
        elsif en_char = '1' then
            vram_we <= char_we_int; 
            vram_addr <= char_addr_int;
        else
            vram_we <= '0'; 
            vram_addr <= (others => '0');
        end if;
    end process;

end Behavioral;