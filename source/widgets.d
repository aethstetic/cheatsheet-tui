module widgets;

import std.algorithm : max, min;
import screen : screen_buf;
import cheatsheet : command, category, search_result;

void draw_tab_bar(ref screen_buf scr, int row, const category[] categories, int active_tab) {
    scr.set_style(false, false, true);
    scr.fill_row(row);

    int col = 1;
    foreach (i, ref cat; categories) {
        if (i == active_tab)
            scr.set_style(true);
        else
            scr.set_style(false, false, true);

        scr.draw_char(row, col, ' ');
        scr.draw_text(row, col + 1, cat.name);
        int name_len = cast(int) cat.name.length;
        scr.draw_char(row, col + 1 + name_len, ' ');
        col += name_len + 2;

        scr.set_style(false, false, true);
        if (col < scr.cols()) {
            scr.draw_char(row, col, ' ');
            col++;
        }
    }

    scr.set_style(false, false, true);
    foreach (c; col .. scr.cols())
        scr.draw_char(row, c, ' ');
}

void draw_search_bar(ref screen_buf scr, int row, const(char)[] query, bool active, int cursor_pos) {
    scr.set_style(false, true);
    scr.fill_row(row);

    string prefix = active ? " Search: " : " /: Search ";
    scr.set_style(active, !active);
    scr.draw_text(row, 0, prefix);

    if (active || query.length > 0) {
        scr.set_style();
        scr.draw_text(row, cast(int) prefix.length, query);

        if (active) {
            int cpos = cast(int) prefix.length + cursor_pos;
            if (cpos < scr.cols()) {
                char cursor_char = (cursor_pos < cast(int) query.length)
                    ? query[cursor_pos] : ' ';
                scr.set_style(false, false, true);
                scr.draw_char(row, cpos, cursor_char);
            }
        }
    }
}

void draw_column_header(ref screen_buf scr, int row) {
    scr.set_style(true, true);
    scr.fill_row(row);

    int name_w = max(12, scr.cols() / 6);
    int syntax_w = max(20, scr.cols() / 3);

    scr.draw_text(row, 2, "NAME", name_w);
    scr.draw_text(row, 2 + name_w, "SYNTAX", syntax_w);
    scr.draw_text(row, 2 + name_w + syntax_w, "DESCRIPTION");
}

private void draw_command_row(ref screen_buf scr, int row, ref const command cmd,
                              bool selected, int cols) {
    int name_w = max(12, cols / 6);
    int syntax_w = max(20, cols / 3);
    int desc_w = cols - name_w - syntax_w - 4;

    if (selected) {
        scr.set_style(true, false, true);
        scr.fill_row(row);
        scr.draw_text(row, 0, ">");
    } else {
        scr.reset_style();
        scr.fill_row(row);
    }

    if (selected)
        scr.set_style(true, false, true);
    else
        scr.set_style(true);
    scr.draw_text(row, 2, cmd.name, name_w - 1);

    if (selected)
        scr.set_style(false, false, true);
    else
        scr.reset_style();
    scr.draw_text(row, 2 + name_w, cmd.syntax, syntax_w - 1);

    if (selected)
        scr.set_style(false, false, true);
    else
        scr.set_style(false, true);
    if (desc_w > 0) {
        int desc_col = 2 + name_w + syntax_w;
        if (cast(int) cmd.description.length > desc_w && desc_w > 3) {
            scr.draw_text(row, desc_col, cmd.description[0 .. desc_w - 3], desc_w - 3);
            scr.draw_text(row, desc_col + desc_w - 3, "...", 3);
        } else {
            scr.draw_text(row, desc_col, cmd.description, desc_w);
        }
    }
}

int draw_command_list(ref screen_buf scr, int start_row, int end_row,
                      const command[] commands, int selected_idx, int scroll_offset) {
    int visible = end_row - start_row;
    int drawn = 0;

    foreach (i; 0 .. visible) {
        int cmd_idx = scroll_offset + i;
        int row = start_row + i;

        if (cmd_idx < cast(int) commands.length) {
            draw_command_row(scr, row, commands[cmd_idx],
                             cmd_idx == selected_idx, scr.cols());
            drawn++;
        } else {
            scr.reset_style();
            scr.fill_row(row);
        }
    }
    return drawn;
}

