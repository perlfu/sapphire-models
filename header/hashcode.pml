#define N 1

/* flag */
#define FALSE 0
#define TRUE 1

/* address */
#define INVALID 2

/* hash state */
mtype { UNHASHED, HASHED, MOVED }

/* phase */
#define INACTIVE   0
#define MARK_ALLOC 1
#define COPY       2
#define FLIP       3
#define RECLAIM     4

/* property */
ltl p_consistency { []((hash == 0 -> [](hash == 0)) &&
    		       (hash == 1 -> [](hash == 1))) } 

mtype hashState[2];
byte hashcode[2];
bit forwarded[2];
byte replica[2];
bit busy[2];

bit fromSpace;

bit  hsReq[N];
byte hsAck;

#define IS_HASHED(o) (hashState[o] == HASHED || hashState[o] == MOVED)
#define WILL_NOT_MOVE(o) (o != fromSpace)
#define HAS_MOVED(o) (forwarded[o] == TRUE)

inline initObject(i)
{
    hashState[i] = UNHASHED;
    hashcode[i] = INVALID;
    forwarded[i] = FALSE;
    replica[i] = INVALID;
    busy[i] = FALSE;
}

#define getForwardingPointer(o)  replica[o]

inline setHashedAtomic(o)
{
  atomic {
  if
  ::(hashState[o] == UNHASHED) -> hashState[o] = HASHED;
  ::else -> skip
  fi
  }
}

inline markBusyAtomic(o)
{
  atomic {
    (busy[o] == FALSE) -> busy[o] = TRUE
  }
}

inline clearBusy(o)
{
  busy[o] = FALSE
}

inline getObjectHashCode(o, r)
{
  bit oo;

  hashByAddress(o);
  printf("oo = %d\n", oo);
  assert(hashState[oo] == HASHED || hashState[oo] == MOVED);
  if
    ::(hashState[oo] == HASHED) -> r = oo;
    ::(hashState[oo] == MOVED) ->
      atomic {
        assert(hashcode[oo] != INVALID);
        r = hashcode[oo];
     }
  fi
}

inline hashByAddress(o)
{
  do
  ::
    if
    ::IS_HASHED(o) -> oo = o; break
    ::else -> skip
    fi;

    if
    ::WILL_NOT_MOVE(o) ->
      setHashedAtomic(o);
      oo = o;
      break
    ::else -> skip
    fi;

    if
    ::HAS_MOVED(o) ->
      if
      ::IS_HASHED(o) -> oo = o; break
      ::else ->
	assert(forwarded[o] == TRUE);
        oo = replica[o];
        setHashedAtomic(oo);
        break
      fi;
    ::else -> skip
    fi;

    markBusyAtomic(o);
    if
    ::HAS_MOVED(o) -> skip
    ::else ->
      setHashedAtomic(o);
      oo = o;
      clearBusy(o);
      break;
    fi;
    clearBusy(o);

    if
    ::IS_HASHED(o) -> oo = o; break
    ::else -> skip
    fi;
    
    oo = getForwardingPointer(o);
    setHashedAtomic(oo);
    break;
  od
}

inline startHandshake()
{
  atomic{
  int i;
  do
  ::(i == N) -> break
  ::else -> hsReq[i] = TRUE; break
  od
  };
  (hsAck == N);
  hsAck = 0;
}

int hash = INVALID;      /* hashcode that the mutator has ever seen */
int root = 0;            /* a slot in the mutator's root */

inline collection()
{
  /* initialise to-space */
  /*  atomic { initObject(1 - fromSpace) } */

  gcPhase = MARK_ALLOC;
  startHandshake(); 

  markBusyAtomic(fromSpace);
  if
  ::(hashState[fromSpace] == UNHASHED)->
    hashState[1 - fromSpace] = UNHASHED;
  ::(hashState[fromSpace] == HASHED) ->
    hashState[1 - fromSpace] = MOVED;
    hashcode[1 - fromSpace] = fromSpace;
  ::(hashState[fromSpace] == MOVED) ->
    hashState[1 - fromSpace] = MOVED;
    hashcode[1 - fromSpace] = hashcode[fromSpace];
  fi;
  replica[fromSpace] = 1 - fromSpace;
  forwarded[fromSpace] = TRUE;
  clearBusy(fromSpace);

  gcPhase = COPY; 
  startHandshake();

  gcPhase = FLIP;
  startHandshake();
  root = 1 - fromSpace;   /* flip mutator's root */

  gcPhase = RECLAIM;
  startHandshake();

  fromSpace = 1 - fromSpace;
  gcPhase = INACTIVE;
  startHandshake();
}

proctype collector()
{
  byte gcPhase = INACTIVE;
  do
  ::collection()
  od
}

#define safepoint() \
  (hsReq[tid] == TRUE) -> \
      hsReq[tid] = FALSE; \
      hsAck = hsAck + 1

proctype mutator(byte tid)
{
  int hc, rt;
  do
  ::safepoint();
  ::rt = root;getObjectHashCode(rt, hc);hash = hc;
  od
}

init
{
  byte i;

  atomic {
    i = 0;
    do
    ::(i < 2) -> initObject(i); i = i + 1
    ::else -> break
    od;

    fromSpace = 0;
    hsAck = 0;
  }

  atomic {
    run collector();
    i = 0;
    do
    ::(i < N) -> run mutator(i); i = i + 1
    ::else -> break
    od;
  }
}
