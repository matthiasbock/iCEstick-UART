library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.numeric_bit.all;

--
-- This module transmits a byte via UART
--
-- When a rising edge is encountered on the send signal,
-- 8 bits from data are shifted out on the TX pin, LSB first.
-- After the last bit is transmitted, sent changes to HIGH.
--
entity uart_tx is
    port(
        -- 12 MHz input clock
        clock_12mhz      : in  std_logic;
        
        -- resets module from standby before and after data reception
        reset            : in  std_logic;
        
        -- the transmitting pin of the RS-232 connection
        tx               : out std_logic;
        -- Request-To-Send: Here the FPGA waits for the receiver to get ready for reception
        rts              : in  std_logic;
        
        -- transmit byte
        data             : in  std_logic_vector(7 downto 0);
        send             : in  std_logic;
        sent             : out std_logic
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
    process(reset, clock_12mhz)

       variable tick_counter : integer range 0 to 1250 := 0;
       constant tick_overflow: integer := 1250; -- 12 MHz / 1250 = 9600 bps

       variable sending      : boolean := false;
       variable bit_counter  : integer range 0 to 8 := 0;
       
    begin
        if (reset = '1')
        then
            tick_counter := 0;
            bit_counter  := 0;
            tx          <= '1';
            sending      := false;
            sent        <= '1';
        
        elsif (clock_12mhz'event and clock_12mhz = '1')
        then
            if (send = '1' and not sending)
            then
                sent       <= '0';
                sending     := true;
                bit_counter := 0;
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
                        tx <= '0';
                        sent <= '0';
                    elsif (bit_counter < 9)
                    then
                        tx <= data(bit_counter-1);
                        sent <= '0';
                    elsif (bit_counter = 9)
                    then
                        -- stopp bit
                        tx <= '0';
                        sent <= '0';
                    else
                        -- 8 bits have been sent
                        tx <= '1';
                        sent <= '1';
                        sending := false;
                    end if;
                    bit_counter := bit_counter + 1;
                end if; -- receiving

                tick_counter := 0;
            end if; -- UART clock
        end if; -- 12 MHz clock
    end process; -- main

end;
