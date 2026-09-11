# Montezuma's Revenge (IBM PC CGA, 1984) — Reconstructed Source

A reconstruction of the assembly source for `MX4C.COM`, the CGA release of
Montezuma's Revenge from the original Parker Brothers boot floppy. Assembled with
Microsoft MASM 1.25, the listing in `src/` produces a file identical to the original,
byte for byte — all 32,228 of them. Alongside it, `docs/` carries a 93-page technical
book on how the game works, and `patch/` an optional fix for the keyboard handling.

Montezuma's Revenge was designed and originally programmed by [**Robert Jaeger**](https://normaldistribution.com/). The
game is his; this repository only takes apart one conversion of it.

## The book

**[The Montezuma's Revenge Cookbook](docs/CookBook.pdf)** — 93 pages on how the game
works, in six parts: the machine and the startup, the main loop and its ten-state
machine, the picture (tiles, the screen map, rooms as bytecode, sprites, animation,
darkness), the game (items, the player, enemies, scoring), the peripherals (sound,
input, text) and the appendices — a map of the image, reference tables generated from
the listing, and an honest list of what is still not understood.

Every address the book cites can be opened in `src/` and found to carry the instruction
described.

## What this repository is not

It does not contain the game. There is no `MX4C.COM` here, no extracted graphics, no
extracted music and no playable build — you cannot download this and play. What is here
is a listing, a build procedure and documentation. Verifying the reconstruction takes
your own copy of the original file, and verification is what this repository is for.

Nothing here was recovered from a leak or a private archive. The original symbol table
does not survive an assembly and a `.COM` file has no room for debug information, so
every name, macro and comment in `src/` was written fresh while reading the machine
code. The bytes are authentic; the names are ours.

## On rights

This work was prepared for educational, historical-research and archival purposes. It
pursues no commercial gain.

Robert Jaeger, the game's original author and the principal at Normal Distribution LLC,
has been informed of this project and is supportive of it as a non-commercial effort, on
the condition that his authorship is credited. By his own account, Parker Brothers held
the game under licence and the rights reverted to him after a few years; he publishes
new versions of it to this day.

The IBM PC conversion examined here was not his work. Parker Brothers commissioned the
conversions to other machines and made the programming changes themselves, and neither
he nor this project knows who wrote this one. Whatever separate rights may subsist in
that conversion have not been traced, and nothing here should be read as a claim that
they have been. Should Mr Jaeger, or any other party holding rights in the game or in
this conversion of it, consider that these materials ought to be taken down, they will
be taken down: **rustequal@gmail.com**.

See [NOTICE.md](NOTICE.md) for who holds what in this repository.

## Repository layout

```
src/               the listing: 21 modules, MX4C.INC, MX4C.TXT, MAKEIT.BAT
docs/CookBook.pdf  The Montezuma's Revenge Cookbook, 93 pages
patch/KBDFIX.DIF   optional: keyboard handling off IRQ1
tools/masm/        MASM 1.25: MASM.EXE, LINK.EXE, EXE2BIN.EXE
tools/PATCH.COM    the utility that applies KBDFIX.DIF
build/             scratch directory the build happens in, ignored by git
BUILD.BAT          copies the sources and the assembler into build/ and builds
```

The image is a flat `.COM`: whatever lies where in the file assembles in that order.
The modules therefore run in ascending address order and each covers a contiguous
stretch of the image, which is why they are not split by subject. `MAKEIT.BAT` is the
manifest — the order of the modules in its link line is the order of the bytes in the
image, and it is not free to change.

## Building

The sources are written for **MASM 1.25** and the build is verified with it. Later
assemblers have not been tested. The assembler is in the repository, so a clone has
everything the build needs.

### 1. Clone the repository

```
git clone https://github.com/rustequal/montezuma.git
```

Keep the path short and free of spaces: DOSBox exposes 8.3 filenames only. Everything
inside the repository is already 8.3.

### 2. Point DOSBox at the clone

[DOSBox](https://www.dosbox.com/) or [DOSBox-X](https://dosbox-x.com/) is enough; real
hardware, 86Box and PCem work equally well. Open the configuration file (`Options` →
`Configuration` in the shell, or `dosbox.conf` next to the executable) and put the clone
on drive C:

```ini
[cpu]
core=auto
cycles=auto

[autoexec]
mount c D:\montezuma
c:
```

On Linux and macOS the mount line reads `mount c /home/you/montezuma`.

### 3. Build

```
C:\> BUILD.BAT          the original sources, matches MX4C.COM byte for byte
C:\> BUILD.BAT KBD      the same sources with the keyboard patch applied
```

`BUILD.BAT` copies `SRC\*.*` and `TOOLS\MASM\*.EXE` into `BUILD\` and runs `MAKEIT.BAT`
there. Nothing is written outside `BUILD\`, which git ignores, so the tree stays clean
and a rebuild needs no cleanup. `MASM 1.25` looks for `INCLUDE` files in the current
directory, which is why everything is gathered in one place first.

`MAKEIT.BAT` assembles the twenty-one modules, links them through a response file,
converts the result with `EXE2BIN` and removes the intermediates. The output is
`BUILD\MX4C.COM`.

`LINK` will report `warning: no stack segment` and count it as an error. That is
correct and cannot be removed. Microsoft's own limits on `EXE2BIN` say so plainly: the
input must be a real linker `.EXE`, code and data together under 64K, **and no STACK
segment** — the check fires on a non-zero `SS:SP` in the `.EXE` header.

### 4. Verify

`BUILD.BAT` builds but does not compare; the original is not in this repository. Put
your own copy in `BUILD\` under another name and compare there:

```
C:\BUILD> fc /b MX4C.COM ORIG.COM
no differences encountered
```

```
MX4C.COM   the original, not distributed here
size       32228 bytes
CRC-32     640FBD53
SHA-256    02ee40f9650e2e2b27c531411a44af1a3291375254a6e69022800bc6426641c3
```

A patched build is a different file and does not match these; see
[patch/README.md](patch/README.md).

### 5. Run it

The build configuration above is tuned for the assembler, not for the game. Running what
you have just built takes a second configuration, because this game keeps time by
counting:

```ini
[dosbox]
machine=cga

[cpu]
core=normal
cycles=fixed 315

[speaker]
pcspeaker=true

[autoexec]
mount c D:\montezuma\build
c:
MX4C.COM
```

`cycles=fixed 315` is about an IBM PC/XT, an 8088 at 4.77 MHz, and it is the setting
that matters most. There is no vertical retrace wait and no clock read anywhere in the
image: a frame is paced by totalling up what the frame cost to draw and burning the
remainder in an idle loop of counted instructions (`FRMWAIT` and `DELAY` in
`src/TIMING.ASM`). On `cycles=max` that loop finishes instantly and the game runs as
fast as the host will let it. Ctrl-F11 and Ctrl-F12 adjust the figure while it runs, if
your DOSBox reports something other than a comfortable speed.

`machine=cga` is what the image expects — it sets video mode 4, 320×200 in four colours,
and writes straight into B800h. Sound is the PC speaker driven off the timer, which the
game reprograms from 18.2 Hz to 100 Hz and drives through its own `INT 08h` handler.

In DOSBox-X, add `cputype=8088` under `[cpu]` for a closer match; plain DOSBox has no
such setting and `core=normal` is as close as it gets.

Once it is up: F5 goes back to the menu, F10 pauses.

## The keyboard patch

The game reads one key per frame out of the BIOS buffer, so movement depends on the
keyboard's own auto-repeat: a step waits out the typematic delay, keys cannot be held,
and two keys at once are not seen at all. `patch/KBDFIX.DIF` replaces that with a
handler on IRQ1 and a key-state table. It is optional, it is not part of the
reconstruction, and applying it changes the size of the image.
See [patch/README.md](patch/README.md).

## Credits

Montezuma's Revenge was designed and originally programmed by Robert Jaeger and
published by Parker Brothers in 1984. The IBM PC conversion was commissioned by Parker
Brothers.
