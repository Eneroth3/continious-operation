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

  def test_Operation
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

    msg =
      "Unso should have removed the cpoint. "\
      "The point creations should have merged into one undo stack entry"
    assert(cp.deleted?, msg)

    discard_model_changes
  end

  def test_Operation_Interupted
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

    msg =
      "Undo should not have deleted point. "\
      "Sequence should have been interrupted by point drawn outside of it."
    assert(cp1.valid?, msg)
    assert(cp2.valid?, msg)
    msg = "Error in test. Last point should have been deleted."
    assert(cp3.deleted?, msg)

    discard_model_changes
  end

  def test_commit
    # Explicit commit, not passing block to start_operation.

    model = Sketchup.active_model
    os = OperationSequence.new("Draw CPoints")
    os.start
    os.start_operation
    cp = model.entities.add_cpoint(ORIGIN)
    os.commit_operation
    os.start_operation
    model.entities.add_cpoint(ORIGIN)
    os.commit_operation

    Sketchup.undo

    msg =
      "Unso should have removed the cpoint. "\
      "The point creations should have merged into one undo stack entry"
    assert(cp.deleted?, msg)

    discard_model_changes
  end

  def test_interupt
    # Explicit sequence interruption.

    model = Sketchup.active_model
    os = OperationSequence.new("Draw CPoints")
    os.start

    cp1 = nil
    os.start_operation do
      cp1 = model.entities.add_cpoint(ORIGIN)
    end
    os.interrupt
    cp2 = nil
    os.start_operation do
     cp2 = model.entities.add_cpoint(ORIGIN)
    end

    Sketchup.undo

    msg =
      "Undo should not have deleted point. "\
      "Sequence should have been interrupted by point drawn outside of it."
    assert(cp1.valid?, msg)
    msg = "Error in test. Last point should have been deleted."
    assert(cp2.deleted?, msg)

    discard_model_changes
  end

  def test_Operation_Double
    model = Sketchup.active_model
    os1 = OperationSequence.new("Draw CPoints 1")
    os2 = OperationSequence.new("Draw CPoints 2")
    os1.start
    os2.start
    cpts1 = []
    cpts2 = []

    os1.start_operation do
      cpts1 << model.entities.add_cpoint(ORIGIN)
    end
    os1.start_operation do
      cpts1 << model.entities.add_cpoint(ORIGIN)
    end

    os2.start_operation do
      cpts2 << model.entities.add_cpoint(ORIGIN)
    end
    os2.start_operation do
      cpts2 << model.entities.add_cpoint(ORIGIN)
    end

    os1.start_operation do
      cpts1 << model.entities.add_cpoint(ORIGIN)
    end

    Sketchup.undo

    assert(cpts1[-1].deleted?, "Point should be deleted.")
    refute(cpts1[-2].deleted?, "Point should be kept.")
    refute(cpts2[-1].deleted?, "Point should be kept.")

    Sketchup.undo

    assert(cpts2[-1].deleted?, "Point should be deleted.")
    assert(cpts2[-2].deleted?, "Point should be deleted.")
    refute(cpts1[-2].deleted?, "Point should be kept.")

    Sketchup.undo

    assert(cpts1[-2].deleted?, "Point should be deleted.")
    assert(cpts1[-3].deleted?, "Point should be deleted.")

    discard_model_changes
  end

end
