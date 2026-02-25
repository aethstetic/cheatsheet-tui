module screen;

import terminal;

struct cell {
    char ch = ' ';
    bool bold = false;
    bool dim_ = false;
    bool reverse_ = false;

    bool opEquals(ref const cell o) const {
        return ch == o.ch && bold == o.bold && dim_ == o.dim_ && reverse_ == o.reverse_;
    }
}

struct screen_buf {
    private int cols_ = 0;
    private int rows_ = 0;
    private cell[] front_;
    private cell[] back_;
    private cell current_style_;
    private cell last_emitted_style_;

    int cols() const { return cols_; }
    int rows() const { return rows_; }

    static screen_buf create() {
        screen_buf s;
        auto sz = get_size();
        s.do_resize(sz.cols, sz.rows);
        return s;
    }

    void do_resize(int cols, int rows) {
        cols_ = cols;
        rows_ = rows;
        front_ = new cell[](cols * rows);
        back_ = new cell[](cols * rows);
        foreach (ref c; front_) c.ch = '\0';
    }

    void clear() {
        foreach (ref c; back_) c = cell.init;
        current_style_ = cell.init;
    }

    void set_style(bool b = false, bool d = false, bool r = false) {
        current_style_.bold = b;
        current_style_.dim_ = d;
        current_style_.reverse_ = r;
    }

    void reset_style() {
        current_style_ = cell.init;
    }

    void draw_text(int row, int col, const(char)[] text, int max_width = -1) {
        if (row < 0 || row >= rows_) return;
        int w = (max_width >= 0) ? max_width : cols_ - col;
        int i = 0;
        foreach (idx; 0 .. text.length) {
            if (i >= w) break;
            int c = col + i;
            if (c >= 0 && c < cols_) {
                auto ref cl = back_[row * cols_ + c];
                cl = current_style_;
                cl.ch = text[idx];
            }
            i++;
        }
    }

    void draw_char(int row, int col, char ch) {
        if (row < 0 || row >= rows_ || col < 0 || col >= cols_) return;
        auto ref cl = back_[row * cols_ + col];
        cl = current_style_;
        cl.ch = ch;
    }

    void fill_row(int row, char ch = ' ') {
        if (row < 0 || row >= rows_) return;
        foreach (c; 0 .. cols_) {
            auto ref cl = back_[row * cols_ + c];
            cl = current_style_;
            cl.ch = ch;
        }
    }

    private void emit_cell(ref const cell c) {
        if (c.bold != last_emitted_style_.bold
            || c.dim_ != last_emitted_style_.dim_
            || c.reverse_ != last_emitted_style_.reverse_) {
            write_raw(reset_all);
            if (c.bold) write_raw(bold);
            if (c.dim_) write_raw(dim);
            if (c.reverse_) write_raw(terminal.reverse);
            last_emitted_style_.bold = c.bold;
            last_emitted_style_.dim_ = c.dim_;
            last_emitted_style_.reverse_ = c.reverse_;
        }
        char[1] buf = [c.ch];
        write_raw(buf[]);
    }

    void render() {
        last_emitted_style_ = cell.init;
        int prev_r = -1, next_c = -1;
        foreach (r; 0 .. rows_) {
            foreach (c; 0 .. cols_) {
                auto idx = r * cols_ + c;
                if (back_[idx] != front_[idx]) {
                    if (r != prev_r || c != next_c)
                        move_to(r + 1, c + 1);
                    emit_cell(back_[idx]);
                    front_[idx] = back_[idx];
                    prev_r = r;
                    next_c = c + 1;
                }
            }
        }
        write_raw(reset_all);
        flush();
    }

    void force_repaint() {
        foreach (ref c; front_) {
            c = cell.init;
            c.ch = '\0';
        }
    }
}
