module executor;

import terminal;
import core.sys.posix.unistd;
import core.sys.posix.sys.wait;
import core.stdc.stdlib : getenv;
import core.stdc.string : strlen;

/// Leaves alt screen, runs cmd in user's shell, waits for Enter, then returns.
int run(string cmd) {
    disable_alt_screen();
    show_cursor();
    write_raw(reset_all);
    flush();

    auto pid = fork();
    if (pid == -1) return -1;

    if (pid == 0) {
        const(char)* shell = getenv("SHELL");
        if (shell is null) shell = "/bin/sh";
        import core.sys.posix.unistd : execl;
        execl(shell, shell, "-c".ptr, (cmd ~ "\0").ptr, null);
        core.sys.posix.unistd._exit(127);
    }

    int status;
    waitpid(pid, &status, 0);

    const(char)* msg = "\n\033[1m[Press Enter to return to cheatsheet]\033[0m";
    core.sys.posix.unistd.write(STDOUT_FILENO, msg, strlen(msg));

    ubyte[1] buf;
    while (core.sys.posix.unistd.read(STDIN_FILENO, buf.ptr, 1) == 1) {
        if (buf[0] == '\n' || buf[0] == '\r') break;
    }

    enable_alt_screen();
    hide_cursor();
    flush();

    if (WIFEXITED(status))
        return WEXITSTATUS(status);
    return -1;
}

/// Tries wl-copy, xclip, xsel in order.
bool copy_to_clipboard(string text) {
    if (try_clipboard("wl-copy", text)) return true;
    if (try_clipboard("xclip", text)) return true;
    if (try_clipboard("xsel", text)) return true;
    return false;
}

private bool try_clipboard(const(char)* cmd, string text) {
    import core.stdc.stdlib : system;
    import core.stdc.stdio : snprintf;

    char[256] which_buf;
    auto n = snprintf(which_buf.ptr, which_buf.length, "which %s >/dev/null 2>&1", cmd);
    if (system(which_buf.ptr) != 0) return false;

    int[2] pipefd;
    if (pipe(pipefd) == -1) return false;

    auto pid = fork();
    if (pid == -1) {
        close(pipefd[0]);
        close(pipefd[1]);
        return false;
    }

    if (pid == 0) {
        close(pipefd[1]);
        dup2(pipefd[0], STDIN_FILENO);
        close(pipefd[0]);

        import core.sys.posix.fcntl : open, O_RDWR;
        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }

        import core.sys.posix.unistd : execlp;
        execlp(cmd, cmd, null);
        core.sys.posix.unistd._exit(127);
    }

    close(pipefd[0]);
    if (text.length > 0)
        core.sys.posix.unistd.write(pipefd[1], text.ptr, text.length);
    close(pipefd[1]);

    int status;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

private bool WIFEXITED(int status) { return (status & 0x7f) == 0; }
private int WEXITSTATUS(int status) { return (status >> 8) & 0xff; }
