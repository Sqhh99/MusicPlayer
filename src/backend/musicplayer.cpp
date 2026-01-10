#include "musicplayer.h"
#include <QFileInfo>
#include <QMediaPlayer>
#include <QDebug>

MusicPlayer::MusicPlayer(QObject *parent) : QObject(parent), currentMediaIndex(0), loop(false), currentEqPreset(Flat), bassLevel(50), midLevel(50), trebleLevel(50)
{
    player = new QMediaPlayer(this);
    audioOutput = new QAudioOutput(this); // 创建音频输出对象

    player->setAudioOutput(audioOutput);
    initConnections();
}

void MusicPlayer::initConnections()
{
    connect(player, &QMediaPlayer::playbackStateChanged, this, &MusicPlayer::onPlaybackStateChanged);
    connect(player, &QMediaPlayer::mediaStatusChanged, this, &MusicPlayer::onMediaStatusChanged);
    connect(player, &QMediaPlayer::errorOccurred, this, &MusicPlayer::onPlayerError);

    connect(player, &QMediaPlayer::durationChanged, this, [this](qint64 duration){
        emit IdurationChanged(duration);
    });

    connect(player, &QMediaPlayer::positionChanged, this, [this](qint64 pos){
        emit IpositionChanged(pos);
    });
}

MusicPlayer::~MusicPlayer()
{
    delete player;
    delete audioOutput;
}

void MusicPlayer::setPlaylist(const QStringList &files)
{
    mediaList.clear();
    for (const QString &file : files) {
        mediaList.append(QUrl::fromLocalFile(file));
    }

    if (!mediaList.isEmpty()) {
        player->setSource(mediaList.at(0)); // 设置当前播放文件
    }
}

void MusicPlayer::play()
{
    if (!mediaList.isEmpty()) {
        player->play();
        emit musicStart(currentIndex());
    }
}

void MusicPlayer::play(int index)
{
    if (index >= 0 && index < mediaList.size()) {
        currentMediaIndex = index;
        player->setSource(mediaList.at(currentMediaIndex));
        this->play();
    }
}

void MusicPlayer::pause()
{
    player->pause();
}

void MusicPlayer::stop()
{
    player->stop();
}

void MusicPlayer::setVolume(int volume)
{
    if (!audioOutput) {
        return;
    }
    audioOutput->setVolume(volume / 100.0);
    emit volumeChanged(volume);
}

int MusicPlayer::volume() const
{
    return static_cast<int>(audioOutput->volume() * 100);
}

int MusicPlayer::currentIndex() const
{
    return currentMediaIndex;
}

void MusicPlayer::setLoop(bool loop)
{
    this->loop = loop;
}

bool MusicPlayer::getLoop() const
{
    return loop;
}

bool MusicPlayer::isPlaying() const
{
    return player && player->playbackState() == QMediaPlayer::PlayingState;
}

bool MusicPlayer::isPaused() const
{
    return player && player->playbackState() == QMediaPlayer::PausedState;
}

void MusicPlayer::onPlayerError(QMediaPlayer::Error error, const QString &errorString)
{
    Q_UNUSED(error);
    emit playerError(errorString);
}

void MusicPlayer::onMediaStatusChanged(QMediaPlayer::MediaStatus status)
{
    if (status == QMediaPlayer::EndOfMedia) {
        if (loop) {
            player->setPosition(0);
            player->play();
        } else {
            currentMediaIndex = (currentMediaIndex + 1) % mediaList.size();
            player->setSource(mediaList.at(currentMediaIndex));
            // Use this->play() to emit musicStart signal for proper song info update
            this->play();
        }
        emit musicCompletion(currentMediaIndex);
    }
}

void MusicPlayer::onPlaybackStateChanged(QMediaPlayer::PlaybackState state)
{
    emit playbackStateChanged(state);
}

void MusicPlayer::previous()
{
    if (mediaList.isEmpty()) return;
    currentMediaIndex = (currentMediaIndex - 1 + mediaList.size()) % mediaList.size();
    player->setSource(mediaList.at(currentMediaIndex));
    this->play();
}

void MusicPlayer::next()
{
    if (mediaList.isEmpty()) return;
    currentMediaIndex = (currentMediaIndex + 1) % mediaList.size();
    player->setSource(mediaList.at(currentMediaIndex));
    this->play();
}

QStringList MusicPlayer::getPlaylist() const
{
    QStringList result;
    for (const QUrl &url : mediaList) {
        result.append(url.toLocalFile());
    }
    return result;
}

