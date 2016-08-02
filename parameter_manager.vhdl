library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- This module receives raw bytes from the UART pin
-- and outputs them as parameters 1 to 4 (index 0 to 3).
-- The receiving state machine is reset via a magic reset byte.
--
entity parameter_manager is
    port(
        -- 12 MHz clock input
        clock_12mhz      : in  std_logic;
        manager_reset    : in  std_logic;

        -- serial port interface to computer
        rx               : in  std_logic;
        tx               : out std_logic;
        rts              : in  std_logic;
        cts              : out std_logic;

        -- parameter management
        param0           : out std_logic_vector(7 downto 0);
        param1           : out std_logic_vector(7 downto 0);
        param2           : out std_logic_vector(7 downto 0);
        param3           : out std_logic_vector(7 downto 0)
    );
end;
 
--
-- Module implementation
--
architecture manager of parameter_manager is

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
end;
