----------------------------------------------------------------------------------
-- Company: UC3M
-- Engineer: Alejandro Estaire Martin
-- 
-- Create Date: 27.05.2025 20:13:53
-- Design Name: 
-- Module Name: fsm_audiometry - Behavioral
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

entity fsm_audiometry is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        canal_sel  : in  std_logic_vector(1 downto 0);  
        cuenta_max : out unsigned(14 downto 0);
        freq_id    : out std_logic_vector(2 downto 0);
        new_freq   : out std_logic;
        seg        : out std_logic_vector(6 downto 0);
        an         : out std_logic_vector(3 downto 0);
        dp         : out std_logic                        -- Punto decimal
    );
end fsm_audiometry;

architecture Behavioral of fsm_audiometry is
    type estado_t is (IDLE, F250, F500, F1000, F2000, F4000, F8000, F15000);
    signal estado : estado_t := IDLE;

    signal temporizador : unsigned(26 downto 0) := (others => '0'); -- ~2s

    constant C250    : unsigned(14 downto 0) := to_unsigned(373, 15);
    constant C500    : unsigned(14 downto 0) := to_unsigned(746, 15);
    constant C1000   : unsigned(14 downto 0) := to_unsigned(1493, 15);
    constant C2000   : unsigned(14 downto 0) := to_unsigned(2986, 15);
    constant C4000   : unsigned(14 downto 0) := to_unsigned(5972, 15);
    constant C8000   : unsigned(14 downto 0) := to_unsigned(11945, 15);
    constant C15000  : unsigned(14 downto 0) := to_unsigned(22350, 15);
    constant CIDLE  : unsigned(14 downto 0) := to_unsigned(0, 15);

    signal id : std_logic_vector(2 downto 0);
    signal freq_pulse : std_logic := '0';

    signal digits : std_logic_vector(15 downto 0);
    signal sel    : unsigned(1 downto 0) := (others => '0');
    signal cnt_disp : unsigned(15 downto 0) := (others => '0');
    signal enable_prueba : std_logic;
    signal canal_prev   : std_logic_vector(1 downto 0) := (others => '0');
    signal start_test   : std_logic := '0';
    signal prueba_activa: std_logic := '0';



begin

    -- Asociar cuenta_max y freq_id
    with estado select
        cuenta_max <= C250    when F250,
                      C500    when F500,
                      C1000   when F1000,
                      C2000   when F2000,
                      C4000   when F4000,
                      C8000   when F8000,
                      C15000  when F15000,
                      CIDLE   when IDLE;

    with estado select
    id <= "000" when F250,
          "001" when F500,
          "010" when F1000,
          "011" when F2000,
          "100" when F4000,
          "101" when F8000,
          "110" when F15000,
          "111" when IDLE;


    freq_id <= id;
    new_freq <= freq_pulse;
    enable_prueba <= '1' when (canal_sel = "01" or canal_sel = "10") else '0';


    -- Mostrar en 7 segmentos
    process(estado)
    begin
        case estado is
            when F250    => digits <= x"0025";  -- se mostrará como 0.250
            when F500    => digits <= x"0050";  -- 0.500
            when F1000   => digits <= x"0100";  -- 1.000
            when F2000   => digits <= x"0200";  -- 2.000
            when F4000   => digits <= x"0400";  -- 4.000
            when F8000   => digits <= x"0800";  -- 8.000
            when F15000  => digits <= x"1500";  -- 15.00
            when IDLE    => digits <= x"DBAC";  -- P, L, A, Y




        end case;
    end process;
    
    
    process(clk)
    begin
        if rising_edge(clk) then
            canal_prev <= canal_sel;
    
            if (canal_sel /= "00" and canal_prev = "00") then
                start_test <= '1';
            else
                start_test <= '0';
            end if;
        end if;
    end process;



    process(clk)
        variable bcd : std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk) then
            cnt_disp <= cnt_disp + 1;
            if cnt_disp = 0 then
                sel <= sel + 1;
            end if;

            case sel is
                when "00" => bcd := digits(3 downto 0);  an <= "1110";
                when "01" => bcd := digits(7 downto 4);  an <= "1101";
                when "10" => bcd := digits(11 downto 8); an <= "1011";
                when others => bcd := digits(15 downto 12); an <= "0111";
            end case;

            case bcd is
                when "0000" => seg <= "1000000"; -- 0 normal
                when "0001" => seg <= "1111001"; -- 1
                when "0010" => seg <= "0100100"; -- 2
                when "0011" => seg <= "0110000"; -- 3
                when "0100" => seg <= "0011001"; -- 4
                when "0101" => seg <= "0010010"; -- 5 
                when "0110" => seg <= "0000010"; -- 6
                when "0111" => seg <= "1111000"; -- 7
                when "1000" => seg <= "0000000"; -- 8
                when "1001" => seg <= "0010000"; -- 9
            
                -- Letras personalizadas (orden gfedcba)
                when "1010" => seg <= "0001000"; -- A (a, b, c, e, f, g) 
                when "1011" => seg <= "1000111"; -- L (f, e, d)
                when "1100" => seg <= "0010001"; -- Y (g, f, d, c, b)
                when "1101" => seg <= "0001100"; -- P (g, f, e, b, a)
                when "1110" => seg <= "0110000"; -- E (g, f, e, d, a)
                when "1111" => seg <= "1111111"; -- blanco (todo apagado)

            
                when others => seg <= "1111111"; -- apagado
            end case;


            -- Activar punto decimal en el lugar adecuado
                        case estado is
                when F250 | F500 =>
                    if sel = "10" then dp <= '0'; else dp <= '1'; end if;  -- dp entre dígito 0 y 1

                when F1000 | F2000 | F4000 | F8000 =>
                    if sel = "10" then dp <= '0'; else dp <= '1'; end if;  -- dp entre dígito 1 y 2

                when F15000 =>
                    if sel = "10" then dp <= '0'; else dp <= '1'; end if;  -- dp entre dígito 2 y 3

                when others =>
                    dp <= '1';
            end case;

        end if;
    end process;

    -- FSM de estados
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                estado <= IDLE;
                temporizador <= (others => '0');
                freq_pulse <= '0';
                prueba_activa <= '0';
            else
                freq_pulse <= '0';
    
                -- Inicio de prueba desde IDLE si se detecta flanco
                if start_test = '1' and estado = IDLE then
                    estado <= F250;
                    prueba_activa <= '1';
                    temporizador <= (others => '0');
    
                elsif prueba_activa = '1' then
                    if temporizador = to_unsigned(45_158_420, 27) then
                    --if temporizador = to_unsigned(451_584, 27) then -- Descomentar para simulación (cambia el tiempo entre estados a 20ms) (22579210Hz x 0,02s = 451584
                        temporizador <= (others => '0');
                        freq_pulse <= '1';
                        case estado is
                            when F250    => estado <= F500;
                            when F500    => estado <= F1000;
                            when F1000   => estado <= F2000;
                            when F2000   => estado <= F4000;
                            when F4000   => estado <= F8000;
                            when F8000   => estado <= F15000;
                            when F15000  =>
                                estado <= IDLE;         -- Final de la prueba
                                prueba_activa <= '0';   -- Desactivar FSM
                            when others => null;
                        end case;
                    else
                        temporizador <= temporizador + 1;
                    end if;
                else
                    temporizador <= (others => '0');
                end if;
            end if;
        end if;
    end process;



end Behavioral;
