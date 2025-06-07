----------------------------------------------------------------------------------
-- Company: UC3M
-- Engineer: Alejandro Estaire Martin 
-- 
-- Create Date: 27.05.2025 20:16:28
-- Design Name: 
-- Module Name: contador_reloj - Behavioral
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

entity contador_reloj is
  Generic(
    ciclos: integer    --numero ciclos que hay que contar
  );
  Port (
    clk_in: in std_logic;
    clk_out: out std_logic;
    eoc: out std_logic
  );
end contador_reloj;

architecture Behavioral of contador_reloj is

  signal cuenta : integer := 0; 
  signal clk_aux:  std_logic := '0';
  signal eoc_aux : std_logic;
  
begin
  clk_out <= clk_aux;   
  eoc_aux <= '1' when cuenta = ciclos-1 else '0';
  eoc<=eoc_aux;
  
  --cambiar valor tras el fin de cuenta
  process (clk_in) 
  begin
    if rising_edge (clk_in) then
        if eoc_aux = '1' then
            clk_aux <= NOT clk_aux;
        end if;
    end if;
  end process;
  
  --contador de n ciclos
  process (clk_in)
  begin
    if rising_edge (clk_in) then
        if cuenta = ciclos-1 then
          cuenta <= 0;
        else
          cuenta <= cuenta+1;
        end if;
    end if; 
end process;
  
end Behavioral;

