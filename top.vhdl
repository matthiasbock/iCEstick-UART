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
        rts              : in  std_logic;
        cts              : out std_logic;

        test             : out std_logic;
        
        -- LED outputs
        led_top          : out std_logic;
        led_left         : out std_logic;
        led_center       : out std_logic;
        led_right        : out std_logic;
        led_bottom       : out std_logic
    );
end;
 
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
            
            -- RS-232 transmission:
            -- the data receiving pin
            rx               : in  std_logic;
            -- the Clear-To-Send pin
            cts              : out std_logic;

            test             : out std_logic;
            
            -- output received byte
            received_byte    : out std_logic_vector(7 downto 0);
            byte_ready       : out std_logic
            );
    end component;

    component uart_tx is
        port(
            -- 21 MHz input clock
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
    end component;

    signal reset : std_logic := '1';

    -- UART-RX
    signal uart_rx_reset      : std_logic := '1';
    signal uart_received_byte : std_logic_vector(7 downto 0);
    signal uart_byte_ready    : std_logic := '0';

    --UART-TX
    signal uart_transmit_byte : std_logic_vector(7 downto 0);
    signal uart_send          : std_logic := '0';
    signal uart_sent          : std_logic := '0';
begin
    -- manage reset signals
    reset <= '0' after 30ns;
    
    -- instantiate a UART receiver entity
    my_uart_receiver: uart_rx
    port map(
            clock_12mhz      => clock_12mhz,
            reset            => uart_rx_reset,
            rx               => rx,
            cts              => cts,
            test             => test,
            received_byte    => uart_received_byte,
            byte_ready       => uart_byte_ready
            );

    my_uart_transmitter: uart_tx
    port map(
            clock_12mhz      => clock_12mhz,
            reset            => reset,
            tx               => tx,
            rts              => rts,
            data             => uart_transmit_byte,
            send             => uart_send,
            sent             => uart_sent
            );

    -- verify byte reception
    led_center <= rts;
    led_top <= uart_send;
    led_left <= uart_received_byte(2);
    led_bottom <= uart_sent;
    led_right <= uart_received_byte(4);

    uart_transmit_byte <= uart_received_byte;
    uart_send <= uart_byte_ready;

    --
    -- Interpreter for via UART received bytes
    --
    process(clock_12mhz, uart_byte_ready)
        constant char_lower_a: std_logic_vector(7 downto 0) := "01100001";
        constant char_upper_A: std_logic_vector(7 downto 0) := "01000001";
    begin
        if (reset'event)
        then
            uart_rx_reset <= '0' after 30ns;
        end if;
        if (uart_byte_ready'event and uart_byte_ready = '1')
        then
            -- prepare UART receiver for next reception
            uart_rx_reset <= '1';
            uart_rx_reset <= '0' after 30ns;
        end if; -- UART: byte ready
    end process; -- UART data interpreter
    
end;
