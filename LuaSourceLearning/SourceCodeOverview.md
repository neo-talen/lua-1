
## 1. 优点

与宿主语言交互：Lua速度是Python的3-5倍  
字符串操作：两者差不多  
综合性能：具体取决于代码中各种操作的比例，实际效果Lua一般在Python的2-4倍之间  

## 2. Overview
---

- 1. 交互式输入时，通过lua_readline来阻塞获取玩家输入：  

                #define lua_readline(L_state, buffer, prompt) \  
                        ((void)L_state, fputs(prompt, stdout), fflush(stdout),  /* show prompt */ \  
                        fgets(buffer, LUA_MAXINPUT, stdin) != NULL)  //  LUA_MAXINPUT = 512  

- 2. Lua table:  
        https://zhuanlan.zhihu.com/p/97830462  

        Lua Table 有两部分组成：有序列表array和hashtable：  
        - 1. array是一个动态维护的数组，key就是数组的索引，从1开始到size；数组大小由个数决定，在2的幂次情形下动态增长。  
        - 2. hashtable也是一个动态维护的数组，索引是hash(key)，使用链接法解决hash冲突。  
        
        t[key]的过程是，先看key是否在array的索引中，如果没有再去计算hash(key)到hashtable中查找。  
        ***NOTE:*** resize的时候会根据当前key（所有整数key，包括array和hashtable中的）重新计算array真正所需大小（有些值被置nil了），找到最最大的利用率>=50%的2次幂作为新的size。其余的值放到hashtable中。

- 3. Lua内存占用：  
        - Value: 8B (取决于平台，LUA_NUMBER定义等)  
        - TValue: 16B  value with type tag  

        - TString: 固定部分24 + 1('\0'字符串结尾符) + str_len(字符串实际消耗内存)  
                字符串分为ShortString和LongString（>40个字符）；ShortString存放在一个StringTable中，相同短字符串实际都是一份内存数据；长字符串则没有这套机制，每个长字符串有各自的内存空间。  

        - Table: 固定部分56 + sizeof(array) * sizeof(TValue)(16) + sizeof(hashtable) * sizeof(Node)(24/32)

- 4. Lua Upvalue:  
        Upvalue，缩写upval，用来实现闭包，类似C++的lambda捕获。  

                local upval = 1
                local upval2 = 2
                function test()
                        local locvar = 3
                        print(upval)

                        local function aaa()
                                print(upval+upval2+locvar)
                        end
                        aaa()
                end
        
        上面代码块中，test闭包函数中的Upvalue为upval，aaa闭包函数中的Upvalue为upval, upval2和locvar。  

        closed upvalue和open upvalue： closed意思是当前使用的upvalue被释放掉了之后，需要自己拷贝并持有它。如三层的闭包引用了第二层闭包的某个Value的upvalue，当第二层闭包结束时，该upvalue就变成了一个closed upvalue，此时该upvalue会重新赋值持有这个Value。  

- 5. Lua VM:  
        Lua的虚拟机机制，代码模块：lopcodes.h, lopnames.h, lvm.c(主循环执行逻辑)  


- 6. realloc不会改动到原来的数据，会copy过去。

