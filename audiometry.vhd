----------------------------------------------------------------------------------
-- Company: UC3M
-- Engineer: Alejandro Estaire Martin
-- 
-- Create Date: 27.05.2025 20:07:52
-- Design Name: 
-- Module Name: audiometry - Behavioral
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

entity audiometry is
    port( 
    clk         : in std_logic; 
    reset       : in std_logic; 
    sw          : in std_logic_vector(3 downto 0);  -- volumen
    canal_sel   : in std_logic_vector(1 downto 0);  -- canal izquierdo/derecho
    tx_mclk     : out std_logic; 
    tx_lrck     : out std_logic; 
    tx_sclk     : out std_logic; 
    tx_data     : out std_logic; 
    rx_mclk     : out std_logic; 
    rx_lrck     : out std_logic; 
    rx_sclk     : out std_logic; 
    rx_data     : in std_logic;
    led         : out std_logic_vector(2 downto 0);
    seg         : out std_logic_vector(6 downto 0);
    an          : out std_logic_vector(3 downto 0);
    dp          : out std_logic
    
    );
end audiometry;

architecture Behavioral of audiometry is

--COMPONENTES
    component clk_wiz_0
        port(
        clk_in1  : in std_logic;
        clk_out1 : out std_logic        
        );
    end component;

    component gen_seno
        port(
        clk          : in  std_logic;
        tick         : in  std_logic;
        new_freq     : in  std_logic;
        cuenta_max   : in  unsigned(14 downto 0);
        gen_seno_out : out std_logic_vector(23 downto 0)
        );
    end component;

    component fsm_audiometry
        Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        canal_sel  : in  std_logic_vector(1 downto 0);  
        cuenta_max : out unsigned(14 downto 0);
        freq_id    : out std_logic_vector(2 downto 0);
        new_freq   : out std_logic;
        seg        : out std_logic_vector(6 downto 0);
        an         : out std_logic_vector(3 downto 0);
        dp         : out std_logic  -- Punto decimal
        );
    end component;

    component contador_reloj is
        generic(ciclos : integer);
        port(
        clk_in  : in std_logic;
        clk_out : out std_logic;
        eoc     : out std_logic
        ); 
    end component;

    component control_volumen is
        port( 
        entrada_audio : in std_logic_vector(23 downto 0);
        volumen       : in std_logic_vector(3 downto 0);
        salida_audio  : out std_logic_vector(23 downto 0)
        );
    end component;


    --SIGNALS
    signal mclk, sclk, lrclk : std_logic;
    signal cuenta_data : natural range 24 downto 0;
    signal bajada_sclk, subida_sclk : std_logic;
    signal en_tx : std_logic := '0';
    signal eoc_sclk, eoc_lrck : std_logic;
    
    signal nota_tx      : std_logic_vector(23 downto 0);
    signal nota_rx      : std_logic_vector(23 downto 0);
    signal nota_recibida: std_logic_vector(23 downto 0);
    signal nota_volumen : std_logic_vector(23 downto 0);
    
    signal cuenta_frec : unsigned(14 downto 0);
    signal seno : std_logic_vector(23 downto 0);
    signal freq_actual : std_logic_vector(2 downto 0);
    signal lr_actual : std_logic := '0';
    signal activar_dch : std_logic;
    signal activar_izq : std_logic;
    
    signal freq_prev    : std_logic_vector(2 downto 0) := (others => '0');
    signal new_freq     : std_logic := '0';
    signal new_freq_pulso : std_logic;
    


    begin

        gen_reloj: clk_wiz_0    
          port map (clk_in1 => clk, clk_out1 => mclk);
        
        fsm_inst: fsm_audiometry
          port map (
            clk        => mclk,
            reset      => reset,
            canal_sel  => canal_sel,
            cuenta_max => cuenta_frec,
            freq_id    => freq_actual,
            new_freq   => open,
            seg        => seg,
            an         => an,
            dp         => dp
          );
        
        gen_seno_inst: gen_seno
          port map (
            clk          => mclk,
            tick         => eoc_lrck,
            new_freq     => new_freq_pulso,
            cuenta_max   => cuenta_frec,
            gen_seno_out => seno
          );
        
        gen_sclk: contador_reloj
          generic map(ciclos => 4)
          port map(clk_in => mclk, clk_out => sclk, eoc => eoc_sclk);
        
        gen_lrclk: contador_reloj
          generic map(ciclos => 256)
          port map(clk_in => mclk, clk_out => lrclk, eoc => eoc_lrck);
        
        volumen_sw: control_volumen
          port map(
            entrada_audio => seno,
            volumen       => sw,
            salida_audio  => nota_volumen
          );
        
        tx_mclk <= mclk;  tx_sclk <= sclk;  tx_lrck <= lrclk;
        rx_mclk <= mclk;  rx_sclk <= sclk;  rx_lrck <= lrclk;
        activar_dch <= canal_sel(0);  -- SW canal derecho
        activar_izq <= canal_sel(1);  -- SW canal izquierdo
        
        -- Detectar flanco de cambio de frecuencia
        process(mclk)
        begin
          if rising_edge(mclk) then
            if reset = '1' then
              freq_prev <= (others => '0');
              new_freq  <= '0';
            else
              if freq_actual /= freq_prev then
                new_freq <= '1';
              else
                new_freq <= '0';
              end if;
              freq_prev <= freq_actual;
            end if;
          end if;
        end process;
        
        new_freq_pulso <= new_freq;
        
        
        process (reset, mclk)
        begin
            if reset='1' then
                en_tx <= '0';
                lr_actual <= '0';
            elsif rising_edge(mclk) then
                if eoc_lrck='1' then
                    en_tx <= '1';
                    lr_actual <= lrclk;
        
                    if lrclk = '1' then  -- Canal izquierdo
                        if activar_izq = '1' then
                            nota_tx <= nota_volumen;
                        else
                            nota_tx <= (others => '0');
                        end if;
                    else  -- Canal derecho
                        if activar_dch = '1' then
                            nota_tx <= nota_volumen;
                        else
                            nota_tx <= (others => '0');
                        end if;
                    end if;
        
                elsif bajada_sclk='1' then
                    if cuenta_data = 0 then
                        en_tx <= '0';
                    end if;
                end if;
            end if;
        end process;
        
        process (reset, mclk)
        begin
            if reset = '1' then
                tx_data <= '0';
            elsif rising_edge(mclk) then
                if en_tx='1' then
                    if bajada_sclk='1' then
                        if cuenta_data > 0 then
                            tx_data <= nota_tx(cuenta_data - 1);
                        else
                            tx_data <= '0';
                        end if;
                    end if;
                else
                    tx_data <= '0';
                end if;
            end if;
        end process;
        
        bajada_sclk <= '1' when eoc_sclk = '1' and sclk = '1' else '0';
        subida_sclk <= '1' when sclk = '0' and eoc_sclk = '1' else '0';
        
        process (reset, mclk)
        begin
          if reset='1' then
            cuenta_data <= 24;
          elsif rising_edge(mclk) then
            if bajada_sclk ='1' and en_tx='1' then
                if cuenta_data = 0 then
                    cuenta_data <= 24;
                else
                    cuenta_data <= cuenta_data - 1;
                end if;
            end if;
          end if;
        end process;
        
        process (reset, mclk)
        begin
            if reset = '1' then
                nota_rx <= (others => '0');
            elsif rising_edge(mclk) then
                if en_tx='1' and subida_sclk='1' and cuenta_data < 24 then
                    nota_rx(cuenta_data) <= rx_data;
                elsif en_tx = '0' then
                    nota_recibida <= nota_rx;
                end if;
            end if;
        end process;
        
        --led(2 downto 0) <= freq_actual;
        led(2 downto 0) <= (others => '0');  -- siempre apagados
                
end Behavioral;
