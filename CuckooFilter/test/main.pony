use "ponytest"
use ".."
use "random"
use "time"
use "collections"
actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    test(_TestFingerprint)
    test(_TestBucket)
    test(_TestCuckooFilter)
class iso _TestFingerprint is UnitTest
  fun name(): String => "Testing Fingerprint"
  fun apply(t: TestHelper) =>
    t.long_test(2000000000)
    let data: Array[U8] val = [1; 2; 3; 4; 5; 6]
    let cb = {(fp: (Fingerprint | HashingError))(t) =>
      match fp
        | HashingError => t.fail("Hashing Error")
        | let fp1: Fingerprint val =>
          let data2: Array[U8] val = [1; 2; 3; 4; 5; 6]
          let cb2 = {(fp: (Fingerprint | HashingError))(t, fp1) =>
            match fp
              | HashingError => t.fail("Hashing Error")
              | let fp2: Fingerprint val =>
                t.assert_true(fp1 == fp2)
                let data3: Array[U8] val = [22; 2; 22; 33; 5; 6]
                let cb3 = {(fp: (Fingerprint | HashingError))(t, fp1) =>
                  match fp
                    | HashingError => t.fail("Hashing Error")
                    | let fp3: Fingerprint val =>
                      t.assert_true(fp1 != fp3)
                  end
                  t.complete(true)
                } val
                Fingerprinter.fingerprint[U32](data3, 4, cb3)
            end
          } val
          Fingerprinter.fingerprint[U32](data2, 4, cb2)
      end
    } val
    Fingerprinter.fingerprint[U32](data, 4, cb)

