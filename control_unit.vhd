library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_unit is
    Port ( 
        clk, reset, start : in STD_LOGIC;
        instruction : in STD_LOGIC_VECTOR (63 downto 0);    -- Instruction code
        
        -- Sinyal feedback selesai instruksi dari datapath
        clear_done, rect_done, tri_done, line_done, circ_done : in STD_LOGIC;
        
        -- Sinyal enable ke datapath
        en_clear, en_rect, en_tri, en_line, en_circ : out STD_LOGIC; -- Hapus canvas, segiempat, segitiga, garis
        reg_color_we : out STD_LOGIC;   -- Untuk warna
        busy, done : out STD_LOGIC  -- Sedang ada instruction atau sedang idle
    );
end control_unit;

architecture Behavioral of control_unit is

    -- Type sama seperti struct
    -- Sebuah array sebesar 64 slot dengan setiap slot berisi 16-bit Microinstruction  
    type u_mem_type is array (0 to 79) of std_logic_vector(15 downto 0);
    
    -- Format Microinstruction (16-bit):
    -- [15:14] State Type: 00=Idle/Fetch, 01=Wait for Done, 10=Finish/Print
    -- [13:10] Unused (0000)
    -- [09]    Busy
    -- [08]    Done
    -- [07]    Enable Clear
    -- [06]    Enable Rectangle 
    -- [05]    Enable Triangle
    -- [04]    Enable Line
    -- [03]    Reg Color Write Enable
    -- [02:00] Unused
    
    -- Object dari u_mem_type yang tidak dapat diubah (constant)
    constant u_rom : u_mem_type := (
        -- ALAMAT 0: FETCH / IDLE STATE
        -- Menunggu sinyal Start.
        -- State=00 (Idle)
        0 => "00" & "0000" & "00" & "00000" & "000", 

        -- ALAMAT 10: SET COLOR (OPCODE 1)
        -- Set warna untuk gambar.
        -- State=10 (Finish), Busy=1, WE=1
        10 => "10" & "0000" & "10" & "00001" & "000",

        -- ALAMAT 20: CLEAR (Opcode 2)
        -- Hapus canvas.
        -- State=01 (Wait Done), Busy=1, En_Clear=1
        20 => "01" & "0000" & "10" & "10000" & "000",

        -- ALAMAT 30: DRAW RECT (Opcode 3)
        -- Menggambar segiempat.
        -- State=01 (Wait Done), Busy=1, En_Rect=1
        30 => "01" & "0000" & "10" & "01000" & "000",

        -- ALAMAT 40: DRAW TRIANGLE (Opcode 4)
        -- Menggambar segitiga.
        -- State=01 (Wait Done), Busy=1, En_Tri=1
        40 => "01" & "0000" & "10" & "00100" & "000",

        -- ALAMAT 50: DRAW LINE (Opcode 5)
        -- Menggambar garis.
        -- State=01 (Wait Done), Busy=1, En_Line=1
        50 => "01" & "0000" & "10" & "00010" & "000",

        -- ALAMAT 60: DRAW CIRCLE (Opcode 0)
        -- Menggambar lingkaran.
        -- State=01 (Wait Done), Busy=1, En_Circ=1
        60 => "01" & "0000" & "10" & "00000" & "100",

        -- ALAMAT 70: FINISH / PRINT (Opcode 0)
        -- Selesai menggambar. Menunggu FETCH lagi.
        -- State=00 (Idle), Busy=0, Done=1
        70 => "00" & "0000" & "01" & "00000" & "000",

        others => (others => '0')
    );

    -- Micro-Program Counter (uPC)
    signal uPC : integer range 0 to 63 := 0;    -- Counter instruksi saat ini
    
    -- Current Microinstruction Register (uIR)
    signal uIR : std_logic_vector(15 downto 0); -- Instruksi saat ini disimpan disini

    -- Alias untuk sinyal input instruksi
    alias opcode : std_logic_vector(3 downto 0) is instruction(63 downto 60);   -- opcode adalah 4-bit terbesar instruction code

begin

    -- 1. FETCH MICROINSTRUCTION
    uIR <= u_rom(uPC);

    -- 2. DECODE OUTPUT CONTROL UNIT (Hardwired dari bit microinstruction)
    busy         <= uIR(9);
    done         <= uIR(8);
    en_clear     <= uIR(7);
    en_rect      <= uIR(6);
    en_tri       <= uIR(5);
    en_line      <= uIR(4);
    reg_color_we <= uIR(3);
    en_circ      <= uIR(2);

    -- 3. DECODE STATE (Sequencer, Next address logic)
    process(clk)
        variable seq_type : std_logic_vector(1 downto 0); -- Menyimpan state
        variable condition_met : boolean; -- Flag tambahan untuk periksa apakah instruksi sudah selesai
    begin
        if rising_edge(clk) then
            if reset = '1' then
                uPC <= 0;   -- Idle/Fetch
            else
                seq_type := uIR(15 downto 14); -- 2-bit terbesar pada uIR adalah State  
                
                -- Logika Multiplexer: Untuk cek Done berdasarkan siapa yang aktif
                condition_met := false;
                if uIR(7)='1' and clear_done='1' then condition_met := true; end if;
                if uIR(6)='1' and rect_done='1'  then condition_met := true; end if;
                if uIR(5)='1' and tri_done='1'   then condition_met := true; end if;
                if uIR(4)='1' and line_done='1'  then condition_met := true; end if;
                if uIR(2)='1' and circ_done='1'  then condition_met := true; end if;

                case seq_type is
                    -- STATE 00: IDLE / FETCH
                    when "00" =>
                        if uPC = 0 then
                            if start = '1' then -- cek Start
                                case opcode is
                                    when "0001" => uPC <= 10; -- Set Color
                                    when "0010" => uPC <= 20; -- Clear Canvas (fill canvas dengan warna yang aktif)
                                    when "0011" => uPC <= 30; -- Menggambar Rectangle
                                    when "0100" => uPC <= 40; -- Menggambar Triangle
                                    when "0101" => uPC <= 50; -- Menggambar Line
                                    when "0110" => uPC <= 60; -- Menggambar Circle
                                    when "0000" => uPC <= 70; -- Finish / Print
                                    when others => uPC <= 0; -- Invalid Opcode, kembali ke IDLE
                                end case;   
                            end if;
                        else
                            -- Jika uPC 60, STATE=00. Diam di tempat
                            uPC <= uPC;
                        end if;

                    -- STATE 01: WAIT FOR DONE
                    when "01" =>
                        if condition_met then
                            uPC <= 0; -- Pekerjaan selesai, kembali ke IDLE
                        else
                            uPC <= uPC; -- Tunggu pekerjaan selesai
                        end if;

                    -- STATE 10: FINISH (PRINT)
                    when "10" =>
                        uPC <= 0; -- Kembali ke IDLE

                    when others =>
                        uPC <= 0;
                end case;
            end if;
        end if;
    end process;

end Behavioral;