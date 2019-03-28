use "FowlerNollVo"
use "collections"
use "time"
use "random"

primitive CuckooFilterAddError

primitive CuckooFilterContainsError

primitive CuckooFilterRemoveError

primitive MaxCuckooCount
  fun apply(): USize =>
     500

interface CuckooFilterAddNextLoop
  be loop(ok': (Bool | CuckooFilterAddError))
  be apply()

interface CuckooFilterContainsNextLoop
  be loop(ok': (Bool | CuckooFilterContainsError))
  be apply()

interface CuckooFilterRemoveNextLoop
  be loop(ok': (Bool | CuckooFilterRemoveError))
  be apply()

actor CuckooFilter[A: PrimeFieldWidths]
  let _cfSize: USize
  let _bSize: USize
  let _fpSize: USize
  var _count: USize = 0
  var _buckets: Array[Bucket] ref = []
  new create(cfSize': USize, bSize': USize, fpSize': USize) =>
    iftype A <: U32 then
      if fpSize' > 4 then
        error
      end
    elseif A <: U64 then
      if fpSize' > 8 then
        error
      end
    elseif A <: U128 then
      if fpSize' > 16 then
        error
      end
    end

    _cfSize = cfSize'
    _bSize = bSize'
    _fpSize = fpSize'
  be _addCb (fp': (Fingerprint | HashingError), data: Array[U8] val, cb: {((Bool | CuckooFilterAddError))} val) =>
   match fp'
     | HashingError => cb(false)
     | let fp: Fingerprint =>
       let j = Util.hash(data) % _cfSize.u32()
       let resize = {(index: USize) (_buckets) =>
         if (index > (_buckets.size() - 1)) then
           for i in Range((_buckets.size() - 1), index + 1) do
             _buckets.push(Bucket.create(_bSize))
           end
         end
       }
       let increment = {() (_counts) =>
         _count = _count + 1
       }
       resize(j)
       try
         if (_buckets(j)?.add(fp)) then
           increment()
           cb(true)
           return
         else
           let k = (j xor fp.hash()) % _cfSize
           resize(k)
           if (_buckets(k)?.add(fp)) then
             increment()
             cb(true)
             return
           else
             let now = Time.now()
             let gen = Rand(now._1.u64(), now._2.u64())
             var i : USize = gen.usize() % 2
             var fingerprint : Fingerprint = data
             for n in Range(0, MaxCuckooCount) do
               fingerprint = _buckets(i)?.swap(data)
               i = (i xor fingerprint.hash()) % _cfSize
               resize(i)
               if _buckets(i)?.add(fingerprint) then
                 increment()
                 cb(true)
                 return
               end
             end
             cb(false)
             return
           end
         end
       else
         cb(CuckooFilterAddError)
         return
       end
   end
  be add (data: Array[U8] val, cb: {((Bool | CuckooFilterAddError))} val) =>
    let fpCb = {(fp': (Fingerprint | HashingError)) (cf: CuckooFilter[A] tag = this) => cf._addCb(fp', data, cb)}
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)
  be contains (data: Array[U8] val, cb: {((Bool | CuckooFilterContainsError))} val) =>
    let fpCb = {(fp': (Fingerprint | HashingError)) =>
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
            cb(CuckooFilterContainsError)
            return
          end
      end
    }
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)

  be remove (data: Array[U8] val, cb: {((Bool | CuckooFilterRemoveError))} val) =>
    let fpCb = {(fp': (Fingerprint | HashingError)) =>
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
                cb()
                return
              else
                cb(false)
                return
              end
            end
          else
            cb(CuckooFilterRemoveError)
            return
          end
      end
    }
    Fingerprinter.fingerprint[A](data, _fpSize, fpCb)

  fun count(): USize val =>
    _count.usize()

  fun reliable(): Bool =>
    (100 * (_count / _cfSize)) <= 95
