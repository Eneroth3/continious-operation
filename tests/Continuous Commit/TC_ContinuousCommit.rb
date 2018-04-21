require 'testup/testcase'

class TC_ContinuousCommit < TestUp::TestCase

  ContinuousCommit = ContinuousCommitLib::ContinuousCommit

  def setup
    # ...
  end

  def teardown
    # ...
  end

  #-----------------------------------------------------------------------------

  def test_commit
    model = Sketchup.active_model
    cc = ContinuousCommit.new(name: "Draw CPoints")
    cc.start

    # REVIEW: Is there a cleaner way to move up a local variable out of code block?
    cp = nil

    cc.start_operation do
      cp = model.entities.add_cpoint(ORIGIN)
    end

    cc.start_operation do
     model.entities.add_cpoint(ORIGIN)
    end

    Sketchup.undo

    msg = "The operations in the same stream should have been merged into one undo stack entry."
    assert(cp.deleted?, msg)

    discard_model_changes
  end

  def test_commit_Interupted
    model = Sketchup.active_model
    cc = ContinuousCommit.new(name: "Draw CPoints")
    cc.start

    cp1 = nil
    cp3 = nil

    cc.start_operation do
      cp1 = model.entities.add_cpoint(ORIGIN)
    end

    cp2 = model.entities.add_cpoint(ORIGIN)

    cc.start_operation do
     cp3 = model.entities.add_cpoint(ORIGIN)
    end

    Sketchup.undo

    msg = "The operation stream should have been reset after an operation made outside of it."
    assert(cp1.valid?, msg)
    assert(cp2.valid?, msg)
    msg = "Error in test. Last point should have been deleted."
    assert(cp3.deleted?, msg)

    discard_model_changes
  end

  # TODO: Test with explicit commit_operation call.

end
