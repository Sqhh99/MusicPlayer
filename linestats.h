#ifndef LINESTATS_H
#define LINESTATS_H

class LineStats {
public:
    int codeLines = 0;

    int commentLines = 0;

    int blankLines = 0;

    int total() const;

    LineStats operator+(const LineStats& addend) const;

    LineStats& operator+=(const LineStats& addend);
};

#endif
