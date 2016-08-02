library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- This is a demo for the UART RX module
--
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

        -- test signals
        test1            : out std_logic;
        test2            : out std_logic;
        test3            : out std_logic;
        test4            : out std_logic;

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
            -- 12 MHz input clock
            uart_rx_clock_12mhz      : in  std_logic;
            
            -- resets module from standby before and after data reception
            uart_rx_reset            : in  std_logic;
            
            -- the receiving pin of the RS-232 connection
            uart_rx_pin_rx           : in  std_logic;
            -- Clear-To-Send: Here the FPGA can indicate, that it's ready to receive more data
            uart_rx_pin_cts          : out std_logic;
            
            -- output received byte
            uart_rx_data             : out std_logic_vector(7 downto 0);
            uart_rx_data_ready       : out std_logic
            );
    end component;

    component uart_tx is
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
    end component;

    signal reset : std_logic := '1';

    -- intermediate signals for debugging
    signal uart_intermediate_rx : std_logic := '0';
    signal uart_intermediate_tx : std_logic := '0';
    signal uart_intermediate_rts: std_logic := '0';
    signal uart_intermediate_cts: std_logic := '0';
    
    -- UART-RX
    signal uart_reset_receiver  : std_logic := '0';
    signal uart_received_byte   : std_logic_vector(7 downto 0);
    signal uart_byte_ready      : std_logic := '0';

    -- UART-TX
    signal uart_reset_transmitter: std_logic := '0';
    signal uart_transmit_byte   : std_logic_vector(7 downto 0);
    signal uart_send            : std_logic := '0';
    signal uart_sent            : std_logic := '0';

begin
    -- manage reset signals
    reset <= '0' after 30ns;
    
    -- instantiate a UART receiver entity
    my_uart_receiver: uart_rx
    port map(
            uart_rx_clock_12mhz     => clock_12mhz,
            uart_rx_reset           => '0',
            uart_rx_pin_rx          => uart_intermediate_rx,
            uart_rx_pin_cts         => uart_intermediate_cts,
            uart_rx_data            => uart_received_byte,
            uart_rx_data_ready      => uart_byte_ready
            );

    my_uart_transmitter: uart_tx
    port map(
            uart_tx_clock_12mhz     => clock_12mhz,
            uart_tx_reset           => '0',
            uart_tx_pin_tx          => uart_intermediate_tx,
            uart_tx_pin_rts         => uart_intermediate_rts,
            uart_tx_data            => uart_transmit_byte,
            uart_tx_send            => uart_send,
            uart_tx_sent            => uart_sent
            );

    -- verify byte reception
    led_center <= uart_received_byte(0);
    led_top    <= uart_received_byte(1);
    led_left   <= uart_received_byte(2);
    led_bottom <= uart_received_byte(3);
    led_right  <= uart_received_byte(4);

    --
    -- loopback received byte
    --
    process(uart_intermediate_cts)
    begin
        if (uart_intermediate_cts'event and uart_intermediate_cts = '1')
        then
            uart_transmit_byte  <= uart_received_byte;
            uart_send           <= '1';
            uart_send           <= '0' after 100ns;
        end if;
    end process;

    -- mirror UART input pint
    uart_intermediate_rx <= rx;
    test1 <= rx;

    -- mirror UART output to test pin
    tx    <= uart_intermediate_tx;
    test2 <= uart_intermediate_tx;

    -- test RTS and CTS signals
    uart_intermediate_rts <= rts;
    test3   <= rts;
    cts     <= uart_intermediate_cts;
    test4   <= uart_intermediate_cts;

    --
    -- Interpreter for via UART received bytes
    --
    -- process(clock_12mhz, uart_byte_ready)
        -- constant char_lower_a: std_logic_vector(7 downto 0) := "01100001";
        -- constant char_upper_A: std_logic_vector(7 downto 0) := "01000001";
    -- begin
        -- if (reset'event)
        -- then
            -- uart_rx_reset <= '0' after 30ns;
        -- end if;
        -- if (uart_byte_ready'event and uart_byte_ready = '1')
        -- then
            -- -- prepare UART receiver for next reception
            -- uart_rx_reset <= '1';
            -- uart_rx_reset <= '0' after 30ns;
        -- end if; -- UART: byte ready
    -- end process; -- UART data interpreter
    
end;