int draw_search_results(ref screen_buf scr, int start_row, int end_row,
                        const category[] categories, const search_result[] results,
                        int selected_idx, int scroll_offset) {
    int visible = end_row - start_row;
    int drawn = 0;

    foreach (i; 0 .. visible) {
        int res_idx = scroll_offset + i;
        int row = start_row + i;

        if (res_idx < cast(int) results.length) {
            auto r = results[res_idx];
            auto ref cmd = categories[r.category_idx].commands[r.command_idx];
            draw_command_row(scr, row, cmd, res_idx == selected_idx, scr.cols());
            drawn++;
        } else {
            scr.reset_style();
            scr.fill_row(row);
        }
    }
    return drawn;
}

void draw_status_bar(ref screen_buf scr, int row, string mode) {
    scr.set_style(false, false, true);
    scr.fill_row(row);

    string hints;
    switch (mode) {
        case "normal":
            hints = " [j/k] nav  [tab] category  [/] search  [enter] run  [a] add  [e] edit  [d] del  [c] copy  [?] help  [q] quit";
            break;
        case "search":
            hints = " type to search  [enter] select  [esc] cancel  [j/k] navigate results";
            break;
        case "confirm":
            hints = " [enter] confirm  [esc] cancel";
            break;
        case "form":
            hints = " [tab] next field  [enter] save  [esc] cancel";
            break;
        case "help":
            hints = " press any key to close help";
            break;
        default:
            hints = " " ~ mode;
            break;
    }
    scr.draw_text(row, 0, hints, scr.cols());
}

void draw_scrollbar(ref screen_buf scr, int start_row, int end_row,
                    int total_items, int visible_items, int scroll_offset) {
    if (total_items <= visible_items) return;

    int height = end_row - start_row;
    int col = scr.cols() - 1;

    int thumb_size = max(1, height * visible_items / total_items);
    int thumb_pos = height * scroll_offset / total_items;
    thumb_pos = min(thumb_pos, height - thumb_size);

    foreach (i; 0 .. height) {
        int row = start_row + i;
        if (i >= thumb_pos && i < thumb_pos + thumb_size) {
            scr.set_style(true);
            scr.draw_char(row, col, '#');
        } else {
            scr.set_style(false, true);
            scr.draw_char(row, col, '|');
        }
    }
}

void draw_confirm_dialog(ref screen_buf scr, string title, string message,
                         string hint = "[enter] confirm  [esc] cancel") {
    int w = max(40, min(cast(int) message.length + 6, scr.cols() - 4));
    int h = 7;
    int x = (scr.cols() - w) / 2;
    int y = (scr.rows() - h) / 2;

    scr.set_style(false, false, true);
    foreach (r; 0 .. h) {
        foreach (c; 0 .. w) {
            char ch = ' ';
            if (r == 0 || r == h - 1) {
                ch = (c == 0 || c == w - 1) ? '+' : '-';
            } else if (c == 0 || c == w - 1) {
                ch = '|';
            }
            scr.draw_char(y + r, x + c, ch);
        }
    }

    scr.set_style(true, false, true);
    scr.draw_text(y + 1, x + 2, title, w - 4);

    scr.set_style(false, false, true);
    scr.draw_text(y + 3, x + 2, message, w - 4);

    scr.set_style(false, true, true);
    scr.draw_text(y + 5, x + 2, hint, w - 4);
}

void draw_help_overlay(ref screen_buf scr) {
    int w = 52;
    int h = 20;
    int x = max(0, (scr.cols() - w) / 2);
    int y = max(0, (scr.rows() - h) / 2);

    scr.set_style(false, false, true);
    foreach (r; 0 .. h) {
        foreach (c; 0 .. w) {
            char ch = ' ';
            if (r == 0 || r == h - 1) {
                ch = (c == 0 || c == w - 1) ? '+' : '-';
            } else if (c == 0 || c == w - 1) {
                ch = '|';
            }
            scr.draw_char(y + r, x + c, ch);
        }
    }

    scr.set_style(true, false, true);
    scr.draw_text(y + 1, x + 2, "Cheatsheet TUI - Help", w - 4);

    static immutable string[2][] bindings = [
        ["Up / k",       "Move selection up"],
        ["Down / j",     "Move selection down"],
        ["PgUp / PgDn", "Scroll page up/down"],
        ["Tab",          "Next category"],
        ["Shift-Tab",    "Previous category"],
        ["/",            "Enter search mode"],
        ["Escape",       "Exit search / close dialog"],
        ["Enter",        "Execute selected command"],
        ["c",            "Copy command to clipboard"],
        ["a",            "Add new command"],
        ["e",            "Edit selected command"],
        ["d",            "Delete selected command"],
        ["?",            "Toggle this help"],
        ["q / Ctrl-Q",   "Quit"],
    ];

    int row = y + 3;
    foreach (ref b; bindings) {
        if (row >= y + h - 1) break;
        scr.set_style(true, false, true);
        scr.draw_text(row, x + 3, b[0], 17);
        scr.set_style(false, false, true);
        scr.draw_text(row, x + 21, b[1], w - 23);
        row++;
    }

    scr.set_style(false, true, true);
    scr.draw_text(y + h - 2, x + 2, "Press any key to close", w - 4);
}

