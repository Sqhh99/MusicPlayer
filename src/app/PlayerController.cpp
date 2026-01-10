#include "PlayerController.h"
#include "PlaylistModel.h"
#include <QFileInfo>
#include <QStandardPaths>

PlayerController::PlayerController(QObject *parent)
    : QObject(parent)
    , m_musicPlayer(new MusicPlayer(this))
    , m_settings(new MusicSettings(this))
    , m_playlistModel(new PlaylistModel(this))
{
    setupConnections();

    QString lastPath = m_settings->loadLastPath();
    if (lastPath.isEmpty()) {
        lastPath = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    }
    m_lastFolder = QUrl::fromLocalFile(lastPath);

    // Load initial volume
    int savedVolume = m_settings->value("volume", 80).toInt();
    m_musicPlayer->setVolume(savedVolume);

    int savedBass = m_settings->value("eq/bass", 50).toInt();
    int savedMid = m_settings->value("eq/mid", 50).toInt();
    int savedTreble = m_settings->value("eq/treble", 50).toInt();
    m_musicPlayer->setCustomEqualizer(savedBass, savedMid, savedTreble);
}

PlayerController::~PlayerController()
{
    // Save current volume
    m_settings->setValue("volume", m_musicPlayer->volume());
}

void PlayerController::setupConnections()
{
    // Connect music player signals to controller slots
    connect(m_musicPlayer, &MusicPlayer::playbackStateChanged,
            this, &PlayerController::onPlaybackStateChanged);
    connect(m_musicPlayer, &MusicPlayer::IpositionChanged,
            this, &PlayerController::onPositionChanged);
    connect(m_musicPlayer, &MusicPlayer::IdurationChanged,
            this, &PlayerController::onDurationChanged);
    connect(m_musicPlayer, &MusicPlayer::musicStart,
            this, &PlayerController::onMusicStart);
    connect(m_musicPlayer, &MusicPlayer::playerError,
            this, &PlayerController::onPlayerError);
    connect(m_musicPlayer, &MusicPlayer::volumeChanged,
            this, &PlayerController::volumeChanged);
    connect(m_musicPlayer, &MusicPlayer::mutedChanged,
            this, &PlayerController::mutedChanged);
}

// Playback state
bool PlayerController::isPlaying() const
{
    return m_musicPlayer->isPlaying();
}

bool PlayerController::isPaused() const
{
    return m_musicPlayer->isPaused();
}

bool PlayerController::isLooping() const
{
    return m_musicPlayer->getLoop();
}

void PlayerController::setLooping(bool loop)
{
    if (m_musicPlayer->getLoop() != loop) {
        m_musicPlayer->setLoop(loop);
        emit loopingChanged();
    }
}

// Volume
int PlayerController::volume() const
{
    return m_musicPlayer->volume();
}

void PlayerController::setVolume(int value)
{
    if (m_musicPlayer->volume() != value) {
        m_musicPlayer->setVolume(value);
    }
}

bool PlayerController::isMuted() const
{
    return m_musicPlayer->isMuted();
}

void PlayerController::setMuted(bool muted)
{
    if (m_musicPlayer->isMuted() != muted) {
        m_musicPlayer->mute(muted);
    }
}

// Position/Duration
qint64 PlayerController::position() const
{
    return m_position;
}

qint64 PlayerController::duration() const
{
    return m_duration;
}

QString PlayerController::positionText() const
{
    return formatTime(m_position);
}

QString PlayerController::durationText() const
{
    return formatTime(m_duration);
}

QString PlayerController::formatTime(qint64 ms) const
{
    int totalSeconds = ms / 1000;
    int minutes = totalSeconds / 60;
    int seconds = totalSeconds % 60;
    return QString("%1:%2")
        .arg(minutes, 2, 10, QChar('0'))
        .arg(seconds, 2, 10, QChar('0'));
}

// Current song
QString PlayerController::currentSong() const
{
    return m_currentSong;
}

int PlayerController::currentIndex() const
{
    return m_musicPlayer->currentIndex();
}

// Playlist
PlaylistModel* PlayerController::playlist() const
{
    return m_playlistModel;
}

// Equalizer
int PlayerController::equalizerPreset() const
{
    return static_cast<int>(m_musicPlayer->currentPreset());
}

