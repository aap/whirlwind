#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <assert.h>
#include <unistd.h>
#include <fcntl.h>

#define nil NULL

void
panic(char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	fprintf(stderr, "\n");
	va_end(ap);
	exit(1);
}

FILE*
mustopen(const char *name, const char *mode)
{
	FILE *f;
	if(f = fopen(name, mode), f == nil)
		panic("couldn't open file: %s", name);
	return f;
}

typedef struct Flexowriter Flexowriter;
struct Flexowriter
{
	int in, out;
};

void
putfl(Flexowriter *fl, int c)
{
	char cc;
	cc = c & 077;
	write(fl->out, &cc, 1);
}
int
getfl(Flexowriter *fl)
{
	char c;
	read(fl->in, &c, 1);
	return c;
}


typedef uint16_t word;

enum {
	// TODO
	SI = 0,
	RS = 1,
	BI = 2,
	RD = 3,
	BO = 4,
	RC = 5,

	SD = 6,
	CF = 7,//TODO

	TS = 8,
	TD = 9,
	TA = 10,
	CK = 11,
	AB = 12,
	EX = 13,
	CP = 14,
	SP = 15,
	CA = 16,
	CS = 17,
	AD = 18,
	SU = 19,
	CM = 20,
	SA = 21,
	AO = 22,
	DM = 23,
	MR = 24,
	MH = 25,
	DV = 26,
	SL = 27,
	SR = 28,
	SF = 29,
	CL = 30,
	MD = 31
};

enum
{
	ALARM_OV = 1,
	ALARM_DV,
	ALARM_CK,
};

#define WD(x) ((x) & 0177777)
#define SGN(x) ((x) & 0100000)
#define INST(o,x) ((o)<<11 | (x)&03777)

typedef struct WWI WWI;

struct WWI
{
	/* control */
	int run;
	word pc, prevpc;
	word cs;
	/* storage */
	word ss;
	/* first 32 words test storage. switches and flip-flops */
	word store[04000];
	word par;
	/* arithmetic */
	word ar;
	word ac;
	word br;
	word sam;
	/* IO */
	word ior;
	int interlock;
	int ios;
	int rec;
	void *unit;
	void (*record)(WWI *ww);
	void (*read)(WWI *ww);

	/* PT */
	void *ptunits[4];
	int wbyw;
	int p7;
};

void
ptrecord(WWI *ww)
{
	if(ww->unit)
		putfl(ww->unit, ww->ior>>10 & 077);
	ww->interlock = 0;
}

void
ptread(WWI *ww)
{
	if(ww->unit)
		ww->ior |= getfl(ww->unit);
	ww->interlock = 0;
}

static void
pstate(WWI *ww)
{
	printf("%06o: AC/%06o BR/%06o AR/%06o SAM/%o PC/%04o\n",
		ww->prevpc, ww->ac, ww->br, ww->ar, ww->sam, ww->pc);
}

static word
readstore(WWI *ww)
{
	ww->par = ww->store[ww->ss];
	return ww->par;
}

static void
writestore(WWI *ww, word w)
{
	ww->store[ww->ss] = w;
}

void
si_misc(WWI *ww)
{
	if(ww->ios == 0)
		ww->run = 0;
	else if(ww->ios == 1)
		ww->run = 0;
}

void
si_mt(WWI *ww)
{
}

void
si_pt(WWI *ww)
{
	ww->rec = !!(ww->ios & 4);
	ww->wbyw = !!(ww->ios & 2);
	// Or force completion pulse??
	ww->p7 = !!(ww->ios & 1);
	ww->unit = ww->ptunits[ww->ios>>7 & 3];
	ww->record = ptrecord;
	ww->read = ptread;
}

void
si_unused(WWI *ww)
{
}

void
si_camera(WWI *ww)
{
}

void
si_scope(WWI *ww)
{
}

void
si_drum(WWI *ww)
{
}

static void
clear(WWI *ww)
{
	ww->ac = 0;
	ww->br = 0;
}

static void
add(WWI *ww, word a)
{
	int s, t;

	s = ww->ac + a;
	t = WD(ww->ac<<1) + WD(a<<1);
	ww->ac = s;
	if(s & 0200000)
		ww->ac++;

	ww->sam = (s ^ t)>>16 & 1;
	if(SGN(ww->ac))
		ww->sam <<= 1;
}

static void
wwalarm(WWI *ww, int a)
{
	static char *strs[] = {
		"NA",
		"OV alarm",
		"DV alarm",
		"CK alarm"
	};
	printf("%s\n", strs[a]);
	ww->run = 0;
}

