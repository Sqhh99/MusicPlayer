#ifndef PLAYERCONTROLLER_H
#define PLAYERCONTROLLER_H

#include <QObject>
#include <QUrl>
#include <QMediaPlayer>
#include <QStringList>
#include "../backend/musicplayer.h"
#include "../backend/musicsettings.h"
#include "../backend/LyricsParser.h"
#include "PlaylistModel.h"


class PlayerController : public QObject
{
    Q_OBJECT

    // Playback state properties
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY pausedChanged)
    Q_PROPERTY(bool isLooping READ isLooping WRITE setLooping NOTIFY loopingChanged)
    Q_PROPERTY(bool isShuffle READ isShuffle WRITE setShuffle NOTIFY shuffleChanged)

    // Volume properties
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool isMuted READ isMuted WRITE setMuted NOTIFY mutedChanged)

    // Position and duration
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString positionText READ positionText NOTIFY positionChanged)
    Q_PROPERTY(QString durationText READ durationText NOTIFY durationChanged)

    // Current song info
    Q_PROPERTY(QString currentSong READ currentSong NOTIFY currentSongChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)

    // Playlist
    Q_PROPERTY(PlaylistModel* playlist READ playlist CONSTANT)

    // Equalizer
    Q_PROPERTY(int equalizerPreset READ equalizerPreset WRITE setEqualizerPreset NOTIFY equalizerPresetChanged)
    Q_PROPERTY(int bassLevel READ bassLevel WRITE setBassLevel NOTIFY bassLevelChanged)
    Q_PROPERTY(int midLevel READ midLevel WRITE setMidLevel NOTIFY midLevelChanged)
    Q_PROPERTY(int trebleLevel READ trebleLevel WRITE setTrebleLevel NOTIFY trebleLevelChanged)
    Q_PROPERTY(QUrl lastFolder READ lastFolder NOTIFY lastFolderChanged)

    // Album art and lyrics
    Q_PROPERTY(QUrl albumArtUrl READ albumArtUrl NOTIFY albumArtUrlChanged)
    Q_PROPERTY(QStringList lyrics READ lyrics NOTIFY lyricsChanged)
    Q_PROPERTY(int currentLyricIndex READ currentLyricIndex NOTIFY currentLyricIndexChanged)

public:
    explicit PlayerController(QObject *parent = nullptr);
    ~PlayerController() override;

    // Playback state getters
    bool isPlaying() const;
    bool isPaused() const;
    bool isLooping() const;
    void setLooping(bool loop);
    bool isShuffle() const;
    void setShuffle(bool shuffle);

    // Volume getters/setters
    int volume() const;
    void setVolume(int value);
    bool isMuted() const;
    void setMuted(bool muted);

    // Position/duration getters
    qint64 position() const;
    qint64 duration() const;
    QString positionText() const;
    QString durationText() const;

    // Current song info
    QString currentSong() const;
    int currentIndex() const;

    // Playlist access
    PlaylistModel* playlist() const;

    // Equalizer
    int equalizerPreset() const;
    void setEqualizerPreset(int preset);
    int bassLevel() const;
    void setBassLevel(int level);
    int midLevel() const;
    void setMidLevel(int level);
    int trebleLevel() const;
    void setTrebleLevel(int level);

    QUrl lastFolder() const;

    // Album art and lyrics
    QUrl albumArtUrl() const;
    QStringList lyrics() const;
    int currentLyricIndex() const;

public slots:
    // Playback control
    void play();
    void playIndex(int index);
    void pause();
    void stop();
    void next();
    void previous();
    void seek(qint64 position);
    void togglePlayPause();

    // File operations
    void setPlaylistFromUrls(const QList<QUrl> &urls);
    QStringList loadSavedPlaylist();

signals:
    void playingChanged();
    void pausedChanged();
    void loopingChanged();
    void shuffleChanged();
    void volumeChanged();
    void mutedChanged();
    void positionChanged();
    void durationChanged();
    void currentSongChanged();
    void currentIndexChanged();
    void equalizerPresetChanged();
    void bassLevelChanged();
    void midLevelChanged();
    void trebleLevelChanged();
    void errorOccurred(const QString &message);
    void lastFolderChanged();
    void albumArtUrlChanged();
    void lyricsChanged();
    void currentLyricIndexChanged();

private slots:
    void onPlaybackStateChanged(QMediaPlayer::PlaybackState state);
    void onPositionChanged(qint64 pos);
    void onDurationChanged(qint64 dur);
    void onMusicStart(int index);
    void onPlayerError(const QString &errorMessage);

private:
    MusicPlayer *m_musicPlayer;
    MusicSettings *m_settings;
    PlaylistModel *m_playlistModel;
    LyricsParser *m_lyricsParser;

    qint64 m_position = 0;
    qint64 m_duration = 0;
    QString m_currentSong;
    QUrl m_lastFolder;
    QUrl m_albumArtUrl;
    int m_currentLyricIndex = -1;

    QString formatTime(qint64 ms) const;
    void setupConnections();
    void updateMediaMetadata();
};

#endif // PLAYERCONTROLLER_H
