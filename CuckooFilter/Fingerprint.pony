use "FowlerNollVo"
use "collections"
primitive HashingError
class val Fingerprint
  var _hash : Array[U8] val
  new val _create (hash': Array[U8] val) =>
    _hash = hash'
  fun hash (): USize =>
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
  be fingerprint[A: PrimeFieldWidths](data: Array[U8] val, fpSize: USize val, cb: {((Fingerprint | HashingError))} val) =>
    try
      let hash : Array[U8] val = recover FNV1a[A](data)?.slice(0, fpSize) end
      let fp : Fingerprint val = Fingerprint._create(hash)
      cb(fp)
    else
      cb(HashingError)
    end
