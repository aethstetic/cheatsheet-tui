import terminal;
import app : application;
import core.stdc.stdio : fprintf, stderr;

void main() {
    try {
        auto raw = raw_mode.enter();
        enable_alt_screen();
        hide_cursor();
        flush();

        auto a = application.create();
        a.run();

        show_cursor();
        disable_alt_screen();
        write_raw(reset_all);
        flush();
    } catch (Throwable e) {
        show_cursor();
        disable_alt_screen();
        write_raw(reset_all);
        flush();
        fprintf(stderr, "Error: %.*s\n", cast(int) e.msg.length, e.msg.ptr);
    }
}
