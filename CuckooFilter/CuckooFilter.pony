use "FowlerNollVo"
use "collecitons"

primitive CuckooFilterAddError

primitive CuckooFilterContainsError

primitive CuckooFilterRemoveError

primitive MaxCuckooCount
  fun apply(): USize =>
     500
actor CuckooFilter[A: PrimeFieldWidths]
  let _cfSize: USize
  let _bSize: USize
  let _fpSize: USize
  var _count: USize = 0
  var _buckets: Array[Bucket] = []
  new create(cfSize': USize val, bSize': USize va, fpSize': USize) ? =>
    iftype A <: U32 then
      if fpSize > 4 then
        error
      end
    elseif A <: U64 then
      if fpSize > 8 then
        error
      end
    elseif A <: U128 then
      if fpSize > 16 then
        error
      end
    end

    _cfSize = cfSize'
    _bSize = bSize'
    _fpSize = fpSize'

  fun ref _resize(index) =>
    if (index > (_buckets.size() - 1)) then
      for i in Range((_buckets.size() - 1), index + 1) do
        buckets.push(new Bucket(_bSize))
      end
    end

  fun ref _increment() =>
      _count = _count + 1

  be add (data: Array[U8] val, cb: {(Bool | CuckooFilterAddError)}) =>
    let fpCb = {(fp': (Fingerprint | HashingError) =>
      match fp'
        | HashingError => cb(false)
        | let fp: Fingerprint =>
          let j = Util.hash(data) % _cfSize
          _resize(j)
          try
            if (_buckets(j)?.add(fp)) then
              _increment()
              return cb(true)
            else
              let k = (j xor fp.hash()) % _cfSize
              _resize(k)
              if (_buckets(k)?.add(fp)) then
                _increment()
                return cb(true)
              else
                let now = Time.now()
                let gen = Rand(now._1.u64(), now._2.u64())
                var i : USize = gen.usize() % 2
                var fingerprint : Fingerprint = data
                for n in Range(0, MaxCuckooCount)
                  fingerprint = bucket(i)?.swap(data)
                  i = (i xor fingerprint.hash()) % _cfSize
                  _resize(i)
                  if _buckets(i)?.add(fingerprint) then
                    _increment()
                    return cb(true)
                  end
                end
                return cb(false)
              end
            end
          else
            return cb(CuckooFilterAddError)
          end
      end
    }
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)
  be contains (data: Array[U8] val, cb: {(Bool | CuckooFilterContainsError)}) =>
    let fpCb = {(fp': (Fingerprint | HashingError) =>
      match fp'
        | HashingError => cb(false)
        | let fp: Fingerprint =>
          let j = Util.hash(data) % _cfSize
          try
            if (_buckets(j)?.contains(fp)) then
              return cb(true)
            else
              let k = (j xor fp.hash()) % _cfSize
              if (_buckets(k)?.contains(fp)) then
                return cb(true)
              else
                return cb(false)
              end
            end
          else
            return cb(CuckooFilterContainsError)
          end
      end
    }
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)

  be remove (data: Array[U8] val, cb: {(Bool | CuckooFilterRemoveError)}) =>
    let fpCb = {(fp': (Fingerprint | HashingError) =>
      match fp'
        | HashingError => cb(false)
        | let fp: Fingerprint =>
          let j = Util.hash(data) % _cfSize
          try
            if (_buckets(j)?.remove(fp)) then
              return cb(true)
            else
              let k = (j xor fp.hash()) % _cfSize
              if (_buckets(k)?.remove(fp)) then
                return cb(true)
              else
                return cb(false)
              end
            end
          else
            return cb(CuckooFilterContainsError)
          end
      end
    }
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)

  fun count(): USize val =>
    _count.usize()

  fun reliable(): Bool =>
    (100 * (_count / _cfSize)) <= 95
