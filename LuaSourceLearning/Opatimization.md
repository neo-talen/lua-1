# Opatimization


## Tips

http://lua-users.org/wiki/OptimisationTips


- 1. use local variables, and can just create a local variable from global.  
   for reason local variables are reside in virtrual machine registers and are accessed directly by index. Global variables on the other hand, reside in a lua table and as such are accessed by a hash lookup.  
   almost 10%~20% performance up with empty loop example.  [http://lua-users.org/wiki/OptimisingUsingLocalVariables]  
  
        code view:  
        #TODO  

- 2. 


