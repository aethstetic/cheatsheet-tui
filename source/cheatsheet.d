module cheatsheet;

import std.algorithm : sort, max, min;
import std.array : array;
import std.conv : to;
import std.file : exists, mkdirRecurse, readText, write;
import std.path : buildPath, baseName;
import std.process : environment;
import std.string : strip, indexOf, toLower, startsWith, join;
import std.uni : toLower;

struct command {
    string name;
    string syntax;
    string description;
    string tags;
    bool is_custom = false;
}

struct category {
    string name;
    string filename;
    command[] commands;
}

struct search_result {
    int category_idx;
    int command_idx;
    int score;
}

string config_dir() {
    string xdg = environment.get("XDG_CONFIG_HOME", "");
    if (xdg.length > 0)
        return buildPath(xdg, "cheatsheet-tui");
    string home = environment.get("HOME", "/tmp");
    return buildPath(home, ".config", "cheatsheet-tui");
}

private string extract_field(string line, string prefix) {
    auto idx = line.indexOf(prefix);
    if (idx < 0) return "";
    return line[idx + prefix.length .. $].strip();
}

category parse_file(string path, string display_name) {
    category cat;
    cat.name = display_name;
    cat.filename = baseName(path);

    string content;
    try {
        content = readText(path);
    } catch (Exception) {
        return cat;
    }

    command cmd;
    bool in_command = false;

    foreach (raw_line; content.splitter('\n')) {
        string line = raw_line.strip();

        if (line.length > 2 && line[0] == '#' && line[1] == ' ') {
            if (cat.name.length == 0)
                cat.name = line[2 .. $].strip();
            continue;
        }

        if (line == "---") {
            if (in_command && cmd.name.length > 0)
                cat.commands ~= cmd;
            cmd = command.init;
            in_command = true;
            continue;
        }

        if (!in_command) continue;

        if (line.startsWith("name:"))
            cmd.name = extract_field(line, "name:");
        else if (line.startsWith("syntax:"))
            cmd.syntax = extract_field(line, "syntax:");
        else if (line.startsWith("description:"))
            cmd.description = extract_field(line, "description:");
        else if (line.startsWith("tags:"))
            cmd.tags = extract_field(line, "tags:");
        else if (line.startsWith("custom:"))
            cmd.is_custom = extract_field(line, "custom:") == "true";
    }

    if (in_command && cmd.name.length > 0)
        cat.commands ~= cmd;

    return cat;
}

private auto splitter(string s, char delim) {
    import std.algorithm : splitter_ = splitter;
    return s.splitter_(delim);
}

void write_file(string path, ref const category cat) {
    string content = "# " ~ cat.name ~ "\n\n";
    foreach (ref cmd; cat.commands) {
        content ~= "---\n";
        content ~= "name: " ~ cmd.name ~ "\n";
        content ~= "syntax: " ~ cmd.syntax ~ "\n";
        content ~= "description: " ~ cmd.description ~ "\n";
        content ~= "tags: " ~ cmd.tags ~ "\n";
        if (cmd.is_custom) content ~= "custom: true\n";
        content ~= "\n";
    }
    import std.file : stdwrite = write;
    stdwrite(path, content);
}

void save_category(ref const category cat) {
    string dir = config_dir();
    mkdirRecurse(dir);
    write_file(buildPath(dir, cat.filename), cat);
}

private string display_name_for(string filename) {
    switch (filename) {
        case "file-ops.txt":         return "file ops";
        case "permissions.txt":      return "permissions";
        case "processes.txt":        return "processes";
        case "networking.txt":       return "network";
        case "systemd.txt":          return "systemd";
        case "package-managers.txt": return "packages";
        case "disk-storage.txt":     return "disk";
        default: break;
    }
    import std.array : replace;
    string name = filename;
    auto dot = name.lastIndexOf('.');
    if (dot >= 0) name = name[0 .. dot];
    return name.replace("-", " ");
}

private auto lastIndexOf(string s, char c) {
    foreach_reverse (i, ch; s) {
        if (ch == c) return cast(ptrdiff_t) i;
    }
    return cast(ptrdiff_t) -1;
}

