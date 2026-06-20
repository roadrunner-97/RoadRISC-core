import definitions::*;

typedef enum logic[2:0]{
    EMPTY,
    ONE_BYTE,
    TWO_BYTES,
    THREE_BYTES,
    FULL
} rx_buffer_state_t;

typedef enum logic[3:0]{
    IDLE,
    START_BIT,
    BIT_ZERO,
    BIT_ONE,
    BIT_TWO,
    BIT_THREE,
    BIT_FOUR,
    BIT_FIVE,
    BIT_SIX,
    BIT_SEVEN,
    STOP_BIT
} rx_bit_state_t;

module uart(
    input logic clock,
    input logic reset,

    input logic rx_pin,
    output logic tx_pin,

    peripheral_if.peripheral rx_word,
    peripheral_if.peripheral flags
);

assign tx_pin = 'b1;

logic rx_sync;
clock_synchroniser sync (
    .dest_clock (clock),
    .signal_in  (rx_pin),
    .signal_out (rx_sync)
);

logic [15:0] sample_timer;

word_t rx_buffer;
rx_bit_state_t bit_state;
rx_buffer_state_t buffer_state;
logic [7:0] byte_data;



always_ff @(posedge clock) begin
    if(reset) begin
        sample_timer <= '0;
        bit_state <= IDLE;
        buffer_state <= EMPTY;
    end else begin
        case(bit_state)
        IDLE: begin
            if(!rx_sync && buffer_state != FULL) begin
                bit_state <= START_BIT;
                sample_timer <= '0;
            end
        end

        START_BIT: begin
            if(sample_timer == 2604) begin
                if(!rx_sync) begin //not a glitch
                    bit_state <= BIT_ZERO;
                    sample_timer <= 0;
                    byte_data <= 0;
                end else begin
                    bit_state <= IDLE; //false alarm
                end
            end else begin
                sample_timer <= sample_timer + 1;
            end
        end

        BIT_ZERO, BIT_ONE, BIT_TWO, BIT_THREE, BIT_FOUR, BIT_FIVE, BIT_SIX, BIT_SEVEN: begin
            if(sample_timer == 5208) begin
                byte_data <= {rx_sync, byte_data[7:1]};
                bit_state <= bit_state.next();
                sample_timer <= 0;
            end else begin
                sample_timer <= sample_timer + 1;
            end
        end

        STOP_BIT: begin
            if(sample_timer == 2604) begin
                rx_buffer <= {rx_buffer[23:0], byte_data};
                case(buffer_state)
                    EMPTY:       buffer_state <= ONE_BYTE;
                    ONE_BYTE:    buffer_state <= TWO_BYTES;
                    TWO_BYTES:   buffer_state <= THREE_BYTES;
                    THREE_BYTES: buffer_state <= FULL;
                endcase
                sample_timer <= 0;
                bit_state <= IDLE;
            end else begin
                sample_timer <= sample_timer + 1;
            end
        end
        endcase
    end

    if(rx_word.requested && buffer_state == FULL)
        buffer_state <= EMPTY;
end

assign flags.response   = {31'b0, (buffer_state == FULL)};
assign rx_word.response = rx_buffer;


endmodule