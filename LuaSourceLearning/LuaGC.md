
# GC

## 参考资料

https://blog.codingnow.com/2011/03/lua_gc_1.html  

## 要点
1. 三色标记：黑色，确定可达，已标记状态。灰色，中间状态，待处理子节点。白色，默认状态，当标记阶段结束仍然白色的，会在sweep阶段回收。  Lua中有两种白色，当前白和旧白，当前白用于在标记阶段结束，sweep阶段时候新增的对象，sweep阶段只会回收标记为旧白的对象。灰色的存在使得标记阶段也可以被分步执行。
2. barrier: 在标记阶段新增对象时，可能会和已经标记过得对象（黑色）之间发生引用关系的变化，此时需要处理保证不会出现黑色对象引用到了白色对象的情况，有两种方式：a) 标记过程向前一步，如果新增对象被一个黑色对象引用，则标记新增对象为灰色；b) 标记过程回退一步，将引用了新增对象的黑色对象置灰，置灰会使得下一次标记过程对其进行重新扫描。

3. traversetable: {stron key: weak value}: traverseweakvalue；{weak key: stron value}: traverseephemeron；{weak key: weak value}: linkgclist(table, g->allweak)；{strong key: strong value}: traversestrongtable;
4. 

## 数据结构
                #define CommonHeader	struct GCObject *next; lu_byte tt; lu_byte marked

                /*
                ** Nodes for Hash tables: A pack of two TValue's (key-value pairs)
                ** plus a 'next' field to link colliding entries. The distribution
                ** of the key's fields ('key_tt' and 'key_val') not forming a proper
                ** 'TValue' allows for a smaller size for 'Node' both in 4-byte
                ** and 8-byte alignments.
                */
                typedef union Node {
                        struct NodeKey {
                                TValuefields;  /* fields for value */
                                lu_byte key_tt;  /* key type */
                                int next;  /* for chaining */
                                Value key_val;  /* key value */
                        } u;
                        TValue i_val;  /* direct access to node's value as a proper 'TValue' */
                } Node;

                typedef struct Table {
                        CommonHeader;
                        lu_byte flags;  /* 1<<p means tagmethod(p) is not present */
                        lu_byte lsizenode;  /* log2 of size of 'node' array */
                        unsigned int alimit;  /* "limit" of 'array' array */
                        TValue *array;  /* array part */
                        Node *node;
                        Node *lastfree;  /* any free position is before this position */
                        struct Table *metatable;
                        GCObject *gclist;
                } Table;

## lgc.c

