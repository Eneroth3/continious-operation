require 'testup/testcase'
require_relative "../../continuous_commit.rb"

class TC_OperationSequence < TestUp::TestCase

  OperationSequence = OperationSequenceLib::OperationSequence

  def setup
    # ...
  end

  def teardown
    # ...
  end

  #-----------------------------------------------------------------------------

  def test_commit
    model = Sketchup.active_model
    os = OperationSequence.new("Draw CPoints")
    os.start
    cp = nil
    os.start_operation do
      cp = model.entities.add_cpoint(ORIGIN)
    end
    os.start_operation do
     model.entities.add_cpoint(ORIGIN)
    end

    Sketchup.undo

    msg = "The operations in the same stream should have been merged into one undo stack entry."
    assert(cp.deleted?, msg)

    discard_model_changes
  end

  def test_commit_Interupted
    model = Sketchup.active_model
    os = OperationSequence.new("Draw CPoints")
    os.start

    cp1 = nil
    os.start_operation do
      cp1 = model.entities.add_cpoint(ORIGIN)
    end
    cp2 = model.entities.add_cpoint(ORIGIN)
    cp3 = nil
    os.start_operation do
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
