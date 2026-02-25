module input;

import terminal;

enum key {
    none,
    character,
    enter,
    escape,
    backspace,
    del,
    tab,
    shift_tab,
    up,
    down,
    left,
    right,
    home,
    end,
    page_up,
    page_down,
    ctrl_a,
    ctrl_c,
    ctrl_d,
    ctrl_e,
    ctrl_k,
    ctrl_q,
    ctrl_u,
    ctrl_w,
}

struct key_event {
    key k = key.none;
    char ch = 0;
    string utf8;
}

private key_event parse_escape_sequence() {
    int b = read_byte();
    if (b == -1) return key_event(key.escape);

    if (b == '[') {
        int c = read_byte();
        if (c == -1) return key_event(key.escape);

        switch (c) {
            case 'A': return key_event(key.up);
            case 'B': return key_event(key.down);
            case 'C': return key_event(key.right);
            case 'D': return key_event(key.left);
            case 'H': return key_event(key.home);
            case 'F': return key_event(key.end);
            case 'Z': return key_event(key.shift_tab);
            case '3': { int d = read_byte(); if (d == '~') return key_event(key.del); break; }
            case '5': { int d = read_byte(); if (d == '~') return key_event(key.page_up); break; }
            case '6': { int d = read_byte(); if (d == '~') return key_event(key.page_down); break; }
            case '1': {
                int d = read_byte();
                if (d == '~') return key_event(key.home);
                if (d == ';') { read_byte(); read_byte(); }
                break;
            }
            case '4': { int d = read_byte(); if (d == '~') return key_event(key.end); break; }
            default:
                if (c >= '0' && c <= '9') {
                    while (true) {
                        int d = read_byte();
                        if (d == -1 || (d >= 'A' && d <= 'Z') || (d >= 'a' && d <= 'z') || d == '~')
                            break;
                    }
                }
                break;
        }
        return key_event(key.none);
    }

    if (b == 'O') {
        int c = read_byte();
        if (c == -1) return key_event(key.escape);
        switch (c) {
            case 'H': return key_event(key.home);
            case 'F': return key_event(key.end);
            default: break;
        }
        return key_event(key.none);
    }

    return key_event(key.escape);
}

key_event read_key() {
    int b = read_byte();
    if (b == -1) return key_event(key.none);

    if (b == 27) return parse_escape_sequence();

    switch (b) {
        case 1:   return key_event(key.ctrl_a);
        case 3:   return key_event(key.ctrl_c);
        case 4:   return key_event(key.ctrl_d);
        case 5:   return key_event(key.ctrl_e);
        case 9:   return key_event(key.tab);
        case 10:  return key_event(key.enter);
        case 13:  return key_event(key.enter);
        case 11:  return key_event(key.ctrl_k);
        case 17:  return key_event(key.ctrl_q);
        case 21:  return key_event(key.ctrl_u);
        case 23:  return key_event(key.ctrl_w);
        case 127: return key_event(key.backspace);
        default: break;
    }

    if (b >= 0x80) {
        char[4] buf;
        buf[0] = cast(char) b;
        int extra = 0;
        if ((b & 0xE0) == 0xC0) extra = 1;
        else if ((b & 0xF0) == 0xE0) extra = 2;
        else if ((b & 0xF8) == 0xF0) extra = 3;
        foreach (i; 0 .. extra) {
            int c = read_byte();
            if (c == -1) break;
            buf[1 + i] = cast(char) c;
        }
        return key_event(key.character, 0, cast(string) buf[0 .. 1 + extra].dup);
    }

    if (b >= 32 && b < 127) {
        char[1] s = [cast(char) b];
        return key_event(key.character, cast(char) b, cast(string) s.dup);
    }

    return key_event(key.none);
}
