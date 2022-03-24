
# Parser

## 要点

1. llex.h/.c  词法分析模块

## 数据结构

        typedef union {
            lua_Number r;
            lua_Integer i;
            TString *ts;
        } SemInfo;  /* semantics information */


        typedef struct Token {
            int token;
            SemInfo seminfo;
        } Token;

        /* state of the lexer plus state of the parser when shared by all
        functions */
        typedef struct LexState {
            int current;  /* current character (charint) */
            int linenumber;  /* input line counter */
            int lastline;  /* line of last token 'consumed' */
            Token t;  /* current token */
            Token lookahead;  /* look ahead token */
            struct FuncState *fs;  /* current function (parser) */
            struct lua_State *L;
            ZIO *z;  /* input stream */
            Mbuffer *buff;  /* buffer for tokens */
            Table *h;  /* to avoid collection/reuse strings */
            struct Dyndata *dyd;  /* dynamic structures used by the parser */
            TString *source;  /* current source name */
            TString *envn;  /* environment variable name */
        } LexState;

        /* kinds of variables/expressions */
        typedef enum {
            VVOID,  /* when 'expdesc' describes the last expression of a list,
                        this kind means an empty list (so, no expression) */
            VNIL,  /* constant nil */
            VTRUE,  /* constant true */
            VFALSE,  /* constant false */
            VK,  /* constant in 'k'; info = index of constant in 'k' */
            VKFLT,  /* floating constant; nval = numerical float value */
            VKINT,  /* integer constant; ival = numerical integer value */
            VKSTR,  /* string constant; strval = TString address;
                        (string is fixed by the lexer) */
            VNONRELOC,  /* expression has its value in a fixed register;
                            info = result register */
            VLOCAL,  /* local variable; var.ridx = register index;
                        var.vidx = relative index in 'actvar.arr'  */
            VUPVAL,  /* upvalue variable; info = index of upvalue in 'upvalues' */
            VCONST,  /* compile-time <const> variable;
                        info = absolute index in 'actvar.arr'  */
            VINDEXED,  /* indexed variable;
                            ind.t = table register;
                            ind.idx = key's R index */
            VINDEXUP,  /* indexed upvalue;
                            ind.t = table upvalue;
                            ind.idx = key's K index */
            VINDEXI, /* indexed variable with constant integer;
                            ind.t = table register;
                            ind.idx = key's value */
            VINDEXSTR, /* indexed variable with literal string;
                            ind.t = table register;
                            ind.idx = key's K index */
            VJMP,  /* expression is a test/comparison;
                        info = pc of corresponding jump instruction */
            VRELOC,  /* expression can put result in any register;
                        info = instruction pc */
            VCALL,  /* expression is a function call; info = instruction pc */
            VVARARG  /* vararg expression; info = instruction pc */
        } expkind;  // expression kind

        typedef struct expdesc {
            expkind k;
            union {
                    lua_Integer ival;    /* for VKINT */
                    lua_Number nval;  /* for VKFLT */
                    TString *strval;  /* for VKSTR */
                    int info;  /* for generic use */
                    struct {  /* for indexed variables */
                    short idx;  /* index (R or "long" K) */
                    lu_byte t;  /* table (register or upvalue) */
                } ind;
                struct {  /* for local variables */
                    lu_byte ridx;  /* register holding the variable */
                    unsigned short vidx;  /* compiler index (in 'actvar.arr')  */
                } var;
            } u;
            int t;  /* patch list of 'exit when true' */
            int f;  /* patch list of 'exit when false' */
        } expdesc;  // expression describe

        /* description of an active local variable */
        typedef union Vardesc {
            struct {
                TValuefields;  /* constant value (if it is a compile-time constant) */
                lu_byte kind;
                lu_byte ridx;  /* register holding the variable */
                short pidx;  /* index of the variable in the Proto's 'locvars' array */
                TString *name;  /* variable name */
            } vd;
            TValue k;  /* constant value (if any) */
        } Vardesc;

        /* description of pending goto statements and label statements */
        typedef struct Labeldesc {
            TString *name;  /* label identifier */
            int pc;  /* position in code */
            int line;  /* line where it appeared */
            lu_byte nactvar;  /* number of active variables in that position */
            lu_byte close;  /* goto that escapes upvalues */
        } Labeldesc;

        /* list of labels or gotos */
        typedef struct Labellist {
            Labeldesc *arr;  /* array */
            int n;  /* number of entries in use */
            int size;  /* array size */
        } Labellist;


        /* dynamic structures used by the parser */
        typedef struct Dyndata {
            struct {  /* list of all active local variables */
                Vardesc *arr;
                int n;
                int size;
            } actvar;
            Labellist gt;  /* list of pending gotos */
            Labellist label;   /* list of active labels */
        } Dyndata;


        /* control of blocks */
        struct BlockCnt;  /* defined in lparser.c */


        /* state needed to generate code for a given function */
        typedef struct FuncState {
            Proto *f;  /* current function header */
            struct FuncState *prev;  /* enclosing function */
            struct LexState *ls;  /* lexical state */
            struct BlockCnt *bl;  /* chain of current blocks */
            int pc;  /* next position to code (equivalent to 'ncode') */
            int lasttarget;   /* 'label' of last 'jump label' */
            int previousline;  /* last line that was saved in 'lineinfo' */
            int nk;  /* number of elements in 'k' */
            int np;  /* number of elements in 'p' */
            int nabslineinfo;  /* number of elements in 'abslineinfo' */
            int firstlocal;  /* index of first local var (in Dyndata array) */
            int firstlabel;  /* index of first label (in 'dyd->label->arr') */
            short ndebugvars;  /* number of elements in 'f->locvars' */
            lu_byte nactvar;  /* number of active local variables */
            lu_byte nups;  /* number of upvalues */
            lu_byte freereg;  /* first free register */
            lu_byte iwthabs;  /* instructions issued since last absolute line info */
            lu_byte needclose;  /* function needs to close upvalues when returning */
        } FuncState;

        /*
        ** nodes for block list (list of active blocks)
        */
        typedef struct BlockCnt {
            struct BlockCnt *previous;  /* chain */
            int firstlabel;  /* index of first label in this block */
            int firstgoto;  /* index of first pending goto in this block */
            lu_byte nactvar;  /* # active locals outside the block */
            lu_byte upval;  /* true if some variable in the block is an upvalue */
            lu_byte isloop;  /* true if 'block' is a loop */
            lu_byte insidetbc;  /* true if inside the scope of a to-be-closed var. */
        } BlockCnt;

## lzio.c
处理文件读

### 数据结构

        typedef struct Mbuffer {
            char *buffer;
            size_t n;
            size_t buffsize;
        } Mbuffer;

        struct Zio {
            size_t n;			/* bytes still unread */
            const char *p;		/* current position in buffer */
            lua_Reader reader;		/* reader function */
            void *data;			/* additional data */
            lua_State *L;			/* Lua state (for reader) */
        };

### 函数和功能

| 名称 | 功能 | 参数 | tips |
|:--|:--|:--| :-- |
|luaZ_init|初始化ZIO|lua_State *L, ZIO *z, lua_Reader reader, void *data||
|luaZ_fill||ZIO *z||

---

## lparser.c

| 名称 | 功能 | 参数 | tips |
|:--|:--|:--| :-- |
|||||

---

<br>


## 思考

- 1. firsttry的宏是啥，为啥用这个宏  
- 2. GCdebt是啥，用来干啥  
  