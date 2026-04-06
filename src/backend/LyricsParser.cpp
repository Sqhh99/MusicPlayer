#include "LyricsParser.h"
#include <QFile>
#include <QTextCodec>
#include <QRegularExpression>
#include <algorithm>
#include <limits>

namespace {

QString decodeLyricsData(const QByteArray &data)
{
    if (data.isEmpty()) {
        return QString();
    }

    const QList<QByteArray> codecNames = {
        "UTF-8",
        "UTF-16LE",
        "UTF-16BE",
        "Shift-JIS",
        "CP932",
        "GB18030"
    };

    static const QRegularExpression timeRegex(R"(\[(\d+):(\d+)(?:\.(\d+))?\])");

    QString bestText;
    int bestScore = std::numeric_limits<int>::min();

    auto scoreDecodedText = [&](const QString &text) {
        const int timestampHits = text.count(timeRegex);
        const int replacementCount = text.count(QChar::ReplacementCharacter);
        const int nullCount = text.count(QChar(u'\0'));

        int mojibakePenalty = 0;
        for (QChar ch : text) {
            const ushort code = ch.unicode();
            if (code == 0xFFFD) {
                continue;
            }
            if ((code >= 0x80 && code <= 0x9F) || (code >= 0xE000 && code <= 0xF8FF)) {
                mojibakePenalty += 1;
            }
        }

        return (timestampHits * 100) - (replacementCount * 60) - (nullCount * 40) - (mojibakePenalty * 4);
    };

    for (const QByteArray &name : codecNames) {
        QTextCodec *codec = QTextCodec::codecForName(name);
        if (!codec) {
            continue;
        }

        const QString decoded = codec->toUnicode(data);
        const int score = scoreDecodedText(decoded);
        if (score > bestScore) {
            bestScore = score;
            bestText = decoded;
        }
    }

    if (QTextCodec *localeCodec = QTextCodec::codecForLocale()) {
        const QString decoded = localeCodec->toUnicode(data);
        const int score = scoreDecodedText(decoded);
        if (score > bestScore) {
            bestScore = score;
            bestText = decoded;
        }
    }

    return bestText;
}

}

LyricsParser::LyricsParser(QObject *parent)
    : QObject(parent)
{
}

bool LyricsParser::loadFromFile(const QString &path)
{
    clear();

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }

    const QString content = decodeLyricsData(file.readAll());
    const QStringList lines = content.split(QRegularExpression(R"(\r\n|\n|\r)"), Qt::SkipEmptyParts);

    for (const QString &rawLine : lines) {
        QString line = rawLine.trimmed();
        if (!line.isEmpty()) {
            parseLine(line);
        }
    }
    
    file.close();
    
    // Sort lyrics by timestamp
    std::sort(m_lines.begin(), m_lines.end(), 
              [](const LyricLine &a, const LyricLine &b) {
                  return a.timestamp < b.timestamp;
              });
    
    return !m_lines.isEmpty();
}

void LyricsParser::clear()
{
    m_lines.clear();
    m_title.clear();
    m_artist.clear();
    m_album.clear();
}

bool LyricsParser::isEmpty() const
{
    return m_lines.isEmpty();
}

int LyricsParser::getCurrentLineIndex(qint64 positionMs) const
{
    if (m_lines.isEmpty()) {
        return -1;
    }
    
    // Find the last line whose timestamp <= current position
    int index = -1;
    for (int i = 0; i < m_lines.size(); ++i) {
        if (m_lines[i].timestamp <= positionMs) {
            index = i;
        } else {
            break;
        }
    }
    
    return index;
}

QStringList LyricsParser::getLyricsTexts() const
{
    QStringList texts;
    texts.reserve(m_lines.size());
    for (const LyricLine &line : m_lines) {
        texts.append(line.text);
    }
    return texts;
}

const QList<LyricLine>& LyricsParser::getLines() const
{
    return m_lines;
}

bool LyricsParser::parseLine(const QString &line)
{
    // Regular expression to match LRC tags: [xx:xx.xx] or [key:value]
    static QRegularExpression tagRegex(R"(\[([^\]]+)\])");
    
    // Check for metadata tags first
    static QRegularExpression metaRegex(R"(\[(ti|ar|al|id):([^\]]*)\])");
    QRegularExpressionMatch metaMatch = metaRegex.match(line);
    if (metaMatch.hasMatch()) {
        QString key = metaMatch.captured(1).toLower();
        QString value = metaMatch.captured(2).trimmed();
        
        if (key == "ti") {
            m_title = value;
        } else if (key == "ar") {
            m_artist = value;
        } else if (key == "al") {
            m_album = value;
        }
        // id tag is ignored
        return false;
    }
    
    // Match timestamp pattern [mm:ss.xx] or [mm:ss]
    static QRegularExpression timeRegex(R"(\[(\d+):(\d+)(?:\.(\d+))?\])");
    QRegularExpressionMatchIterator it = timeRegex.globalMatch(line);
    
    QList<qint64> timestamps;
    int lastMatchEnd = 0;
    
    while (it.hasNext()) {
        QRegularExpressionMatch match = it.next();
        qint64 ts = parseTimestamp(match.captured(0));
        if (ts >= 0) {
            timestamps.append(ts);
            lastMatchEnd = match.capturedEnd();
        }
    }
    
    if (timestamps.isEmpty()) {
        return false;
    }
    
    // Get the text after all timestamps
    QString text = line.mid(lastMatchEnd).trimmed();
    
    // Skip empty lines or pure credits (like 作词:xxx)
    if (text.isEmpty()) {
        return false;
    }
    
    // Add a lyric line for each timestamp (handles multiple timestamps per line)
    for (qint64 ts : timestamps) {
        LyricLine lyricLine;
        lyricLine.timestamp = ts;
        lyricLine.text = text;
        m_lines.append(lyricLine);
    }
    
    return true;
}

qint64 LyricsParser::parseTimestamp(const QString &timestamp) const
{
    // Match [mm:ss.xx] or [mm:ss]
    static QRegularExpression regex(R"(\[(\d+):(\d+)(?:\.(\d+))?\])");
    QRegularExpressionMatch match = regex.match(timestamp);
    
    if (!match.hasMatch()) {
        return -1;
    }
    
    int minutes = match.captured(1).toInt();
    int seconds = match.captured(2).toInt();
    int centiseconds = 0;
    
    if (match.lastCapturedIndex() >= 3 && !match.captured(3).isEmpty()) {
        QString cs = match.captured(3);
        // Handle both .xx (centiseconds) and .xxx (milliseconds) formats
        if (cs.length() == 2) {
            centiseconds = cs.toInt() * 10;  // Convert to milliseconds
        } else if (cs.length() == 3) {
            centiseconds = cs.toInt();  // Already in milliseconds
        } else if (cs.length() == 1) {
            centiseconds = cs.toInt() * 100;  // Convert to milliseconds
        }
    }
    
    return (minutes * 60 + seconds) * 1000 + centiseconds;
}
