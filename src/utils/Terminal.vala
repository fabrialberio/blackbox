namespace Terminal {
  public bool is_flatpak() {
    return FileUtils.test("/.flatpak-info", FileTest.EXISTS);
  }

  /* fp_guess_shell
   *
   * Copyright 2019 Christian Hergert <chergert@redhat.com>
   *
   * The following function is a derivative work of the code from
   * https://gitlab.gnome.org/chergert/flatterm which is licensed under the
   * Apache License, Version 2.0 <LICENSE-APACHE or
   * https://opensource.org/licenses/MIT>, at your option. This file may not
   * be copied, modified, or distributed except according to those terms.
   *
   * SPDX-License-Identifier: (MIT OR Apache-2.0)
   */
  public string? fp_guess_shell(Cancellable? cancellable = null) throws Error {
    if (!is_flatpak())
      return Vte.get_user_shell();

    string[] argv = { "flatpak-spawn", "--host", "getent", "passwd",
      Environment.get_user_name() };

    var launcher = new GLib.SubprocessLauncher(
      SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
    );

    launcher.unsetenv("G_MESSAGES_DEBUG");
    var sp = launcher.spawnv(argv);

    if (sp == null)
      return null;

    string? buf = null;
    if (!sp.communicate_utf8(null, cancellable, out buf, null))
      return null;

    var parts = buf.split(":");

    if (parts.length < 7) {
      return null;
    }

    return parts[6].strip();
  }

  public string[]? fp_get_env(Cancellable? cancellable = null) throws Error {
    if (!is_flatpak())
      return Environ.get();

    string[] argv = { "flatpak-spawn", "--host", "env" };

    var launcher = new GLib.SubprocessLauncher(
      SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
    );

    launcher.setenv("G_MESSAGES_DEBUG", "false", true);

    var sp = launcher.spawnv(argv);

    if (sp == null)
      return null;

    string? buf = null;
    if (!sp.communicate_utf8(null, cancellable, out buf, null))
      return null;

    string[] arr = buf.strip().split("\n");

    return arr;
  }

  public int get_foreground_process (
    int terminal_fd,
    Cancellable? cancellable = null
  ) {
    if (!is_flatpak ()) {
      return Posix.tcgetpgrp (terminal_fd);
    }

    KeyFile kf = new KeyFile ();
    kf.load_from_file ("/.flatpak-info", KeyFileFlags.NONE);
    string host_root = kf.get_string ("Instance", "app-path");

    string[] argv = {
      "flatpak-spawn",
      "--host",
      "%s/bin/terminal-toolbox".printf (host_root),
      //  "/app/bin/toolbox/terminal-toolbox",
      "tcgetpgrp",
      terminal_fd.to_string ()
    };

    warning ("flatpak-spawn command: %s", string.joinv (" ", argv));

    var launcher = new GLib.SubprocessLauncher(
      SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE
    );

    launcher.setenv("G_MESSAGES_DEBUG", "false", true);

    var sp = launcher.spawnv(argv);

    if (sp == null) {
      return -1;
    }

    string? buf = null;
    string? err_buf = null;
    if (!sp.communicate_utf8(null, cancellable, out buf, out err_buf)) {
      return -1;
    }

    warning ("PID from terminal-toolbox '%s' -- err %s", buf?.strip (), err_buf);

    return -1;
  }
}
