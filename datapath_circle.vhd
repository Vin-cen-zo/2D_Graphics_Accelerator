library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath_circle is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        en_circ    : in  STD_LOGIC;
        instruction: in  STD_LOGIC_VECTOR(63 downto 0);
        
        circ_we    : out STD_LOGIC; -- Write Enable untuk Circle
        circ_addr  : out STD_LOGIC_VECTOR(16 downto 0); -- Alamat Framebuffer
        circ_done  : out STD_LOGIC -- Sinyal Selesai Menggambar Lingkaran
    );
end datapath_circle;

architecture Behavioral of datapath_circle is

    -- Register Parameter
    signal xc, yc, r : signed(11 downto 0); -- Center (xc, yc) dan radius r
    
    -- Variabel Bresenham
    signal x, y : signed(11 downto 0); -- Titik koordinat saat ini

    signal d    : signed(15 downto 0); -- Decision parameter
    
    -- Register Filling (Scanline)
    signal fill_y       : signed(11 downto 0); -- Y koordinat untuk garis horizontal
    signal fill_x_start : signed(11 downto 0); -- X awal untuk garis horizontal
    signal fill_x_end   : signed(11 downto 0); -- X akhir untuk garis horizontal
    signal curr_fill_x  : signed(11 downto 0); -- X saat ini dalam proses pengisian garis
    
    -- State Machine
    type state_type is (IDLE, LOAD, SETUP, SETUP_LINES, DRAW_LINE, CALC_NEXT, FINISHED); -- Definisi state
    signal state : state_type := IDLE; -- State awal
    
    -- Counter step simetri
    signal line_step : integer range 0 to 3 := 0; -- 4 garis simetri

begin

    process(clk)
        variable r_resized : signed(15 downto 0); -- Radius yang di-resize untuk perhitungan
        variable term_4x   : signed(15 downto 0); -- Variabel bantu untuk 4*x
        variable diff      : signed(15 downto 0); -- Variabel bantu untuk perhitungan selisih
    begin
        if rising_edge(clk) then
            if reset = '1' then -- Reset semua register dan state
                state <= IDLE;
                circ_we <= '0'; 
                circ_done <= '0';
                line_step <= 0;
            else
                case state is
                    when IDLE => -- Tunggu sinyal enable
                        circ_we <= '0'; 
                        circ_done <= '0';
                        if en_circ = '1' then 
                            state <= LOAD; 
                        end if;

                    when LOAD =>
                        -- Load parameter dari instruksi
                        xc <= signed("00" & instruction(59 downto 50)); -- 10 bit untuk xc
                        yc <= signed("00" & instruction(49 downto 40)); -- 10 bit untuk yc
                        r  <= signed("00" & instruction(39 downto 30)); -- 10 bit untuk radius r
                        state <= SETUP; -- Lanjut ke setup awal

                    when SETUP => -- Inisialisasi variabel Bresenham
                        x <= to_signed(0, 12); -- Mulai dari x = 0
                        y <= r; -- Mulai dari y = r
                        -- d = 3 - (2 * r)
                        r_resized := resize(r, 16); -- Resize radius ke 16 bit
                        d <= 3 - (r_resized + r_resized); -- Inisialisasi decision parameter
                        
                        state <= SETUP_LINES; -- Siap setup garis
                        line_step <= 0; -- Reset step garis

                    when SETUP_LINES => -- Siapkan garis horizontal simetris
                        circ_we <= '0'; -- Nonaktifkan write enable sementara
                        
                        -- Setup 4 garis horizontal simetris
                        case line_step is -- Pilih garis berdasarkan step
                            when 0 => -- Atas
                                fill_y       <= yc - y; -- Garis atas
                                fill_x_start <= xc - x; -- X mulai
                                fill_x_end   <= xc + x; -- X akhir
                            when 1 => -- Bawah
                                fill_y       <= yc + y; -- Garis bawah
                                fill_x_start <= xc - x; -- X mulai
                                fill_x_end   <= xc + x; -- X akhir
                            when 2 => -- Tengah Atas
                                fill_y       <= yc - x; -- Garis tengah atas
                                fill_x_start <= xc - y; -- X mulai
                                fill_x_end   <= xc + y; -- X akhir
                            when 3 => -- Tengah Bawah
                                fill_y       <= yc + x; -- Garis tengah bawah
                                fill_x_start <= xc - y; -- X mulai
                                fill_x_end   <= xc + y; -- X akhir
                        end case;
                        state <= DRAW_LINE; -- Lanjut ke gambar garis

                    when DRAW_LINE => -- Gambar garis horizontal
                        -- Logika Loop Horizontal (Scanline Filling)
                        if circ_we = '0' then -- Mulai garis baru
                            curr_fill_x <= fill_x_start; -- Set X saat ini ke awal
                            circ_we <= '1'; -- Mulai menggambar
                        else -- Sedang menggambar garis
                            -- Clipping & Drawing
                            if (curr_fill_x >= 0 and curr_fill_x < 512 and fill_y >= 0 and fill_y < 256) then -- Cek batas layar
                                circ_we <= '1'; -- Aktifkan write enable
                                circ_addr <= std_logic_vector(fill_y(7 downto 0)) & std_logic_vector(curr_fill_x(8 downto 0)); -- Alamat framebuffer
                            else -- Di luar batas layar
                                circ_we <= '0'; -- Nonaktifkan write enable
                            end if;
                            
                            -- Increment X
                            if curr_fill_x < fill_x_end then -- Lanjutkan menggambar garis
                                curr_fill_x <= curr_fill_x + 1;
                            else -- Garis selesai
                                circ_we <= '0'; -- Stop gambar baris ini
                                if line_step < 3 then -- Lanjut ke garis simetri berikutnya
                                    line_step <= line_step + 1; -- Increment step
                                    state <= SETUP_LINES; -- Setup garis berikutnya
                                else -- Semua garis simetri selesai
                                    line_step <= 0; -- Reset step
                                    state <= CALC_NEXT; -- Hitung titik berikutnya
                                end if;
                            end if;
                        end if;

                    when CALC_NEXT => -- Hitung titik berikutnya menggunakan Bresenham
                        circ_we <= '0'; -- Nonaktifkan write enable
                        if y < x then -- Selesai menggambar lingkaran
                            state <= FINISHED; -- Lanjut ke selesai
                        else -- Hitung titik berikutnya
                            x <= x + 1; -- Increment x
                            if d > 0 then -- Pilih pixel berdasarkan decision parameter
                                y <= y - 1; -- Decrement y
                                -- Rumus: d = d + 4 * (x - y) + 10
                                diff := resize(x - y, 16); -- Hitung (x - y)
                                term_4x := diff + diff + diff + diff; -- Kali 4
                                d <= d + term_4x + 10; -- Update decision parameter
                            else
                                -- Rumus: d = d + 4 * x + 6
                                diff := resize(x, 16); -- Hitung x
                                term_4x := diff + diff + diff + diff; -- Kali 4
                                d <= d + term_4x + 6; -- Update decision parameter
                            end if;
                            state <= SETUP_LINES; -- Kembali setup garis untuk titik baru
                        end if;

                    when FINISHED => -- Selesai menggambar lingkaran
                        circ_we <= '0';
                        circ_done <= '1';
                        if en_circ = '0' then 
                            state <= IDLE; -- Kembali ke idle saat sinyal enable dimatikan
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;