# KBDFIX — keyboard handling off IRQ1

An optional patch to the sources. It is not part of the reconstruction: the listing in
`src/` is what the original binary was built from, and this changes it.

## What it fixes

The main loop asks the BIOS once a frame whether a key is waiting, and takes at most one
out of the buffer:

```
        mov     LASTKEY, 0               ; 044B  the frame's key starts out empty until one is read
        xor     al, al                   ; 0451  AL takes no part here, cleared along the way
        mov     ah, 1                    ; 0453  AH=1: is a key waiting in the buffer
        int     16h                      ; 0455  keyboard BIOS: is there one
        je      MAINLP                   ; 0457  the buffer is empty -- straight on to the next frame
        xor     ax, ax                   ; 0459  AH=0: take the key out of the buffer
        int     16h                      ; 045B  keyboard BIOS: one key per frame, no more
        mov     LASTKEY, ax              ; 045D  scan code and ASCII are handed on to the state handlers
```

Everything that follows from that is what the patch is for. The game never sees a key
being *held* — it sees the keyboard's own typematic repeat, so a held direction pauses
for the initial delay and then steps at the repeat rate instead of moving smoothly. Two
keys at once do not exist: the buffer hands over one code, so running and jumping in the
same frame is not expressible. And a key release is invisible, so the game learns that a
direction has stopped only by not hearing about it again.

On a joystick none of this applies, which is a fair guess at why it shipped this way.

## What it does instead

A handler goes in ahead of the BIOS one on `INT 09h`. It takes the code off port 60h,
updates that key's byte in a 128-entry state table and chains to the old vector — the
port B strobe, the EOI, the ASCII translation and the buffer are all still the BIOS's
job, so `INT 16h`, Ctrl-Alt-Del and the lock keys behave as before.

Each byte of the table carries three bits: the key is down, the key has been pressed
since the last snapshot, and this frame's answer. Once a frame `KBFRAME` takes the
snapshot, and for the rest of the frame the game's `KEYLOOK` answers out of it — exactly
the way a key used to sit in `LASTKEY` for a whole frame. The frame stays the unit of
input; it is only the source that changes.

The patch adds `KEYBRD.ASM` and touches six files: `BOOT.ASM` calls `SYSINI` in place of
`SNDINI` and `KBFRAME` in place of `FRMWAIT`, `JOYSTK.ASM` calls `KBHELD` from `KEYLOOK`,
`TIMING.ASM`, `MX4C.INC` and `MX4C.TXT` follow, and `MAKEIT.BAT` gains the new module.
`FRMWAIT` still runs — `KBFRAME` calls it — so the pacing of the frame is untouched.

## Applying it

The patch is applied to a copy of the sources, never to `src/` itself. `BUILD.BAT KBD`
does this and then builds:

```
C:\> BUILD.BAT KBD
```

By hand, the same thing:

```
C:\> COPY SRC\*.* BUILD
C:\> COPY TOOLS\MASM\*.EXE BUILD
C:\> COPY TOOLS\PATCH.COM BUILD
C:\> COPY PATCH\KBDFIX.DIF BUILD
C:\> CD BUILD
C:\BUILD> PATCH TEST KBDFIX.DIF
C:\BUILD> PATCH APPLY KBDFIX.DIF
C:\BUILD> MAKEIT.BAT
```

`PATCH TEST` rehearses the whole thing without touching a file. `PATCH APPLY` verifies
the length and CRC-32 of every file it is about to change before it changes any of them,
so a mismatched source tree stops the run rather than half-patching it. The utility is
in `tools/PATCH.COM`; its own repository is at <https://github.com/rustequal/patch>.

## The result

A patched build is a different program and does not match the original image. That is
expected, not a failure:

```
BUILD\MX4C.COM, patched
size       32528 bytes  (300 more than the original)
CRC-32     3E8C98F7
SHA-256    4d45c7ad9e8436ec62db0f654b548905b9ba5db3f8093374ccde8b180b6675e6
```

For the original build's figures, see the root [README.md](../README.md).