static void
ovcheck(WWI *ww)
{
	if(ww->sam)
		wwalarm(ww, ALARM_OV);
	ww->sam = 0;
}

static void
roundoff(WWI *ww)
{
	if(SGN(ww->br))
		add(ww, 1);
	ovcheck(ww);
	ww->br = 0;
}

static void
dvshift(WWI *ww)
{
	ww->br = ww->br<<1 | ~ww->ac>>15&1;
	ww->ac = ww->ac<<1 | ww->ac>>15;
}

static void
step(WWI *ww)
{
	word x, ac;
	word pqrs;
	int neg, sc;

	ww->ss = ww->pc;
	ww->prevpc = ww->pc;
	ww->pc = ww->pc+1 & 03777;
	readstore(ww);

	ww->ss = ww->par&03777;
	ww->cs = ww->par>>11;

	switch(ww->cs){
	case SI:
		ww->ios = ww->ss & 03777;
		switch(ww->ios>>6 & 7){
		case 0: si_misc(ww); break;
		case 1: si_mt(ww); break;
		case 2: si_pt(ww); break;
		case 3: si_unused(ww); break;
		case 4: si_unused(ww); break;
		case 5: si_camera(ww); break;
		case 6: si_scope(ww); break;
		case 7: si_drum(ww); break;
		}
		// TODO: check if this is right
		ww->ior = 0;
		break;
	case RC:
		while(ww->interlock)
			;	// TODO: wait for completion
		ww->ior = ww->ac;
		ww->interlock = 1;
		ww->record(ww);
		break;
	case RD:
		while(ww->interlock)
			;	// TODO: wait for completion
		ww->interlock = 1;
		ww->ar = 0;
		ww->par = 0;
		ww->read(ww);
		ww->ar = ww->ior;
		ww->par = ww->ior;
		ww->ior = 0;
		ww->ac = ww->ar;
		break;

	case CK:
		readstore(ww);
		if(ww->ac != ww->par)
			wwalarm(ww, ALARM_CK);
		break;

	case CA:
		ww->ar = readstore(ww);
		x = ww->ar;
		goto samadd;
	case CS:
		ww->ar = readstore(ww);
		x = ~ww->ar;
		goto samadd;
	case CM:
		ww->ar = readstore(ww);
		if(SGN(ww->ar)) ww->ar = ~ww->ar;
		x = ww->ar;
samadd:
		clear(ww);
		if(ww->sam == 1)
			ww->ac = 1;
		else if(ww->sam == 2)
			ww->ac = 0177776;
		add(ww, x);
		ovcheck(ww);
		break;

	case SA:
		ww->ar = readstore(ww);
		add(ww, ww->ar);
		if(ww->sam)
			ww->ac ^= 0100000;
		break;

	case AD:
		ww->ar = readstore(ww);
		add(ww, ww->ar);
		ovcheck(ww);
		break;
	case SU:
		ww->ar = readstore(ww);
		add(ww, ~ww->ar);
		ovcheck(ww);
		break;
	case DM:
		ww->ar = readstore(ww);
		if(SGN(ww->ar)) ww->ar = ~ww->ar;
		ww->br = ww->ac;
		if(SGN(ww->br))
			ww->ac = ~ww->br;
		add(ww, ~ww->ar);
		assert(ww->sam == 0);
		break;
	case AB:
		ww->ar = readstore(ww);
		ww->ac = ww->br;
		add(ww, ww->ar);
		ovcheck(ww);
		writestore(ww, ww->ac);
		break;
	case AO:
		ww->ar = readstore(ww);
		ww->ac = ww->ar;
		add(ww, 1);
		ovcheck(ww);
		writestore(ww, ww->ac);
		break;

	case TS:
		writestore(ww, ww->ac);
		break;
	case TA:
	ta:
		readstore(ww);
		writestore(ww, ww->par&0174000 | ww->ar&03777);
		break;
	case TD:
		readstore(ww);
		writestore(ww, ww->par&0174000 | ww->ac&03777);
		break;

	case EX:
		ww->ar = readstore(ww);
		writestore(ww, ww->ac);
		ww->ac = ww->ar;
		break;

	case SD:
		ww->ar = readstore(ww);
		ww->ac ^= ww->ar;
		ww->sam = 0;
		break;
	case MD:
		ww->ar = readstore(ww);
		ww->ac &= ww->ar;
		ww->ar = ~ww->ac;
		break;

	case SP:
		ww->ar = ww->ar&0174000 | ww->pc&03777;
		ww->pc = ww->ss;
		break;
	case CP:
		ww->ar = ww->ar&0174000 | ww->pc&03777;
		if(SGN(ww->ac))
			ww->pc = ww->ss;
		break;

	case SR:
		sc = ww->ss & 037;
		neg = SGN(ww->ac);
		if(neg) ww->ac = ~ww->ac;
		while(sc--){
			ww->br = ww->ac<<15 | ww->br>>1;
			ww->ac = ww->ac>>1;
		}
		if((ww->ss & 01000) == 0)
			roundoff(ww);
		if(neg) ww->ac = ~ww->ac;
		ww->sam = 0;
		break;

	case SL:
		sc = ww->ss & 037;
		neg = SGN(ww->ac);
		if(neg) ww->ac = ~ww->ac;
		while(sc--){
			ww->ac = ww->ac<<1&077777 | ww->br>>15&1;
			ww->br = ww->br<<1;
		}
		if((ww->ss & 01000) == 0)
			roundoff(ww);
		if(neg) ww->ac = ~ww->ac;
		ww->sam = 0;
		break;

	case CL:
		sc = ww->ss & 037;
		while(sc--){
			ac = ww->ac<<1 | ww->br>>15&1;
			ww->br = ww->br<<1 | ww->ac>>15&1;
			ww->ac = ac;
		}
		if((ww->ss & 01000) == 0)
			ww->br = 0;
		break;

	case SF:
		sc = 0;
		neg = SGN(ww->ac);
		if(neg) ww->ac = ~ww->ac;
		while((ww->ac & 040000) == 0 && sc <= 32){
			ww->ac = ww->ac<<1 | ww->br>>15;
			ww->br <<= 1;
			sc++;
		}
		if(neg) ww->ac = ~ww->ac;
		ww->sam = 0;
		ww->ar = sc;	// TODO: correct or keep 0-4?
		goto ta;

	case MH:
	case MR:
		ww->ar = readstore(ww);
		neg = SGN(ww->ac) != SGN(ww->ar);
		if(SGN(ww->ac)) ww->ac = ~ww->ac;
		ww->br = ww->ac;
		ww->ac = 0;
		if(SGN(ww->ar)) ww->ar = ~ww->ar;
		sc = 15;
		while(sc--){
			if(ww->br & 1)
				add(ww, ww->ar);
			ww->br = ww->ac<<15 | ww->br>>1;
			ww->ac = ww->ac>>1;
		}
		if(ww->cs == MR)
			roundoff(ww);
		if(neg) ww->ac = ~ww->ac;
		assert(ww->sam == 0);
		break;

	case DV:
		ww->ar = readstore(ww);
		neg = SGN(ww->ac) != SGN(ww->ar);
		if(SGN(ww->ac)) ww->ac = ~ww->ac;
		if(SGN(ww->ar)) ww->ar = ~ww->ar;

		add(ww, ~ww->ar);
		if(SGN(ww->ac) == 0 || ww->ac == 0177777){
			wwalarm(ww, ALARM_DV);
			break;
		}
		dvshift(ww);
		sc = 16;
		while(sc--){
			if(ww->br & 1) add(ww, ~ww->ar);
			else add(ww, ww->ar);
			dvshift(ww);
		}
		ww->ac = 0;
		if(neg) ww->ac = ~ww->ac;
		assert(ww->sam == 0);
		break;

	case RS:
	case BI:
	case BO:
	default:
		printf("INVALID %d\n", ww->cs);
	}

//	pstate(ww);
}