void PlayerController::setEqualizerPreset(int preset)
{
    m_musicPlayer->setEqualizerPreset(static_cast<EqualizerPreset>(preset));
    emit equalizerPresetChanged();
}

int PlayerController::bassLevel() const
{
    return m_musicPlayer->getBassLevel();
}

void PlayerController::setBassLevel(int level)
{
    m_musicPlayer->setCustomEqualizer(level, m_musicPlayer->getMidLevel(), m_musicPlayer->getTrebleLevel());
    m_settings->setValue("eq/bass", level);
    emit bassLevelChanged();
}

int PlayerController::midLevel() const
{
    return m_musicPlayer->getMidLevel();
}

void PlayerController::setMidLevel(int level)
{
    m_musicPlayer->setCustomEqualizer(m_musicPlayer->getBassLevel(), level, m_musicPlayer->getTrebleLevel());
    m_settings->setValue("eq/mid", level);
    emit midLevelChanged();
}

int PlayerController::trebleLevel() const
{
    return m_musicPlayer->getTrebleLevel();
}

void PlayerController::setTrebleLevel(int level)
{
    m_musicPlayer->setCustomEqualizer(m_musicPlayer->getBassLevel(), m_musicPlayer->getMidLevel(), level);
    m_settings->setValue("eq/treble", level);
    emit trebleLevelChanged();
}

// Playback control slots
void PlayerController::play()
{
    m_musicPlayer->play();
}

void PlayerController::playIndex(int index)
{
    m_musicPlayer->play(index);
}

void PlayerController::pause()
{
    m_musicPlayer->pause();
}

void PlayerController::stop()
{
    m_musicPlayer->stop();
}

void PlayerController::next()
{
    m_musicPlayer->next();
}

void PlayerController::previous()
{
    m_musicPlayer->previous();
}

void PlayerController::seek(qint64 position)
{
    if (m_musicPlayer->player) {
        m_musicPlayer->player->setPosition(position);
    }
}

void PlayerController::togglePlayPause()
{
    if (isPlaying()) {
        pause();
    } else {
        play();
    }
}

// File operations
void PlayerController::setPlaylistFromUrls(const QList<QUrl> &urls)
{
    if (urls.isEmpty()) {
        return;
    }

    QStringList filePaths;
    filePaths.reserve(urls.size());
    for (const QUrl &url : urls) {
        if (url.isLocalFile()) {
            filePaths.append(url.toLocalFile());
        } else if (url.isValid()) {
            filePaths.append(url.toString());
        }
    }

    if (filePaths.isEmpty()) {
        return;
    }

    m_musicPlayer->setPlaylist(filePaths);
    m_playlistModel->setPlaylist(filePaths);
    m_settings->saveMusicPaths(filePaths);

    const QString lastPath = QFileInfo(filePaths.first()).absolutePath();
    if (!lastPath.isEmpty()) {
        m_settings->saveLastPath(lastPath);
        const QUrl newFolder = QUrl::fromLocalFile(lastPath);
        if (m_lastFolder != newFolder) {
            m_lastFolder = newFolder;
            emit lastFolderChanged();
        }
    }
}

QStringList PlayerController::loadSavedPlaylist()
{
    QStringList savedPaths = m_settings->loadMusicPaths();
    if (!savedPaths.isEmpty()) {
        m_musicPlayer->setPlaylist(savedPaths);
        m_playlistModel->setPlaylist(savedPaths);
    }
    return savedPaths;
}

QUrl PlayerController::lastFolder() const
{
    return m_lastFolder;
}

// Private slots
void PlayerController::onPlaybackStateChanged(QMediaPlayer::PlaybackState state)
{
    Q_UNUSED(state)
    emit playingChanged();
    emit pausedChanged();
}

void PlayerController::onPositionChanged(qint64 pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged();
    }
}

void PlayerController::onDurationChanged(qint64 dur)
{
    if (m_duration != dur) {
        m_duration = dur;
        emit durationChanged();
    }
}

void PlayerController::onMusicStart(int index)
{
    Q_UNUSED(index)
    QString song = m_musicPlayer->currentSong();
    if (m_currentSong != song) {
        m_currentSong = song;
        emit currentSongChanged();
    }
    emit currentIndexChanged();
}

void PlayerController::onPlayerError(const QString &errorMessage)
{
    emit errorOccurred(errorMessage);
}
