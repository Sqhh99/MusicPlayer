#include "linestats.h"

int LineStats::total() const {
    return codeLines + commentLines + blankLines;
}

LineStats LineStats::operator+(const LineStats& addend) const {
    LineStats result;
    result.blankLines = this->blankLines + addend.blankLines;
    result.codeLines = this->codeLines + addend.codeLines;
    result.commentLines = this->commentLines + addend.commentLines;
    return result;
}

LineStats& LineStats::operator+=(const LineStats& addend) {
    this->blankLines += addend.blankLines;
    this->codeLines += addend.codeLines;
    this->commentLines += addend.commentLines;
    return *this;
}
