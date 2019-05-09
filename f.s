	sp	start

a,	0
b,	0
c,	0
ip,	0
toin,	0	/ >IN, index of first unparsed char
wdp,	0	/ index of first char in word
wdl,	0	/ length of word
ninb,	0	/ number of chars in inbuf
inbuf,	.=.+100
dstk,	.=.+40
rstk,	.=.+40

start,	ca	(rstk		/ set up stacks
	td	rsp
	ca	(dstk-1
	td	dsp
	td	dsp1
	td	dsp2
	ao	dsp

lup,	sp	pword		/ get first word
	 sp	ok		/ end of line
	sp	packw		/ pack word for finding
	sp	find		/ find in dictionary
	 sp	number		/ not in dict, maybe a number
	cp	imm		/ found, immediate if AC neg
	/ TODO: check state now and compile or interpret
imm,	td	imm1		/ store code address
	ca	(imm1+1		/ put return address in ip
	td	ip
imm1,	sp	.		/ execute word
	sp	lup
number,	sp	numb		/ try to parse a number
	 si	0		/ not a number, just halt
	sp	pushd		/ it was a number, push
	sp	lup
ok,	sp	puts; okstr
	sp	refill
	sp	lup

okstr,	10; 60; 36; 51; 177777


/
/ Utilities
/

/ compare AC to arg, skip return if equal
caie,	ta	cain1
	ts	cain-1		/ save AC
	ta	.+1
	su	.		/ subtract arg
	dm	(0		/ turn 0 into -0
	cp	cain2		/ if neg, they were equal
	sp	cain3		/ not equal

/ compare AC to arg, skip return if not equal
	0
cain,	ta	cain1
	ts	cain-1		/ save AC
	ta	.+1
	su	.		/ subtract arg
	dm	(0		/ turn 0 into -0
	cp	.+2		/ if neg, they were equal
cain2,	 ao	cain1		/ not equal, skip return
cain3,	ao	cain1
	ca	cain-1		/ restore AC
cain1,	sp	.


/
/ Stack
/

/ put AC on return stack
pushr,	ta	pushr1
rsp,	ts	.	/ store on stack
	ao	rsp	/ advance pointer
	ta	.+1	/ load value from old pointer
	ca	.	/ load pushed value
pushr1,	sp	.

/ pop one word from return stack into AC
popr,	ta	popr1
	ca	rsp	/ get current rsp
	su	(1	/ decrement
	td	rsp	/ put back
	td	.+1
	ca	.
popr1,	sp	.

/ put AC on data stack
pushd,	ta	dsret
dsp,	ts	.	/ store on stack
	ao	dsp	/ advance pointer
	ta	dsp1
	ta	dsp2
	sp	dsp1

/ pop one word from data stack into AC
popd,	ta	popret+1
	ca	dsp1
	td	popret
	td	dsp
	su	(1
	td	dsp1
	td	dsp2
popret,	ca	.
	sp	.

/ replace top of data stack with AC
totos,	ta	.+2
dsp2,	ts	.
	sp	.

/ get top of data stack without popping
tos,	ta	dsret
dsp1,	ca	.	/ load top of stack
dsret,	sp	.


/
/ Address Interpreter
/

next,	ao	ip	/ increment ip
	ta	.+1	/ current word
	sp	.	/ execute

docol,	ta	ip	/ set new ip
	sp	pushr	/ push old ip
	sp	next

exit,	sp	popr
	ts	ip
	sp	next

lit,	ta	.+1	/ next word
	ca	.	/ load the literal number
	sp	pushd
	ao	ip	/ skip in execution
	sp 	next

halt,	si	0


/
/ Input Output
/

key,	ta	key+4
	si	200
	rd	.
	sp	pushd
	sp	.

/ pop from stack and print
emit,	ta	emit.+4
	sp	popd
	sp	.+2
/ print AC
emit.,	ta	emit.+4
	clc	12
	si	215
	rc	.
	sp	.

/ print 6-digit number in AC, then a space
/ clobbers AC, A, B
pnum,	ta	pnum1
	ts	a
	cp	pnum2
	ca	numtab		/ positive number, load '0'
pnum4,	sp	emit.
	cs	(4		/ 5 iterations
	ts	b
pnum3,	ca	a		/ load number
	srh	14		/ get leftmost digit
	ad	(numtab
	td	.+3		/ address of digit
	slr	17
	ts	a		/ store remainder
	ca	.		/ load digit
	sp	emit.
	ao	b
	cp	pnum3
	sp	space
pnum1,	sp	.
pnum2,	ad	(077777		/ negative number, make positive
	ts	a
	ca	numtab+1	/ load '1'
	sp	pnum4
numtab,	76; 25; 17; 7; 13; 23; 33; 27

newln,	ta	.+3
	ca	(51
	sp	emit.
	sp	.
space,	ta	.+3
	ca	(10
	sp	emit.
	sp	.

/ print negative terminated string
puts,	ta	puts1
	ta	.+2
	ao	puts1		/ skip arg
	ca	.		/ load string pointer
	td	puts2
puts2,	ca	.		/ load character
puts1,	cp	.		/ end of string, return
	sp	emit.		/ print
	ao	puts2		/ increment address
	sp	puts2		/ and loop


/
/ Text interpreter
/

/ fill input buffer from keyboard
refill,	ta	refil1
	ca	(0
	ts	ninb
	ts	toin
	ca	(inbuf		/ init buffer
	td	refil2
refil3,	sp	key		/ get char
	sp	popd
	sp cain; 51		/ CR, exit of loop
	 sp	refcr
	sp cain; 77		/ delete
	 sp	refdel
refil2,	ts	.		/ put AC into buffer
	sp	emit.		/ and print
	ao	ninb
	ao	refil2		/ advance
	sp	refil3		/ loop
refcr,	sp	space
refil1,	sp	.
refdel,	sp	newln
	sp	refill+1

/ skip leading spaces in inbuf
/ clobbers A
skpsp,	ta	skpsp1
	ca	(skpsp2		/ setup callback func
	ta	lbuf.
	sp	lbuf		/ start looping
	sp	skpsp1		/ loop end, return?
skpsp2,	ta	skpsp3		/ callback
	sp caie; 10
skpsp1,	 sp	.		/ not equal, return from skpsp
	ao	toin
skpsp3,	sp	.		/ space, return from cb

/ parse first word in inbuf
/ skip return if word was found
/ clobbers A
pword,	ta	pword1
	sp	skpsp		/ skip spaces
	ca	toin
	ts	wdp		/ remember start of word
	ca	(0
	ts	wdl		/ reset word length
	ca	(pword2		/ setup callback func
	ta	lbuf.
	sp	lbuf		/ start looping
pword4,	cm	wdl		/ end of word found
	su	(0
	cp	.+2		/ check if length is 0
	 ao	pword1		/ no, skip return
pword1,	sp	.		/ return
pword2,	ta	pword3		/ callback
	sp cain; 10
	 sp	pword4		/ space marks end
	ao	wdl		/ not a space, increment length
	ao	toin		/ and >in
pword3,	sp	.

/ loop through input
/ clobbers A
lbuf,	ta	lbuf1
	cs	ninb
	ad	toin
	ts	a		/ get loop counter
	ca	(inbuf
	ad	toin
	td	lbuf2		/ store pointer
	sp	lbuf3		/ jump into loop
lbuf2,	ca	.		/ load character
lbuf.,	sp	.		/ callback subr
	ao	lbuf2
lbuf3,	ao	a
	cp	lbuf2
lbuf1,	sp	.

/ pack chars in word buffer for a dict search
/ this looks fairly inefficient...
packw,	ta	packw1
	cs	wdl
	ts	a		/ loop counter
	ca	(inbuf
	ad	wdp
	td	packw2		/ in buffer start
	ca	free
	td	packw1-1
	ad	(1
	td	packw2+1	/ out buffer start
	ca	(0
	ts	b		/ current packed char
	ts	c		/ even/odd counter
	sp	packw3		/ start loop
packw4,	ca	b		/ get current char
	clc	6		/ shift up
packw2,	ad	.		/ insert character
	ts	.		/ store char
	ts	b
	cs	c
	ts	c		/ flip counter
	cp	packw3-1
	 ao	packw2+1	/ advance packed buffer
	 ca	(0
	 ts	b		/ reset current packed char
	ao	packw2		/ advance buffer
packw3,	ao	a
	cp	packw4
	ca	wdl		/ packing done, calculate length
	ad	(1
	srh	1
	ts	.		/ store before buffer
packw1,	sp	.

/ parse number in word buffer
/ skip and return number in AC if success
/ clobbers A, B
numb,	ta	numb1
	cs	wdl
	ts	a		/ loop counter
	ca	(inbuf
	ad	wdp		/ start of word
	td	numb2
	ca	(0
	ts	b		/ init number
	sp	numb3
numb4,	ca	b
	clc	3		/ shift to accept new digit
	ts	b
numb2,	ca	.		/ load digit
	sp	swtch; digtab
	 sp	numb1		/ not a digit
	ad	b		/ a digit, add to number
	ts	b		/ store new number
	ao	numb2		/ advance pointer
numb3,	ao	a
	cp	numb4		/ loop
	ao	numb1		/ success, skip return
	ca	b		/ return number
numb1,	sp	.

/ table lookup, value to find in AC
/ skip and return matching value in AC on success
	0			/ loop counter
swtch,	ta	swtch1
	ta	.+3
	ts	swtch2		/ store value to find
	ao	swtch1		/ skip argument
	ca	.		/ load address of table
	td	swtch3
	ao	swtch3		/ advance to first case
	ta	.+1		/ case counter
	cs	.		/ load loop counter
	ts	swtch-1		/ store
swtch3,	ca	.		/ load case value
	sp cain; swtch2, .
	 sp	swtch4		/ found
	ao	swtch3		/ not found, advance
	ao	swtch3
	ao	swtch-1		/ advance counter
	cp	swtch3		/ loop to next case
	sp	swtch1		/ not found, return
swtch4,	ao	swtch1		/ found, skip return
	ao	swtch3		/ load return value's address
	td	.+1
	ca	.		/ load return value
swtch1,	sp	.

digtab,	7
	76; 0
	25; 1
	17; 2
	 7; 3
	13; 4
	23; 5
	33; 6
	27; 7

/ dictionary entry
/	0/	illll link
/	1/	n1
/	2/	n2
/		...
/	x/	def

/ find word in dictionary
/ clobbers A, B, C, skip and return code word in AC if found
find,	ta	find1
	ca	last		/ start of dict
	td	find2
find6,	ca	find2		/ set string pointer in dictionary
	td	find5
	ca	free		/ get pointer of word to find
	td	find3
	td	find5+1
find2,	ca	.		/ load word's header
	sp cain; 0
	 sp	find1		/ not found, return
	ts	b		/ store sign, later code word address
	td	find2		/ next header
	clc	1
	clc	24		/ get word count
	ts	c		/ store
find3,	cs	.		/ get negative word count
	ts	a		/ loop counter
	ad	c		/ get difference
	dm	(0
	cp	find4		/ start loop if equal
	 sp	find6		/ not equal, try next
find5,	ca	.		/ load dictionary string word
	su	.		/ subtract search string word
	dm	(0
	cp	.+2		/ jump if equal
	 sp	find6		/ unequal
find4,	ao	find5
	td	b		/ store code word address
	ao	find5+1		/ advance string pointers
	ao	a		/ advance loop counter
	cp	find5		/ loop
	ao	find1		/ found, skip return
	ca	b		/ load flag, code word address
find1,	sp	.

last,	plus_

halt_,	010000 (0); 5006; 4440
	si	0

dup_,	010000 halt_; 002216; 000054
dup,	sp	tos
	sp	pushd
	sp	next

dot_,	004000 dup_; 000021
dot,	sp	popd
	sp	pnum
	sp	next

plus_,	004000 dot_; 15
plus,	sp	popd
	ts	a
	sp	tos
	ad	a
	sp	totos
	sp	next

free,	.+1
