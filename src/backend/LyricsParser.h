#ifndef LYRICSPARSER_H
#define LYRICSPARSER_H

#include <QObject>
#include <QString>
#include <QList>
#include <QStringList>

struct LyricLine {
    qint64 timestamp;   // milliseconds
    QString text;
};

class LyricsParser : public QObject
{
    Q_OBJECT

public:
    explicit LyricsParser(QObject *parent = nullptr);

    // Load and parse LRC file
    bool loadFromFile(const QString &path);
    
    // Clear all loaded lyrics
    void clear();
    
    // Check if lyrics are loaded
    bool isEmpty() const;
    
    // Get the current line index based on playback position
    int getCurrentLineIndex(qint64 positionMs) const;
    
    // Get all lyrics as plain text list (for QML display)
    QStringList getLyricsTexts() const;
    
    // Get all parsed lines with timestamps
    const QList<LyricLine>& getLines() const;
    
    // Metadata accessors
    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString album() const { return m_album; }

private:
    QList<LyricLine> m_lines;
    QString m_title;
    QString m_artist;
    QString m_album;
    
    // Parse a single LRC line, returns true if it's a lyric line
    bool parseLine(const QString &line);
    
    // Parse timestamp [mm:ss.xx] format, returns milliseconds or -1 if invalid
    qint64 parseTimestamp(const QString &timestamp) const;
};

#endif // LYRICSPARSER_H
