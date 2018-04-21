require_relative "../continuous_commit.rb"

module ContinuousCommit
module Examples
module DrawPoints

  INSTRUCTIONS =
    "Points added from here should be merged into a single entry in the undo "\
    "stack. Undo once and they should all be gone.<br /><br/>"\
    "This continuity should however be interrupted if another action to the "\
    "model is performed. If you manually modify the model your modification, "\
    "the points drawn before and the points drawn after should be 3 separate "\
    "entries to the undo stack."

  @ip = Sketchup::InputPoint.new
  @cc = ContinuousCommit.new(name: "Points")
  @dlg = nil

  # Draw a guide point in the center of the view.
  def self.draw_point
    model = Sketchup.active_model
    view = model.active_view
    @ip.pick(view, view.vpwidth / 2, view.vpheight / 2)
    point = @ip.position

    model.active_entities.add_cpoint(point)
  end

  # Draw point withing continuous operation, meaning that if the previous
  # operation to the model was made by the same continuous commit, they are
  # merged into one entry in the undo stack.
  def self.continuous_point_draw
    @cc.start_operation { draw_point }
  end

  def self.create_dialog
    UI::HtmlDialog.new(dialog_title: "Continuous Operation Example")
  end

  def self.attach_callbacks
    @dlg.add_action_callback("draw") { continuous_point_draw }
    @dlg.set_on_closed { @cc.stop }

    nil
  end

  def self.set_html
    html = <<-EOT
      #{INSTRUCTIONS}<br /><br />
      <button onclick="sketchup.draw()">Draw Point</button>
    EOT
    @dlg.set_html(html)

    nil
  end

  def self.show_dialog
    @cc.start

    if @dlg && @dlg.visible?
      @dlg.bring_to_front
    else
      @dlg ||= create_dialog
      set_html
      attach_callbacks
      @dlg.show
    end

    nil
  end

  menu = UI.menu("Plugins")
  menu.add_item("Continuous Operation Example") { show_dialog }

end
end
end
