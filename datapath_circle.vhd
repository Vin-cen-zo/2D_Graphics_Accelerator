library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath_circle is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        en_circ    : in  STD_LOGIC;
        instruction: in  STD_LOGIC_VECTOR(63 downto 0);
        
        circ_we    : out STD_LOGIC; -- Write Enable untuk lingkaran
        circ_addr  : out STD_LOGIC_VECTOR(16 downto 0); -- Alamat memori untuk lingkaran
        circ_done  : out STD_LOGIC -- Sinyal selesai untuk lingkaran
    );
end datapath_circle;

architecture Behavioral of datapath_circle is

    -- Register Parameter
    signal xc, yc, r : signed(11 downto 0); -- Center (xc, yc) dan radius r
    
    -- Variabel Bresenham
    signal x, y : signed(11 downto 0); -- Current point
    signal d    : signed(13 downto 0); -- Decision parameter (14-bit)
    
    -- Register Filling (Scanline)
    signal fill_y       : signed(11 downto 0); -- Y coordinate untuk scanline
    signal fill_x_start : signed(11 downto 0); -- X start untuk scanline
    signal fill_x_end   : signed(11 downto 0); -- X end untuk scanline
    signal curr_fill_x  : signed(11 downto 0); -- Current X untuk scanline filling
    
    signal circ_we_int  : std_logic := '0'; -- Internal write enable
    
    -- State Machine
    type state_type is (IDLE, LOAD, SETUP, PREP_SCANLINE, DRAW_SCANLINE, CALC_NEXT, FINISHED); -- Tambah state PREP_SCANLINE
    signal state : state_type := IDLE; -- Initial state
    
    -- Counter step simetri
    signal line_step : integer range 0 to 3 := 0; -- 4 langkah simetri

