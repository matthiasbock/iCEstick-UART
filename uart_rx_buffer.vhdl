library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- This module receives bytes on the UART RX pin
-- and saves the received data to internal registers 
-- using the more significant 4 bits as address
-- and the lesser significant 4 bits as data
--
entity uart_rx_buffer is
    port(
        -- 12 MHz clock
        uart_rx_buffer_clock_12mhz  : in std_logic;

        -- UART RX signal
        uart_rx_buffer_pin_rx       : in std_logic;

        -- received data
        uart_rx_buffer_data         : out std_logic_vector(63 downto 0);
        uart_rx_buffer_data_changed : out std_logic
    );
end;
 
architecture manager of uart_rx_buffer is

    --
    -- include UART receiver entity
    --
    component uart_rx
        port(
            -- 12 MHz input clock
            uart_rx_clock_12mhz      : in  std_logic;
            
            -- resets module from standby before and after data reception
            uart_rx_reset            : in  std_logic;
            
            -- the receiving pin of the RS-232 connection
            uart_rx_pin_rx           : in  std_logic;
            
            -- output received byte
            uart_rx_data             : out std_logic_vector(7 downto 0);
            uart_rx_data_ready       : out std_logic
            );
    end component;

    signal uart_rx_buffer_byte_ready       : std_logic := '0';
    signal uart_rx_buffer_received_byte    : std_logic_vector(7 downto 0) := (others => '0');

    signal test : std_logic_vector(7 downto 0) := (others => '0');
    
begin

    --
    -- instantiate imported UART receiver
    --
    my_uart_receiver: uart_rx
    port map(
            uart_rx_clock_12mhz     => uart_rx_buffer_clock_12mhz,
            uart_rx_reset           => open,
            uart_rx_pin_rx          => uart_rx_buffer_pin_rx,
            -- uart_rx_pin_cts         => open,
            uart_rx_data            => uart_rx_buffer_received_byte,
            uart_rx_data_ready      => uart_rx_buffer_byte_ready
            );

    --
    -- Whenever a byte is received,
    -- save the received data to the appropriate register position
    --
    process(uart_rx_buffer_byte_ready)
        variable index : integer;
    begin
        if (rising_edge(uart_rx_buffer_byte_ready))
        then
            index := to_integer(unsigned(uart_rx_buffer_received_byte(7 downto 4)))*4;
            uart_rx_buffer_data(index)   <= uart_rx_buffer_received_byte(3);
            uart_rx_buffer_data(index+1) <= uart_rx_buffer_received_byte(2);
            uart_rx_buffer_data(index+2) <= uart_rx_buffer_received_byte(1);
            uart_rx_buffer_data(index+3) <= uart_rx_buffer_received_byte(0);
        end if;
    end process;

    uart_rx_buffer_data_changed <= uart_rx_buffer_byte_ready;

end;