void MusicPlayer::clearPlaylist()
{
    player->stop();
    mediaList.clear();
    currentMediaIndex = 0;
    emit playlistChanged();
}

bool MusicPlayer::addToPlaylist(const QString &file)
{
    QUrl url = QUrl::fromLocalFile(file);
    if (url.isValid()) {
        mediaList.append(url);
        emit playlistChanged();
        return true;
    }
    return false;
}

bool MusicPlayer::removeFromPlaylist(int index)
{
    if (index >= 0 && index < mediaList.size()) {
        if (index == currentMediaIndex) {
            player->stop();
            mediaList.removeAt(index);
            
            if (!mediaList.isEmpty()) {
                currentMediaIndex = currentMediaIndex % mediaList.size();
                player->setSource(mediaList.at(currentMediaIndex));
                player->play();
            } else {
                currentMediaIndex = 0;
            }
        } 
        else {
            mediaList.removeAt(index);
            if (index < currentMediaIndex) {
                currentMediaIndex--;
            }
        }
        emit playlistChanged();
        return true;
    }
    return false;
}

void MusicPlayer::mute(bool muted)
{
    if (audioOutput) {
        audioOutput->setMuted(muted);
        emit mutedChanged(muted);
    }
}

bool MusicPlayer::isMuted() const
{
    return audioOutput ? audioOutput->isMuted() : false;
}

qint64 MusicPlayer::position() const
{
    return player ? player->position() : 0;
}

qint64 MusicPlayer::duration() const
{
    return player ? player->duration() : 0;
}

QString MusicPlayer::currentSong() const
{
    if (currentMediaIndex >= 0 && currentMediaIndex < mediaList.size()) {
        QUrl url = mediaList.at(currentMediaIndex);
        return QFileInfo(url.toLocalFile()).fileName();
    }
    return QString();
}

void MusicPlayer::setEqualizerPreset(EqualizerPreset preset)
{
    currentEqPreset = preset;
    
    // 根据预设设置各频段级别
    switch (preset) {
        case Flat:
            bassLevel = 50;
            midLevel = 50;
            trebleLevel = 50;
            break;
            
        case BassBoost:
            bassLevel = 80;
            midLevel = 50;
            trebleLevel = 40;
            break;
            
        case TrebleBoost:
            bassLevel = 40;
            midLevel = 50;
            trebleLevel = 80;
            break;
            
        case VocalBoost:
            bassLevel = 40;
            midLevel = 80;
            trebleLevel = 60;
            break;
            
        case RockPreset:
            bassLevel = 65;
            midLevel = 45;
            trebleLevel = 70;
            break;
            
        case PopPreset:
            bassLevel = 55;
            midLevel = 70;
            trebleLevel = 65;
            break;
            
        case ClassicalPreset:
            bassLevel = 60;
            midLevel = 50;
            trebleLevel = 60;
            break;
            
        case JazzPreset:
            bassLevel = 60;
            midLevel = 55;
            trebleLevel = 70;
            break;
            
        case Custom:
            // 保持当前自定义设置
            break;
    }
    
    // 应用均衡器设置
    applyEqualizer();
    
    // 发送预设变化信号
    emit equalizerPresetChanged(preset);
}

EqualizerPreset MusicPlayer::currentPreset() const
{
    return currentEqPreset;
}

void MusicPlayer::setCustomEqualizer(int bass, int mid, int treble)
{
    // 限制在0-100范围内
    bassLevel = qBound(0, bass, 100);
    midLevel = qBound(0, mid, 100);
    trebleLevel = qBound(0, treble, 100);
    
    // 设置为自定义预设
    currentEqPreset = Custom;
    
    // 应用均衡器设置
    applyEqualizer();
    
    // 发送预设变化信号
    emit equalizerPresetChanged(Custom);
}

void MusicPlayer::applyEqualizer()
{
    // 在Qt 6中，我们可以使用QAudioOutput的API来设置均衡器
    // 但是Qt 6的均衡器API还不够完善，这里我们只是模拟实现
    
    if (!audioOutput) return;
    
    // 为不同的频率范围调整音量（如果有更高级的API可用）
    // 这里我们简单地将整体音量调整作为示例
    // 在实际项目中，您可能需要使用第三方库来实现真正的均衡器功能
    
    qDebug() << "应用均衡器设置: 低音=" << bassLevel << " 中音=" << midLevel << " 高音=" << trebleLevel;
    
    // 注意：实际的均衡器实现需要使用更高级的音频API
    // 可能需要Qt Multimedia Effects模块或第三方库
}
