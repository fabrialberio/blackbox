/* Application.vala
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

public class Terminal.Application : Adw.Application {
  private ActionEntry[] ACTIONS = {
    { "focus-next-tab", on_focus_next_tab },
    { "focus-previous-tab", on_focus_previous_tab },
    { "new-window", on_new_window },
    { "about", on_about },
    //  { "quit", on_app_quit },
  };

  public Application () {
    Object (
      application_id: "com.raggesilver.BlackBox",
      flags: ApplicationFlags.HANDLES_COMMAND_LINE
    );

    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.textdomain (GETTEXT_PACKAGE);
    Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
    Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

    this.add_action_entries (ACTIONS, this);

    var keymap = Keymap.get_default ();
    keymap.apply (this);
  }

  public override void activate () {
    new Window (this).show ();
  }

  public override int command_line (GLib.ApplicationCommandLine cmd) {
    CommandLineOptions options;

    this.hold ();

    if (!CommandLine.parse_command_line (cmd, out options)) {
      this.release ();
      return -1;
    }
    else if (options.help) {
      // For logistical reasons help is handled in `parse_command_line`.
    }
    else if (options.version) {
      cmd.print (
        "%s version %s%s\n",
        APP_NAME,
        VERSION,
        is_flatpak () ? " (flatpak)" : ""
      );
    }
    else {
      new Window (
        this,
        options.command,
        options.current_working_dir,
        false
      ).show ();
    }
    this.release ();
    return 0;
  }

  //  private void on_app_quit () {
  //    // This involves confirming before closing tabs/windows
  //    warning ("App quit is not implemented yet.");
  //  }

  private void on_about () {
    var win = create_about_dialog () as Gtk.Window;
    win.set_transient_for (this.get_active_window ());
    win.show ();
  }

  private void on_new_window () {
    new Window (this, null, null, false).show ();
  }

  private void on_focus_next_tab () {
    (this.get_active_window () as Window)?.focus_next_tab ();
  }

  private void on_focus_previous_tab () {
    (this.get_active_window () as Window)?.focus_previous_tab ();
  }
}