| 名称 | 功能 | 参数 | tips |
|:--|:--|:--| :-- |
|getgclist|获取指定对象记录的gclist|GCObject *o|对于对象o的类型,返回其gclist字段<br>如Table，LuaClosure，CClosure，thread，Proto和UData类型的对象，都有gclist字段|
|linkgclist|把o加到一个gclist中|GCObject *o, GCObject **pnext, GCObject **list|添加完后，o在gclist最前端|
|clearkey|clear keys for empty entries in tables.|Node *n|只是标记了key是dead，可以被回收了，但是不会删除该Node|
|iscleared|识别一个weak table中的key or value是不是可以被清理的|global_State *g, const GCObject *o|对于string，由string table管理，不需要在这里做删除，其他类型返回iswhite(o)|
|luaC_barrier_|处理标记回收阶段新增GCObject *v修改到引用关系的情形:o是黑色，引用了新增v是白色|lua_State *L, GCObject *o, GCObject *v|分标记阶段和扫描阶段做处理<br>标记阶段将v设置为灰色,等下一次标记过程来处理<br>sweep阶段则将o置为白色，等待下一轮gc处理|
|luaC_barrierback_|同上，但是是回退一步处理|lua_State *L, GCObject *o|直接将o置为gray,留待下一次标记过程处理|
|luaC_fix|将一个o对象加入fix列表，不参与垃圾回收|lua_State *L, GCObject *o|从g->allgc的第一个对象（o必须是g->allgc第一个位置的对象）置灰（永远都是灰的）并移动到g->fixed列表最前面的位置|
|luaC_newobj|创建一个新的collectable对象|lua_State *L, int tt, size_t sz|luaM_newobject并置白，插入g->allgc第一个位置|
|reallymarkobject|把一个对象标黑|global_State *g, GCObject *o|1. short str不管，long str直接标黑<br>2. Upvalue，open的置灰，closed的置黑，将value走一遍reallmarkobject<br>3. UserData对于没有user value的情况，直接标记其metatable(有的话)和自身为黑 <br>4. LuaClosure,CClosure,Table,Thread,Proto等连入g->gray链中，等待下一次访问|
|markmt|标记metamethod|global_State *g|遍历g->mt的列表做一下mark|
|markbeingfnz|标记所有在being-finalized列表中的对象|global_State *g|遍历g->tobefnz，逐个markobject，返回个数|
|remarkupvals|标记所有的upvalues的value|global_State *g|遍历所有的g->twups，thread with upvalues，然后遍历其所有的upvalues，mark其value|
|cleargraylists|情况gray list|global_State *g|g->gray, g->grayagain, g->weak, g->allweak, g->ephemeron置NULL|
|restartcollection|重新开始一次回收|global_State *g|清空gray list， 标记root set(g->mainthread, g->l_registry，标记所有的metamethod,标记所有的beingfinalized对象|
|genlink|判断object是回到grayagain list还是到old age|global_State *g, GCObject *o|o是一个black对象，如果是这次回收中设置的对象，则加入grayagain list，否则修改为old对象|
|traverseweakvalue|Traverse a table with weak values and link it to proper list|global_State *g, Table *h|1. 如果标记阶段，则将其加入grayagain list，在atomic阶段处理<br>2. 如果是atomic处理阶段，且value是white类型的，cleard|
|traverseephemeron|Traverse an ephemeron table and link it to proper list|global_State *g, Table *h, int inv|1. 遍历array part标记<br>2. 遍历hash part，clear值为nil的entry，mark值为white的，对于有white-white的键值对，加入g->ephemeron list，... link table into proper list|
|traversestrongtable|traverse stron table|global_State *g, Table *h|直接处理table，不需要连入正确的list，因为是强引用|
|traversetable|traverse table总入口|global_State *g, Table *h|根据mode是否是weak，weakkey or weekvalue调用traverseweakvalue，traverseephemeron or traversestrongtable来遍历|
|traverseudata|遍历userdata|global_State *g, Udata *u|mark udata的metatable， 遍历uvalue mark|
|traverseproto|遍历prototype|global_State *g, Proto *f|mark: source, k(const), upvalues, p(nested protos), locavars.varname（local variable names)|
|traverseCclosure|遍历cclosure|global_State *g, CClosure *cl|mark related upvalues|
|traverseLclosure|遍历lclosure|global_State *g, LClosure *cl|mark: proto and upvalues|
|traversethread|遍历thread|global_State *g, lua_State *th|1. 如果是propagate阶段或者是old的thread，加入grayagain list<br>2. 标记th->stack到th->top的所有栈元素<br>3. 标记所有的open upvalues<br>4. 如果是atomic阶段，清空extra栈，判断并加入twups(thread with upvalues) list<br>5. 如果不是g->gcemergency则shrink stack|
|propagatemark|traverse one gray object, turning it to black|global_State *g|从g->gray list取一个对象，标记为黑色然后调用其traverse函数：只有Table,UserData,LuaClosure,CClosure,Proto,Thread有各自的traverse函数和需要|
|propagateall|加了个循环遍历完g->gray list|global_State *g|while (g->gray)\ tot += propagatemark(g)|
|convergeephemerons||global_State *g|会调用traverseephemeron，inv 1-0 循环，正向反向traver|
|clearbykeys|clear entries with unmarked keys from all weaktables in list 'l'|global_State *g, GCObject *l||
|clearbyvalues|clear entries with unmarked values from all weaktables in list 'l' up to element 'f'|global_State *g, GCObject *l, GCObject *f||
|freeupval||lua_State *L, UpVal *uv|unlink uv|
|freeobj||lua_State *L, GCObject *o|根据不同的类型进行free操作|
|sweeplist|判断old white并回收，修改为current white做好下次gc准备|lua_State *L, GCObject **p, int countin, int *countout|countin是这次sweep个数，countout是这次遍历的个数，遍历完了返回NULL|
|sweeptolive|一个一个回收，直到第一个存活对象|lua_State *L, GCObject **p||
|checkSizes|check string table大小，尝试shrink|lua_State *L, global_State *g|g->strt.nuse < g->strt.size / 4 then resize to g->strt.size / 2，修正g->GCestimate|
|udata2finalize|Get the next udata to be finalized from the 'tobefnz' list, and link it back into the 'allgc' list.|global_State *g||
|dothecall||lua_State *L, void *ud|luaD_callnoyield(L, L->top - 2, 0)|
|GCTM|调用用于gc的meta method|lua_State *L|从tobefnz list取一个对象，找到其gc的meta method，压入栈，dothecall|
|runafewfinalizers|调用指定个数的GCTM|lua_State *L, int n|循环n，判断g->tobefnz，run GCTM|
|callallpendingfinalizers|调用全部个数的GCTM|lua_State *L|循环run GCTM，直到g->tobefnz为空|
|findlast|定位到gc列表最后一个对象|GCObject **p||
|separatetobefnz|Move all unreachable objects (or 'all' objects) that need finalization from list 'finobj' to list 'tobefnz' (to be finalized).|global_State *g, ||
---

<br>

<div align=center><img src ="./Res/gc.png"/ border="3"></div>

<br>

<div align=center>图2.1 gc相关结构理解图 </div>


## 思考

- 1. 
- 