library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_char_test is
end tb_char_test;

architecture Behavioral of tb_char_test is

    component gpu
        Port ( 
            clk, reset, start : in STD_LOGIC;
            instruction : in STD_LOGIC_VECTOR(63 downto 0);
            busy, done : out STD_LOGIC;
            dump_mode : in STD_LOGIC;
            dump_addr : in STD_LOGIC_VECTOR(16 downto 0);
            dump_data_out : out STD_LOGIC_VECTOR(23 downto 0)
        );
    end component;

    signal clk, reset, start : std_logic := '0';
    signal instruction : std_logic_vector(63 downto 0) := (others => '0');
    signal busy, done, dump_mode : std_logic := '0';
    signal dump_addr : std_logic_vector(16 downto 0) := (others => '0');
    signal dump_data_out : std_logic_vector(23 downto 0);

    constant clk_period : time := 10 ns;
    type char_file is file of character;
    type header_type is array (0 to 53) of character;

    -- Posisi Y untuk tiap baris
    constant Y1 : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(50, 10));  -- LIST THE...
    constant Y2 : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(80, 10));  -- INI PENTING
    constant Y3 : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(110, 10)); -- YANG PERTAMA
    constant Y4 : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(140, 10)); -- I LOVE...

    -- Tipe data untuk grup instruksi
    type instr_group is array (natural range <>) of std_logic_vector(63 downto 0);

    -- 0. SETUP
    constant CMD_SETUP : instr_group(0 to 1) := (
        x"1000000000FFFFFF", -- White
        x"2000000000000000"  -- Clear
    );

    -- BARIS 1: LIST OF THE THINGS THAT I HATE (Merah)
    constant CMD_COLOR_RED : instr_group(0 to 0) := ( 0 => x"1000000000FF0000" );

    constant WORD_LIST : instr_group(0 to 3) := (
        x"7" & x"4C" & std_logic_vector(to_unsigned(20, 10)) & Y1 & x"00000000",
        x"7" & x"49" & std_logic_vector(to_unsigned(30, 10)) & Y1 & x"00000000",
        x"7" & x"53" & std_logic_vector(to_unsigned(40, 10)) & Y1 & x"00000000",
        x"7" & x"54" & std_logic_vector(to_unsigned(50, 10)) & Y1 & x"00000000"
    );
    constant WORD_OF : instr_group(0 to 1) := (
        x"7" & x"4F" & std_logic_vector(to_unsigned(70, 10)) & Y1 & x"00000000",
        x"7" & x"46" & std_logic_vector(to_unsigned(80, 10)) & Y1 & x"00000000"
    );
    constant WORD_THE : instr_group(0 to 2) := (
        x"7" & x"54" & std_logic_vector(to_unsigned(100, 10)) & Y1 & x"00000000",
        x"7" & x"48" & std_logic_vector(to_unsigned(110, 10)) & Y1 & x"00000000",
        x"7" & x"45" & std_logic_vector(to_unsigned(120, 10)) & Y1 & x"00000000"
    );
    constant WORD_THINGS : instr_group(0 to 5) := (
        x"7" & x"54" & std_logic_vector(to_unsigned(140, 10)) & Y1 & x"00000000",
        x"7" & x"48" & std_logic_vector(to_unsigned(150, 10)) & Y1 & x"00000000",
        x"7" & x"49" & std_logic_vector(to_unsigned(160, 10)) & Y1 & x"00000000",
        x"7" & x"4E" & std_logic_vector(to_unsigned(170, 10)) & Y1 & x"00000000",
        x"7" & x"47" & std_logic_vector(to_unsigned(180, 10)) & Y1 & x"00000000",
        x"7" & x"53" & std_logic_vector(to_unsigned(190, 10)) & Y1 & x"00000000"
    );
    constant WORD_THAT : instr_group(0 to 3) := (
        x"7" & x"54" & std_logic_vector(to_unsigned(210, 10)) & Y1 & x"00000000",
        x"7" & x"48" & std_logic_vector(to_unsigned(220, 10)) & Y1 & x"00000000",
        x"7" & x"41" & std_logic_vector(to_unsigned(230, 10)) & Y1 & x"00000000",
        x"7" & x"54" & std_logic_vector(to_unsigned(240, 10)) & Y1 & x"00000000"
    );
    constant WORD_I_TOP : instr_group(0 to 0) := (
    0 => x"7" & x"49" & std_logic_vector(to_unsigned(260, 10)) & Y1 & x"00000000"
    );
    constant WORD_HATE : instr_group(0 to 3) := (
        x"7" & x"48" & std_logic_vector(to_unsigned(280, 10)) & Y1 & x"00000000",
        x"7" & x"41" & std_logic_vector(to_unsigned(290, 10)) & Y1 & x"00000000",
        x"7" & x"54" & std_logic_vector(to_unsigned(300, 10)) & Y1 & x"00000000",
        x"7" & x"45" & std_logic_vector(to_unsigned(310, 10)) & Y1 & x"00000000"
    );

    -- BARIS 2: INI PENTING (Biru)
    constant CMD_COLOR_BLUE : instr_group(0 to 0) := ( 0 => x"10000000000000FF" );

    constant WORD_INI : instr_group(0 to 2) := (
        x"7" & x"49" & std_logic_vector(to_unsigned(20, 10)) & Y2 & x"00000000",
        x"7" & x"4E" & std_logic_vector(to_unsigned(30, 10)) & Y2 & x"00000000",
        x"7" & x"49" & std_logic_vector(to_unsigned(40, 10)) & Y2 & x"00000000"
    );
    constant WORD_PENTING : instr_group(0 to 6) := (
        x"7" & x"50" & std_logic_vector(to_unsigned(60, 10)) & Y2 & x"00000000",
        x"7" & x"45" & std_logic_vector(to_unsigned(70, 10)) & Y2 & x"00000000",
        x"7" & x"4E" & std_logic_vector(to_unsigned(80, 10)) & Y2 & x"00000000",
        x"7" & x"54" & std_logic_vector(to_unsigned(90, 10)) & Y2 & x"00000000",
        x"7" & x"49" & std_logic_vector(to_unsigned(100, 10)) & Y2 & x"00000000",
        x"7" & x"4E" & std_logic_vector(to_unsigned(110, 10)) & Y2 & x"00000000",
        x"7" & x"47" & std_logic_vector(to_unsigned(120, 10)) & Y2 & x"00000000"
    );

    -- BARIS 3: YANG PERTAMA (Hitam)
    constant CMD_COLOR_BLACK : instr_group(0 to 0) := ( 0 => x"1000000000000000" );

    constant WORD_YANG : instr_group(0 to 3) := (
        x"7" & x"59" & std_logic_vector(to_unsigned(20, 10)) & Y3 & x"00000000",
        x"7" & x"41" & std_logic_vector(to_unsigned(30, 10)) & Y3 & x"00000000",
        x"7" & x"4E" & std_logic_vector(to_unsigned(40, 10)) & Y3 & x"00000000",
        x"7" & x"47" & std_logic_vector(to_unsigned(50, 10)) & Y3 & x"00000000"
    );
    constant WORD_PERTAMA : instr_group(0 to 6) := (
        x"7" & x"50" & std_logic_vector(to_unsigned(70, 10)) & Y3 & x"00000000",
        x"7" & x"45" & std_logic_vector(to_unsigned(80, 10)) & Y3 & x"00000000",
        x"7" & x"52" & std_logic_vector(to_unsigned(90, 10)) & Y3 & x"00000000",
        x"7" & x"54" & std_logic_vector(to_unsigned(100, 10)) & Y3 & x"00000000",
        x"7" & x"41" & std_logic_vector(to_unsigned(110, 10)) & Y3 & x"00000000",
        x"7" & x"4D" & std_logic_vector(to_unsigned(120, 10)) & Y3 & x"00000000",
        x"7" & x"41" & std_logic_vector(to_unsigned(130, 10)) & Y3 & x"00000000"
    );

    -- BARIS 4: I LOVE DIGIDAW 67
    constant CMD_COLOR_PURPLE: instr_group(0 to 0) := ( 0 => x"1000000000b405ff" );

    constant FULL_SENTENCE_BOTTOM : instr_group(0 to 13) := (
        -- I
        x"7" & x"49" & std_logic_vector(to_unsigned(20, 10)) & Y4 & x"00000000",
        -- LOVE
        x"7" & x"4C" & std_logic_vector(to_unsigned(40, 10)) & Y4 & x"00000000",
        x"7" & x"4F" & std_logic_vector(to_unsigned(50, 10)) & Y4 & x"00000000",
        x"7" & x"56" & std_logic_vector(to_unsigned(60, 10)) & Y4 & x"00000000",
        x"7" & x"45" & std_logic_vector(to_unsigned(70, 10)) & Y4 & x"00000000",
        -- DIGIDAW
        x"7" & x"44" & std_logic_vector(to_unsigned(90, 10)) & Y4 & x"00000000",
        x"7" & x"49" & std_logic_vector(to_unsigned(100, 10)) & Y4 & x"00000000",
        x"7" & x"47" & std_logic_vector(to_unsigned(110, 10)) & Y4 & x"00000000",
        x"7" & x"49" & std_logic_vector(to_unsigned(120, 10)) & Y4 & x"00000000",
        x"7" & x"44" & std_logic_vector(to_unsigned(130, 10)) & Y4 & x"00000000",
        x"7" & x"41" & std_logic_vector(to_unsigned(140, 10)) & Y4 & x"00000000",
        x"7" & x"57" & std_logic_vector(to_unsigned(150, 10)) & Y4 & x"00000000",
        -- 67
        x"7" & x"36" & std_logic_vector(to_unsigned(170, 10)) & Y4 & x"00000000",
        x"7" & x"37" & std_logic_vector(to_unsigned(180, 10)) & Y4 & x"00000000"
    );

    -- WAJAH SENYUM
    constant CMD_COLOR_SMILE : instr_group(0 to 0) := ( 0 => x"1000000000FFDF00" ); -- Kuning
    constant CMD_COLOR_BLACK_EYES : instr_group(0 to 0) := ( 0 => x"1000000000000000" ); -- Hitam

    constant LINGKARAN : instr_group(0 to 0) := (
        0 => x"6" & std_logic_vector(to_unsigned(60, 10)) & std_logic_vector(to_unsigned(200, 10)) & std_logic_vector(to_unsigned(40, 10)) & "000000000000000000000000000000"
    );

    constant MATA : instr_group(0 to 1) := (
        -- Mata Kiri (R=5) 
        x"6" & std_logic_vector(to_unsigned(45, 10)) & std_logic_vector(to_unsigned(190, 10)) & std_logic_vector(to_unsigned(5, 10)) & "000000000000000000000000000000",
        -- Mata Kanan (R=5) 
        x"6" & std_logic_vector(to_unsigned(75, 10)) & std_logic_vector(to_unsigned(190, 10)) & std_logic_vector(to_unsigned(5, 10)) & "000000000000000000000000000000"
    );

    constant SENYUM : instr_group(0 to 2) := (
        x"5" & std_logic_vector(to_unsigned(45, 10)) & std_logic_vector(to_unsigned(210, 10)) & std_logic_vector(to_unsigned(60, 10)) & std_logic_vector(to_unsigned(220, 10)) & x"00000",
        x"5" & std_logic_vector(to_unsigned(60, 10)) & std_logic_vector(to_unsigned(220, 10)) & std_logic_vector(to_unsigned(75, 10)) & std_logic_vector(to_unsigned(210, 10)) & x"00000",
        x"5" & std_logic_vector(to_unsigned(75, 10)) & std_logic_vector(to_unsigned(210, 10)) & std_logic_vector(to_unsigned(77, 10)) & std_logic_vector(to_unsigned(208, 10)) & x"00000"
    );

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
        file bmp_in  : char_file;
        file out00, out01, out02, out03, out04, out05, out06, out07, out08, out09, out10, out11, out12, out13 : char_file;
        variable char_buffer : character;
        variable header : header_type;
        variable temp_data : std_logic_vector(23 downto 0);

        -- Procedure Eksekusi Array Instruksi
        procedure run_batch(arr : instr_group) is
        begin
            dump_mode <= '0';
            for j in arr'range loop
                instruction <= arr(j);
                wait for 10 ns;
                wait until rising_edge(clk); start <= '1';
                wait until rising_edge(clk); start <= '0';
                wait for 20 ns;
                if busy = '1' then wait until busy = '0'; end if;
                wait for 50 ns;
            end loop;
        end procedure;

        -- Procedure Dump File
        procedure save_frame(file_handle : inout char_file; fname : string) is
        begin
            report "Saving Frame: " & fname;
            dump_mode <= '1';
            file_open(file_handle, fname, write_mode);
            -- Header Patch 512x256
            header(18):=character'val(0); header(19):=character'val(2); header(20):=character'val(0); header(21):=character'val(0);
            header(22):=character'val(0); header(23):=character'val(1); header(24):=character'val(0); header(25):=character'val(0);
            for i in 0 to 53 loop write(file_handle, header(i)); end loop;
            -- Pixel Data
            for y in 255 downto 0 loop
                for x in 0 to 511 loop
                    dump_addr <= std_logic_vector(to_unsigned((y*512)+x, 17));
                    wait until rising_edge(clk); wait for 1 ns;
                    temp_data := dump_data_out;
                    write(file_handle, character'val(to_integer(unsigned(temp_data(7 downto 0)))));   -- B
                    write(file_handle, character'val(to_integer(unsigned(temp_data(15 downto 8)))));  -- G
                    write(file_handle, character'val(to_integer(unsigned(temp_data(23 downto 16))))); -- R
                end loop;
            end loop;
            file_close(file_handle);
            dump_mode <= '0';
        end procedure;

    begin
        -- Init Header
        file_open(bmp_in, "template.bmp", read_mode);
        for i in 0 to 53 loop read(bmp_in, char_buffer); header(i) := char_buffer; end loop;
        file_close(bmp_in);

        report "Reset System...";
        reset <= '1'; wait for 100 ns; reset <= '0'; wait for 20 ns;

        -- Frame 00: Background Kosong
        run_batch(CMD_SETUP);
        save_frame(out00, "gif_char_00.bmp");

        -- Frame 01: LIST
        run_batch(CMD_COLOR_RED); -- Set Merah
        run_batch(WORD_LIST);
        save_frame(out01, "gif_char_01.bmp");

        -- Frame 02: LIST OF
        run_batch(WORD_OF);
        save_frame(out02, "gif_char_02.bmp");
        -- Frame 03: LIST OF THE
        run_batch(WORD_THE);
        save_frame(out03, "gif_char_03.bmp");

        -- Frame 04: LIST OF THE THINGS
        run_batch(WORD_THINGS);
        save_frame(out04, "gif_char_04.bmp");
        -- Frame 05: ... THAT
        run_batch(WORD_THAT);
        save_frame(out05, "gif_char_05.bmp");

        -- Frame 06: ... I
        run_batch(WORD_I_TOP);
        save_frame(out06, "gif_char_06.bmp");
        -- Frame 07: ... HATE
        run_batch(WORD_HATE);
        save_frame(out07, "gif_char_07.bmp");

        -- Frame 08: INI
        run_batch(CMD_COLOR_BLUE); -- Ganti Biru
        run_batch(WORD_INI);
        save_frame(out08, "gif_char_08.bmp");

        -- Frame 09: INI PENTING
        run_batch(WORD_PENTING);
        save_frame(out09, "gif_char_09.bmp");

        -- Frame 10: YANG
        run_batch(CMD_COLOR_BLACK); -- Ganti Hitam
        run_batch(WORD_YANG);
        save_frame(out10, "gif_char_10.bmp");

        -- Frame 11: YANG PERTAMA
        run_batch(WORD_PERTAMA);
        save_frame(out11, "gif_char_11.bmp");

        -- Frame 12: I LOVE DIGIDAW... (Sekaligus)
        run_batch(CMD_COLOR_PURPLE); -- Ganti Ungu
        run_batch(FULL_SENTENCE_BOTTOM);
        save_frame(out12, "gif_char_12.bmp");

        -- Frame 13: WAJAH SENYUM
        run_batch(CMD_COLOR_SMILE); -- Kuning
        run_batch(LINGKARAN);
        run_batch(CMD_COLOR_BLACK_EYES); -- Hitam
        run_batch(MATA);
        run_batch(SENYUM);
        save_frame(out13, "gif_char_13.bmp");

        report "SEMUA FRAME SELESAI!";
        std.env.stop;
        wait;
    end process;

end Behavioral;