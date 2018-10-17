init:	mvi	A, 0x03	; Reset the 2SIO port 1
		out	0x10
		mvi	A, 0x11	; Set port 1 to 8,2,n
		out	0x10

loop:	in	0x10	; wait for a character to arrive
		rrc
		jnc	loop

		in	0x11	; get the character
		out	0x11	; send it back out
		jmp	loop	; continue forever