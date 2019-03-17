use "random"
use "time"
class Bucket
  var _contents: Array[Fingerprint]
  let _size: USize
  new create(size': USize) =>
    _contents = recover Array[Fingerprint](size') end
    _size = size'

  fun contains (fp : Fingerprint): Bool =>
    try
      _contents.find(fp, 0, 0, {(a: box->Fingerprint!, b: box->Fingerprint!): Bool => a == b} val)?
      true
    else
      false
    end

  fun ref add (fp : Fingerprint): Bool =>
    if (_contents.size() < _size) then
      _contents.push(fp)
      true
    else
      false
    end

  fun ref swap (fp : Fingerprint val): Fingerprint ? =>
    let now = Time.now()
    let gen = Rand(now._1.u64(), now._2.u64())
    let i : USize = gen.usize() % _contents.size()
    _contents(i)? = fp

  fun ref remove (fp : Fingerprint): Bool =>
    try
      let i: USize = _contents.find(fp, 0, 0, {(a: box->Fingerprint!, b: box->Fingerprint!): Bool => a == b} val)?
      _contents.delete(i)?
      true
    else
      false
    end
