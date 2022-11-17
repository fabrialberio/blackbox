/* Shortcuts.vala
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

namespace Terminal {
  public const string ACTION_FOCUS_NEXT_TAB             = "app.focus-next-tab";
  public const string ACTION_FOCUS_PREVIOUS_TAB         = "app.focus-previous-tab";
  public const string ACTION_NEW_WINDOW                 = "app.new-window";

  public const string ACTION_WIN_SWITCH_HEADER_BAR_MODE = "win.switch-headerbar-mode";
  public const string ACTION_WIN_NEW_TAB                = "win.new_tab";
  public const string ACTION_WIN_EDIT_PREFERENCES       = "win.edit_preferences";
  public const string ACTION_WIN_COPY                   = "win.copy";
  public const string ACTION_WIN_PASTE                  = "win.paste";
  public const string ACTION_WIN_SEARCH                 = "win.search";
  public const string ACTION_WIN_FULLSCREEN             = "win.fullscreen";
  public const string ACTION_WIN_SHOW_HELP_OVERLAY      = "win.show-help-overlay";
}

// We load the user's keybindings and use them to override the default keymap.
// This way, if we release a new version with an extra action that isn't present
// in the user's file, we'll just use the default shortcut.

public class Terminal.Keymap : Object, Json.Serializable {
  // User defined keybindings
  public Gee.MultiMap<string, string> keymap { get; protected set; }
  // Black Box's default keybindings.
  public Gee.MultiMap<string, string> default_keymap;

  construct {
    this.default_keymap = new Gee.HashMultiMap<string, string> ();

    this.default_keymap.set (ACTION_FOCUS_NEXT_TAB,              "<Control>Tab");
    this.default_keymap.set (ACTION_FOCUS_PREVIOUS_TAB,          "<Shift><Control>Tab");
    this.default_keymap.set (ACTION_NEW_WINDOW,                  "<Shift><Control>n");
    this.default_keymap.set (ACTION_WIN_SWITCH_HEADER_BAR_MODE,  "<Shift><Control>h");
    this.default_keymap.set (ACTION_WIN_NEW_TAB,                 "<Shift><Control>t");
    this.default_keymap.set (ACTION_WIN_EDIT_PREFERENCES,        "<Control>comma");
    this.default_keymap.set (ACTION_WIN_COPY,                    "<Shift><Control>c");
    this.default_keymap.set (ACTION_WIN_PASTE,                   "<Shift><Control>v");
    this.default_keymap.set (ACTION_WIN_SEARCH,                  "<Shift><Control>f");
    this.default_keymap.set (ACTION_WIN_FULLSCREEN,              "F11");
    this.default_keymap.set (ACTION_WIN_SHOW_HELP_OVERLAY,       "<Control>question");
  }

  // Private constructor
  private Keymap () {}

  private static Keymap? instance = null;

  public static Keymap get_default () {
    if (instance != null) {
      return instance;
    }

    // FIXME: initialize `keymap` prop in `construct` and just instanciate
    // Keymap manually if there's no user-keymap.json

    var f = new File (Constants.get_user_keybindings_path ());
    string data = "{\"keymap\":{}}";

    if (FileUtils.test (f.path, FileTest.EXISTS | FileTest.IS_REGULAR)) {
      data = f.read_all (null);
    }

    message ("File: %s", f.path);
    message ("Shortcuts data:\n%s", data);

    instance = (Keymap) Json.gobject_from_data (
      typeof (Keymap),
      data
    );

    return instance;
  }

  public void apply (Gtk.Application app) {
    foreach (string key in this.default_keymap.get_keys ()) {
      // Get accelerators for this action from the user's keybindings or from
      // the default map, in case the user hasn't specified one
      string[] accelerators = this.keymap.contains (key)
        ? this.keymap.@get (key).to_array ()
        : this.default_keymap.@get (key).to_array ();

      app.set_accels_for_action (key, accelerators);
    }
  }

  public void save () {
    var data = Json.gobject_to_data (this, null);
    var f = new File (Constants.get_user_keybindings_path ());

    f.write_plus (data);

    message ("Save:\n%s", data);
  }

  public string[]? get_default_shortcut_for_action (string action) {
    return this.default_keymap.contains (action)
      ? this.default_keymap.@get (action).to_array ()
      : null;
  }

  public void set_shortcut_for_action (string action, string? accel) {
    this.keymap.remove_all (action);
    this.keymap.@set (action, accel);
  }

  public void reset_shortcut_for_action (string action) {
    string[]? _default = this.get_default_shortcut_for_action (action);

    if (_default == null) {
      this.set_shortcut_for_action (action, null);
    }
    else {
      foreach (unowned string shortcut in _default) {
        this.set_shortcut_for_action (action, shortcut);
      }
    }
  }

  public override bool deserialize_property (
    string    name,
    out Value @value,
    ParamSpec spec,
    Json.Node node
  ) {
    message ("Deserializing %s", name);
    switch (name) {
      case "keymap": {
        var map = new Gee.HashMultiMap<string, string> ();

        // keymap object
        var obj = node.get_object ();
        // foeach key/value pair
        obj?.foreach_member ((_obj, key, val) => {
          // get the accelerators array
          var arr = val.get_array ();
          if (arr == null) return;

          if (arr.get_length () == 0) {
            map.@set (key, null);
          }

          // add each accelerator for this action
          arr.foreach_element ((_arr, i, element) => {
            var str = element.get_string ();
            if (str != null) {
              map.@set (key, str);
            }
          });
        });

        @value = map;

        return true;
      }
    }
    return default_deserialize_property (name, out @value, spec, node);
  }

  public override Json.Node serialize_property (
    string name,
    Value @value,
    ParamSpec spec
  ) {
    switch (name) {
      case "keymap": {
        var keymap_object = new Json.Object ();

        foreach (string key in this.default_keymap.get_keys ()) {
          // Get accelerators for this action from the user's keybindings or from
          // the default map, in case the user hasn't specified one
          string[] accelerators = this.keymap.contains (key)
            ? this.keymap.@get (key).to_array ()
            : this.default_keymap.@get (key).to_array ();

          var arr = new Json.Array ();

          foreach (unowned string accel in accelerators) {
            if (accel != null) {
              arr.add_string_element (accel);
            }
          }

          keymap_object.set_array_member (key, arr);
        }

        var keymap_node = new Json.Node (Json.NodeType.OBJECT);
        keymap_node.set_object (keymap_object);

        return keymap_node;
      }
    }

    return default_serialize_property (name, value, spec);
  }
}

