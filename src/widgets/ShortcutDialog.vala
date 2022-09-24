/* ShortcutDialog.vala
 *
 * Copyright 2022 Paulo Queiroz <pvaqueiroz@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Terminal.ShortcutDialog : Gtk.Dialog {

  static Gtk.KeyvalTrigger JUST_ESCAPE = new Gtk.KeyvalTrigger (Gdk.Key.Escape, 0);
  static Gtk.KeyvalTrigger JUST_BACKSPACE = new Gtk.KeyvalTrigger (Gdk.Key.BackSpace, 0);

  public signal void  shortcut_set (string? accelerator);
  public signal void  disable ();

  public bool is_shortcut_set { get; protected set; default = false; }
  public string shortcut_name { get; protected set; }

  public string heading_text {
    owned get {
      return _("Enter new shortcut for \"%s\"").printf (this.shortcut_name);
    }
  }

  construct {
    this.use_header_bar = (int) true;
  }

  public ShortcutDialog (
    Gtk.Window parent,
    string shortcut_name,
    string? current_accel
  ) {
    Object (modal: true, transient_for: parent, shortcut_name: shortcut_name);

    this.title = _("Edit Shortcut");
    var hb = this.get_header_bar ();

    var set_button = new Gtk.Button.with_label (_("Apply")) {
      css_classes = { "suggested-action" }
    };

    this.bind_property ("is-shortcut-set", set_button, "sensitive", GLib.BindingFlags.SYNC_CREATE, null, null);

    set_button.clicked.connect(() => {
      this.response (Gtk.ResponseType.APPLY);
    });

    var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
      css_classes = { "destructive-action" }
    };

    cancel_button.clicked.connect(() => {
      this.response (Gtk.ResponseType.CANCEL);
    });

    hb.pack_start (cancel_button);
    hb.pack_end (set_button);
    hb.set_show_title_buttons (false);

    this.modal = true;

    var b = this.get_content_area ();

    var heading = new Gtk.Label ("") {
      wrap = true,
      css_classes = { "heading" },
    };

    this.bind_property ("heading-text", heading, "label", GLib.BindingFlags.SYNC_CREATE, null, null);

    set_property_depends_on (this, "heading-text", this, "shortcut-name", null);

    //  set_reactive (
    //    heading, "label", () => {
    //      return _("Enter new shortcut to change %s").printf (this.shortcut_name);
    //    },
    //    this, "shortcut-name",
    //    null
    //  );

    var foot_note = new Gtk.Label (_("Press Escape to cancel or Backspace to disable shortcut")) {
      wrap = true,
      css_classes = { "dim-label" },
    };

    var shortcut_label = new Gtk.ShortcutLabel ("") {
      halign = Gtk.Align.CENTER,
    };

    b.append (heading);
    b.append (shortcut_label);
    b.append (foot_note);

    b.valign = Gtk.Align.CENTER;
    b.vexpand = true;
    b.spacing = 12;

    widget_set_margin (b, 12);

    this.set_default_size (-1, 200);

    var kpc = new Gtk.EventControllerKey ();

    kpc.key_pressed.connect ((event, keyval, _keycode, modifier) => {
      int[] masks = {
        Gdk.ModifierType.CONTROL_MASK,
        Gdk.ModifierType.SHIFT_MASK,
        Gdk.ModifierType.ALT_MASK
      };

      var real_modifiers = 0;

      foreach (unowned int mask in masks) {
        if ((modifier & mask) != 0) {
          real_modifiers |= mask;
        }
      }

      var k = new Gtk.KeyvalTrigger (keyval, real_modifiers);

      if (k.compare (JUST_ESCAPE) == 0) {
        return false;
      }
      else if (k.compare (JUST_BACKSPACE) == 0) {
        this.disable ();
        this.response (Gtk.ResponseType.NONE);
        return true;
      }

      bool is_valid =
        // This is a very stupid way to check if the keyval is not Control_L,
        // Shift_L, or Alt_L. We don't want these keys to be valid.
        Gdk.keyval_name (keyval).index_of ("_", 0) == -1 &&
        // Unless keyval is one of the Function keys, shortcuts need either
        // Control or Alt.
        (
          (keyval >= Gdk.Key.F1 && keyval <= Gdk.Key.F35) ||
          (real_modifiers & Gdk.ModifierType.CONTROL_MASK) != 0 ||
          (real_modifiers & Gdk.ModifierType.ALT_MASK) != 0
        );

      shortcut_label.set_accelerator (k.to_string ());

      this.is_shortcut_set = is_valid;
      this.shortcut_set (is_valid ? k.to_string () : null);

      return true;
    });

    (this as Gtk.Widget)?.add_controller (kpc);
  }
}
