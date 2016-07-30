library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.numeric_bit.all;

--
-- This module monitors the RX pin
-- for incoming data and outputs the received bytes
-- for superior modules to work with
--
-- A rising edge is presented on the byte_ready signal,
-- when 8 bits have been received, which are presented via received_byte.
-- The module must be reset initially and after every
-- received byte in order to accept new data. 
--
entity uart_rx is
    port(
        -- 21 MHz input clock
        clock_12mhz      : in  std_logic;
        
        -- resets module from standby before and after data reception
        reset            : in  std_logic;
        
        -- the receiving pin of the RS-232 transmission
        rx               : in  std_logic;
        test             : out std_logic;
        
        -- output received byte
        received_byte    : out std_logic_vector(7 downto 0);
        byte_ready       : out std_logic
    );
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
    process(reset, clock_12mhz, rx)

       variable tick_counter : integer range 0 to 1250 := 0;
       constant tick_overflow: integer := 1250; -- 12 MHz / 1250 = 9600 bps

       variable receiving    : boolean := false;
       variable bit_counter  : integer range 0 to 8 := 0;

       variable toggler      : std_logic := '0';
       
    begin
        if (reset = '1')
        then
            tick_counter := 0;
            bit_counter  := 0;
            receiving    := false;
            byte_ready  <= '0';
        
        elsif (clock_12mhz'event and clock_12mhz = '1')
        then
            -- divide master clock down to baud rate
            if (tick_counter < tick_overflow)
            then
                tick_counter := tick_counter + 1;

            else
                -- This block is evaluated at 9600 Hz

                -- verify baud frequency
                if (toggler = '0')
                then
                    toggler := '1';
                else
                    toggler := '0';
                end if;
                test <= toggler;
                
                -- are we receiving a byte yet?
                if (receiving)
                then
                    -- save incoming bit at corresponding position in vector
                    if (bit_counter < 8)
                    then
                        received_byte(bit_counter) <= rx;
                        bit_counter := bit_counter + 1;
                    else
                        -- 8 or more bits have been received
                        byte_ready <= '1';
                    end if;
                else
                    -- if a start bit is received, initiate reception
                    if (rx = '0')
                    then
                        receiving := true;
                    end if; -- start bit
                end if; -- receiving

                tick_counter := 0;
            end if; -- UART clock
        end if; -- 12 MHz clock
    end process; -- main

end;
