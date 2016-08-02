library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- This module transmits a byte via UART
--
-- When a rising edge is encountered on the uart_tx_send signal,
-- 8 bits from data are shifted out on the TX pin, LSB first.
-- After the last bit is transmitted, uart_tx_sent changes to HIGH.
--
entity uart_tx is
    port(
        -- 12 MHz input clock
        uart_tx_clock_12mhz      : in  std_logic;
        
        -- resets module from standby before and after data reception
        uart_tx_reset            : in  std_logic;
        
        -- the transmitting pin of the RS-232 connection
        uart_tx_pin_tx           : out std_logic;
        -- Request-To-Send: Here the FPGA waits for the receiver to get ready for reception
        -- TODO: actually wait for RTS signal
        uart_tx_pin_rts          : in  std_logic;
        
        -- transmit byte
        uart_tx_data             : in  std_logic_vector(7 downto 0);
        uart_tx_send             : in  std_logic;
        uart_tx_sent             : out std_logic
    );
end;
 
--
-- UART transmitter module implementation
--
architecture uart_sender of uart_tx is
begin
    --
    -- main routine:
    -- executed, whenever the module is reset
    -- or a rising edge occurs on the main clock
    --
    process(uart_tx_reset, uart_tx_clock_12mhz)

       variable tick_counter : integer range 0 to 1250 := 0;
       constant tick_overflow: integer := 1250; -- 12 MHz / 1250 = 9600 bps

       variable sending      : boolean := false;
       variable bit_counter  : integer range 0 to 8 := 0;
       
    begin
        if (uart_tx_reset = '1')
        then
            tick_counter    := 0;
            bit_counter     := 0;
            uart_tx_pin_tx  <= '1';
            sending         := false;
            uart_tx_sent    <= '1';
        
        elsif (uart_tx_clock_12mhz'event and uart_tx_clock_12mhz = '1')
        then
            if (uart_tx_send = '1')
            then
                uart_tx_sent    <= '0';
                sending         := true;
                bit_counter     := 0;
            end if;

            -- divide master clock down to baud rate
            if (tick_counter < tick_overflow)
            then
                tick_counter := tick_counter + 1;

            else
                -- This block is evaluated at 9600 Hz
                
                -- are we currently transmitting?
                if (sending)
                then
                    if (bit_counter = 0)
                    then
                        -- start bit
                        uart_tx_pin_tx <= '0';
                        uart_tx_sent <= '0';
                    elsif (bit_counter < 9)
                    then
                        uart_tx_pin_tx <= uart_tx_data(bit_counter-1);
                        uart_tx_sent <= '0';
                    elsif (bit_counter = 9)
                    then
                        -- stopp bit
                        uart_tx_pin_tx <= '0';
                        uart_tx_sent <= '0';
                    else
                        -- 8 bits have been sent
                        uart_tx_pin_tx <= '1';
                        uart_tx_sent <= '1';
                        sending := false;
                    end if;
                    bit_counter := bit_counter + 1;
                end if; -- receiving

                tick_counter := 0;
            end if; -- UART clock
        end if; -- 12 MHz clock
    end process; -- main

end;
