/* Reactive.vala
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
  public delegate Value SetReactiveCallback ();

  [CCode (sentinel = "")]
  public void set_reactive (
    GLib.Object obj,
    string property,
    SetReactiveCallback callback,
    ...
  ) {
    var l = va_list ();
    Object? dependency = null;

    while ((dependency = l.arg<Object?> ()) != null) {
      string prop = l.arg<string> ();

      // Assert property exists
      assert (dependency.get_class ().find_property (prop) != null);

      dependency.notify [prop].connect (() => {
        obj.set_property (property, callback ());
      });
    }

    obj.set_property (property, callback ());
  }

  public void set_property_depends_on (Object obj, string property, ...) {
    var l = va_list ();
    Object? dependency = null;

    while ((dependency = l.arg<Object?> ()) != null) {
      string prop = l.arg<string> ();

      // Assert property exists
      assert (dependency.get_class ().find_property (prop) != null);

      dependency.notify [prop].connect (() => {
        obj.notify_property (property);
      });
    }

    obj.notify_property (property);
  }
}
