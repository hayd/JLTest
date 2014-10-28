module JLTest

_TESTCTX = :(testContext)

type TestContext
  name             #test case name
  curTest          #current test
  numRun           #num tests run
  numPassed        #num tests passed
  numFailed        #num assertions failed
  numErrors        #num assertions with errors
  numSkipped       #num tests skipped
  setUpCase        #before test case
  tearDownCase     #after test case
  setUp            #before test
  tearDown         #after test
  preAssert        #before assertion
  postAssert       #after assertion

  TestContext(desc) = new (desc,"",0,0,0,0,0,()->nothing, ()->nothing, ()->nothing, ()->nothing,(args...)->nothing, (args...)->nothing)
end

function printTestReport(tc::JLTest.TestContext)
  local rep = "Run: $(tc.numRun) | Passed: $(tc.numPassed) | Failed: $(tc.numFailed) | Errors: $(tc.numErrors) | Skipped: $(tc.numSkipped)"
  local topLeft = repeat("=",int((length(rep) - length(tc.name) - 1)/2))
  local topRight = repeat("=", length(rep) - length(topLeft) - length(tc.name) - 1)
  local borderBot = repeat("=",length(rep))
  println(topLeft," ",tc.name," ", topRight)
  println(rep)
  println(borderBot)
end

function setUp(tc::JLTest.TestContext)
  try
    tc.numRun += 1
    tc.setUp()
  catch ex
    println("Exception in setUp for ", tc.desc, " : ", ex)
  end
end

function doTest(tc::JLTest.TestContext, assertion::String, test::Function, args...)
  if !(test(args...))
    tc.numFailed += 1
    print(assertion,"(")
    for arg in args[1:end-1]
      print(arg,", ")
    end
    println(args[end], ") failed")
  end
end

function handleException(tc::JLTest.TestContext, assertion, ex, bt)
  tc.numErrors += 1
  println("Exception:", ex, " during ", assertion)
  Base.show_backtrace(STDOUT, bt)
end

function tearDown(tc::JLTest.TestContext)
  try
    tc.tearDown()
  catch ex
    println("Exception in tearDown for ", tc.desc, " : ", ex)
  end
end


macro assertion1(assertion,arg1,test)
  quote
    local tc = $(esc(_TESTCTX))
    local a = $(esc(arg1))
    tc.preAssert(tc, $assertion,a)
    try

      doTest(tc, $assertion, $(esc(test)),a)
    catch ex
      bt=catch_backtrace()
      handleException(tc, $assertion, ex,bt)
    end
    tc.postAssert(tc, $assertion,a)
  end
end

macro assertion2(assertion,arg1,arg2,test)
  quote
    local tc = $(esc(_TESTCTX))
    local a = $(esc(arg1))
    local b = $(esc(arg2))
    tc.preAssert(tc, $assertion, a, b)
    try
      doTest(tc, $assertion, $(esc(test)),a,b)
    catch ex
      bt=catch_backtrace()
      handleException(tc, $assertion, ex,bt)
    end
    tc.postAssert(tc, $assertion, a, b)
  end
end

export @casename
macro casename(str)
  quote
    $(esc(_TESTCTX)).name = $str
  end
end


export @testname
macro testname(str)
  quote
    $(esc(_TESTCTX)).curTest = $str
  end
end

export @setUp
#set a function to be called before each test starts
macro setUp(func)
  quote
    $(esc(_TESTCTX)).setUp =  $(esc(func))
    nothing
  end
end

export @tearDown
#set a function to be called after each test finishes
macro tearDown(func)
  quote
    $(esc(_TESTCTX)).tearDown =  $(esc(func))
    nothing
  end
end

export @assertEqual
macro assertEqual(val1,val2)
  test = :((a,b)->(a == b))
  :( @assertion2("assertEqual", $(esc(val1)), $(esc(val2)), $(esc(test))) )
end

export @assertNotEqual
macro assertNotEqual(val1,val2)
  test = :((a,b)->(a != b))
  :(@assertion2("assertNotEqual",$(esc(val1)),$(esc(val2)),$(esc(test))))
end

export @assertLess
#val1 < val2
macro assertLess(val1,val2)
  test = :((a,b)->(a < b))
  :(@assertion2("assertEqual",$(esc(val1)),$(esc(val2)),$(esc(test))))
end

export @assertLessEqual
#val1 <= val2
macro assertLessEqual(val1,val2)
  test = :((a,b)->(a <= b))
  :(@assertion2("assertLessEqual",$(esc(val1)),$(esc(val2)),$(esc(test))))
end

export @assertGreater
#val1 > val2
macro assertGreater(val1,val2)
  test = :((a,b)->(a > b))
  :(@assertion2("assertGreater",$(esc(val1)),$(esc(val2)),$(esc(test))))
end

export @assertGreaterEqual
#val1 >= val2
macro assertGreaterEqual(val1,val2)
  test = :((a,b)->(a >= b))
  :(@assertion2("assertGreater",$(esc(val1)),$(esc(val2)),$(esc(test))))
end

export @assertIs
#an obj1 is the same as obj2
macro assertIs(obj1,obj2)
  test = :((a,b)->(a === b))
  :(@assertion2("assertIs",$(esc(obj1)),$(esc(obj2)),$(esc(test))))