actor NextFp
  var data : Array[Array[U8]] val
  var fps : Array[Fingerprint] ref
  var cb : {((Array[Fingerprint] | HashingError))} val
  var i : USize = 0
  new _create(data': Array[Array[U8]] val, cb': {((Array[Fingerprint] | HashingError))} val) =>
    cb = cb'
    data = data'
    fps = Array[Fingerprint](data.size())
    try
      Fingerprinter.fingerprint[U32](data(i = i + 1)?, 4, {(fp: (Fingerprint | HashingError)) (nextFp : NextFp tag = this) => nextFp(fp) })
    else
      cb(HashingError)
    end
  be apply(fp': (Fingerprint | HashingError)) =>
    match fp'
      | HashingError => cb(HashingError)
      | let fp : Fingerprint =>
        fps.push(fp)
        if i < data.size() then
          try
            Fingerprinter.fingerprint[U32](data(i = i + 1)?, 4, {(fp: (Fingerprint | HashingError)) (nextFp : NextFp tag = this) => nextFp(fp) })
          else
            cb(HashingError)
          end
        else
          cb(fps)
        end
    end

class iso _TestBucket is UnitTest
  fun name(): String => "Testing Bucket"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    let data : Array[Array[U8]] val = recover
      var data': Array[Array[U8]] = []
      let now = Time.now()
      var gen = Rand(now._1.u64(), now._2.u64())
      for i in Range(0, 8) do
        var bytes: Array[U8] = Array[U8](6)
        for j in Range(0, 6) do
          bytes.push(gen.u8())
        end
        data'.push(bytes)
      end
      data'
    end
    let cb = {(fps' : (Array[Fingerprint] | HashingError)) (t) =>
      match fps'
      | HashingError => t.fail("Data Error")
        | let fps: Array[Fingerprint] =>
          var bucket = Bucket.create(6)
          try
            //Test Add
            for i in Range(0, 6) do
              t.assert_true(bucket.add(fps(i)?))
            end
            for i in Range(6, 8) do
              t.assert_false(bucket.add(fps(i)?))
            end
            // Test Contains
            for i in Range(0, 6) do
              t.assert_true(bucket.contains(fps(i)?))
            end
            for i in Range(6, 8) do
              t.assert_false(bucket.contains(fps(i)?))
            end
            //Test swap
            let swapped : Fingerprint = bucket.swap(fps(6)?)?
            t.assert_true(bucket.contains(fps(6)?))
            t.assert_false(bucket.contains(swapped))
          else
            t.fail("Data Error")
          end
          t.complete(true)
      end
    } val
    let next = NextFp._create(data, cb)

class iso _TestCuckooFilter is UnitTest
  fun name(): String => "Testing CuckooFilter"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000000)

    let dataCount: USize = 1500
    let dataSize: USize = 34
    var data: Array[Array[U8]] val = recover
      var data': Array[Array[U8]] = []
      let now = Time.now()
      var gen = Rand(now._1.u64(), now._2.u64())

      for i in Range(0, dataCount) do
        var bytes: Array[U8] = Array[U8](6)
        for j in Range(0, dataSize) do
          bytes.push(gen.u8())
        end
        data'.push(bytes)
      end
      data'
    end
    var cf: CuckooFilter[U32] = CuckooFilter[U32](dataCount, 6, 4)
    let cb = {() (t, cf, data) =>
      let cb = {() (t, cf, data)  =>
        let cb = {() (t, cf, data) =>
          let cb = {() (t) => t.complete(true)} val
          let next = object is CuckooFilterNextLoop
            var _t: TestHelper = t
            var _cf: CuckooFilter[U32] = cf
            var _data: Array[Array[U8]] val = data
            var _cb: {()} val = cb
            var _i: USize = 0

            be apply() =>
              if _i < _data.size() then
                try
                  _cf.contains(_data(_i)?, {(ok: Bool) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
                else
                  _t.fail("data error")
                  _t.complete(true)
                end
              else
                _cb()
              end
            be loop (ok: Bool) =>
              _t.assert_false(ok)

              if ok then
                _t.complete(true)
              end
              _i = _i + 1
              if _i < _data.size() then
                try
                  _cf.contains(_data(_i)?, {(ok: (Bool)) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
                else
                  _t.fail("data error")
                  _t.complete(true)
                end
              else
                _cb()
              end
          end
          next()
        } val
        let next = object is CuckooFilterNextLoop
          var _t: TestHelper = t
          var _cf: CuckooFilter[U32] = cf
          var _data: Array[Array[U8]] val = data
          var _cb: {()} val = cb
          var _i: USize = 0

          be apply() =>
            if _i < _data.size() then
              try
                _cf.remove(_data(_i)?, {(ok: Bool) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
              else
                _t.fail("data error")
                _t.complete(true)
              end
            else
              _cb()
            end
          be loop (ok: Bool) =>
            _t.assert_true(ok)

            if not ok then
              _t.complete(true)
            end
            _i = _i + 1
            if _i < _data.size() then
              try
                _cf.remove(_data(_i)?, {(ok) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
              else
                _t.fail("data error")
                _t.complete(true)
              end
            else
              _cb()
            end
        end
        next()
      } val
      let next = object is CuckooFilterNextLoop
        var _t: TestHelper = t
        var _cf: CuckooFilter[U32] = cf
        var _data: Array[Array[U8]] val = data
        var _cb: {()} val = cb
        var _i: USize = 0

        be apply() =>
          if _i < _data.size() then
            try
              _cf.contains(_data(_i)?, {(ok : Bool) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
            else
              _cb()
            end
          else
            _cb()
          end
        be loop (ok: Bool) =>
          _t.assert_true(ok)

          if not ok then
            _t.complete(true)
          end
          _i = _i + 1
          if _i < _data.size() then
            try
              _cf.contains(_data(_i)?, {(ok: Bool) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
            else
              _cb()
            end
          else
            _cb()
          end
      end
      next()
    } val

    let next = object is CuckooFilterNextLoop
      var _t: TestHelper = t
      var _cf: CuckooFilter[U32] = cf
      var _data: Array[Array[U8]] val = data
      var _cb: {()} val = cb
      var _i: USize = 0
      be apply() =>
        if _i < _data.size() then
          try
            _cf.add(_data(_i)?, {(ok: Bool) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
          else
            _t.fail("data error")
            _t.complete(true)
          end
        else
          _cb()
        end
      be loop (ok: Bool) =>
        _t.assert_true(ok)

        if not ok then
          _t.complete(true)
        end
        _i = _i + 1
        if _i < _data.size() then
          try
            _cf.add(_data(_i)?, {(ok: Bool) (next : CuckooFilterNextLoop tag = this) => next.loop(ok) })
          else
            _t.fail("data error")
            _t.complete(true)
          end
        else
          _cb()
        end
    end
    next()
