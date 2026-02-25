module terminal;

import core.sys.posix.termios;
import core.sys.posix.unistd;
import core.sys.posix.sys.ioctl;
import core.stdc.string : memcpy;
import core.stdc.stdio : snprintf;

struct raw_mode {
    @disable this(this);

    private termios orig_;
    private bool active_ = false;

    static raw_mode enter() {
        raw_mode rm;
        if (tcgetattr(STDIN_FILENO, &rm.orig_) == -1)
            assert(false, "tcgetattr failed");

        termios raw = rm.orig_;
        raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
        raw.c_oflag &= ~(OPOST);
        raw.c_cflag |= CS8;
        raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
        raw.c_cc[VMIN] = 0;
        raw.c_cc[VTIME] = 1; /// 100ms read timeout

        if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1)
            assert(false, "tcsetattr failed");

        rm.active_ = true;
        return rm;
    }

    ~this() {
        if (active_)
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_);
    }
}

struct term_size {
    int cols;
    int rows;
}

term_size get_size() {
    winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0)
        return term_size(80, 24);
    return term_size(ws.ws_col, ws.ws_row);
}

private __gshared char[65536] write_buf;
private __gshared size_t write_pos = 0;

void flush() {
    if (write_pos > 0) {
        core.sys.posix.unistd.write(STDOUT_FILENO, write_buf.ptr, write_pos);
        write_pos = 0;
    }
}

void write_raw(const(char)[] s) {
    auto ptr = s.ptr;
    auto len = s.length;
    while (len > 0) {
        auto space = write_buf.length - write_pos;
        if (space == 0) {
            flush();
            space = write_buf.length;
        }
        auto chunk = (len < space) ? len : space;
        memcpy(write_buf.ptr + write_pos, ptr, chunk);
        write_pos += chunk;
        ptr += chunk;
        len -= chunk;
    }
}

void move_to(int row, int col) {
    char[32] buf;
    auto n = snprintf(buf.ptr, buf.length, "\033[%d;%dH", row, col);
    write_raw(buf[0 .. n]);
}

void clear()              { write_raw("\033[2J\033[H"); }
void hide_cursor()        { write_raw("\033[?25l"); }
void show_cursor()        { write_raw("\033[?25h"); }
void enable_alt_screen()  { write_raw("\033[?1049h"); }
void disable_alt_screen() { write_raw("\033[?1049l"); }

enum string reset_all = "\033[0m";
enum string bold      = "\033[1m";
enum string dim       = "\033[2m";
enum string underline = "\033[4m";
enum string reverse   = "\033[7m";

int read_byte() {
    ubyte[1] c;
    auto n = core.sys.posix.unistd.read(STDIN_FILENO, c.ptr, 1);
    if (n <= 0) return -1;
    return c[0];
}
