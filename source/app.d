module app;

import std.algorithm : max;
import screen : screen_buf;
import input : key, key_event, read_key;
import cheatsheet : category, command, search_result, load_all, search, save_category;
import terminal : get_size;

private __gshared bool g_resized = false;
private __gshared bool g_quit = false;

private extern(C) void sigwinch_handler(int) nothrow @nogc {
    g_resized = true;
}

private extern(C) void sigint_handler(int) nothrow @nogc {
    g_quit = true;
}

enum app_mode {
    normal,
    search,
    help,
    confirm,
}

struct application {
    private screen_buf scr;
    private category[] categories;
    private int active_tab = 0;
    private int selected_idx = 0;
    private int scroll_offset = 0;

    private app_mode mode = app_mode.normal;

    private char[512] search_buf_;
    private int search_len_ = 0;
    private int search_cursor = 0;
    private search_result[] search_results;
    private int search_selected_idx = 0;
    private int search_scroll_offset = 0;

    private string status_msg;
    private int status_ticks = 0;

    static application create() {
        application a;
        a.scr = screen_buf.create();
        a.categories = load_all();
        return a;
    }

    private int visible_rows() {
        return scr.rows() - 4;
    }

    private void ensure_scroll() {
        if (categories.length == 0 || categories[active_tab].commands.length == 0) {
            selected_idx = 0;
            scroll_offset = 0;
            return;
        }
        int total = cast(int) categories[active_tab].commands.length;
        if (selected_idx < 0) selected_idx = 0;
        if (selected_idx >= total) selected_idx = total - 1;

        int vis = visible_rows();
        if (vis <= 0) return;
        if (scroll_offset > selected_idx) scroll_offset = selected_idx;
        if (scroll_offset + vis <= selected_idx) scroll_offset = selected_idx - vis + 1;
        if (scroll_offset < 0) scroll_offset = 0;
    }

    private void ensure_search_scroll() {
        int total = cast(int) search_results.length;
        if (total == 0) {
            search_selected_idx = 0;
            search_scroll_offset = 0;
            return;
        }
        if (search_selected_idx < 0) search_selected_idx = 0;
        if (search_selected_idx >= total) search_selected_idx = total - 1;

        int vis = visible_rows();
        if (vis <= 0) return;
        if (search_scroll_offset > search_selected_idx)
            search_scroll_offset = search_selected_idx;
        if (search_scroll_offset + vis <= search_selected_idx)
            search_scroll_offset = search_selected_idx - vis + 1;
        if (search_scroll_offset < 0) search_scroll_offset = 0;
    }

    private void set_status(string msg) {
        status_msg = msg;
        status_ticks = 30;
    }

    private void update_search() {
        search_results = search(categories, search_buf_[0 .. search_len_]);
        search_selected_idx = 0;
        search_scroll_offset = 0;
    }

    private void save_current_category() {
        if (active_tab >= 0 && active_tab < cast(int) categories.length) {
            save_category(categories[active_tab]);
        }
    }

    private void execute_selected() {
        import widgets : draw_confirm_dialog;
        import executor : run;

        const(command)* cmd = null;
        if (mode == app_mode.search && search_results.length > 0) {
            auto r = &search_results[search_selected_idx];
            cmd = &categories[r.category_idx].commands[r.command_idx];
        } else if (categories.length > 0 && categories[active_tab].commands.length > 0) {
            cmd = &categories[active_tab].commands[selected_idx];
        }
        if (cmd is null) return;

        string msg = "Run: " ~ cmd.syntax;
        draw_confirm_dialog(scr, "Execute Command", msg,
                            "[enter] run  [esc] cancel");
        scr.render();

        while (true) {
            key_event ev = read_key();
            if (ev.k == key.none) continue;
            if (ev.k == key.enter) {
                run(cmd.syntax);
                scr.force_repaint();
                return;
            }
            if (ev.k == key.escape) return;
        }
    }

    private void copy_selected() {
        import executor : copy_to_clipboard;

        const(command)* cmd = null;
        if (mode == app_mode.search && search_results.length > 0) {
            auto r = &search_results[search_selected_idx];
            cmd = &categories[r.category_idx].commands[r.command_idx];
        } else if (categories.length > 0 && categories[active_tab].commands.length > 0) {
            cmd = &categories[active_tab].commands[selected_idx];
        }
        if (cmd is null) return;

        if (copy_to_clipboard(cmd.syntax)) {
            set_status("Copied: " ~ cmd.syntax);
        } else {
            set_status("Copy failed (no clipboard tool found)");
        }
    }

    private void do_add_command() {
        import editor : add_command, result;
        command cmd;
        if (add_command(scr, cmd) == result.saved) {
            if (active_tab >= 0 && active_tab < cast(int) categories.length) {
                categories[active_tab].commands ~= cmd;
                selected_idx = cast(int) categories[active_tab].commands.length - 1;
                save_current_category();
                set_status("Added: " ~ cmd.name);
            }
        }
        scr.force_repaint();
    }

