use "ponytest"
use ".."
actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    test(_TestFingerprint)

  class iso _TestFingerprint is UnitTest
    fun name(): String => "Testing Fingerprint"
    fun apply(t: TestHelper) =>
      t.long_test(2000000000)
      let data: Array[U8] val = [1; 2; 3; 4; 5; 6]
      let cb = {(fp: (Fingerprint | HashingError))(t) =>
        match fp
          |  HashingError => t.fail("Hashing Error")
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
