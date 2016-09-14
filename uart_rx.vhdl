library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- This module monitors the RX pin
-- for incoming data and outputs the received bytes
-- for superior modules to work with
--
-- A rising edge is presented on the uart_rx_data_ready signal,
-- when 8 bits have been received, which are presented via uart_rx_data.
-- The module must be reset initially and after every
-- received byte in order to accept new data. 
--
entity uart_rx is
    port(
        -- 12 MHz input clock
        uart_rx_clock_12mhz      : in  std_logic;
        
        -- reset this module once at FPGA startup!
        uart_rx_reset            : in  std_logic;
        
        -- the receiving pin of the RS-232 connection
        uart_rx_pin_rx           : in  std_logic;
        -- Clear To Send: On this pin the FPGA can indicate, that it's ready to receive more data
        uart_rx_pin_cts          : out std_logic;
        -- Data Set Ready: On this pin the FPGA can indicate, that it's ready to receive more data
        uart_rx_pin_dsr          : out std_logic;
        
        -- the byte received on the serial port
        uart_rx_data             : out std_logic_vector(7 downto 0);
        uart_rx_data_ready       : out std_logic
    );

    --
    -- Workaround for apparent bug in iCEcube2 2016.02.27810:
    -- Synthesizer removes registers, which are used by other entities
    --
    attribute syn_preserve: boolean;
    attribute syn_preserve of uart_rx_pin_cts       : signal is true;
    attribute syn_preserve of uart_rx_pin_dsr       : signal is true;
    attribute syn_preserve of uart_rx_data          : signal is true;
    attribute syn_preserve of uart_rx_data_ready    : signal is true;
end;
 
--
-- UART receiver module implementation
--
architecture uart_receiver of uart_rx is
begin
    --
    -- main routine:
    -- executed, whenever the module is reset
    -- or a rising edge occurs on the main clock
    --
    process(uart_rx_reset, uart_rx_clock_12mhz)

       variable tick_counter : integer range 0 to 1250 := 0;
       constant tick_overflow: integer := 1250; -- 12 MHz / 1250 = 9600 bps
       constant tick_middle  : integer := tick_overflow / 2;

       variable receiving    : boolean := false;
       variable synchronized : boolean := false;
       variable bit_counter  : integer := 0;
       variable data         : std_logic_vector(7 downto 0) := (others => '0');

    begin
        if (uart_rx_reset = '1')
        then
            tick_counter := 0;
            bit_counter  := 0;
            receiving    := false;
            synchronized := false;
            uart_rx_data_ready <= '0';
            uart_rx_data <= (others => '0');

            -- ready to receive data
            uart_rx_pin_cts <= '0';
            uart_rx_pin_dsr <= '0';
        
        elsif (uart_rx_clock_12mhz'event and uart_rx_clock_12mhz = '1')
        then
            -- synchronize our UART counter on start bit
            if ((not receiving)
            and (uart_rx_pin_rx = '0')
            and (not synchronized))
            then
                -- counter is set to half overflow, so that the following counter overflows occur in the middle of a signal bit
                tick_counter := tick_middle;
                synchronized := true;
            end if;
        
            -- divide master clock down to baud rate
            if (tick_counter < tick_overflow)
            then
                tick_counter := tick_counter + 1;

            else
                -- This block is evaluated at 9600 Hz

                -- are we receiving a byte yet?
                if (receiving)
                then
                    if (bit_counter < 8)
                    then
                        -- save incoming bit at corresponding position in vector
                        data(bit_counter) := uart_rx_pin_rx;
                        bit_counter := bit_counter + 1;
                    elsif (bit_counter = 8)
                    then
                        -- 8 or more bits have been received
                        -- pass received byte to higher functions
                        uart_rx_data <= data;
                        -- not ready to receive more data
                        uart_rx_pin_cts <= '1';
                        uart_rx_pin_dsr <= '1';
                        -- wait one clock pulse to signal data readynes
                        bit_counter := 9;
                    elsif (bit_counter = 9)
                    then
                        -- invoke byte received event
                        uart_rx_data_ready <= '1';
                        -- higher functions get some time to process received data until line is cleared for next byte
                        bit_counter := 10;
                    elsif (bit_counter < 100)
                    then
                        bit_counter := bit_counter + 1;
                        synchronized := false;
                    else
                        -- reset receiver
                        bit_counter := 0;
                        uart_rx_data_ready <= '0';
                        receiving := false;
                        -- ready to receive another byte
                        uart_rx_pin_cts <= '0';
                        uart_rx_pin_dsr <= '0';
                    end if;
                else
                    -- if a start bit is received, initiate reception
                    if (uart_rx_pin_rx = '0')
                    then
                        receiving := true;
                    end if; -- start bit
                end if; -- receiving

                tick_counter := 0;
            end if; -- UART clock
        end if; -- 12 MHz clock
    end process; -- main

end;