    private void do_edit_command() {
        import editor : edit_command, result;
        if (categories.length == 0 || categories[active_tab].commands.length == 0) return;

        if (edit_command(scr, categories[active_tab].commands[selected_idx]) == result.saved) {
            save_current_category();
            set_status("Updated: " ~ categories[active_tab].commands[selected_idx].name);
        }
        scr.force_repaint();
    }

    private void do_delete_command() {
        import editor : confirm_delete, result;
        if (categories.length == 0 || categories[active_tab].commands.length == 0) return;

        auto cmd = &categories[active_tab].commands[selected_idx];
        if (confirm_delete(scr, *cmd) == result.saved) {
            string name = cmd.name;
            auto cmds = categories[active_tab].commands;
            categories[active_tab].commands = cmds[0 .. selected_idx] ~ cmds[selected_idx + 1 .. $];

            if (selected_idx >= cast(int) categories[active_tab].commands.length) {
                selected_idx = max(0, cast(int) categories[active_tab].commands.length - 1);
            }
            save_current_category();
            set_status("Deleted: " ~ name);
        }
        scr.force_repaint();
    }

    private void handle_normal(ref const key_event ev) {
        if (ev.k == key.character) {
            switch (ev.ch) {
                case 'q': g_quit = true; return;
                case 'j': case 'J':
                    selected_idx++;
                    ensure_scroll();
                    return;
                case 'k': case 'K':
                    selected_idx--;
                    ensure_scroll();
                    return;
                case '/':
                    mode = app_mode.search;
                    search_len_ = 0;
                    search_cursor = 0;
                    search_results = [];
                    search_selected_idx = 0;
                    search_scroll_offset = 0;
                    return;
                case 'a': case 'A': do_add_command(); return;
                case 'e': case 'E': do_edit_command(); return;
                case 'd': case 'D': do_delete_command(); return;
                case 'c': case 'C': copy_selected(); return;
                case '?': mode = app_mode.help; return;
                default: break;
            }
        }

        switch (ev.k) {
            case key.up:
                selected_idx--;
                ensure_scroll();
                break;
            case key.down:
                selected_idx++;
                ensure_scroll();
                break;
            case key.page_up:
                selected_idx -= visible_rows();
                ensure_scroll();
                break;
            case key.page_down:
                selected_idx += visible_rows();
                ensure_scroll();
                break;
            case key.home:
                selected_idx = 0;
                ensure_scroll();
                break;
            case key.end:
                if (categories.length > 0)
                    selected_idx = cast(int) categories[active_tab].commands.length - 1;
                ensure_scroll();
                break;
            case key.tab:
                active_tab = (active_tab + 1) % max(1, cast(int) categories.length);
                selected_idx = 0;
                scroll_offset = 0;
                break;
            case key.shift_tab:
                active_tab = (active_tab + cast(int) categories.length - 1)
                             % max(1, cast(int) categories.length);
                selected_idx = 0;
                scroll_offset = 0;
                break;
            case key.enter:
                execute_selected();
                break;
            case key.ctrl_q:
                g_quit = true;
                break;
            case key.escape:
                g_quit = true;
                break;
            default: break;
        }
    }

    private void handle_search(ref const key_event ev) {
        if (ev.k == key.escape) {
            mode = app_mode.normal;
            return;
        }

        if (ev.k == key.enter) {
            if (search_results.length > 0) {
                auto r = &search_results[search_selected_idx];
                active_tab = r.category_idx;
                selected_idx = r.command_idx;
                scroll_offset = 0;
                ensure_scroll();
            }
            mode = app_mode.normal;
            return;
        }

        if (ev.k == key.up) {
            search_selected_idx--;
            ensure_search_scroll();
            return;
        }
        if (ev.k == key.down) {
            search_selected_idx++;
            ensure_search_scroll();
            return;
        }
        if (ev.k == key.page_up) {
            search_selected_idx -= visible_rows();
            ensure_search_scroll();
            return;
        }
        if (ev.k == key.page_down) {
            search_selected_idx += visible_rows();
            ensure_search_scroll();
            return;
        }

        if (ev.k == key.backspace) {
            if (search_cursor > 0) {
                import core.stdc.string : memmove;
                if (search_len_ - search_cursor > 0)
                    memmove(&search_buf_[search_cursor - 1],
                            &search_buf_[search_cursor],
                            search_len_ - search_cursor);
                search_len_--;
                search_cursor--;
                update_search();
            }
            return;
        }
        if (ev.k == key.del) {
            if (search_cursor < search_len_) {
                import core.stdc.string : memmove;
                if (search_len_ - search_cursor - 1 > 0)
                    memmove(&search_buf_[search_cursor],
                            &search_buf_[search_cursor + 1],
                            search_len_ - search_cursor - 1);
                search_len_--;
                update_search();
            }
            return;
        }
        if (ev.k == key.left) {
            if (search_cursor > 0) search_cursor--;
            return;
        }
        if (ev.k == key.right) {
            if (search_cursor < search_len_) search_cursor++;
            return;
        }
        if (ev.k == key.ctrl_a || ev.k == key.home) {
            search_cursor = 0;
            return;
        }
        if (ev.k == key.ctrl_e || ev.k == key.end) {
            search_cursor = search_len_;
            return;
        }
        if (ev.k == key.ctrl_u) {
            import core.stdc.string : memmove;
            if (search_len_ - search_cursor > 0)
                memmove(&search_buf_[0],
                        &search_buf_[search_cursor],
                        search_len_ - search_cursor);
            search_len_ -= search_cursor;
            search_cursor = 0;
            update_search();
            return;
        }
        if (ev.k == key.ctrl_k) {
            search_len_ = search_cursor;
            update_search();
            return;
        }
        if (ev.k == key.tab) {
            if (search_results.length > 0) {
                auto r = &search_results[search_selected_idx];
                active_tab = r.category_idx;
                selected_idx = r.command_idx;
                scroll_offset = 0;
                ensure_scroll();
            }
            mode = app_mode.normal;
            return;
        }

        if (ev.k == key.character) {
            char[4] ins_buf;
            const(char)[] ins;
            if (ev.utf8.length > 0) {
                ins = ev.utf8;
            } else {
                ins_buf[0] = ev.ch;
                ins = ins_buf[0 .. 1];
            }
            int ilen = cast(int) ins.length;
            if (search_len_ + ilen <= cast(int) search_buf_.length) {
                import core.stdc.string : memmove;
                if (search_len_ - search_cursor > 0)
                    memmove(&search_buf_[search_cursor + ilen],
                            &search_buf_[search_cursor],
                            search_len_ - search_cursor);
                search_buf_[search_cursor .. search_cursor + ilen] = ins[];
                search_len_ += ilen;
                search_cursor += ilen;
            }
            update_search();
        }
    }

