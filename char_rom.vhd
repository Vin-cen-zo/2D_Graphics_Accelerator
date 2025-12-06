library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity char_rom is
    Port (
        addr : in  STD_LOGIC_VECTOR(7 downto 0); -- ASCII Code (misal 65 = 'A')
        row  : in  STD_LOGIC_VECTOR(2 downto 0); -- Baris ke-berapa (0-7)
        data : out STD_LOGIC_VECTOR(7 downto 0)  -- Pola bit 1 baris tersebut
    );
end char_rom;

architecture Behavioral of char_rom is

begin
    process(addr, row)
        variable char_index : integer;
        variable row_index : integer;
    begin
        char_index := to_integer(unsigned(addr));
        row_index  := to_integer(unsigned(row));
        
        -- Default (Blank)
        data <= "00000000";

        case char_index is
            -- HURUF A (ASCII 65 / x41)
            when 65 => 
                case row_index is
                    when 0 => data <= "00111000"; 
                    when 1 => data <= "01101100"; 
                    when 2 => data <= "11000110"; 
                    when 3 => data <= "11000110"; 
                    when 4 => data <= "11111110"; 
                    when 5 => data <= "11000110"; 
                    when 6 => data <= "11000110"; 
                    when 7 => data <= "00000000";
                    when others => data <= "00000000";
                end case;

            -- HURUF B (ASCII 66 / x42)
            when 66 => 
                case row_index is
                    when 0 => data <= "11111000";
                    when 1 => data <= "11001100";
                    when 2 => data <= "11001100";
                    when 3 => data <= "11111000";
                    when 4 => data <= "11001100";
                    when 5 => data <= "11001100";
                    when 6 => data <= "11111000";
                    when others => data <= "00000000";
                end case;
            
            -- HURUF C (ASCII 67 / x43)
            when 67 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "01100110";
                    when 2 => data <= "11000010";
                    when 3 => data <= "11000000";
                    when 4 => data <= "11000010";
                    when 5 => data <= "01100110";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;

            -- HURUF D (ASCII 68 / x44)
            when 68 => 
                case row_index is
                    when 0 => data <= "11110000";
                    when 1 => data <= "11011000";
                    when 2 => data <= "11001100";
                    when 3 => data <= "11001100";
                    when 4 => data <= "11001100";
                    when 5 => data <= "11011000";
                    when 6 => data <= "11110000";
                    when others => data <= "00000000";
                end case;

            -- HURUF E (ASCII 69 / x45)
            when 69 => 
                case row_index is
                    when 0 => data <= "11111110";
                    when 1 => data <= "11000000";
                    when 2 => data <= "11000000";
                    when 3 => data <= "11111100";
                    when 4 => data <= "11000000";
                    when 5 => data <= "11000000";
                    when 6 => data <= "11111110";
                    when others => data <= "00000000";
                end case;

            -- HURUF F (ASCII 70 / x46)
            when 70 => 
                case row_index is
                    when 0 => data <= "11111110";
                    when 1 => data <= "11000000";
                    when 2 => data <= "11000000";
                    when 3 => data <= "11111100";
                    when 4 => data <= "11000000";
                    when 5 => data <= "11000000";
                    when 6 => data <= "11000000";
                    when others => data <= "00000000";
                end case;

            -- HURUF G (ASCII 71 / x47)
            when 71 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "01100110";
                    when 2 => data <= "11000010";
                    when 3 => data <= "11000000";
                    when 4 => data <= "11001110";
                    when 5 => data <= "01100110";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;

            -- HURUF H (ASCII 72 / x48)
            when 72 => 
                case row_index is
                    when 0 => data <= "11000110";
                    when 1 => data <= "11000110";
                    when 2 => data <= "11000110";
                    when 3 => data <= "11111110";
                    when 4 => data <= "11000110";
                    when 5 => data <= "11000110";
                    when 6 => data <= "11000110";
                    when others => data <= "00000000";
                end case;

            -- HURUF I (ASCII 73 / x49)
            when 73 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "00011000";
                    when 2 => data <= "00011000";
                    when 3 => data <= "00011000";
                    when 4 => data <= "00011000";
                    when 5 => data <= "00011000";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;

            -- HURUF J (ASCII 74 / x4A)
            when 74 => 
                case row_index is
                    when 0 => data <= "00011110";
                    when 1 => data <= "00001100";
                    when 2 => data <= "00001100";
                    when 3 => data <= "00001100";
                    when 4 => data <= "11001100";
                    when 5 => data <= "11001100";
                    when 6 => data <= "01111000";
                    when others => data <= "00000000";
                end case;

            -- HURUF K (ASCII 75 / x4B)
            when 75 => 
                case row_index is
                    when 0 => data <= "11001100";
                    when 1 => data <= "11011000";
                    when 2 => data <= "11110000";
                    when 3 => data <= "11100000";
                    when 4 => data <= "11110000";
                    when 5 => data <= "11011000";
                    when 6 => data <= "11001100";
                    when others => data <= "00000000";
                end case;

            -- HURUF L (ASCII 76 / x4C)
            when 76 => 
                case row_index is
                    when 0 => data <= "11000000";
                    when 1 => data <= "11000000";
                    when 2 => data <= "11000000";
                    when 3 => data <= "11000000";
                    when 4 => data <= "11000000";
                    when 5 => data <= "11000000";
                    when 6 => data <= "11111110";
                    when others => data <= "00000000";
                end case;

            -- HURUF M (ASCII 77 / x4D)
            when 77 => 
                case row_index is
                    when 0 => data <= "11000011";
                    when 1 => data <= "11100111";
                    when 2 => data <= "11111111";
                    when 3 => data <= "11011011";
                    when 4 => data <= "11000011";
                    when 5 => data <= "11000011";
                    when 6 => data <= "11000011";
                    when others => data <= "00000000";
                end case;

            -- HURUF N (ASCII 78 / x4E)
            when 78 => 
                case row_index is
                    when 0 => data <= "11000110";
                    when 1 => data <= "11100110";
                    when 2 => data <= "11110110";
                    when 3 => data <= "11011110";
                    when 4 => data <= "11001110";
                    when 5 => data <= "11000110";
                    when 6 => data <= "11000110";
                    when others => data <= "00000000";
                end case;

            -- HURUF O (ASCII 79 / x4F)
            when 79 => 
                case row_index is
                    when 0 => data <= "00111000";
                    when 1 => data <= "01101100";
                    when 2 => data <= "11000110";
                    when 3 => data <= "11000110";
                    when 4 => data <= "11000110";
                    when 5 => data <= "01101100";
                    when 6 => data <= "00111000";
                    when others => data <= "00000000";
                end case;

            -- HURUF P (ASCII 80 / x50)
            when 80 => 
                case row_index is
                    when 0 => data <= "11111000";
                    when 1 => data <= "11001100";
                    when 2 => data <= "11001100";
                    when 3 => data <= "11111000";
                    when 4 => data <= "11000000";
                    when 5 => data <= "11000000";
                    when 6 => data <= "11000000";
                    when others => data <= "00000000";
                end case;

            -- HURUF Q (ASCII 81 / x51)
            when 81 => 
                case row_index is
                    when 0 => data <= "00111000";
                    when 1 => data <= "01101100";
                    when 2 => data <= "11000110";
                    when 3 => data <= "11000110";
                    when 4 => data <= "11010110";
                    when 5 => data <= "01101100";
                    when 6 => data <= "00111110";
                    when others => data <= "00000000";
                end case;

            -- HURUF R (ASCII 82 / x52)
            when 82 => 
                case row_index is
                    when 0 => data <= "11111000";
                    when 1 => data <= "11001100";
                    when 2 => data <= "11001100";
                    when 3 => data <= "11111000";
                    when 4 => data <= "11100000";
                    when 5 => data <= "11011000";
                    when 6 => data <= "11001100";
                    when others => data <= "00000000";
                end case;

            -- HURUF S (ASCII 83 / x53)
            when 83 => 
                case row_index is
                    when 0 => data <= "01111100";
                    when 1 => data <= "11000010";
                    when 2 => data <= "11000000";
                    when 3 => data <= "01111100";
                    when 4 => data <= "00000110";
                    when 5 => data <= "11000010";
                    when 6 => data <= "01111100";
                    when others => data <= "00000000";
                end case;

            -- HURUF T (ASCII 84 / x54)
            when 84 => 
                case row_index is
                    when 0 => data <= "11111110";
                    when 1 => data <= "00011000";
                    when 2 => data <= "00011000";
                    when 3 => data <= "00011000";
                    when 4 => data <= "00011000";
                    when 5 => data <= "00011000";
                    when 6 => data <= "00011000";
                    when others => data <= "00000000";
                end case;

            -- HURUF U (ASCII 85 / x55)
            when 85 => 
                case row_index is
                    when 0 => data <= "11000110";
                    when 1 => data <= "11000110";
                    when 2 => data <= "11000110";
                    when 3 => data <= "11000110";
                    when 4 => data <= "11000110";
                    when 5 => data <= "11000110";
                    when 6 => data <= "01111100";
                    when others => data <= "00000000";
                end case;

            -- HURUF V (ASCII 86 / x56)
            when 86 => 
                case row_index is
                    when 0 => data <= "11000110";
                    when 1 => data <= "11000110";
                    when 2 => data <= "11000110";
                    when 3 => data <= "11000110";
                    when 4 => data <= "11000110";
                    when 5 => data <= "01101100";
                    when 6 => data <= "00111000";
                    when others => data <= "00000000";
                end case;

            -- HURUF W (ASCII 87 / x57)
            when 87 => 
                case row_index is
                    when 0 => data <= "11000011";
                    when 1 => data <= "11000011";
                    when 2 => data <= "11000011";
                    when 3 => data <= "11011011";
                    when 4 => data <= "11111111";
                    when 5 => data <= "11100111";
                    when 6 => data <= "11000011";
                    when others => data <= "00000000";
                end case;

            -- HURUF X (ASCII 88 / x58)
            when 88 => 
                case row_index is
                    when 0 => data <= "11000110";
                    when 1 => data <= "11000110";
                    when 2 => data <= "01101100";
                    when 3 => data <= "00111000";
                    when 4 => data <= "01101100";
                    when 5 => data <= "11000110";
                    when 6 => data <= "11000110";
                    when others => data <= "00000000";
                end case;

            -- HURUF Y (ASCII 89 / x59)
            when 89 => 
                case row_index is
                    when 0 => data <= "11000110";
                    when 1 => data <= "11000110";
                    when 2 => data <= "01101100";
                    when 3 => data <= "00111000";
                    when 4 => data <= "00011000";
                    when 5 => data <= "00011000";
                    when 6 => data <= "00011000";
                    when others => data <= "00000000";
                end case;
            
            -- HURUF Z (ASCII 90 / x5A)
            when 90 => 
                case row_index is
                    when 0 => data <= "11111110";
                    when 1 => data <= "00000110";
                    when 2 => data <= "00001100";
                    when 3 => data <= "00011000";
                    when 4 => data <= "00110000";
                    when 5 => data <= "01100000";
                    when 6 => data <= "11111110";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 0 (ASCII 48 / x30)
            when 48 => 
                case row_index is
                    when 0 => data <= "00111000";
                    when 1 => data <= "01101100";
                    when 2 => data <= "11000110";
                    when 3 => data <= "11010110";
                    when 4 => data <= "11100110";
                    when 5 => data <= "01101100";
                    when 6 => data <= "00111000";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 1 (ASCII 49 / x31)
            when 49 => 
                case row_index is
                    when 0 => data <= "00011000";
                    when 1 => data <= "00111000";
                    when 2 => data <= "00011000";
                    when 3 => data <= "00011000";
                    when 4 => data <= "00011000";
                    when 5 => data <= "00011000";
                    when 6 => data <= "01111110";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 2 (ASCII 50 / x32)
            when 50 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "01100110";
                    when 2 => data <= "00000110";
                    when 3 => data <= "00001100";
                    when 4 => data <= "00110000";
                    when 5 => data <= "01100000";
                    when 6 => data <= "01111110";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 3 (ASCII 51 / x33)
            when 51 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "01100110";
                    when 2 => data <= "00000110";
                    when 3 => data <= "00011100";
                    when 4 => data <= "00000110";
                    when 5 => data <= "01100110";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 4 (ASCII 52 / x34)
            when 52 => 
                case row_index is
                    when 0 => data <= "00001100";
                    when 1 => data <= "00011100";
                    when 2 => data <= "00111100";
                    when 3 => data <= "01101100";
                    when 4 => data <= "11111110";
                    when 5 => data <= "00001100";
                    when 6 => data <= "00001100";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 5 (ASCII 53 / x35)
            when 53 => 
                case row_index is
                    when 0 => data <= "01111110";
                    when 1 => data <= "01100000";
                    when 2 => data <= "01111100";
                    when 3 => data <= "00000110";
                    when 4 => data <= "00000110";
                    when 5 => data <= "01100110";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;
            
            -- ANGKA 6 (ASCII 54 / x36)
            when 54 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "01100110";
                    when 2 => data <= "01100000";
                    when 3 => data <= "01111100";
                    when 4 => data <= "01100110";
                    when 5 => data <= "01100110";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 7 (ASCII 55 / x37)
            when 55 => 
                case row_index is
                    when 0 => data <= "01111110";
                    when 1 => data <= "00000110";
                    when 2 => data <= "00001100";
                    when 3 => data <= "00011000";
                    when 4 => data <= "00110000";
                    when 5 => data <= "00110000";
                    when 6 => data <= "00110000";
                    when others => data <= "00000000";
                end case;
            
            -- ANGKA 8 (ASCII 56 / x38)
            when 56 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "01100110";
                    when 2 => data <= "01100110";
                    when 3 => data <= "00111100";
                    when 4 => data <= "01100110";
                    when 5 => data <= "01100110";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;

            -- ANGKA 9 (ASCII 57 / x39)
            when 57 => 
                case row_index is
                    when 0 => data <= "00111100";
                    when 1 => data <= "01100110";
                    when 2 => data <= "01100110";
                    when 3 => data <= "00111110";
                    when 4 => data <= "00000110";
                    when 5 => data <= "01100110";
                    when 6 => data <= "00111100";
                    when others => data <= "00000000";
                end case;

            when others =>
                -- Kotak Solid jika tidak sesuai
                data <= "11111111"; 
        end case;
    end process;
end Behavioral;