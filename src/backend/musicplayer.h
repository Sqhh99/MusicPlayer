#ifndef MUSICPLAYER_H
#define MUSICPLAYER_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QList>
#include <QStringList>
#include <QUrl>

// 简单均衡器预设
enum EqualizerPreset {
    Flat,
    BassBoost,
    TrebleBoost,
    VocalBoost,
    RockPreset,
    PopPreset,
    ClassicalPreset,
    JazzPreset,
    Custom
};

class MusicPlayer : public QObject
{
    Q_OBJECT
public:
    explicit MusicPlayer(QObject *parent = nullptr);
    ~MusicPlayer() override;
    
    // 播放列表管理
    void setPlaylist(const QStringList &files);
    QStringList getPlaylist() const;
    void clearPlaylist();
    bool addToPlaylist(const QString &file);
    bool removeFromPlaylist(int index);
    
    // 播放控制
    void play();               // 播放音乐
    void play(int index);      // 播放指定索引的音乐
    void pause();              // 暂停音乐
    void stop();               // 停止音乐
    void next();               // 播放下一首
    void previous();           // 播放上一首
    
    // 音量控制
    void setVolume(int volume);      // 设置音量 (0-100)
    int volume() const;              // 获取音量
    void mute(bool muted = true);    // 静音或取消静音
    bool isMuted() const;            // 是否静音
    
    // 状态获取
    int currentIndex() const;         // 获取当前播放文件的索引
    qint64 position() const;          // 获取当前播放位置(毫秒)
    qint64 duration() const;          // 获取当前歌曲总时长(毫秒)
    QString currentSong() const;      // 获取当前播放歌曲名称
    bool isPlaying() const;           // 是否正在播放
    bool isPaused() const;            // 是否处于暂停状态
    
    // 播放模式控制
    void setLoop(bool loop);          // 设置循环播放
    bool getLoop() const;             // 获取循环播放状态
    void setShuffle(bool shuffle);    // 设置随机播放
    bool getShuffle() const;          // 获取随机播放状态
    
    // 均衡器控制
    void setEqualizerPreset(EqualizerPreset preset);  // 设置均衡器预设
    EqualizerPreset currentPreset() const;            // 获取当前均衡器预设
    void setCustomEqualizer(int bass, int mid, int treble); // 设置自定义均衡器
    
    // 均衡器频段级别访问
    int getBassLevel() const { return bassLevel; }    // 获取低音级别
    int getMidLevel() const { return midLevel; }      // 获取中音级别
    int getTrebleLevel() const { return trebleLevel; } // 获取高音级别
    
    // 公开播放器成员以便直接连接
    QMediaPlayer *player;

signals:
    void musicStart(int index);                      // 播放开始
    void musicCompletion(int index);                 // 播放完成
    void IdurationChanged(qint64 duration);          // 歌曲时长变化
    void IpositionChanged(qint64 position);          // 播放位置变化
    void playbackStateChanged(QMediaPlayer::PlaybackState state); // 播放状态改变
    void playlistChanged();                          // 播放列表变化
    void volumeChanged(int volume);                  // 音量变化
    void mutedChanged(bool muted);                   // 静音状态变化
    void playerError(const QString &errorMessage);   // 播放器错误
    void equalizerPresetChanged(EqualizerPreset preset); // 均衡器预设变化

private slots:
    void onMediaStatusChanged(QMediaPlayer::MediaStatus status);
    void onPlaybackStateChanged(QMediaPlayer::PlaybackState state);
    void onPlayerError(QMediaPlayer::Error error, const QString &errorString);

private:
    QAudioOutput *audioOutput;     // 音频输出
    QList<QUrl> mediaList;         // 播放列表
    int currentMediaIndex;         // 当前播放的文件索引
    bool loop;                     // 是否循环播放
    bool shuffle;                  // 是否随机播放
    EqualizerPreset currentEqPreset; // 当前均衡器预设
    int bassLevel;                 // 低音级别 (0-100)
    int midLevel;                  // 中音级别 (0-100)
    int trebleLevel;               // 高音级别 (0-100)
    QList<int> shuffleHistory;     // 随机播放历史
    int shuffleHistoryPosition;    // 随机播放历史位置

    void initConnections();        // 初始化内部连接
    void applyEqualizer();         // 应用均衡器设置
    int randomPlayableIndex() const;
    void recordShuffleIndex(int index);
};

#endif // MUSICPLAYER_H
