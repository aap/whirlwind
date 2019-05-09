# Whirlwind I

This is a very simple emulator of the Whirlwind I.

It executes the basic instruction set and can sort
of talk to an equally simple Flexowriter emulator.
No display or other peripherals have been implemented yet.

It comes with a little assembler ``wwas``.

The assembler (``wwas.c``) gets input from stdin
and writes ``out.mem`` and ``out.lst``.

To run the emulator, run ``mkptyfl /tmp/fl`` to create a
pseudo tty for the flexowriter, then run ``ww1``,
which will open ``/tmp/fl``, load memory from ``out.mem``
and start executing at 40.

# Forth

I also wrote a very bare bones Forth.
You can assemble it with ``wwas < f.s``.

Right now it supports pushing numbers to the stack,
and these words: ``halt``, ``dup``, ``+``, ``.``.

