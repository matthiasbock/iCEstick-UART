library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.numeric_bit.all;

--
-- This is a demo for the UART RX module
--
--
entity top is
    port(
        -- 201 MHz clock input
        clock_12mhz      : in  std_logic;
        
        -- serial port interface to computer
        rx               : in  std_logic;
        tx               : out std_logic;
        
        -- LED outputs
        led_top          : out std_logic;
        led_left         : out std_logic;
        led_center       : out std_logic;
        led_right        : out std_logic;
        led_bottom       : out std_logic;
    );
end top;
 
--
-- Module implementation
--
architecture main of top is

    -- include external entities
    component uart_rx
        port(
            -- 21 MHz input clock
            clock_12mhz      : in  std_logic;
            
            -- resets module from standby before and after data reception
            reset            : in  std_logic;
            
            -- the receiving pin of the RS-232 transmission
            rx               : in  std_logic;
            
            -- output received byte
            received_byte    : out std_logic_vector(7 downto 0);
            byte_ready       : out std_logic
            );
    end component;
    
    signal reset : std_logic := '1';

    signal uart_rx_reset      : std_logic;
    signal uart_received_byte : out std_logic_vector(7 downto 0);
    signal uart_byte_ready    : signal := '0';

begin
    -- manage reset signals
    reset <= '0' after 30ns;
    
    -- instantiate included entities
    my_uart_receiver: pll
    port map(
            clock_12mhz      => clock_12mhz,
            reset            => reset or uart_rx_reset,
            rx               => rx,
            received_byte    => uart_received_byte,
            byte_ready       => uart_byte_ready
            );

    --
    -- Interpreter for via UART received bytes
    --
    process(uart_byte_ready)
        constant a: std_logic_vector(7 downto 0) := "01100001";
        constant A: std_logic_vector(7 downto 0) := "01000001";
    begin
        -- rising edge
        if (uart_byte_ready'event and uart_byte_ready = '1')
        then
            -- switch some LEDs for demonstration
            if (received_byte = a)
            then
                led_center <= '0';
            end if;
            if (received_byte = A)
            then
                led_center <= '1';
            end if;
        
            -- prepare UART receiver for next reception
            uart_rx_reset <= '1';
            uart_rx_reset <= '0' after 30ns;
        end if; -- UART: byte ready
    end process; -- UART data interpreter
    
end main;
