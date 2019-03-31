use "FowlerNollVo"
use "collections"
use "time"
use "random"

primitive MaxCuckooCount
  fun apply(): USize =>
     500

interface CuckooFilterNextLoop
  be loop(ok: Bool)
  be apply()

actor CuckooFilter[A: PrimeFieldWidths]
  let _cfSize: USize
  let _bSize: USize
  var _fpSize: USize
  var _count: USize = 0
  var _buckets: Array[Bucket] ref = []
  new create(cfSize': USize, bSize': USize, fpSize': USize) =>
    _fpSize = fpSize'
    iftype A <: U32 then
      if fpSize' > 4 then
        _fpSize = 4
      end
    elseif A <: U64 then
      if fpSize' > 8 then
        _fpSize = 8
      end
    elseif A <: U128 then
      if fpSize' > 16 then
        _fpSize = 16
      end
    end
    _cfSize = cfSize'
    _bSize = bSize'
  fun ref _resize (index: USize) =>
    if ((index + 1) > _buckets.size()) then
      for i in Range((_buckets.size()), index + 1) do
        var bucket: Bucket ref = Bucket.create(_bSize)
        _buckets.push(bucket)
      end
      _buckets.compact()
    end

  fun ref _increment () =>
    _count = _count + 1

  be _addCb (fp': (Fingerprint | HashingError), data: Array[U8] val, cb: {(Bool)} val) =>
   match fp'
     | HashingError => cb(false)
     | let fp: Fingerprint =>
       let j : USize = Util.hash(data) % _cfSize
       _resize(j)
       try
         if (_buckets(j)?.add(fp)) then
           _increment()
           cb(true)
           return
         else
           let k: USize = (j xor fp.hash()) % _cfSize
           _resize(k)
           if (_buckets(k)?.add(fp)) then
             _increment()
             cb(true)
             return
           else
             let now = Time.now()
             let gen = Rand(now._1.u64(), now._2.u64())
             var i : USize = gen.usize() % 2
             var fingerprint : Fingerprint = fp
             for n in Range(0, MaxCuckooCount()) do
               fingerprint = _buckets(i)?.swap(fingerprint)?
               i = (i xor fingerprint.hash()) % _cfSize
               _resize(i)
               if _buckets(i)?.add(fingerprint) then
                 _increment()
                 cb(true)
                 return
               end
             end
               cb(false)
               return
           end
         end
       else
         cb(false)
         return
       end
   end

  be add (data: Array[U8] val, cb: {(Bool)} val) =>
    let fpCb = {(fp': (Fingerprint | HashingError)) (cf: CuckooFilter[A] tag = this) => cf._addCb(fp', data, cb)} val
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)

  be _containsCb(fp': (Fingerprint | HashingError), data: Array[U8] val, cb: {(Bool)} val) =>
    match fp'
      | HashingError => cb(false)
      | let fp: Fingerprint =>
        let j = Util.hash(data) % _cfSize
        try
          if (_buckets(j)?.contains(fp)) then
            cb(true)
            return
          else
            let k = (j xor fp.hash()) % _cfSize
            if (_buckets(k)?.contains(fp)) then
              cb(true)
              return
            else
              cb(false)
              return
            end
          end
        else
          cb(false)
          return
        end
    end

  be contains (data: Array[U8] val, cb: {(Bool)} val) =>
    let fpCb = {(fp': (Fingerprint | HashingError)) (cf: CuckooFilter[A] tag = this, data, cb) =>  cf._containsCb(fp', data, cb) } val
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)

  be _removeCb (fp': (Fingerprint | HashingError), data: Array[U8] val, cb: {(Bool)} val) =>
    match fp'
      | HashingError => cb(false)
      | let fp: Fingerprint =>
        let j = Util.hash(data) % _cfSize
        try
          if (_buckets(j)?.remove(fp)) then
            cb(true)
            return
          else
            let k = (j xor fp.hash()) % _cfSize
            if (_buckets(k)?.remove(fp)) then
              cb(true)
              return
            else
              cb(false)
              return
            end
          end
        else
          cb(false)
          return
        end
    end
  be remove (data: Array[U8] val, cb: {(Bool)} val) =>
    let fpCb = {(fp': (Fingerprint | HashingError)) (cf: CuckooFilter[A] tag = this, data, cb) =>  cf._removeCb(fp', data, cb) } val
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)

  fun count(): USize val =>
    _count.usize()

  fun reliable(): Bool =>
    (100 * (_count / _cfSize)) <= 95
