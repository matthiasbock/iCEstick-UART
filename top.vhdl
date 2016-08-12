library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- UART Buffer Demo
-- Receive bytes on the RX pin and store the received data in registers
--
entity top is
    port(
        -- 12 MHz clock input
        clock_12mhz      : in  std_logic;

        -- serial port interface to computer
        dcd              : out std_logic;
        dsr              : out std_logic;
        dtr              : in  std_logic;
        cts              : out std_logic;
        rts              : in  std_logic;
        tx               : out std_logic;
        rx               : in  std_logic;

        -- LED outputs
        led_top          : out std_logic;
        led_left         : out std_logic;
        led_center       : out std_logic;
        led_right        : out std_logic;
        led_bottom       : out std_logic
    );
end;
 
architecture main of top is

    -- include a UART receiver buffer
    component uart_rx_buffer is
        port(
            -- 12 MHz clock
            uart_rx_buffer_clock_12mhz  : in std_logic;

            -- UART RX signal
            uart_rx_buffer_pin_rx       : in std_logic;

            -- received data
            uart_rx_buffer_data         : out std_logic_vector(63 downto 0);
            uart_rx_buffer_data_changed : out std_logic
        );
    end component;

    signal data: std_logic_vector(63 downto 0) := (others => '0');
    signal data_changed: std_logic := '0';
    
begin

    -- instantiate a UART receiver buffer
    my_uart_rx_buffer: uart_rx_buffer
    port map(
            uart_rx_buffer_clock_12mhz  => clock_12mhz,
            uart_rx_buffer_pin_rx       => rx,
            uart_rx_buffer_data         => data,
            uart_rx_buffer_data_changed => data_changed
            );

    --
    -- For example, when 'a' is sent by the PC, character 0x61 is received: b01100001
    -- This can be verified by displaying the four bits of register 6:
    -- Only the least significant should light up.
    --
    led_center <= data_changed;
    led_top <= data(0);
    led_left <= data(1);
    led_bottom <= data(24);
    led_right <= data(25);
end;
