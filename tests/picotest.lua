-- https://github.com/jozanza/pico-test
local test = {
 test=function(title,f)
  local desc=function(msg,f)
   printh('⚡:desc:'..msg)
   f()
  end
  local it=function(msg,f)
   printh('⚡:it:'..msg)
   local xs={f()}
   for i=1,#xs do
    if xs[i] == true then
     printh('⚡:assert:true')
    else
     printh('⚡:assert:false')
    end
   end
   printh('⚡:it_end')
  end
  printh('⚡:test:'..title)
  f(desc,it)
  printh('⚡:test_end')
 end,
 test_suite={}
}

return test