    private void handle_help(ref const key_event ev) {
        if (ev.k != key.none) {
            mode = app_mode.normal;
            scr.force_repaint();
        }
    }

    private void draw() {
        import widgets;

        scr.clear();

        int row = 0;

        widgets.draw_tab_bar(scr, row, categories, active_tab);
        row++;

        widgets.draw_search_bar(scr, row, search_buf_[0 .. search_len_],
                                mode == app_mode.search, search_cursor);
        row++;

        widgets.draw_column_header(scr, row);
        row++;

        int list_end = scr.rows() - 1;

        if (mode == app_mode.search && search_len_ > 0) {
            int drawn = widgets.draw_search_results(scr, row, list_end,
                                                     categories, search_results,
                                                     search_selected_idx, search_scroll_offset);
            widgets.draw_scrollbar(scr, row, list_end,
                                   cast(int) search_results.length,
                                   drawn, search_scroll_offset);

            if (search_results.length == 0) {
                scr.set_style(false, false, true);
                scr.draw_text(row, 2, "No results found", scr.cols() - 4);
            }
        } else if (categories.length > 0) {
            auto cmds = categories[active_tab].commands;
            int drawn = widgets.draw_command_list(scr, row, list_end,
                                                  cmds, selected_idx, scroll_offset);
            widgets.draw_scrollbar(scr, row, list_end,
                                   cast(int) cmds.length,
                                   drawn, scroll_offset);
        }

        string mode_str;
        final switch (mode) {
            case app_mode.normal:  mode_str = "normal"; break;
            case app_mode.search:  mode_str = "search"; break;
            case app_mode.help:    mode_str = "help"; break;
            case app_mode.confirm: mode_str = "confirm"; break;
        }
        widgets.draw_status_bar(scr, scr.rows() - 1, mode_str);

        if (status_ticks > 0) {
            widgets.draw_message(scr, scr.rows() - 1, status_msg);
        }

        if (mode == app_mode.help) {
            widgets.draw_help_overlay(scr);
        }

        scr.render();
    }

    void run() {
        import core.sys.posix.signal;
        enum SIGWINCH = 28;

        sigaction_t sa;
        sa.sa_handler = &sigwinch_handler;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = 0;
        sigaction(SIGWINCH, &sa, null);

        sa.sa_handler = &sigint_handler;
        sigaction(SIGINT, &sa, null);

        ensure_scroll();
        draw();

        while (!g_quit) {
            if (g_resized) {
                g_resized = false;
                auto sz = get_size();
                scr.do_resize(sz.cols, sz.rows);
                scr.force_repaint();
                ensure_scroll();
            }

            key_event ev = read_key();

            if (status_ticks > 0) status_ticks--;

            if (ev.k == key.none) {
                if (status_ticks == 0 && status_msg.length > 0) {
                    status_msg = "";
                    draw();
                }
                continue;
            }

            final switch (mode) {
                case app_mode.normal:  handle_normal(ev);  break;
                case app_mode.search:  handle_search(ev);  break;
                case app_mode.help:    handle_help(ev);    break;
                case app_mode.confirm: break;
            }

            if (!g_quit) {
                draw();
            }
        }
    }
}
