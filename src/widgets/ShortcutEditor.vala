/* ShortcutEditor.vala
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

[GtkTemplate (ui = "/com/raggesilver/BlackBox/gtk/shortcut-editor.ui")]
public class Terminal.ShortcutEditor : Adw.PreferencesPage {
  public Gtk.Application app { get; construct set; }

  [GtkChild] unowned Adw.PreferencesGroup shortcuts_group;

  static Gee.HashMap<string, string> action_map;

  // We keep track of all action rows we insert into the preferences group to
  // alow us to remove them on UI refresh later.
  Gee.ArrayList<unowned Adw.ActionRow> action_rows;

  static construct {
    action_map = new Gee.HashMap<string, string> ();

    action_map.@set ("app.focus-next-tab", _("Focus Next Tab"));
    action_map.@set ("app.focus-previous-tab", _("Focus Previous Tab"));
    action_map.@set ("app.new-window", _("New Window"));
    action_map.@set ("win.switch-headerbar-mode", _("Toggle Header Bar"));
    action_map.@set ("win.new_tab", _("New Tab"));
    action_map.@set ("win.edit_preferences", _("Preferences"));
    action_map.@set ("win.copy", _("Copy"));
    action_map.@set ("win.paste", _("Paste"));
    action_map.@set ("win.search", _("Search"));
    action_map.@set ("win.fullscreen", _("Fullscreen"));
  }

  construct {
    this.action_rows = new Gee.ArrayList<unowned Adw.ActionRow> ();
    this.build_ui ();
  }

  void edit_shortcut (string action, string? current_accel) {
    string name = action_map [action] ?? action;

    var w = new ShortcutDialog (
      this.app.get_active_window (),
      name,
      current_accel
    );

    string? new_accel = null;

    w.shortcut_set.connect ((accel) => {
      new_accel = accel;
    });

    w.response.connect ((response) => {
      var keymap = Keymap.get_default ();

      if (response == Gtk.ResponseType.APPLY) {
        message ("Bind \"%s\" to %s", name, new_accel);
        keymap.set_shortcut_for_action (action, new_accel);
      }
      else if (response == Gtk.ResponseType.NONE) {
        message ("Disable accelerator for %s", name);
        Keymap.get_default ().set_shortcut_for_action (action, null);
      }

      if (response != Gtk.ResponseType.CANCEL) {
        keymap.apply (this.app);
        keymap.save ();
        this.refresh_ui ();
      }

      w.close ();
    });

    w.show ();
  }

  void refresh_ui () {
    var iter = this.action_rows.iterator ();

    while (iter.has_next ()) {
      iter.next ();
      this.shortcuts_group.remove (iter.@get ());
    }

    this.action_rows.clear ();

    this.build_ui ();
  }

  void build_ui () {
    var k = Keymap.get_default ();

    foreach (string key in k.default_keymap.get_keys ()) {
      // Get accelerators for this action from the user's keybindings or from
      // the default map, in case the user hasn't specified one
      string[] accelerators = k.keymap.contains (key)
        ? k.keymap.@get (key).to_array ()
        : k.default_keymap.@get (key).to_array ();

      var ac = new Adw.ActionRow () {
        title = action_map[key] ?? key,
        //  subtitle = action_map[key] != null ? key : "",
      };

      Gtk.Widget suffix;

      if (accelerators.length == 0 || accelerators[0] == null) {
        suffix = new Gtk.Label (_("Disabled"));
      }
      else {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
          valign = Gtk.Align.CENTER,
          margin_top = 6,
          margin_bottom = 6,
        };

        foreach (unowned string accel in accelerators) {
          if (accel == null) continue;

          var l = new Gtk.ShortcutLabel (accel);

          box.append (l);
        }
        suffix = box;
      }

      ac.add_suffix (suffix);
      ac.set_activatable_widget (new Gtk.Button ());

      ac.activated.connect (() => {
        this.edit_shortcut (key, accelerators [0]);
      });

      this.action_rows.add (ac);
      this.shortcuts_group.add (ac);
    }
  }
}
