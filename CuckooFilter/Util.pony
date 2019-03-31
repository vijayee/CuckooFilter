primitive Util
  fun hash (data: Array[U8] val) : USize =>
    var hash' : USize = 5381
    for num in data.values() do
      hash' = (((hash' << 5) >> 0) + hash') + num.usize()
    end
    hash'
