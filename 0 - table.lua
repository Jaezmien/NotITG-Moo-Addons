table.contains = function(t, x) for _,v in pairs(t) do if v==x then return true end end return false end
table.index_from_value = function(t, k) for i,v in pairs(t) do if v==k then return i end end return nil end
table.to_array = function(t) local a = {}; for _, v in pairs(t) do table.insert(a, v) end; return a end