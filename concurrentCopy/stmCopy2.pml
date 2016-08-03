#define INITVALUE 0
#define UNDEFINED 3
#define FLUSH 2
#define fromSpace 0
#define toSpace   1

byte o[2];
byte Mo[2], Co[2];

chan Mw = [2] of {byte, byte};
chan Cw = [1] of {byte, byte};

bool m_done;

active proctype mem() {
  byte s, v;
endmem:
  do
    ::Mw?s,v ->
       if
         ::(s == FLUSH) -> skip
         ::else ->
            atomic {
              o[s] = v;
              Co[s] = UNDEFINED;
            }
       fi
    ::Cw?s,v ->
       if
         ::(s == FLUSH) -> skip
         ::else ->
            atomic {
              o[s] = v;
              Mo[s] = UNDEFINED;
            }
       fi
  od
}

inline m_write(s, v) {
  Mo[s] = v;
  Mw!s,v
}

inline m_mbar() {
  Mw!FLUSH,1;
  Mw!FLUSH,1;
  Mw!FLUSH,1;
}

proctype M() {
  byte val = 1;
  do
    ::true ->
       m_write(fromSpace, val);
       m_write(toSpace, val);
       val = 2 - val;
    ::true ->
       m_mbar();
       break;
  od;
  m_done = true
}

inline c_read(s, v) {
  if
    ::(Co[s] == UNDEFINED) ->
       Co[s] = o[s]
    ::else -> skip
  fi;
  v = Co[s]
}

inline c_write(s, v) {
  Co[s] = v;
  Cw!s,v
}

inline c_mbar() {
  Cw!FLUSH,1;
  Cw!FLUSH,1
}

proctype C()
{
  byte x, y;

  do
    ::true ->
       c_read(fromSpace, x);
       c_write(toSpace, x);
       c_mbar();
       c_read(fromSpace, x);
       c_read(toSpace, y);
       if
         ::(x == y) -> break
         ::else -> skip
       fi
  od;
  assert(!m_done || o[0] == o[1])
}

init
{
  atomic {
    o[0] = INITVALUE;
    o[1] = UNDEFINED;
    Mo[0] = UNDEFINED;
    Mo[1] = UNDEFINED;
    Co[0] = UNDEFINED;
    Co[1] = UNDEFINED;
    m_done = 0;
    run C();
    run M();
  }
}