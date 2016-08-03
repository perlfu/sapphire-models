#undef NO_FENCE

#define fromSpace 0
#define toSpace   1

/* the heap: contains two copies of a single object */
byte o[2];

/* verification */
bool done;

/* memory architecture */

#define N 2

/*   store load forwarding */
byte Mo[2], Co[2];    /* local latest value */
byte Moc[2], Coc[2];  /* # of write instructions waiting in the store buffer.
                       *   > 0: read should load local latest value
                       *   = 0: read should load from memory
                       */

/*   store buffer: queue of (space * value) */
chan Mw = [N] of {byte, byte};
chan Cw = [N] of {byte, byte};

/*   store buffer emulation */
#define COMMIT_WRITE(q, c)  len(q) > 0 -> q?s,v -> o[s] = v; c[s]--

active proctype mem() {
  byte s, v;
endmem:
  do
    ::atomic{COMMIT_WRITE(Mw, Moc)}
    ::atomic{COMMIT_WRITE(Cw, Coc)}
  od
}

#define M_FENCE \
atomic { \
  do \
    ::COMMIT_WRITE(Mw, Moc) \
    ::else -> break \
  od \
}

#define C_FENCE \
atomic { \
  do \
    ::COMMIT_WRITE(Cw, Coc) \
    ::else -> break \
  od \
}

#define M_READ(s, v) \
atomic { \
  if \
    ::Moc[s] == 0 -> v = o[s] \
    ::else -> v = Mo[s] \
  fi \
}

#define M_WRITE(s, v) \
atomic { \
  Mw!s,v; Mo[s] = v; Moc[s]++; \
}

#define C_READ(s, v) \
atomic { \
  if \
    ::Coc[s] == 0 -> v = o[s] \
    ::else -> v = Co[s] \
  fi \
}

#define C_WRITE(s, v) \
atomic { \
  Cw!s,v; Co[s] = v; Coc[s]++; \
}


proctype M() {
  byte x, y, s, v;
  x = 0;
  do
    ::true ->
       x = 1 - x;
       M_WRITE(fromSpace, x);
       M_WRITE(toSpace, x);
    ::true ->
       M_FENCE;
    ::true ->
       if
         ::!done ->
           M_READ(fromSpace, y)
         ::else ->
           M_READ(toSpace, y)
       fi;
       assert(x == y);
  od;
}

proctype C()
{
  byte s, v, r1, r2, tmp;

  do
    ::true ->
       C_READ(fromSpace, r1);
       C_READ(toSpace, r2);
       if
	 ::(r1 == r2) -> break
	 ::else ->
           atomic { /* CAS */
     	     C_FENCE
	     C_READ(toSpace, tmp);
	     if
	       ::(r2 == tmp) ->
	         C_WRITE(toSpace, r1)
	       ::else -> break
	     fi;
     	     C_FENCE
	   }
       fi	   
  od
  C_FENCE;
  done = true;
}

init
{
  atomic {
    Moc[0] = 0;
    Moc[1] = 0;
    Coc[0] = 0;
    Coc[1] = 0;
    done = false;
    run C();
    run M();
  }
}
