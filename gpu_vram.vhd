library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gpu_vram is
    Port ( 
        clk      : in  STD_LOGIC;
        we       : in  STD_LOGIC; -- Write/Read untuk color 
        addr     : in  STD_LOGIC_VECTOR (16 downto 0); -- (9+8) 17-bit untuk 512x256 resolusi canvas
        data_in  : in  STD_LOGIC_VECTOR (23 downto 0); -- Write 24-bit RGB color
        data_out : out STD_LOGIC_VECTOR (23 downto 0) -- Read 24-bit RGB color
    );
end gpu_vram;

architecture Behavioral of gpu_vram is

    -- Total Pixel = 512 * 256 = 131,072
    -- 131,072 pixel dengan 24-bit RGB
    type ram_type is array (0 to 131071) of std_logic_vector(23 downto 0);
    
    -- Inisialisasi memori dengan 0 (Hitam) agar simulasi bersih
    signal RAM : ram_type := (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Operasi Write
            if we = '1' then
                RAM(to_integer(unsigned(addr))) <= data_in;
            end if;
            
            -- Operasi Read
            data_out <= RAM(to_integer(unsigned(addr)));
        end if;
    end process;

end Behavioral;