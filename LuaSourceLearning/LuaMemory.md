
# Memory alloc

## 要点

1. frealloc（global_state->frealloc）操作所有的内存分配，包括malloc(realloc时ptr为空)，realloc（oldsize-->newsize), free(newsize == 0时)。详见lauxlib.c中的l_alloc函数  
2. 
                /*
                ** About the realloc function:
                ** void *frealloc (void *ud, void *ptr, size_t osize, size_t nsize);
                ** ('osize' is the old size, 'nsize' is the new size)
                **
                ** - frealloc(ud, p, x, 0) frees the block 'p' and returns NULL.
                ** Particularly, frealloc(ud, NULL, 0, 0) does nothing,
                ** which is equivalent to free(NULL) in ISO C.
                **
                ** - frealloc(ud, NULL, x, s) creates a new block of size 's'
                ** (no matter 'x'). Returns NULL if it cannot create the new block.
                **
                ** - otherwise, frealloc(ud, b, x, y) reallocates the block 'b' from
                ** size 'x' to size 'y'. Returns NULL if it cannot reallocate the
                ** block to the new size.
                */


## 数据结构

                NONE

## lmem.c

| 名称 | 功能 | 参数 | tips |
|:--|:--|:--| :-- |
|luaM_growaux|parsing过程中array增长的辅助函数， MINSIZEARRAY = 4|lua_State *L, void *block, int nelems, int *psize, int size_elements, int limit, const char *what|<font color=red>TODO</font>|
|luaM_shrinkvector_|parsing过程中，收缩vector的函数|lua_State *L, void *block, int *size, int final_n, int size_elem|<font color=red>TODO</font>|
|luaM_toobig|内存过大报错，luaG_runerror|lua_State *L||
|luaM_free_|释放内存|lua_State *L, void *block, size_t osize|调用g->frealloc函数，传入一个0大小的new size触发free(lauxlib.c::l_alloc函数)|
|tryagain|再次尝试内存分配|lua_State *L, void *block, size_t osize, size_t nsize|try调用gc full. try realloc again.|
|luaM_realloc_|通用的内存申请函数|lua_State *L, void *block, size_t osize, size_t nsize|调用firsttry宏，申请内存，失败则try again,成功则记录GCdebt<br><font color=red>WHY:tryagain函数里没有记录GCdebt</font>|
|luaM_saferealloc_|添加了luaM_error的realloc|lua_State *L, void *block, size_t osize, size_t nsize||
|luaM_malloc|新的内存申请|lua_State *L, size_t size, int tag||
---

<br>


## 思考

- 1. firsttry的宏是啥，为啥用这个宏  
- 2. GCdebt是啥，用来干啥  
  