category parse_hyprland_binds() {
    category cat;
    cat.name = "keybinds";
    cat.filename = "hyprland-keybinds.txt";

    string conf_path = find_hyprland_config();
    if (conf_path.length == 0) return cat;

    string content;
    try {
        content = readText(conf_path);
    } catch (Exception) {
        return cat;
    }

    string[string] vars;
    foreach (raw_line; content.splitter('\n')) {
        string line = raw_line.strip();
        if (line.length == 0 || line[0] == '#') continue;
        if (line[0] == '$') {
            auto eq = line.indexOf('=');
            if (eq >= 0) {
                string vname = line[0 .. eq].strip();
                string val = line[eq + 1 .. $].strip();
                auto hash = val.indexOf('#');
                if (hash >= 0) val = val[0 .. hash].strip();
                vars[vname] = val;
            }
        }
    }

    string subst(string s) {
        string result = s;
        foreach (vname, val; vars) {
            while (true) {
                auto pos = result.indexOf(vname);
                if (pos < 0) break;
                result = result[0 .. pos] ~ val ~ result[pos + vname.length .. $];
            }
        }
        return result;
    }

    foreach (raw_line; content.splitter('\n')) {
        string line = raw_line.strip();
        if (line.length == 0 || line[0] == '#') continue;

        auto eq = line.indexOf('=');
        if (eq < 0) continue;

        string kw = line[0 .. eq].strip();
        if (kw.length < 4 || kw[0 .. 4] != "bind") continue;

        string rhs = subst(line[eq + 1 .. $].strip());

        string[4] fields;
        int fi = 0;
        size_t start = 0;
        foreach (i, ch; rhs) {
            if (ch == ',' && fi < 3) {
                fields[fi++] = rhs[start .. i].strip();
                start = i + 1;
            }
        }
        if (fi < 3) {
            fields[fi++] = rhs[start .. $].strip();
            if (fi == 3) fields[3] = "";
        } else {
            fields[3] = rhs[start .. $].strip();
        }

        string mods = fields[0];
        string bind_key = fields[1];
        string dispatcher = fields[2];
        string arg = fields[3];

        if (arg.length == 0) {
            auto hash = dispatcher.indexOf('#');
            if (hash >= 0) dispatcher = dispatcher[0 .. hash].strip();
        }
        if (dispatcher != "exec") {
            auto hash = arg.indexOf('#');
            if (hash >= 0) arg = arg[0 .. hash].strip();
        }

        if (dispatcher.length == 0) continue;

        command cmd;
        string keybind = (mods.length > 0)
            ? "[" ~ mods ~ " + " ~ bind_key ~ "]"
            : "[" ~ bind_key ~ "]";
        cmd.name = keybind ~ " " ~ dispatcher ~ (arg.length > 0 ? " " ~ arg : "");
        cmd.syntax = kw ~ " = " ~ mods ~ ", " ~ bind_key ~ ", " ~ dispatcher
                     ~ (arg.length > 0 ? ", " ~ arg : "");
        cmd.description = describe_dispatcher(dispatcher, arg);
        cmd.tags = tag_for_bind(dispatcher, arg);

        cat.commands ~= cmd;
    }

    return cat;
}

private string find_hyprland_config() {
    string xdg = environment.get("XDG_CONFIG_HOME", "");
    string base;
    if (xdg.length > 0)
        base = xdg;
    else {
        string home = environment.get("HOME", "");
        if (home.length == 0) return "";
        base = buildPath(home, ".config");
    }
    string path = buildPath(base, "hypr", "hyprland.conf");
    if (exists(path)) return path;
    return "";
}

private string describe_dispatcher(string dispatcher, string arg) {
    if (dispatcher == "exec") return "Run: " ~ arg;
    if (dispatcher == "killactive") return "Close active window";
    if (dispatcher == "togglefloating") return "Toggle floating mode";
    if (dispatcher == "pseudo") return "Toggle pseudo-tiling";
    if (dispatcher == "togglesplit") return "Toggle split orientation";
    if (dispatcher == "movefocus") {
        if (arg == "l") return "Focus window left";
        if (arg == "r") return "Focus window right";
        if (arg == "u") return "Focus window up";
        if (arg == "d") return "Focus window down";
        return "Move focus " ~ arg;
    }
    if (dispatcher == "workspace") {
        if (arg.startsWith("e+")) return "Next workspace (scroll)";
        if (arg.startsWith("e-")) return "Previous workspace (scroll)";
        return "Switch to workspace " ~ arg;
    }
    if (dispatcher == "movetoworkspace") {
        if (arg.startsWith("special:"))
            return "Move window to special workspace " ~ arg[8 .. $];
        return "Move window to workspace " ~ arg;
    }
    if (dispatcher == "togglespecialworkspace")
        return "Toggle special workspace " ~ arg;
    if (dispatcher == "movewindow") return "Move window (mouse)";
    if (dispatcher == "resizewindow") return "Resize window (mouse)";
    if (dispatcher == "fullscreen") return "Toggle fullscreen";
    if (dispatcher == "exit") return "Exit Hyprland";
    string desc = dispatcher;
    if (arg.length > 0) desc ~= " " ~ arg;
    return desc;
}