begin

    circ_we <= circ_we_int; -- Hubungkan output dengan internal

    process(clk)
        -- Variabel matematika
        variable r_resized : signed(13 downto 0); -- Radius resized untuk perhitungan
        variable term_4x   : signed(13 downto 0); -- 4*x untuk perhitungan
        variable diff      : signed(13 downto 0); -- Perbedaan untuk perhitungan
    begin
        if rising_edge(clk) then
            if reset = '1' then -- Reset state machine
                state <= IDLE; -- Kembali ke IDLE
                circ_we_int <= '0'; -- Reset write enable
                circ_done <= '0'; -- Reset done signal
                line_step <= 0; -- Reset line step
            else
                case state is
                    when IDLE => -- State awal
                        circ_we_int <= '0'; -- Reset write enable
                        circ_done <= '0'; -- Reset done signal
                        if en_circ = '1' then -- Jika enable lingkaran aktif
                            state <= LOAD; -- Pindah ke LOAD
                        end if; 

                    when LOAD => -- Load parameter lingkaran
                        xc <= signed("00" & instruction(59 downto 50)); -- Center X
                        yc <= signed("00" & instruction(49 downto 40)); -- Center Y
                        r  <= signed("00" & instruction(39 downto 30)); -- Radius
                        state <= SETUP; -- Pindah ke SETUP

                    when SETUP => -- Inisialisasi Bresenham
                        x <= to_signed(0, 12); -- Start dari (0, r)
                        y <= r; -- Y = r
                        
                        -- Math d = 3 - 2*r
                        r_resized := resize(r, 14); -- Resize radius ke 14-bit
                        d <= 3 - (r_resized + r_resized); -- Inisialisasi decision parameter
                        
                        state <= PREP_SCANLINE; -- Pindah ke PREP_SCANLINE
                        line_step <= 0; -- Reset line step

                    when PREP_SCANLINE => -- Persiapan scanline filling
                        circ_we_int <= '0';
                        
                        -- Tentukan garis horizontal (scanline)
                        case line_step is -- 4 langkah simetri
                            when 0 => -- Atas
                                fill_y       <= yc - y; -- Y coordinate
                                fill_x_start <= xc - x; -- X start
                                fill_x_end   <= xc + x; -- X end
                            when 1 => -- Bawah
                                fill_y       <= yc + y; -- Y coordinate
                                fill_x_start <= xc - x; -- X start
                                fill_x_end   <= xc + x; -- X end
                            when 2 => -- Tengah Atas
                                fill_y       <= yc - x; -- Y coordinate
                                fill_x_start <= xc - y; -- X start
                                fill_x_end   <= xc + y; -- X end
                            when 3 => -- Tengah Bawah
                                fill_y       <= yc + x; -- Y coordinate
                                fill_x_start <= xc - y; -- X start
                                fill_x_end   <= xc + y; -- X end
                        end case;
                        state <= DRAW_SCANLINE; -- Pindah ke DRAW_SCANLINE

                    when DRAW_SCANLINE => -- Gambar scanline
                        if circ_we_int = '0' then -- Mulai scanline baru
                            curr_fill_x <= fill_x_start; -- Inisialisasi current X
                            circ_we_int <= '1'; -- Mulai tulis
                        else
                            -- Clipping & Drawing
                            if (curr_fill_x >= 0 and curr_fill_x < 512 and fill_y >= 0 and fill_y < 256) then -- Cek batas layar
                                circ_we_int <= '1'; -- Enable write
                                circ_addr <= std_logic_vector(fill_y(7 downto 0)) & std_logic_vector(curr_fill_x(8 downto 0)); -- Alamat memori
                            else -- Di luar batas layar
                                circ_we_int <= '0'; -- Non-aktifkan write jika di luar batas
                            end if;
                            
                            -- Loop X
                            if curr_fill_x < fill_x_end then -- Lanjutkan ke X berikutnya
                                curr_fill_x <= curr_fill_x + 1; -- Increment current X
                            else -- Selesai scanline saat ini
                                circ_we_int <= '0'; -- Stop
                                if line_step < 3 then -- Lanjut ke langkah simetri berikutnya
                                    line_step <= line_step + 1; -- Increment line step
                                    state <= PREP_SCANLINE; -- Kembali ke PREP_SCANLINE
                                else -- Semua langkah simetri selesai
                                    line_step <= 0; -- Reset line step
                                    state <= CALC_NEXT; -- Pindah ke CALC_NEXT
                                end if;
                            end if;
                        end if;

                    when CALC_NEXT => -- Hitung titik berikutnya menggunakan Bresenham
                        circ_we_int <= '0'; -- Non-aktifkan write
                        if y < x then -- Selesai menggambar lingkaran
                            state <= FINISHED; -- Pindah ke FINISHED
                        else -- Hitung titik berikutnya
                            x <= x + 1; -- Increment x
                            if d > 0 then -- Pilih pixel diagonal
                                y <= y - 1; -- Decrement y
                                -- Math d = d + 4(x-y) + 10
                                diff := resize(x - y, 14); -- Hitung (x - y)
                                term_4x := diff + diff + diff + diff; -- 4*(x - y)
                                d <= d + term_4x + 10; -- Update decision parameter
                            else -- Pilih pixel horizontal
                                -- Math d = d + 4x + 6
                                diff := resize(x, 14); -- Hitung x
                                term_4x := diff + diff + diff + diff; -- 4*x
                                d <= d + term_4x + 6; -- Update decision parameter
                            end if;
                            state <= PREP_SCANLINE; -- Kembali ke PREP_SCANLINE
                        end if;

                    when FINISHED => -- Selesai menggambar lingkaran
                        circ_we_int <= '0'; -- Non-aktifkan write
                        circ_done <= '1'; -- Set done signal
                        if en_circ = '0' then -- Jika enable lingkaran dimatikan
                            state <= IDLE; -- Kembali ke IDLE
                        end if; 
                end case;
            end if;
        end if;
    end process;

end Behavioral;