use "FowlerNollVo"
primitive HashingError
class Fingerprint
  var _hash : Array[U8]
  new _create (hash': Array[U8] val) =>
    _hash = hash'
  fun hash (): U32 =>
    Util.hash(this._hash)
  fun box eq (that: box->Fingerprint) : Bool =>
    try
      if (this._hash.size() != that._hash.size()) then
        return false
      end
      for i in Range(0, this._hash.size()) do
        if this._hash(i)? != that._hash(i)? then
          return false
        end
      end
      true
    else
      false
    end
  fun box ne (that: box->Fingerprint): Bool =>
    not eq(that)

actor Fingerprinter
  be fingerprint[A: FowlerNollVo.PrimeFieldWidths](data: Array[U8], fpSize: Usize, cb:{((Fingerprint | HashError))}) =>
    try
      let hash : Array[U8] = recover FowlerNollVo.FNV1a[A](data)?.slice(0, fpSize) end
      let fp : Fingerprint = Fingerprint._create(hash)
      cb(fp)
    else
      cb(HashingError)
    end
