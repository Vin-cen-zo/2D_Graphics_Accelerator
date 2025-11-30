library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath_triangle is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        en_tri     : in  STD_LOGIC;
        instruction: in  STD_LOGIC_VECTOR(63 downto 0);
        
        tri_we     : out STD_LOGIC;
        tri_addr   : out STD_LOGIC_VECTOR(16 downto 0);
        tri_done   : out STD_LOGIC
    );
end datapath_triangle;

architecture Behavioral of datapath_triangle is

    -- Register Koordinat
    signal x1, y1, x2, y2, x3, y3 : signed(11 downto 0);
    
    -- Bounding Box & Loop
    signal min_x, max_x, min_y, max_y : signed(11 downto 0);
    signal p_x, p_y : signed(11 downto 0);
    
    type state_type is (IDLE, LOAD, SETUP_BBOX, DRAWING, FINISHED);
    signal state : state_type := IDLE;

    -- Fungsi Edge Check (Determinan)
    function edge_check(px, py, v1x, v1y, v2x, v2y : signed) return boolean is
        variable res : signed(23 downto 0);
    begin
        -- Cross Product 2D: (Px-Ax)*(By-Ay) - (Py-Ay)*(Bx-Ax)
        res := (px - v1x) * (v2y - v1y) - (py - v1y) * (v2x - v1x);
        if res >= 0 then return true; else return false; end if;
        -- jika positif ada di sisi kanan garis
        -- jika negatif ada di sisi kiri garis
        -- jika nol ada di garis 
    end function;

begin

    process(clk)
        variable v_min_x, v_max_x, v_min_y, v_max_y : signed(11 downto 0);
        variable w0, w1, w2 : boolean;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                tri_we <= '0'; tri_done <= '0';
            else
                case state is
                    when IDLE =>
                        tri_we <= '0'; tri_done <= '0';
                        if en_tri = '1' then state <= LOAD; end if;

                    when LOAD =>
                        -- Muat koordinat segitiga dari instruction
                        x1 <= signed("00" & instruction(59 downto 50));
                        y1 <= signed("00" & instruction(49 downto 40));
                        x2 <= signed("00" & instruction(39 downto 30));
                        y2 <= signed("00" & instruction(29 downto 20));
                        x3 <= signed("00" & instruction(19 downto 10));
                        y3 <= signed("00" & instruction(9 downto 0));
                        state <= SETUP_BBOX;

                    when SETUP_BBOX =>
                        -- membuat bounding box segitiga
                        -- Cari Min/Max untuk X
                        v_min_x := x1; v_max_x := x1;
                        if x2 < v_min_x then v_min_x := x2; end if;
                        if x3 < v_min_x then v_min_x := x3; end if;
                        if x2 > v_max_x then v_max_x := x2; end if;
                        if x3 > v_max_x then v_max_x := x3; end if;
                        
                        -- Cari Min/Max untuk Y
                        v_min_y := y1; v_max_y := y1;
                        if y2 < v_min_y then v_min_y := y2; end if;
                        if y3 < v_min_y then v_min_y := y3; end if;
                        if y2 > v_max_y then v_max_y := y2; end if;
                        if y3 > v_max_y then v_max_y := y3; end if;
                        
                        -- Simpan ke register
                        min_x <= v_min_x; max_x <= v_max_x;
                        min_y <= v_min_y; max_y <= v_max_y;
                        
                        -- Set posisi awal loop
                        p_x <= v_min_x;
                        p_y <= v_min_y;
                        
                        state <= DRAWING;

                    when DRAWING =>
                        --mengecek setiap pixel dari bounding box apakah di dalam segitiga atau tidak
                        --Cek Edge Function
                        w0 := edge_check(p_x, p_y, x1, y1, x2, y2);
                        w1 := edge_check(p_x, p_y, x2, y2, x3, y3);
                        w2 := edge_check(p_x, p_y, x3, y3, x1, y1);
                        
                        -- jika di dalam segitiga
                        -- ccw atau cw
                        if ( (w0 and w1 and w2) or ((not w0) and (not w1) and (not w2)) ) then
                            tri_we <= '1';
                            tri_addr <= std_logic_vector(p_y(7 downto 0)) & std_logic_vector(p_x(8 downto 0));
                            --melakukan write ke pixel address yang didalam segitiga
                        else
                            tri_we <= '0';
                        end if;
                        
                        -- Increment Loop

                        if p_x < max_x then
                            p_x <= p_x + 1;
                        else
                            p_x <= min_x;     -- Reset X karena akan pindah ke p_y berikutnya
                            if p_y < max_y then
                                p_y <= p_y + 1; -- Next Line
                            else
                                state <= FINISHED; -- Selesai Loop jika pixel y sudah mentok
                                tri_we <= '0';
                            end if;
                        end if;

                    when FINISHED =>
                        tri_we <= '0';
                        tri_done <= '1';
                        if en_tri = '0' then state <= IDLE; end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;