library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity gpu is
    Port ( 
        clk, reset, start : in STD_LOGIC;
        instruction : in STD_LOGIC_VECTOR(63 downto 0); -- Instruction code
        busy, done : out STD_LOGIC;
        dump_mode : in STD_LOGIC;   -- Enable print ke .bmp
        dump_addr : in STD_LOGIC_VECTOR(16 downto 0);   -- Letak pixel dibaca dari vram
        dump_data_out : out STD_LOGIC_VECTOR(23 downto 0)   -- Meneruskan warna yang tersimapn di vram
    );
end gpu;

architecture Behavioral of gpu is

    component control_unit is
        Port ( 
            clk, reset, start : in STD_LOGIC;
            instruction : in STD_LOGIC_VECTOR(63 downto 0); -- Instruction code
            clear_done, rect_done, tri_done, line_done, circ_done, char_done : in STD_LOGIC; -- Selesai instruction
            en_clear, en_rect, en_tri, en_line, en_circ, reg_color_we, en_char : out STD_LOGIC; -- Melakukan instruction
            busy, done : out STD_LOGIC  -- Sedang ada instruction atau sedang idle
            );
    end component;

    component datapath_unit is
        Port ( 
            clk, reset : in STD_LOGIC;
            instruction : in STD_LOGIC_VECTOR(63 downto 0); -- Instruction code
            en_clear, en_rect, en_tri, en_line, en_circ, reg_color_we, en_char : in STD_LOGIC; -- Selesai instruction
            clear_done, rect_done, tri_done, line_done, circ_done, char_done : out STD_LOGIC; -- Melakukan instruction
            vram_we : out STD_LOGIC;    -- Vram write enable
            vram_addr : out STD_LOGIC_VECTOR(16 downto 0);  -- Vram address pixel
            vram_data : out STD_LOGIC_VECTOR(23 downto 0)   -- Vram color memory
            );
    end component;

    component gpu_vram is 
        Port ( 
            clk, we : in STD_LOGIC; 
            addr : in STD_LOGIC_VECTOR(16 downto 0);    -- Vram address pixel
            data_in : in STD_LOGIC_VECTOR(23 downto 0); -- Vram write color
            data_out : out STD_LOGIC_VECTOR(23 downto 0)    -- Vram read color
            );
    end component;

    -- Sinyal control set warna, clear canvas, gambar segiempat, gambar segitiga, gambar garis
    signal ctrl_reg_color_we, ctrl_en_clear, ctrl_en_rect, ctrl_en_tri, ctrl_en_line, ctrl_en_circ, ctrl_en_char : std_logic;
    
    -- Sinyal done clear canvas, gambar segiempat, gambar segitiga, gambar garis
    signal dp_clear_done, dp_rect_done, dp_tri_done, dp_line_done, dp_circ_done, dp_char_done : std_logic;
    
    -- Sinyal penghubung antar komponen
    signal dp_vram_we, final_we : std_logic;
    signal dp_vram_addr, final_addr : std_logic_vector(16 downto 0);
    signal dp_vram_data : std_logic_vector(23 downto 0);

begin

    -- Menghubungkan port dari control unit
    inst_cu: control_unit port map (
        clk => clk, 
        reset => reset, 
        start => start, 
        instruction => instruction,
        clear_done => dp_clear_done, 
        rect_done => dp_rect_done, 
        tri_done => dp_tri_done, 
        line_done => dp_line_done,
        circ_done => dp_circ_done,
        char_done => dp_char_done,
        en_clear => ctrl_en_clear, 
        en_rect => ctrl_en_rect, 
        en_tri => ctrl_en_tri, 
        en_line => ctrl_en_line,
        en_circ => ctrl_en_circ,
        en_char => ctrl_en_char,
        reg_color_we => ctrl_reg_color_we, 
        busy => busy, 
        done => done
    );

    -- Menghubungkan port dari datapath unit
    inst_dp: datapath_unit port map (
        clk => clk, 
        reset => reset, 
        instruction => instruction,
        en_clear => ctrl_en_clear, 
        en_rect => ctrl_en_rect, 
        en_tri => ctrl_en_tri, 
        en_line => ctrl_en_line,
        en_circ => ctrl_en_circ,
        en_char => ctrl_en_char,
        reg_color_we => ctrl_reg_color_we,
        clear_done => dp_clear_done, 
        rect_done => dp_rect_done, 
        tri_done => dp_tri_done, 
        line_done => dp_line_done,
        circ_done => dp_circ_done,
        char_done => dp_char_done,
        vram_we => dp_vram_we, 
        vram_addr => dp_vram_addr, 
        vram_data => dp_vram_data
    );

    -- Multiplexer untuk memilih mode Read atau Write pada Vram
    -- dump_mode = 0 untuk read (menggambar), menghubungkan gpu dan vram
    -- dump_mode = 1 untuk write (print), menghubungkan testbench dan vram
    final_we   <= dp_vram_we   when dump_mode = '0' else '0'; 
    final_addr <= dp_vram_addr when dump_mode = '0' else dump_addr;

    -- Menghubungkan port dari vram
    inst_vram: gpu_vram port map (
        clk => clk, 
        we => final_we, 
        addr => final_addr,
        data_in => dp_vram_data, 
        data_out => dump_data_out
    );

end Behavioral;