library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath_rectangle is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        
        -- Input dari Control Unit
        en_rect    : in  STD_LOGIC;  -- Sinyal Enable
        instruction: in  STD_LOGIC_VECTOR(63 downto 0); -- Instruksi 64-bit
        
        -- Output ke Datapath Utama
        rect_we    : out STD_LOGIC; -- Write Enable ke VRAM
        rect_addr  : out STD_LOGIC_VECTOR(16 downto 0); -- Alamat VRAM
        rect_done  : out STD_LOGIC -- Sinyal Selesai Menggambar
    );
end datapath_rectangle;

architecture Behavioral of datapath_rectangle is

    -- Register Internal untuk menyimpan parameter kotak
    signal r_x, r_y, r_w, r_h : unsigned(9 downto 0);  -- X, Y, Width, Height
    
    -- Counter Loop
    signal curr_x : unsigned(9 downto 0);  -- Current X position
    signal curr_y : unsigned(9 downto 0);  -- Current Y position
    
    -- State Machine Sederhana untuk Rect Engine
    type state_type is (IDLE, LOAD_PARAMS, DRAWING, FINISHED); 
    signal state : state_type := IDLE; 

begin

    process(clk)
    begin
        if rising_edge(clk) then 
            -- Asynchronous Reset
            if reset = '1' then 
                state <= IDLE; 
                rect_we <= '0'; 
                rect_done <= '0'; 
            else
                -- State Machine
                case state is
                    -- 1. Tunggu sinyal Enable
                    when IDLE =>
                        rect_done <= '0'; 
                        rect_we <= '0'; 
                        if en_rect = '1' then
                            state <= LOAD_PARAMS; -- Masuk ke Load Params jika di-enable
                        end if;

                    -- 2. Baca Parameter dari Instruksi 64-bit
                    when LOAD_PARAMS =>
                        -- Mapping Width [39:30], Height [29:20], X [19:10], Y [9:0]
                        r_w <= unsigned(instruction(39 downto 30));
                        r_h <= unsigned(instruction(29 downto 20));
                        r_x <= unsigned(instruction(19 downto 10));
                        r_y <= unsigned(instruction(9 downto 0));
                        
                        -- Siapkan counter awal
                        curr_x <= unsigned(instruction(19 downto 10)); -- Set ke X awal
                        curr_y <= unsigned(instruction(9 downto 0)); -- Set ke Y awal
                        
                        state <= DRAWING; -- Masuk ke state menggambar

                    -- 3. Loop Menggambar (Nested Loop)
                    when DRAWING =>
                        -- Cek apakah Y sudah melewati batas tinggi
                        if curr_y >= (r_y + r_h) then
                            state <= FINISHED; -- Masuk ke state selesai
                            rect_we <= '0';
                        else
                            -- Tulis ke VRAM
                            rect_we <= '1';
                            
                            -- Rumus Alamat 512 width: (Y * 512) + X
                            -- Karena 512 = 2^9, kita tinggal tempel bit (Concatenation)
                            -- Ambil 8 bit terbawah Y dan 9 bit terbawah X
                            rect_addr <= std_logic_vector(curr_y(7 downto 0)) & std_logic_vector(curr_x(8 downto 0));
                            
                            -- Update posisi X dan Y
                            if curr_x < (r_x + r_w - 1) then
                                curr_x <= curr_x + 1; -- Geser ke kanan
                            else
                                -- Ganti Baris (Carriage Return)
                                curr_x <= r_x;      -- Reset X ke kiri
                                curr_y <= curr_y + 1; -- Turun ke baris bawah
                            end if;
                        end if;

                    -- 4. Selesai
                    when FINISHED =>
                        rect_we <= '0';
                        rect_done <= '1'; -- Lapor ke Control Unit
                        
                        -- Tunggu sampai CU mematikan 'en_rect' biar tidak restart sendiri
                        if en_rect = '0' then
                            state <= IDLE; -- Kembali ke IDLE setelah selesai
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;