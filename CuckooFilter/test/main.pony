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
      let data: Array[U8] = [1; 2; 3; 4; 5; 6]
      Fingerprinter.fingerprint()