void
readmem(WWI *ww, FILE *f)
{
	char buf[100], *s;
	word a, w;

	a = 0;
	while(s = fgets(buf, 100, f)){
		while(*s){
			if(*s == ';')
				break;
			else if('0' <= *s && *s <= '7'){
				w = strtol(s, &s, 8);
				if(*s == ':'){
					a = w;
					s++;
				}else if(a < 04000)
					ww->store[a++] = w;
			}else
				s++;
		}
	}
}

void
printmem(WWI *ww)
{
	word a;
	for(a = 0; a < 04000; a++)
		if(ww->store[a])
			printf("%04o/%06o\n", a, ww->store[a]);
}


int
main()
{
	FILE *mf;
	WWI ww;
	Flexowriter fl;

	memset(&fl, 0, sizeof(fl));
	fl.in = open("/tmp/fl", O_RDWR);
	if(fl.in < 0)
		panic("can't open /tmp/fl");
	fl.out = fl.in;

	memset(&ww, 0, sizeof(ww));
	ww.ptunits[1] = &fl;
	ww.pc = 040;

	mf = mustopen("out.mem", "r");
	readmem(&ww, mf);
	fclose(mf);

	printmem(&ww);
	printf("\n\n");

	ww.run = 1;
	while(ww.run)
		step(&ww);

	printmem(&ww);

	return 0;
}
