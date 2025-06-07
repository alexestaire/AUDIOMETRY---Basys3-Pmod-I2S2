----------------------------------------------------------------------------------
-- Company: UC3M
-- Engineer: Alejandro Estaire Martin
-- 
-- Create Date: 27.05.2025 20:17:21
-- Design Name: 
-- Module Name: control_volumen - Behavioral
-- Project Name: Audiometry
-- Target Devices: Basys3 & Pmod I2S2
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_volumen is
  Port ( 
    entrada_audio: in std_logic_vector(23 downto 0);
    volumen: in std_logic_vector(3 downto 0);
    salida_audio: out std_logic_vector(23 downto 0)
  );
end control_volumen;

architecture Behavioral of control_volumen is
    signal entrada_signed : signed(23 downto 0);
    signal mult_result : signed(39 downto 0);
    signal resultado : signed(23 downto 0);
    signal ganancia : unsigned(15 downto 0);  -- 16-bit scaling factor
begin

    entrada_signed <= signed(entrada_audio);

    -- Asignación de ganancia según volumen (dB HL simulado)
    process(volumen)
    begin
        case volumen is
                                                                   -- Audición normal
            when "0000" => ganancia <= to_unsigned(100, 16);       -- 10dB
            when "0001" => ganancia <= to_unsigned(5087, 16);      -- 17,5dB
            when "0010" => ganancia <= to_unsigned(10074, 16);     -- 25dB
                                                                   -- Pérdida leve
            when "0011" => ganancia <= to_unsigned(15061, 16);     -- 32,5dB
            when "0100" => ganancia <= to_unsigned(20048, 16);     -- 40dB
            when "0101" => ganancia <= to_unsigned(25035, 16);     -- 47,5dB
                                                                   -- Pérdida severa
            when "0110" => ganancia <= to_unsigned(30022, 16);     -- 55dB
            when "0111" => ganancia <= to_unsigned(35009, 16);     -- 62,5dB
            when "1000" => ganancia <= to_unsigned(40000, 16);     -- 70dB
            when others => ganancia <= to_unsigned(0, 16);         -- silencio
        end case;

    end process;

    -- Multiplicación: entrada * ganancia
    mult_result <= entrada_signed * signed(ganancia);

    -- Normalización: ganancia de 1.0 = 65535 → desplazamos 16 bits
    resultado <= mult_result(39 downto 16);

    -- Salida
    salida_audio <= std_logic_vector(resultado);

end Behavioral;