module editor;

import std.algorithm : min, max;
import screen : screen_buf;
import terminal : get_size;
import input : key, key_event, read_key;
import widgets : form_field, draw_form;
import cheatsheet : command;

enum result {
    saved,
    cancelled,
}

private bool run_form(ref screen_buf scr, string title, ref form_field[] fields) {
    int active_field = 0;

    while (true) {
        auto sz = get_size();
        if (sz.cols != scr.cols() || sz.rows != scr.rows()) {
            scr.do_resize(sz.cols, sz.rows);
            scr.force_repaint();
        }

        scr.clear();
        scr.set_style(false, true);
        foreach (r; 0 .. scr.rows())
            scr.fill_row(r, '.');

        draw_form(scr, title, fields, active_field);
        scr.render();

        key_event ev = read_key();
        if (ev.k == key.none) continue;

        if (ev.k == key.escape) return false;

        if (ev.k == key.enter) {
            if (fields.length > 0 && fields[0].value.length == 0) continue;
            return true;
        }

        if (ev.k == key.tab) {
            active_field = (active_field + 1) % cast(int) fields.length;
            continue;
        }

        if (ev.k == key.shift_tab) {
            active_field = (active_field + cast(int) fields.length - 1)
                           % cast(int) fields.length;
            continue;
        }

        auto f = &fields[active_field];

        if (ev.k == key.backspace) {
            if (f.cursor_pos > 0) {
                f.remove(f.cursor_pos - 1);
                f.cursor_pos--;
            }
        } else if (ev.k == key.del) {
            if (f.cursor_pos < f.len) {
                f.remove(f.cursor_pos);
            }
        } else if (ev.k == key.left) {
            if (f.cursor_pos > 0) f.cursor_pos--;
        } else if (ev.k == key.right) {
            if (f.cursor_pos < f.len) f.cursor_pos++;
        } else if (ev.k == key.home || ev.k == key.ctrl_a) {
            f.cursor_pos = 0;
        } else if (ev.k == key.end || ev.k == key.ctrl_e) {
            f.cursor_pos = f.len;
        } else if (ev.k == key.ctrl_u) {
            f.remove_before(f.cursor_pos);
            f.cursor_pos = 0;
        } else if (ev.k == key.ctrl_k) {
            f.truncate(f.cursor_pos);
        } else if (ev.k == key.character) {
            char[4] ins_buf;
            const(char)[] ins;
            if (ev.utf8.length > 0) {
                ins = ev.utf8;
            } else {
                ins_buf[0] = ev.ch;
                ins = ins_buf[0 .. 1];
            }
            f.insert(f.cursor_pos, ins);
            f.cursor_pos += cast(int) ins.length;
        }
    }
}

result add_command(ref screen_buf scr, ref command cmd_out) {
    form_field[] fields = [
        form_field.create("Name"),
        form_field.create("Syntax"),
        form_field.create("Description"),
        form_field.create("Tags"),
    ];

    if (run_form(scr, "Add New Command", fields)) {
        cmd_out.name = fields[0].value.idup;
        cmd_out.syntax = fields[1].value.idup;
        cmd_out.description = fields[2].value.idup;
        cmd_out.tags = fields[3].value.idup;
        cmd_out.is_custom = true;
        return result.saved;
    }
    return result.cancelled;
}

result edit_command(ref screen_buf scr, ref command cmd) {
    form_field[] fields = [
        form_field.create("Name",        cmd.name,        cast(int) cmd.name.length),
        form_field.create("Syntax",      cmd.syntax,      cast(int) cmd.syntax.length),
        form_field.create("Description", cmd.description, cast(int) cmd.description.length),
        form_field.create("Tags",        cmd.tags,        cast(int) cmd.tags.length),
    ];

    if (run_form(scr, "Edit Command", fields)) {
        cmd.name = fields[0].value.idup;
        cmd.syntax = fields[1].value.idup;
        cmd.description = fields[2].value.idup;
        cmd.tags = fields[3].value.idup;
        return result.saved;
    }
    return result.cancelled;
}

result confirm_delete(ref screen_buf scr, ref const command cmd) {
    while (true) {
        auto sz = get_size();
        if (sz.cols != scr.cols() || sz.rows != scr.rows()) {
            scr.do_resize(sz.cols, sz.rows);
            scr.force_repaint();
        }

        scr.clear();
        scr.set_style(false, true);
        foreach (r; 0 .. scr.rows())
            scr.fill_row(r, '.');

        import widgets : draw_confirm_dialog;
        string msg = "Delete '" ~ cmd.name ~ "'?";
        draw_confirm_dialog(scr, "Confirm Delete", msg);
        scr.render();

        key_event ev = read_key();
        if (ev.k == key.none) continue;
        if (ev.k == key.enter) return result.saved;
        if (ev.k == key.escape) return result.cancelled;
    }
}