void draw_message(ref screen_buf scr, int row, string msg) {
    scr.set_style(true, false, true);
    scr.fill_row(row);
    scr.draw_text(row, 1, msg, scr.cols() - 2);
}

struct form_field {
    string label;
    char[512] buf;
    int len = 0;
    int cursor_pos = 0;

    const(char)[] value() const { return buf[0 .. len]; }

    static form_field create(string lbl, const(char)[] initial = "", int cursor = 0) {
        form_field f;
        f.label = lbl;
        f.cursor_pos = cursor;
        f.len = cast(int) min(initial.length, f.buf.length);
        if (f.len > 0)
            f.buf[0 .. f.len] = initial[0 .. f.len];
        return f;
    }

    void insert(int pos, const(char)[] s) {
        int slen = cast(int) s.length;
        if (len + slen > cast(int) buf.length) return;
        import core.stdc.string : memmove;
        if (len - pos > 0)
            memmove(&buf[pos + slen], &buf[pos], len - pos);
        buf[pos .. pos + slen] = s[];
        len += slen;
    }

    void remove(int pos, int count = 1) {
        if (pos < 0 || pos >= len || count <= 0) return;
        if (count > len - pos) count = len - pos;
        import core.stdc.string : memmove;
        if (len - pos - count > 0)
            memmove(&buf[pos], &buf[pos + count], len - pos - count);
        len -= count;
    }

    void truncate(int pos) {
        if (pos < len) len = pos;
    }

    void remove_before(int pos) {
        if (pos <= 0 || pos > len) return;
        import core.stdc.string : memmove;
        memmove(&buf[0], &buf[pos], len - pos);
        len -= pos;
    }
}

void draw_form(ref screen_buf scr, string title, const form_field[] fields, int active_field) {
    int w = min(60, scr.cols() - 4);
    int h = cast(int) fields.length * 3 + 5;
    int x = max(0, (scr.cols() - w) / 2);
    int y = max(0, (scr.rows() - h) / 2);

    scr.set_style(false, true);
    foreach (r; 0 .. h) {
        foreach (c; 0 .. w) {
            char ch = ' ';
            if (r == 0 || r == h - 1) {
                ch = (c == 0 || c == w - 1) ? '+' : '-';
            } else if (c == 0 || c == w - 1) {
                ch = '|';
            }
            scr.draw_char(y + r, x + c, ch);
        }
    }

    scr.set_style(true);
    scr.draw_text(y + 1, x + 2, title, w - 4);

    int row = y + 3;
    foreach (i, ref f; fields) {
        bool active = (i == active_field);

        scr.set_style(active, !active);
        scr.draw_text(row, x + 3, f.label, w - 5);
        int lbl_end = x + 3 + cast(int) f.label.length;
        if (lbl_end < x + w - 2)
            scr.draw_char(row, lbl_end, ':');
        row++;

        int field_w = w - 8;
        scr.reset_style();
        const(char)[] val = f.value;
        if (cast(int) val.length > field_w)
            val = val[$ - field_w .. $];
        scr.draw_text(row, x + 4, val, field_w);

        if (active) {
            int cpos = x + 4 + min(f.cursor_pos, cast(int) f.value.length);
            if (cpos < x + w - 4) {
                char cch = (f.cursor_pos < cast(int) f.value.length)
                    ? f.value[f.cursor_pos] : ' ';
                scr.set_style(false, false, true);
                scr.draw_char(row, cpos, cch);
            }
        }

        row += 2;
    }

    scr.set_style(false, true);
    scr.draw_text(y + h - 2, x + 2, "Tab:Next  Enter:Save  Esc:Cancel", w - 4);
}
