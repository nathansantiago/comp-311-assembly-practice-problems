# RISC-V (RARS) Practice Game: Guess the Number
# Implement ONLY the game logic (branches/jumps/arithmetic).
# The rest of the implementation is provided.
#
# Allowed instructions (based on what you've covered):
#   add, sub, addi, jal (J-type), branch instructions, R-type ops


.data
welcome:        .asciz "=== VAULT CODE ===\nGuess the secret number.\n"
prompt:         .asciz "Enter your guess (0-99): "
too_low_msg:    .asciz "Too low.\n"
too_high_msg:   .asciz "Too high.\n"
correct_msg:    .asciz "Correct! Vault opened.\n"
attempts_msg:   .asciz "Attempts: "
play_again_msg: .asciz "Play again? (1=yes, 0=no): "
goodbye:        .asciz "Goodbye.\n"
newline:        .asciz "\n"

.text
.globl main

j main

# -------------------------------------------------------------------
# Syscall wrappers (provided)
# -------------------------------------------------------------------

# print_str(a0 = address of null-terminated string)
print_str:
    li a7, 4
    ecall
    ret

# print_int(a0 = integer)
print_int:
    li a7, 1
    ecall
    ret

# read_int() -> returns integer in a0
read_int:
    li a7, 5
    ecall
    ret

# read_char() -> returns ASCII code in a0
read_char:
    li a7, 12
    ecall
    ret

# exit()
exit_program:
    li a7, 10
    ecall

# -------------------------------------------------------------------
# Main + Game Skeleton
# -------------------------------------------------------------------

main:
    # Print welcome
    la a0, welcome
    jal print_str

game_restart:
    # Setup game state (provided)
    # s0 = secret number
    # s1 = attempts counter
    li s0, 37
    li s1, 0

game_loop:
    # Prompt user
    la a0, prompt
    jal print_str

    # Read guess -> a0
    jal read_int
    add t0, a0, x0     # t0 = guess (save it)

    # Increment attempts
    addi s1, s1, 1

    # ---------------------------------------------------------------
    # STUDENT TODO #1: Compare guess (t0) to secret (s0)
    #
    # Required behavior:
    #   if (t0 < s0)  -> jump to label: guess_too_low
    #   if (t0 > s0)  -> jump to label: guess_too_high
    #   else          -> jump to label: guess_correct
    #
    # Use only branches/jumps and the instructions you know.
    # ---------------------------------------------------------------

    # Compare guess (t0) vs secret (s0).
    # Values are expected in 0..99.
    add t2, t0, x0
    add t3, s0, x0

compare_loop:
    beq t2, t3, guess_correct
    beq t2, x0, guess_too_low
    beq t3, x0, guess_too_high
    addi t2, t2, -1
    addi t3, t3, -1
    j compare_loop

guess_too_low:
    la a0, too_low_msg
    jal print_str
    j game_loop

guess_too_high:
    la a0, too_high_msg
    jal print_str
    j game_loop

guess_correct:
    la a0, correct_msg
    jal print_str

    # Print attempts line
    la a0, attempts_msg
    jal print_str
    add a0, s1, x0
    jal print_int
    la a0, newline
    jal print_str

    # Ask to play again
    la a0, play_again_msg
    jal print_str
    jal read_int
    add t1, a0, x0     # t1 = replay choice

    # ---------------------------------------------------------------
    # STUDENT TODO #2: Replay logic
    #
    # Required behavior:
    #   if (t1 == 1) -> restart game (jump to game_restart)
    #   else         -> quit (jump to game_quit)
    # ---------------------------------------------------------------

    addi t3, x0, 1
    beq t1, t3, game_restart
    j game_quit

game_quit:
    la a0, goodbye
    jal print_str
    jal exit_program