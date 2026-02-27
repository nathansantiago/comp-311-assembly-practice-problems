# Number Guessing Game — Solution Explanation

This file explains **how the solution works**.

## 1) Big picture

The program is a loop-based game:

1. Print a welcome message.
2. Set a secret number (`s0 = 37`) and attempts counter (`s1 = 0`).
3. Repeatedly ask for a guess.
4. Compare guess vs secret:
	- lower → print `Too low.`
	- higher → print `Too high.`
	- equal → print success and attempts
5. Ask to play again (`1` = yes, anything else = no).

---

## 2) Registers used in the game

- `s0`: secret number (persists across the game loop)
- `s1`: attempts counter
- `t0`: current guess
- `t1`: replay input
- `t2`, `t3`: temporary values for compare logic
- `a0`: argument/return register used by syscall wrapper functions

Why these choices matter:
- `s` registers are good for values that must survive many operations (`secret`, `attempts`).
- `t` registers are good scratch space.

---

## 3) Core solution logic (the important part)

### A) Saving user input

You may see this pattern:

```riscv
add t0, a0, x0
```

That copies `a0` into `t0` saving user keyboard input.

### B) Counting attempts

```riscv
addi s1, s1, 1
```

Every guess increments attempts by 1.

### C) Comparing guess and secret using only `beq`, `addi`, `j`

Because this version avoids `bgt` and `blt` instructions (this will be taught later in the course) in the student logic, it compares by **decrementing two copies together**:

```riscv
add t2, t0, x0   # copy guess
add t3, s0, x0   # copy secret

compare_loop:
	 beq t2, t3, guess_correct
	 beq t2, x0, guess_too_low
	 beq t3, x0, guess_too_high
	 addi t2, t2, -1
	 addi t3, t3, -1
	 j compare_loop
```

Why it works:
- If values are equal, they stay equal after equal decrements, so first `beq` catches it.
- If guess is smaller, `t2` reaches zero first → too low.
- If guess is larger, `t3` reaches zero first → too high.

Not this relies on the assumption inputs are non-negative (the prompt asks for `0-99`).

### D) Replay decision (`1` restarts)

```riscv
addi t3, x0, 1
beq t1, t3, game_restart
j game_quit
```

If replay input equals 1, jump back to reset state. Otherwise quit.

---

## 4) Control-flow map by labels

- `main` → prints welcome
- `game_restart` → initializes secret + attempts
- `game_loop` → prompt, read, attempt++, compare
- `guess_too_low` / `guess_too_high` → message then back to `game_loop`
- `guess_correct` → success, attempts, replay prompt
- `game_quit` → goodbye + exit syscall

This is the assembly equivalent of a `while(true)` loop with `if/else` branches.

---

# Further Reading


## 5) How the “provided code” works

The logic above is only part of the file. The rest is setup and I/O plumbing:

### A) Data section (`.data`)

- Strings like `welcome`, `prompt`, `too_low_msg`, etc. are stored in memory.
- `.asciz` means a null-terminated string (required for print-string syscall).

### B) Text section (`.text`) and entry

- `.globl main` exposes `main` as an entry symbol.
- `j main` ensures execution starts at `main` even if the first code label is a helper function.

### C) Syscall wrapper functions

The wrappers are small helper routines:

- `print_str`: sets `a7=4`, `ecall`
- `print_int`: sets `a7=1`, `ecall`
- `read_int`: sets `a7=5`, `ecall`, result in `a0`
- `read_char`: sets `a7=12`, `ecall`
- `exit_program`: sets `a7=10`, `ecall`

Why wrappers help:
- Main game logic stays readable.
- You call wrappers with `jal` and return with `ret`.

#### For curious readers: what `li`, `a7`, and `ecall` are doing

In RARS, input/output is done through **system calls** (often called syscalls). A syscall is like asking the simulator's runtime for a service your program cannot do directly (print text, read keyboard input, exit, etc.).

- `li a7, N` loads syscall code `N` into register `a7`.
	- Example: `li a7, 4` means “the next syscall is print string.”
	- Example: `li a7, 5` means “the next syscall is read integer.”
- `ecall` executes that request.
- Register `a0` carries the main argument/result:
	- For print string, `a0` holds the address of the string.
	- For print integer, `a0` holds the integer value.
	- For read integer, the value typed by the user is returned in `a0`.

So each wrapper function is just a tiny adapter: set `a7` to choose the service, use `a0` for data, run `ecall`, then `ret` back to the game logic.

### D) Calling convention basics you’re already using

- Put function input in `a0` before `jal`.
- Function returns values in `a0`.
- `jal` stores return address in `ra`.
- `ret` jumps back to `ra`.

---

## 6) Common mistakes and debugging tips

1. **Infinite compare loop**
	- Usually caused by forgetting one `addi ... -1`.
2. **Bad register overwrite**
	- Don’t reuse `a0` if you still need its old value; copy into `t`/`s` first.

---

## 7) Practice extensions (optional)

Some interesting things you can do after you understand the current solution:

- Validate input range (`0..99`) and reject invalid guesses.
- Generate a changing secret value (instead of fixed `37`).
- Add max-attempt limit and game-over condition.
- Print a hint with distance from secret.

---

## 8) Suggested further reading

- RISC-V register convention (caller-saved vs callee-saved)
- RARS syscall reference (`a7` service codes)
- Branching patterns for implementing `if`, `if/else`, and loops in assembly
- Pseudoinstructions (`mv`, `li`, `la`) and their underlying base instructions (Note this will be taught later in the course)

These topics will make the structure of this file much easier to read and modify.
