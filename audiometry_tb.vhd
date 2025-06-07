----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.06.2025 12:24:01
-- Design Name: 
-- Module Name: audiometry_tb - Behavioral
-- Project Name: 
-- Target Devices: 
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

entity tb_audiometry is
end tb_audiometry;

architecture Behavioral of tb_audiometry is

    -- Señales del sistema
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal sw          : std_logic_vector(3 downto 0) := "0000"; -- volumen mínimo
    signal canal_sel   : std_logic_vector(1 downto 0) := "00";   -- canal desactivado al inicio

    signal tx_mclk     : std_logic;
    signal tx_lrck     : std_logic;
    signal tx_sclk     : std_logic;
    signal tx_data     : std_logic;

    signal rx_mclk     : std_logic;
    signal rx_lrck     : std_logic;
    signal rx_sclk     : std_logic;
    signal rx_data     : std_logic := '0';

    signal led         : std_logic_vector(2 downto 0);
    signal seg         : std_logic_vector(6 downto 0);
    signal an          : std_logic_vector(3 downto 0);
    signal dp          : std_logic;

begin

    -- Generación de reloj 100 MHz
    clk_process : process
    begin
        wait for 5 ns;
        clk <= not clk;
    end process;

    -- Estímulos
    stim_proc : process
    begin
        -- Reset activo
        wait for 100 ns;
        reset <= '0';

        -- 1. FSM permanece en IDLE con canal desactivado
        canal_sel <= "00";
        wait for 10 ms;

        -- 2. Activación de canal izquierdo (flanco detectado por FSM)
        canal_sel <= "10";
        wait for 140 ms;  -- tiempo estimado para recorrer los 7 estados (7 x 20 ms)

        -- 3. Vuelta al IDLE y espera 10 ms más
        canal_sel <= "00";
        wait for 10 ms;

        -- 4. Subida de volumen y activación del canal derecho
        sw <= "1000";
        canal_sel <= "01";
        wait for 140 ms;

        -- Fin de simulación
        wait;
    end process;

    -- Instancia del diseño top
    DUT: entity work.audiometry
        port map(
            clk         => clk,
            reset       => reset,
            sw          => sw,
            canal_sel   => canal_sel,
            tx_mclk     => tx_mclk,
            tx_lrck     => tx_lrck,
            tx_sclk     => tx_sclk,
            tx_data     => tx_data,
            rx_mclk     => rx_mclk,
            rx_lrck     => rx_lrck,
            rx_sclk     => rx_sclk,
            rx_data     => rx_data,
            led         => led,
            seg         => seg,
            an          => an,
            dp          => dp
        );

end Behavioral;





