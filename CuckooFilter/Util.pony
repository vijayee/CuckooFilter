primitive Util
  fun hash (data: Array[U8]) : U32 =>
    var hash : U32 = 5381
    for num in data.values() do
      hash = (((hash << 5) >> 0) + hash) + num.u32()
    end
    hash
