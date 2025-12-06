library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_gpu is
end tb_gpu;

architecture Behavioral of tb_gpu is

    component gpu
        Port ( 
            clk, reset, start : in STD_LOGIC;
            instruction : in STD_LOGIC_VECTOR(63 downto 0);
            busy, done : out STD_LOGIC;
            dump_mode : in STD_LOGIC; -- 1: Dump Mode, 0: Normal Mode
            dump_addr : in STD_LOGIC_VECTOR(16 downto 0); -- Address untuk dump mode
            dump_data_out : out STD_LOGIC_VECTOR(23 downto 0) -- Data output untuk dump mode
        );
    end component;

    signal clk, reset, start : std_logic := '0';
    signal instruction : std_logic_vector(63 downto 0) := (others => '0'); -- Instruksi 64-bit
    signal busy, done, dump_mode : std_logic := '0';
    signal dump_addr : std_logic_vector(16 downto 0) := (others => '0'); -- 17-bit address input
    signal dump_data_out : std_logic_vector(23 downto 0); -- 24-bit data output

    constant clk_period : time := 10 ns;
    type char_file is file of character; -- Tipe file untuk penanganan BMP
    type header_type is array (0 to 53) of character; -- Tipe untuk header BMP

begin

    uut_gpu: gpu port map (
        clk => clk, 
        reset => reset, 
        start => start, 
        instruction => instruction,
        busy => busy, 
        done => done, 
        dump_mode => dump_mode,
        dump_addr => dump_addr, 
        dump_data_out => dump_data_out
    );

    clk_process :process begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
        file bmp_in : char_file; -- File BMP untuk template header
        variable char_buffer : character; -- Buffer karakter untuk membaca header
        variable header_template : header_type; -- Template header BMP
        variable i : integer; -- Iterator

        -- Helper Instructions
        procedure send_cmd(cmd_hex : std_logic_vector(63 downto 0)) is -- Prosedur untuk mengirim instruksi ke GPU
        begin
            instruction <= cmd_hex; -- Set instruksi
            wait for 10 ns; -- 
            wait until rising_edge(clk);
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            wait for 20 ns;
            if busy = '1' then 
                wait until busy = '0'; 
            end if;
            wait for 20 ns;
        end procedure;

        procedure save_frame(filename : string) is
            file bmp_out : char_file; -- File BMP untuk output
            variable header : header_type; -- Header BMP
            variable x, y, r, g, b : integer; -- Koordinat dan warna pixel
            variable temp_data : std_logic_vector(23 downto 0); -- Data sementara untuk warna pixel
        begin
            report " >> SAVING: " & filename; -- Log penyimpanan frame
            dump_mode <= '1'; -- Aktifkan mode dump untuk membaca data frame 
            wait for 100 ns;
            file_open(bmp_out, filename, write_mode); -- Buka file BMP untuk ditulis
            header := header_template; -- Salin template header
            -- Patch 512x256
            header(18) := character'val(0); -- Width LSB
            header(19) := character'val(2); -- Width MSB
            header(20) := character'val(0); -- Height LSB
            header(21) := character'val(0); -- Height MSB
            header(22) := character'val(0); -- Depth LSB
            header(23) := character'val(1); -- Depth MSB
            header(24) := character'val(0); -- Reserved LSB
            header(25) := character'val(0); -- Reserved MSB

            for i in 0 to 53 loop -- Tulis header BMP
                write(bmp_out, header(i)); -- Tulis header ke file
            end loop; 
            for y in 255 downto 0 loop -- Tulis data pixel (BGR format)
                for x in 0 to 511 loop -- Iterasi setiap pixel
                    dump_addr <= std_logic_vector(to_unsigned((y * 512) + x, 17)); -- Set alamat dump
                    wait until rising_edge(clk); 
                    wait for 1 ns; 
                    temp_data := dump_data_out; -- Baca data pixel
                    r := to_integer(unsigned(temp_data(23 downto 16))); -- Ekstrak komponen merah
                    g := to_integer(unsigned(temp_data(15 downto 8))); -- Ekstrak komponen hijau
                    b := to_integer(unsigned(temp_data(7 downto 0))); -- Ekstrak komponen biru
                    write(bmp_out, character'val(b)); -- Tulis biru
                    write(bmp_out, character'val(g)); -- Tulis hijau
                    write(bmp_out, character'val(r)); -- Tulis merah
                end loop;
            end loop;
            file_close(bmp_out); -- Tutup file BMP
            dump_mode <= '0'; -- Nonaktifkan mode dump
            wait for 100 ns;
        end procedure;

        function rgb_to_instr(r, g, b : integer) return std_logic_vector is -- Fungsi untuk mengonversi RGB ke format instruksi GPU
        begin
            return x"1000000000" & -- Prefix untuk instruksi warna
            std_logic_vector(to_unsigned(r, 8)) & -- Komponen merah
            std_logic_vector(to_unsigned(g, 8)) & -- Komponen hijau
            std_logic_vector(to_unsigned(b, 8)); -- Komponen biru
        end function;

        -- Variabel Animasi
        variable frame_idx : integer; -- Indeks frame
        variable obj_x, obj_y : integer; -- Posisi objek
        variable sky_color, obj_color, ray_color, window_color : std_logic_vector(63 downto 0); -- Warna dinamis

    begin
        -- Setup
        file_open(bmp_in, "template.bmp", read_mode); -- Buka file template BMP untuk dibaca
        for i in 0 to 53 loop -- Baca header BMP
            read(bmp_in, char_buffer); -- Baca karakter dari file
            header_template(i) := char_buffer; -- Simpan ke template header
        end loop;
        file_close(bmp_in); -- Tutup file template BMP

        reset <= '1'; 
        wait for 100 ns; 
        reset <= '0'; 
        wait for 20 ns;

        -- LOOP ANIMASI 12 FRAME
        for frame_idx in 0 to 11 loop -- Iterasi setiap frame
            report "=== RENDERING FRAME " & integer'image(frame_idx) & " ===";

            -- 1. POSISI
            obj_x := 70 + ((frame_idx mod 6) * 75); -- Gerak horizontal dari kiri ke kanan
            
            case (frame_idx mod 6) is -- Gerak vertikal (terbit - puncak - terbenam)
                when 0 => obj_y := 190; -- Terbit
                when 1 => obj_y := 120; -- Naik
                when 2 => obj_y := 60;  -- Puncak
                when 3 => obj_y := 60;  -- Puncak
                when 4 => obj_y := 120; -- Turun
                when 5 => obj_y := 190; -- Terbenam
                when others => obj_y := 200;
            end case;

            -- 2. WARNA
            if frame_idx < 6 then
                -- SIANG
                obj_color := x"1000000000FFD700"; -- Matahari
                ray_color := x"1000000000FFA500"; -- Sinar
                window_color := x"10000000002F4F4F"; -- Jendela Gelap
                case frame_idx is -- Warna langit berubah-ubah
                    when 0 => sky_color := rgb_to_instr(255, 160, 122); -- Sunrise
                    when 1 => sky_color := rgb_to_instr(135, 206, 235); -- Siang
                    when 2 => sky_color := rgb_to_instr(0, 191, 255); -- Siang Terang
                    when 3 => sky_color := rgb_to_instr(0, 191, 255); -- Siang Terang
                    when 4 => sky_color := rgb_to_instr(135, 206, 235); -- Sore
                    when 5 => sky_color := rgb_to_instr(255, 140, 0); -- Sunset
                    when others => sky_color := x"1000000000000000"; -- Hitam
                end case;
            else
                -- MALAM
                obj_color := x"1000000000F0F8FF"; -- Bulan
                window_color := x"1000000000FFFF00"; -- Jendela Nyala
                case frame_idx is -- Warna langit berubah-ubah
                    when 6 => sky_color := rgb_to_instr(25, 25, 112); -- Senja
                    when 7 => sky_color := rgb_to_instr(0, 0, 50); -- Malam Awal
                    when 8 => sky_color := rgb_to_instr(0, 0, 0); -- Malam
                    when 9 => sky_color := rgb_to_instr(0, 0, 0); -- Malam
                    when 10 => sky_color := rgb_to_instr(0, 0, 50); -- Malam Awal
                    when 11 => sky_color := rgb_to_instr(25, 25, 112); -- Senja
                    when others => sky_color := x"1000000000000000"; -- Hitam
                end case;
            end if;

            -- 3. LAYER MENGGAMBAR
            -- L1: Langit
            send_cmd(sky_color); -- Set warna langit
            send_cmd(x"2000000000000000"); -- Clear Layar

            -- L2: SINAR MATAHARI
            if frame_idx < 6 then -- Hanya gambar sinar saat siang hari
                send_cmd(ray_color); -- Set warna sinar
                -- Gambar Sinar (Koordinat aman karena obj_x >= 70)
                -- Atas
                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x, 10)) & 
                    std_logic_vector(to_unsigned(obj_y - 40, 10)) & 
                    std_logic_vector(to_unsigned(obj_x, 10)) & 
                    std_logic_vector(to_unsigned(obj_y - 60, 10)) & x"00000"
                );
                -- Bawah
                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x, 10)) & 
                    std_logic_vector(to_unsigned(obj_y + 40, 10)) & 
                    std_logic_vector(to_unsigned(obj_x, 10)) & 
                    std_logic_vector(to_unsigned(obj_y + 60, 10)) & x"00000"
                );
                -- Kiri
                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x - 40, 10)) & 
                    std_logic_vector(to_unsigned(obj_y, 10)) & 
                    std_logic_vector(to_unsigned(obj_x - 60, 10)) & 
                    std_logic_vector(to_unsigned(obj_y, 10)) & x"00000"
                );
                -- Kanan
                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x + 40, 10)) & 
                    std_logic_vector(to_unsigned(obj_y, 10)) & 
                    std_logic_vector(to_unsigned(obj_x + 60, 10)) & 
                    std_logic_vector(to_unsigned(obj_y, 10)) & x"00000"
                    );
                -- Diagonal
                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x - 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_y - 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_x - 42, 10)) & 
                    std_logic_vector(to_unsigned(obj_y - 42, 10)) & x"00000"
                    );

                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x + 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_y - 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_x + 42, 10)) & 
                    std_logic_vector(to_unsigned(obj_y - 42, 10)) & x"00000"
                );
                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x - 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_y + 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_x - 42, 10)) & 
                    std_logic_vector(to_unsigned(obj_y + 42, 10)) & x"00000"
                );

                send_cmd(x"5" & 
                    std_logic_vector(to_unsigned(obj_x + 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_y + 28, 10)) & 
                    std_logic_vector(to_unsigned(obj_x + 42, 10)) & 
                    std_logic_vector(to_unsigned(obj_y + 42, 10)) & x"00000"
                );
            end if;

            -- L3: BOLA MATAHARI/BULAN
            send_cmd(obj_color); -- Set warna objek
            send_cmd(x"6" & 
                std_logic_vector(to_unsigned(obj_x, 10)) & 
                std_logic_vector(to_unsigned(obj_y, 10)) & 
                std_logic_vector(to_unsigned(30, 10)) & 
                x"0000000" & "00"
            );

            -- L4: TANAH
            if frame_idx < 6 then send_cmd(x"1000000000228B22"); -- Hijau
            else send_cmd(x"1000000000006400"); end if; -- Hijau Gelap
            
            send_cmd(x"3" & x"00000" & -- Gambar tanah
                std_logic_vector(to_unsigned(512, 10)) & 
                std_logic_vector(to_unsigned(56, 10)) & 
                std_logic_vector(to_unsigned(0, 10)) & 
                std_logic_vector(to_unsigned(200, 10))
            );

            -- L5: RUMAH
            send_cmd(x"1000000000F5F5DC"); -- Warna rumah
            send_cmd(x"3" & x"00000" & -- Gambar tembok
                std_logic_vector(to_unsigned(112, 10)) & 
                std_logic_vector(to_unsigned(80, 10)) & 
                std_logic_vector(to_unsigned(200, 10)) & 
                std_logic_vector(to_unsigned(120, 10))
                );

            send_cmd(x"1000000000B22222"); -- Warna atap
            send_cmd(x"4" & -- Gambar atap
                std_logic_vector(to_unsigned(180, 10)) & 
                std_logic_vector(to_unsigned(120, 10)) & 
                std_logic_vector(to_unsigned(332, 10)) & 
                std_logic_vector(to_unsigned(120, 10)) & 
                std_logic_vector(to_unsigned(256, 10)) & 
                std_logic_vector(to_unsigned(60, 10))
            );

            send_cmd(x"10000000008B4513"); -- Warna pintu
            send_cmd(x"3" & x"00000" & -- Gambar pintu
                std_logic_vector(to_unsigned(32, 10)) & 
                std_logic_vector(to_unsigned(40, 10)) & 
                std_logic_vector(to_unsigned(240, 10)) & 
                std_logic_vector(to_unsigned(160, 10))
            );

            -- L6: JENDELA
            send_cmd(window_color); -- Set warna jendela
            send_cmd(x"3" & x"00000" & -- Gambar jendela kiri
                std_logic_vector(to_unsigned(20, 10)) & 
                std_logic_vector(to_unsigned(20, 10)) & 
                std_logic_vector(to_unsigned(210, 10)) & 
                std_logic_vector(to_unsigned(140, 10))
            );

            send_cmd(x"3" & x"00000" & -- Gambar jendela kanan
                std_logic_vector(to_unsigned(20, 10)) & 
                std_logic_vector(to_unsigned(20, 10)) & 
                std_logic_vector(to_unsigned(280, 10)) & 
                std_logic_vector(to_unsigned(140, 10))
            );

            -- 4. CAPTURE
            if frame_idx < 10 then -- Tambah leading zero untuk frame 0-9
                save_frame("anim_0" & integer'image(frame_idx) & ".bmp"); -- Simpan dengan leading zero
            else
                save_frame("anim_" & integer'image(frame_idx) & ".bmp"); -- Simpan tanpa leading zero
            end if;
            
        end loop;

        report "ANIMASI SELESAI!";
        std.env.stop; -- Hentikan simulasi
        wait;
    end process;

end Behavioral;