end

export @assertIsNot
#an obj1 is not the same as obj2
macro assertIsNot(obj1,obj2)
  test = :((a,b)->(a !== b))
  :(@assertion2("assertIsNot",$(esc(obj1)),$(esc(obj2)),$(esc(test))))
end

export @assertIn
#an obj not in collection
macro assertIn(obj,collection)
  test = :((a,b)->(a in b))
  :(@assertion2("assertIn",$(esc(obj)),$(esc(collection)),$(esc(test))))
end

export @assertNotIn
#an obj not in a collection
macro assertNotIn(obj,collection)
  test = :((a,b)->!(a in b))
  :(@assertion2("assertNotIn",$(esc(obj)),$(esc(collection)),$(esc(test))))
end

export @assertItemsEqual
#two collections equal ignoring order difference
macro assertItemsEqual(col1,col2)
  test = :((a,b)->(sort(a) == sort(b)))
  :(@assertion2("assertItemsEqual",$(esc(col1)),$(esc(col2)),$(esc(test))))
end

export @assertIsA
#an obj is a type
macro assertIsA(obj,typ)
  test = :((a,b)->isa(a,b))
  :(@assertion2("assertIsA",$(esc(obj)),$(esc(typ)),$(esc(test))))
end

export @assertIsNotA
#an obj is not a type
macro assertIsNotA(obj,typ)
  test = :((a,b)->!isa(a,b))
  :(@assertion2("assertIsNotA", $(esc(obj)),$(esc(typ)), $(esc(test))))
end

export @assertMatches
#a regex matches a string
macro assertMatches(regex,str)
  test = :((a,b)->ismatch(a,b))
  :(@assertion2("assertMatches", $(esc(regex)),$(esc(str)),$(esc(test))))
end

export @assertNotMatches
macro assertNotMatches(regex,str)
  test = :((a,b)->!ismatch(a,b))
  :(@assertion2("assertNotMatches", $(esc(regex)),$(esc(str)),$(esc(test))))
end


export @assertTrue
macro assertTrue(expr)
  test = :((a)->(isa(a,Bool) && a))
  :(@assertion1("assertTrue", $(esc(expr)),$(esc(test))))
end

export @assertFalse
macro assertFalse(expr)
  test = :((a)->(isa(a,Bool) && !a))
  :(@assertion1("assertFalse", $(esc(expr)),$(esc(test))))
end

export @testFailed(msg)
#Fail and print msg
macro testFailed(msg)
  test = :((a)->false)
  :(@assertion1("Failed",$(esc(msg)),$(esc(test))))
end

export @expectFailures
#Use to assert that n failures are expected at the point where macro appears
#and deduct from failure count
macro expectFailures(n)
  quote
    if $(esc(_TESTCTX)).numFailed != $(esc(n))
      println("Error: ", $(esc(n))," expected failures but ", $(esc(_TESTCTX)).numFailed, " actual")
    else
      $(esc(_TESTCTX)).numFailed -= $(esc(n))
    end
  end
end

export @expectErrors
#Use to assert that n errors are expected at the point where macro appears
#and deduct from error count
macro expectErrors(n)
  quote
    if $(esc(_TESTCTX)).numFailed != $(esc(n))
      println("Error: ", $(esc(n))," expected errors but ", $(esc(_TESTCTX)).numErrors, " actual")
    else
      $(esc(_TESTCTX)).numErrors -= $(esc(n))
    end
  end
end

export @testreport
macro testreport()
  quote
    printTestReport($(esc(_TESTCTX)))
  end
end

export @testcase
#Create test case around a block
macro testcase(block)
  quote
    let $(esc(_TESTCTX)) = JLTest.TestContext("No Name Test Case")
      local tc = $(esc(_TESTCTX))
      tc.setUpCase()
      $(esc(block))
      tc.tearDownCase()
      if tc.numErrors == 0 && tc.numFailed == 0
        println(tc.name, " Ok")
        if tc.numSkipped > 0
          println(tc.numSkipped, " Tests Skipped")
        end
      else
        println(tc.name, " FAILED! ", tc.numFailed, " failures ", tc.numErrors, " errors")
      end
    end
  end
end

export @test
macro test(block)
  quote
    let tc = $(esc(_TESTCTX))
      numRun = tc.numRun += 1
      tc.curTest = "Test $numRun"
      local before = tc.numFailed + tc.numErrors
      tc.setUp()
      try
        $(esc(block))
      catch ex
        bt=catch_backtrace()
        handleException(tc,tc.curTest,ex,bt)
      end
      tc.tearDown()
      local after = tc.numFailed + tc.numErrors
      if before == after
        tc.numPassed +=1
      else
        println(tc.curTest, " Failed!")
      end
      tc.curTest = ""
    end
  end
end

export @testskip
#Place in front of a test to unconditionally skip it
macro testskip(args...)
  local skip, blk
  if length(args) == 1
    skip = true
    blk = args[1]
  elseif length(args) == 2
    (skip, blk) = args
  else
    error("@testskip accepts at most two arguments")
  end

  if skip
    quote
      $(esc(_TESTCTX)).numSkipped+=1
    end
  else
      :(@test($(blk)))
  end
end

end #JLTest
