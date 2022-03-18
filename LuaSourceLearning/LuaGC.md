
# GC

## 要点
1. 

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

## ltable.c

| 名称 | 功能 | 参数 | tips |
|:--|:--|:--| :-- |


---

<br>

<div align=center><img src ="./Res/gc.png"/ border="3"></div>

<br>

<div align=center>图2.1 gc相关结构理解图 </div>


## 思考

- 1. 
- 