private string tag_for_bind(string dispatcher, string arg) {
    if (dispatcher == "exec") {
        string tag = "exec, launch";
        import std.algorithm : countUntil;
        auto sp = arg.countUntil!(c => c == ' ' || c == '|' || c == '&' || c == ';');
        string base = (sp >= 0) ? arg[0 .. sp] : arg;
        if (base.length > 0) tag ~= ", " ~ base;
        return tag;
    }
    if (dispatcher == "workspace") return "workspace, switch, desktop";
    if (dispatcher == "movetoworkspace") return "workspace, move, window";
    if (dispatcher == "movefocus") return "focus, window, navigate";
    if (dispatcher == "killactive") return "close, kill, window";
    if (dispatcher == "togglefloating") return "float, tile, window";
    if (dispatcher == "togglesplit") return "split, layout, dwindle";
    if (dispatcher == "pseudo") return "pseudo, tile, layout";
    if (dispatcher == "togglespecialworkspace") return "scratchpad, special, workspace";
    if (dispatcher == "movewindow") return "move, mouse, drag";
    if (dispatcher == "resizewindow") return "resize, mouse, drag";
    if (dispatcher == "fullscreen") return "fullscreen, maximize";
    return dispatcher;
}

category[] load_all() {
    import defaults;
    string dir = config_dir();

    auto defs = defaults.all_categories();

    bool any_exist = false;
    foreach (ref cat; defs) {
        if (exists(buildPath(dir, cat.filename))) {
            any_exist = true;
            break;
        }
    }

    if (!any_exist) {
        mkdirRecurse(dir);
        foreach (ref cat; defs)
            write_file(buildPath(dir, cat.filename), cat);
        auto hypr = parse_hyprland_binds();
        if (hypr.commands.length > 0) defs ~= hypr;
        return defs;
    }

    category[] result;
    foreach (ref def_cat; defs) {
        string path = buildPath(dir, def_cat.filename);
        if (exists(path)) {
            result ~= parse_file(path, display_name_for(def_cat.filename));
        } else {
            write_file(path, def_cat);
            result ~= def_cat;
        }
    }

    auto hypr = parse_hyprland_binds();
    if (hypr.commands.length > 0) result ~= hypr;

    return result;
}

search_result[] search(const category[] categories, const(char)[] query) {
    if (query.length == 0) return [];

    char[512] needle_buf;
    auto nlen = min(query.length, needle_buf.length);
    foreach (i; 0 .. nlen) {
        import std.ascii : asciiToLower = toLower;
        needle_buf[i] = asciiToLower(query[i]);
    }
    const(char)[] needle = needle_buf[0 .. nlen];

    search_results_buf_.length = 0;
    search_results_buf_.assumeSafeAppend();

    foreach (ci, ref cat; categories) {
        foreach (mi, ref cmd; cat.commands) {
            int score = 0;

            if (equals_ci(cmd.name, needle))
                score = 100;
            else if (starts_with_ci(cmd.name, needle))
                score = 80;
            else if (contains_ci(cmd.name, needle))
                score = 60;
            else if (contains_ci(cmd.syntax, needle))
                score = 40;
            else if (contains_ci(cmd.description, needle))
                score = 30;
            else if (contains_ci(cmd.tags, needle))
                score = 20;

            if (score > 0)
                search_results_buf_ ~= search_result(cast(int) ci, cast(int) mi, score);
        }
    }

    search_results_buf_.sort!((a, b) => a.score > b.score);
    return search_results_buf_;
}

private search_result[] search_results_buf_;

private bool contains_ci(string haystack, const(char)[] needle) {
    if (needle.length == 0) return true;
    if (haystack.length < needle.length) return false;
    foreach (i; 0 .. haystack.length - needle.length + 1) {
        bool match = true;
        foreach (j; 0 .. needle.length) {
            import std.ascii : toLower;
            if (toLower(haystack[i + j]) != needle[j]) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }
    return false;
}

private bool starts_with_ci(string haystack, const(char)[] needle) {
    if (needle.length > haystack.length) return false;
    foreach (i; 0 .. needle.length) {
        import std.ascii : toLower;
        if (toLower(haystack[i]) != needle[i]) return false;
    }
    return true;
}

private bool equals_ci(string a, const(char)[] b) {
    if (a.length != b.length) return false;
    foreach (i; 0 .. a.length) {
        import std.ascii : toLower;
        if (toLower(a[i]) != b[i]) return false;
    }
    return true;
}
