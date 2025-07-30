#include "playwidget.h"
#include "ui_playwidget.h"
#include <QFileDialog>
#include <QSettings>
#include <QCloseEvent>
#include <QMenu>
#include <QPoint>
#include <QApplication>
#include <QMouseEvent>
#include <QScreen>
#include <QIcon>
#include <QDebug>
#include <QFile>
#include <QStyle>
#include <QStyleOption>
#include <QPainter>
#include <QFont>
#include <QPaintEvent>
#include <QGuiApplication>
#include <QMessageBox>
#include <QShortcut>
#include <QKeySequence>
#include <QTimer>

PlayWidget::PlayWidget(QWidget *parent)
    : QWidget(parent)
    , ui(new Ui::PlayWidget)
    , msettings(new MusicSettings(this))
    , musicPlayer(new MusicPlayer(this))
    , SysIcon(new QSystemTrayIcon(this))
    , min(nullptr)
    , restor(nullptr)
    , quit(nullptr)
    , menu(new QMenu(this))
    , playPauseAction(nullptr)
    , stopAction(nullptr)
    , nextAction(nullptr)
    , prevAction(nullptr)
    , muteAction(nullptr)
    , loopAction(nullptr)
    , volumeUpAction(nullptr)
    , volumeDownAction(nullptr)
    , showPlaylistAction(nullptr)
    , settingsAction(nullptr)
    , volumeMenu(nullptr)
    , playbackMenu(nullptr)
    , recentFilesMenu(nullptr)    , volumePopup(new VolumePopup(this))
    , playlistDelegate(new PlaylistItemDelegate(this))    , isAlwaysOnTop(false)
    , isDragging(false)
    , isSliderDragging(false)
    , progressSyncTimer(new QTimer(this))
    , titleBarLayout(nullptr)
    , minimizeButton(nullptr)
    , closeButton(nullptr)
    , alwaysOnTopButton(nullptr)
    // 缓冲指示器初始化已移除
    , playPauseShortcut(nullptr)
    , nextShortcut(nullptr)
    , prevShortcut(nullptr)
    , volumeUpShortcut(nullptr)
    , volumeDownShortcut(nullptr)
    , muteShortcut(nullptr)
    , togglePlaylistShortcut(nullptr)
    , equalizerShortcut(nullptr)
    , equalizerAction(nullptr)
    , equalizerDialog(nullptr)
    , notificationLabel(nullptr)
    , notificationTimer(new QTimer(this))
{
    // 设置无边框窗口并支持透明度
    setWindowFlags(Qt::Window | Qt::FramelessWindowHint);
    setAttribute(Qt::WA_TranslucentBackground);
    
    ui->setupUi(this);
    loadIcons();
    setupTitleBar();
    
    // 加载样式文件
    loadStyles();
    
    // 设置自定义列表代理
    if (ui->listWidget) {
        ui->listWidget->setItemDelegate(playlistDelegate);
    }

    this->initConn();

    int initialVolume = 80;
    if (musicPlayer) {
        initialVolume = musicPlayer->volume();
    }
    if (volumePopup) {
        volumePopup->setVolume(initialVolume);
    }
    
    loadPlaylist();

    // 设置系统托盘
    setupTrayMenu();
    if (SysIcon) {
        SysIcon->setIcon(QIcon(":/tubiao/listen1.ico"));
    SysIcon->show();
    }

    qApp->installEventFilter(this);

    setupInitialUI();
    updateTrayTooltip();
    
    // 设置缓冲指示器
    // setupBufferingIndicator(); // 已移除缓冲指示器功能

    // 设置键盘快捷键
    setupShortcuts();

    // 初始化通知系统
    notificationLabel = new QLabel(this);
    notificationLabel->setAlignment(Qt::AlignCenter);
    notificationLabel->setStyleSheet(
        "QLabel { "
        "  background-color: #323232; "
        "  color: white; "
        "  border-radius: 10px; "
        "  padding: 12px; "
        "  font-size: 12px; "
        "  border: 1px solid #444444; "
        "}"
    );
    notificationLabel->hide();
    
    // 设置通知计时器
    notificationTimer->setSingleShot(true);
    connect(notificationTimer, &QTimer::timeout, this, &PlayWidget::hideNotification);
    
    // 设置进度条同步定时器 - 每500ms检查一次进度条同步状态
    progressSyncTimer->setInterval(500);
    connect(progressSyncTimer, &QTimer::timeout, this, [this]() {
        // 只有在播放状态且用户没有拖动进度条时才同步
        if (musicPlayer && musicPlayer->player && musicPlayer->isPlaying() && !isSliderDragging && ui->playCourseSlider) {
            qint64 currentPos = musicPlayer->player->position();
            // 只有当位置差异较大时才更新，避免频繁更新
            if (qAbs(ui->playCourseSlider->value() - currentPos) > 1000) {
                ui->playCourseSlider->setValue(currentPos);
            }
        }
    });
    
    // 在有播放器实例时启动定时器
    if (musicPlayer) {
        progressSyncTimer->start();
    }
}

void PlayWidget::setupTitleBar()
{
    // 创建水平布局
    titleBarLayout = new QHBoxLayout();
    titleBarLayout->setSpacing(8);
    titleBarLayout->setContentsMargins(0, 0, 8, 0);
    
    // 创建窗口控制按钮
    minimizeButton = new QPushButton(this);
    closeButton = new QPushButton(this);
    alwaysOnTopButton = new QPushButton(this);
    
    // 设置按钮尺寸
    int buttonSize = 20;
    minimizeButton->setFixedSize(buttonSize, buttonSize);
    closeButton->setFixedSize(buttonSize, buttonSize);
    alwaysOnTopButton->setFixedSize(buttonSize, buttonSize);
    
    // 设置按钮样式和图标
    minimizeButton->setStyleSheet(
        "QPushButton { background-color: transparent; border: none; }");
    minimizeButton->setIcon(QIcon(":/tubiao/zuixiaohua.png"));
    minimizeButton->setIconSize(QSize(16, 16));
    
    closeButton->setStyleSheet(
        "QPushButton { background-color: transparent; border: none; color: #444444; font-weight: bold; }"
        "QPushButton:hover { color: #ff0000; }");
    closeButton->setText("×");
    closeButton->setFont(QFont("Arial", 12, QFont::Bold));
    
    // 使用图标表示置顶/取消置顶
    alwaysOnTopButton->setStyleSheet(
        "QPushButton { background-color: transparent; border: none; }");
    alwaysOnTopButton->setIcon(pinOffIcon);
    alwaysOnTopButton->setIconSize(QSize(16, 16));
    
    // 设置提示文字
    minimizeButton->setToolTip("最小化");
    closeButton->setToolTip("关闭");
    alwaysOnTopButton->setToolTip("置顶窗口");
    
    // 连接槽函数
    connect(minimizeButton, &QPushButton::clicked, this, &PlayWidget::onMinimizeButtonClicked);
    connect(closeButton, &QPushButton::clicked, this, &PlayWidget::onCloseButtonClicked);
    connect(alwaysOnTopButton, &QPushButton::clicked, this, &PlayWidget::onAlwaysOnTopButtonClicked);
    
    // 添加到布局
    titleBarLayout->addStretch();
    titleBarLayout->addWidget(alwaysOnTopButton);
    titleBarLayout->addWidget(minimizeButton);
    titleBarLayout->addWidget(closeButton);
    
    // 在现有布局中查找并修改currentSongLabel所在的布局
    if (ui->currentSongLabel) {
        QLayout* parentLayout = ui->currentSongLabel->parentWidget()->layout();
        if (parentLayout) {
            // 将标签从原始布局中移除
            parentLayout->removeWidget(ui->currentSongLabel);
            
            // 创建新的水平布局来包含标签和控制按钮
            QHBoxLayout* titleRowLayout = new QHBoxLayout();
            titleRowLayout->setContentsMargins(5, 5, 5, 5);
            titleRowLayout->setSpacing(0);
            
            // 添加标签和按钮布局
            titleRowLayout->addWidget(ui->currentSongLabel, 1); // 1表示伸展因子，让标签占据剩余空间
            titleRowLayout->addLayout(titleBarLayout);
            
            // 将新布局加入到原来的位置
            QVBoxLayout* mainLayout = qobject_cast<QVBoxLayout*>(parentLayout);
            if (mainLayout) {
                // 在原来标签的位置插入新布局
                mainLayout->insertLayout(0, titleRowLayout);
            }
        }
    }
}

void PlayWidget::loadIcons() {
    playIcon.addFile(QStringLiteral(":/tubiao/pause01.png"), QSize(), QIcon::Normal, QIcon::Off);
    pauseIcon.addFile(QStringLiteral(":/tubiao/player01.png"), QSize(), QIcon::Normal, QIcon::Off);
    
    playlistHiddenIcon.addFile(QStringLiteral(":/tubiao/playlist_icon.png"), QSize(), QIcon::Normal, QIcon::Off);
    playlistVisibleIcon.addFile(QStringLiteral(":/tubiao/playlist_icon_active.png"), QSize(), QIcon::Normal, QIcon::Off);
    
    // 使用新的窗口控制图标
    pinOnIcon.addFile(QStringLiteral(":/tubiao/yizhiding.png"), QSize(), QIcon::Normal, QIcon::Off);
    pinOffIcon.addFile(QStringLiteral(":/tubiao/zhiding.png"), QSize(), QIcon::Normal, QIcon::Off);
}

void PlayWidget::extracted(QStringList &filePaths) {
    if (ui->listWidget) {
        ui->listWidget->clear();
        for (const QString &filePath : filePaths) {
            QString fileName = QFileInfo(filePath).fileName();
            ui->listWidget->addItem(fileName);
        }
    }
}

void PlayWidget::onOpenFileBtnClicked()
{
    if (!msettings || !musicPlayer) return;

    QStringList filePaths = QFileDialog::getOpenFileNames(this, 
                                                        tr("Open Music Files"), 
                                                        msettings->loadLastPath(),
                                                        tr("Music Files (*.mp3 *.flac *.wav *.m4a *.ogg *.oga *.aac *.opus *.wma *.3gp *.mp4 *.mov *.avi *.mkv *.webm);;Audio Files (*.mp3 *.flac *.wav *.m4a *.ogg *.oga *.aac *.opus *.wma);;Video Files (*.mp4 *.mov *.avi *.mkv *.webm *.3gp);;All Files (*)"));

    if (!filePaths.isEmpty()) {
        if (ui->listWidget) ui->listWidget->clear();
        musicPlayer->setPlaylist(filePaths);
        extracted(filePaths);
        if (ui->listWidget && ui->listWidget->count() > 0) {
             ui->listWidget->setCurrentRow(0);
        }
        msettings->saveMusicPaths(filePaths);
        msettings->saveLastPath(QFileInfo(filePaths.first()).absolutePath());
        
        // Optionally, start playing the first loaded song
        // musicPlayer->play(0);
    }
}

void PlayWidget::onTogglePlaylistBtnClicked()
{
    if (!ui->playlistWidget || !ui->togglePlaylistBtn) return;

    bool isVisible = ui->playlistWidget->isVisible();
    ui->playlistWidget->setVisible(!isVisible);

    // 确保先清除样式表，然后设置图标
    ui->togglePlaylistBtn->setStyleSheet("");

    if (!isVisible) {
        ui->togglePlaylistBtn->setIcon(playlistVisibleIcon);
        ui->togglePlaylistBtn->setToolTip("隐藏播放列表 (L键)");
        
        // 同步系统托盘中的播放列表显示选项
        if (showPlaylistAction) {
            showPlaylistAction->setChecked(true);
            showPlaylistAction->setText("隐藏播放列表");
        }
    } else {
        ui->togglePlaylistBtn->setIcon(playlistHiddenIcon);
        ui->togglePlaylistBtn->setToolTip("显示播放列表 (L键)");
        
        // 同步系统托盘中的播放列表显示选项
        if (showPlaylistAction) {
            showPlaylistAction->setChecked(false);
            showPlaylistAction->setText("显示播放列表");
        }
    }
    adjustSize();
}

void PlayWidget::onprevBtn() { if (musicPlayer) musicPlayer->previous(); }

void PlayWidget::onnextBtn() { if (musicPlayer) musicPlayer->next(); }

void PlayWidget::onplayBtn()
{
    if (!musicPlayer) return;
    if (musicPlayer->isPlaying()) {
        musicPlayer->pause();
    } else {
        musicPlayer->play();
    }
}

void PlayWidget::onmodelBtn()
{
    if (!musicPlayer || !ui->modelBtn) return;

    // 先清除样式表
    ui->modelBtn->setStyleSheet("");
    
    if (musicPlayer->getLoop()) {
        musicPlayer->setLoop(false);
        ui->modelBtn->setIcon(QIcon(":/tubiao/ShunxuBof3.png"));
        ui->modelBtn->setToolTip("Sequential Play");
        
        // 同步系统托盘中的循环播放选项
        if (loopAction) {
            loopAction->setChecked(false);
        }
    } else {
        musicPlayer->setLoop(true);
        ui->modelBtn->setIcon(QIcon(":/tubiao/xunhuanbof2.png"));
        ui->modelBtn->setToolTip("Loop Play");
        
        // 同步系统托盘中的循环播放选项
        if (loopAction) {
            loopAction->setChecked(true);
        }
    }
}

void PlayWidget::onPlaybackStateChanged(QMediaPlayer::PlaybackState state)
{
    if (!ui->playBtn) return;
    switch (state) {
    case QMediaPlayer::PlayingState:
        qDebug() << "PlaybackState: Playing - Setting PAUSE icon";
        ui->playBtn->setIcon(pauseIcon);
        ui->playBtn->setToolTip("暂停 (空格键)");
        
        // 确保当前播放的歌曲名称显示
        if (ui->currentSongLabel && musicPlayer) {
            int index = musicPlayer->currentIndex();
            if (index >= 0 && ui->listWidget && index < ui->listWidget->count()) {
                QString songName = ui->listWidget->item(index)->text();
                ui->currentSongLabel->setText(songName);
            }
        }
        
        // 更新系统托盘
        updateTrayIcon();
        updateTrayTooltip();
        if (playPauseAction) {
            playPauseAction->setText("暂停");
            playPauseAction->setIcon(pauseIcon);
        }
        break;
    case QMediaPlayer::PausedState:
        qDebug() << "PlaybackState: Paused - Setting PLAY icon";
        ui->playBtn->setIcon(playIcon);
        ui->playBtn->setToolTip("播放 (空格键)");
        
        // 更新系统托盘
        updateTrayIcon();
        updateTrayTooltip();
        if (playPauseAction) {
            playPauseAction->setText("播放");
            playPauseAction->setIcon(playIcon);
        }
        break;
    case QMediaPlayer::StoppedState:
        qDebug() << "PlaybackState: Stopped - Setting PLAY icon";
        ui->playBtn->setIcon(playIcon);
        ui->playBtn->setToolTip("播放 (空格键)");
        // 停止时不清空歌曲名称，保持显示当前选中的歌曲
        // 如果当前没有显示歌曲名称且有播放列表，则显示第一首歌
        if (ui->currentSongLabel && ui->currentSongLabel->text().isEmpty() && ui->listWidget && ui->listWidget->count() > 0) {
            int currentRow = ui->listWidget->currentRow();
            if (currentRow >= 0) {
                QString songName = ui->listWidget->item(currentRow)->text();
                ui->currentSongLabel->setText(songName);
            } else {
                QString songName = ui->listWidget->item(0)->text();
                ui->currentSongLabel->setText(songName);
                ui->listWidget->setCurrentRow(0);
            }
        }
        
        // 更新系统托盘
        updateTrayIcon();
        updateTrayTooltip();
        if (playPauseAction) {
            playPauseAction->setText("播放");
            playPauseAction->setIcon(playIcon);
        }
        break;
    default:
        qDebug() << "PlaybackState: Unknown or Other";
        break;
    }
}

void PlayWidget::onActivatedSysTrayIcon(QSystemTrayIcon::ActivationReason reason)
{
    switch (reason) {
    case QSystemTrayIcon::Trigger:
        // 单击系统托盘图标显示/隐藏主窗口
        if (isVisible()) {
            hide();
        } else {
            showNormal();
            activateWindow();
            raise();
        }
        break;
    case QSystemTrayIcon::DoubleClick:
        showNormal();
        activateWindow();
        raise();
        break;
    case QSystemTrayIcon::MiddleClick:
        // 中键点击切换播放/暂停状态
        onTrayPlayPauseAction();
        break;
    default:
        break;
    }
}

void PlayWidget::onVolumeBtn()
{
    if (!volumePopup || !ui->volumeBtn) return;

    // 获取音量按钮的中心位置
        QPoint buttonGlobalPos = ui->volumeBtn->mapToGlobal(QPoint(ui->volumeBtn->width() / 2, 0));
        
    // 更新音量值并显示弹出窗口
    if (musicPlayer) {
        volumePopup->setVolume(musicPlayer->volume());
    }
    volumePopup->showPopup(buttonGlobalPos);
}

void PlayWidget::onVolumeChanged(int value)
{
    if (musicPlayer) {
        musicPlayer->setVolume(value);
    }
}

void PlayWidget::initConn()
{
    // UI 按钮连接
    QList<QPair<QPushButton*, void (PlayWidget::*)()>> buttonConnections = {
        {ui->openFileBtn, &PlayWidget::onOpenFileBtnClicked},
        {ui->togglePlaylistBtn, &PlayWidget::onTogglePlaylistBtnClicked},
        {ui->modelBtn, &PlayWidget::onmodelBtn},
        {ui->prevBtn, &PlayWidget::onprevBtn},
        {ui->nextBtn, &PlayWidget::onnextBtn},
        {ui->playBtn, &PlayWidget::onplayBtn},
        {ui->volumeBtn, &PlayWidget::onVolumeBtn}
    };
    
    for (const auto &conn : buttonConnections) {
        if (conn.first) {
            connect(conn.first, &QPushButton::clicked, this, conn.second);
        }
    }
    
    // 音量弹窗连接
    if (volumePopup) {
        connect(volumePopup, &VolumePopup::volumeChanged, this, &PlayWidget::onVolumeChanged);
    }

    // 音乐播放器连接
    if (musicPlayer) {
        // 播放状态变化
        connect(musicPlayer, &MusicPlayer::playbackStateChanged, this, &PlayWidget::onPlaybackStateChanged);
        
        // 持续时间和位置更新
        connect(musicPlayer, &MusicPlayer::IdurationChanged, this, [this](qint64 duration) {
            if (ui->totalLibel) {
                ui->totalLibel->setText(QString("%1:%2")
                    .arg(duration/1000/60, 2, 10, QChar('0'))
                    .arg(duration/1000%60, 2, 10, QChar('0')));
            }
            if (ui->playCourseSlider) {
                ui->playCourseSlider->setRange(0, duration);
            }
        });        connect(musicPlayer, &MusicPlayer::IpositionChanged, this, [this](qint64 pos) {
            if (ui->curLabel) {
                ui->curLabel->setText(QString("%1:%2")
                    .arg(pos/1000/60, 2, 10, QChar('0'))
                    .arg(pos/1000%60, 2, 10, QChar('0')));
            }
            // 只有在用户没有拖动进度条时才更新进度条位置
            if (ui->playCourseSlider && !isSliderDragging) {
                ui->playCourseSlider->setValue(pos);
            }
        });
        
        // 播放列表交互
        if (ui->listWidget) {
            // 双击播放
            connect(ui->listWidget, &QListWidget::itemDoubleClicked, this, [this](QListWidgetItem *item) {
                int index = ui->listWidget->row(item);
                if (musicPlayer) musicPlayer->play(index);
            });
            
            // 单击选择（不播放）
            connect(ui->listWidget, &QListWidget::itemClicked, this, [this](QListWidgetItem *item) {
                if (ui->currentSongLabel) {
                    ui->currentSongLabel->setText(item->text());
                }
            });
            
            // 音乐开始播放时，同步更新列表选择和标题
            connect(musicPlayer, &MusicPlayer::musicStart, this, [this](int index) {
                if (ui->listWidget && index >= 0 && index < ui->listWidget->count()) {
                    ui->listWidget->setCurrentRow(index);
                    
                    if (ui->currentSongLabel) {
                        ui->currentSongLabel->setText(ui->listWidget->item(index)->text());
                    }
                    
                    // 更新系统托盘提示信息
                    updateTrayTooltip();
                } else if (ui->currentSongLabel) {
                    ui->currentSongLabel->clear();
                }
            });
        }        // 进度条拖动
        if (ui->playCourseSlider && musicPlayer->player) {
            // 用户开始拖动进度条
            connect(ui->playCourseSlider, &QSlider::sliderPressed, this, [this]() {
                isSliderDragging = true;
            });
            
            // 用户释放进度条
            connect(ui->playCourseSlider, &QSlider::sliderReleased, this, [this]() {
                isSliderDragging = false;
                // 释放时设置播放位置
                if (musicPlayer && musicPlayer->player) {
                    musicPlayer->player->setPosition(ui->playCourseSlider->value());
                }
            });
            
            // 拖动过程中实时更新时间显示（但不设置播放位置）
            connect(ui->playCourseSlider, &QSlider::sliderMoved, this, [this](int value) {
                if (ui->curLabel) {
                    ui->curLabel->setText(QString("%1:%2")
                        .arg(value/1000/60, 2, 10, QChar('0'))
                        .arg(value/1000%60, 2, 10, QChar('0')));
                }
            });
        }

        // 连接媒体状态变化信号
        if (musicPlayer && musicPlayer->player) {
            connect(musicPlayer->player, &QMediaPlayer::mediaStatusChanged, 
                    this, &PlayWidget::onMediaStatusChanged);
            
            // 连接播放器错误信号，在错误时重置进度条状态
            connect(musicPlayer->player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error error, const QString &errorString) {
                Q_UNUSED(error)
                qDebug() << "Player error occurred:" << errorString;
                // 重置进度条拖动状态
                isSliderDragging = false;
                // 重置进度条位置
                if (ui->playCourseSlider) {
                    ui->playCourseSlider->setValue(0);
                }
                if (ui->curLabel) {
                    ui->curLabel->setText("00:00");
                }
            });
        }
    }

    // 系统托盘图标连接
    if (SysIcon) {
        connect(SysIcon, &QSystemTrayIcon::activated, this, &PlayWidget::onActivatedSysTrayIcon);
    }
}

void PlayWidget::closeEvent(QCloseEvent *event)
{
    if (!event) return;
    
    if (SysIcon && SysIcon->isVisible()) {
        // 点击关闭按钮时隐藏窗口而不是退出应用
        hide();
        event->ignore();
    } else {
        event->accept();
    }
}

bool PlayWidget::eventFilter(QObject *watched, QEvent *event)
{
    if (!event) return false;
    
    // 处理音量弹窗的点击事件
    if (event->type() == QEvent::MouseButtonPress) {
            QMouseEvent *mouseEvent = static_cast<QMouseEvent*>(event);
        if (!mouseEvent) return false;
        
        if (volumePopup && volumePopup->isVisible()) {
            // 点击在音量弹窗外部时隐藏弹窗（除非点击在音量按钮上）
            if (!volumePopup->geometry().contains(mouseEvent->globalPos())) {
                if (ui->volumeBtn && !ui->volumeBtn->geometry().contains(
                        ui->volumeBtn->mapFromGlobal(mouseEvent->globalPos()))) {
                    volumePopup->hide();
                    return true; // 事件已处理
                }
            }
        }
    }
    
    return QWidget::eventFilter(watched, event);
}

void PlayWidget::onMinimizeButtonClicked()
{
    showMinimized();
}

void PlayWidget::onCloseButtonClicked()
{
    close();
}

void PlayWidget::onAlwaysOnTopButtonClicked()
{
    isAlwaysOnTop = !isAlwaysOnTop;
    
    if (isAlwaysOnTop) {
        setWindowFlags(windowFlags() | Qt::WindowStaysOnTopHint);
        alwaysOnTopButton->setIcon(pinOnIcon);
        alwaysOnTopButton->setToolTip("取消置顶");
    } else {
        setWindowFlags(windowFlags() & ~Qt::WindowStaysOnTopHint);
        alwaysOnTopButton->setIcon(pinOffIcon);
        alwaysOnTopButton->setToolTip("置顶窗口");
    }
    
    // 需要重新显示窗口以应用标志更改
    show();
}

void PlayWidget::mousePressEvent(QMouseEvent *event)
{
    if (!event) return;
    
    if (event->button() == Qt::LeftButton) {
        isDragging = true;
        dragStartPosition = event->globalPos() - frameGeometry().topLeft();
        event->accept();
    } else {
        QWidget::mousePressEvent(event);
    }
}

void PlayWidget::mouseMoveEvent(QMouseEvent *event)
{
    if (!event) return;
    
    if (isDragging && (event->buttons() & Qt::LeftButton)) {
        // 计算新位置并移动窗口
        QPoint newPos = event->globalPos() - dragStartPosition;
        
        // 可选：限制窗口在屏幕内
        QRect screenGeometry = QGuiApplication::primaryScreen()->availableGeometry();
        int x = qBound(screenGeometry.left(), newPos.x(), screenGeometry.right() - width());
        int y = qBound(screenGeometry.top(), newPos.y(), screenGeometry.bottom() - height());
        
        move(x, y);
        event->accept();
    } else {
        QWidget::mouseMoveEvent(event);
    }
}

void PlayWidget::mouseReleaseEvent(QMouseEvent *event)
{
    if (!event) return;
    
    if (event->button() == Qt::LeftButton) {
        isDragging = false;
        event->accept();
    } else {
        QWidget::mouseReleaseEvent(event);
    }
}

void PlayWidget::paintEvent(QPaintEvent *event)
{
    // 绘制窗口背景和边框
    QStyleOption opt;
    opt.initFrom(this);
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing); // 抗锯齿
    style()->drawPrimitive(QStyle::PE_Widget, &opt, &painter, this);
    
    QWidget::paintEvent(event);
}

PlayWidget::~PlayWidget()
{
    // 停止定时器
    if (progressSyncTimer) {
        progressSyncTimer->stop();
    }
    if (notificationTimer) {
        notificationTimer->stop();
    }
    
    // 移除事件过滤器
    if (qApp) {
        qApp->removeEventFilter(this);
    }
    
    // 断开所有连接
    if (musicPlayer) {
        disconnect(musicPlayer, nullptr, this, nullptr);
    }
    
    if (volumePopup) {
        disconnect(volumePopup, nullptr, this, nullptr);
    }
    
    // 清理系统托盘
    if (SysIcon) {
        SysIcon->hide();
        disconnect(SysIcon, nullptr, this, nullptr);
    }
    
    // 删除UI
    delete ui;
    ui = nullptr;
}

// 新增方法：加载样式文件
bool PlayWidget::loadStyleFile(const QString &path, QWidget *target)
{
    QFile styleFile(path);
    if (!styleFile.exists()) {
        qDebug() << "Style file does not exist:" << path;
        return false;
    }
    
    if (!styleFile.open(QFile::ReadOnly)) {
        qDebug() << "Could not open style file:" << path << "Error:" << styleFile.errorString();
        return false;
    }
    
    QString styleSheet = QLatin1String(styleFile.readAll());
    styleFile.close();
    
    if (styleSheet.isEmpty()) {
        qDebug() << "Style file is empty:" << path;
        return false;
    }
    
    if (target) {
        target->setStyleSheet(styleSheet);
    } else {
        // 应用到全局
        qApp->setStyleSheet(qApp->styleSheet() + "\n" + styleSheet);
    }
    
    qDebug() << "Applied style from" << path << (target ? "to widget" : "to application");
    return true;
}

void PlayWidget::showError(const QString &title, const QString &message)
{
    QMessageBox::critical(this, title, message);
}

void PlayWidget::loadStyles()
{
    // 应用滚动条样式
    if (!loadStyleFile("styles/scrollbar.qss")) {
        qDebug() << "Failed to load scrollbar style";
    }
    
    // 应用滑块样式
    if (ui->playCourseSlider) {
        if (!loadStyleFile("styles/slider.qss", ui->playCourseSlider)) {
            qDebug() << "Failed to load slider style";
        }
    }
    
    // 设置主窗口样式 - 使用纯色而非透明色
    setStyleSheet(
        "PlayWidget { "
        "  background-color: #f0f0f0; "
        "  border-radius: 8px; "
        "  border: 1px solid #e0e0e0; "
        "}"
        "QWidget#playerWidget { "
        "  background-color: #f0f0f0; "
        "}"
        "QWidget#playlistWidget { "
        "  background-color: #f5f5f5; "
        "}"
        "QLabel#currentSongLabel { "
        "  color: #303030; "
        "  font-weight: 500; "
        "  font-size: 10pt; "
        "  padding-bottom: 4px; "
        "  padding-left: 8px; "
        "}"
        "QPushButton { "
        "  background-color: #f0f0f0; "
        "  border-radius: 18px; "
        "}"
        "QPushButton:hover { "
        "  background-color: #e0e0e0; "
        "}"
        "QPushButton:pressed { "
        "  background-color: #c8c8c8; "
        "}"
        "QListWidget { "
        "  background-color: #fafafa; "
        "  border: none; "
        "}"
        "QListWidget::item:selected { "
        "  background-color: #c8f0dc; "
        "}"
        "QListWidget::item:hover { "
        "  background-color: #f0f0f0; "
        "}"
    );
}

// 新增方法：加载播放列表
void PlayWidget::loadPlaylist()
{
    if (!msettings || !musicPlayer) return;
    
    QStringList filePaths = msettings->loadMusicPaths();
    if (!filePaths.isEmpty()) {
        this->extracted(filePaths);
        if (ui->listWidget && ui->listWidget->count() != 0) {
            ui->listWidget->setCurrentRow(0);
            
            // 启动时显示第一首歌曲的名称
            if (ui->currentSongLabel && ui->listWidget->count() > 0) {
                QString songName = ui->listWidget->item(0)->text();
                ui->currentSongLabel->setText(songName);
            }
        }
        if (musicPlayer) musicPlayer->setPlaylist(filePaths);
    }
}

// 新增方法：设置初始UI状态
void PlayWidget::setupInitialUI()
{
    // 图标大小设置为20x20，适合按钮
    const QSize iconSize(20, 20);
    
    // 清除按钮的样式表，避免重叠问题
    if (ui->playBtn) {
        ui->playBtn->setStyleSheet("");
        ui->playBtn->setIcon(playIcon);
        ui->playBtn->setToolTip("播放/暂停 (空格键)");
        ui->playBtn->setIconSize(iconSize);
    }
    
    if (ui->togglePlaylistBtn) {
        ui->togglePlaylistBtn->setStyleSheet("");
        ui->togglePlaylistBtn->setIcon(playlistHiddenIcon);
        ui->togglePlaylistBtn->setToolTip("显示/隐藏播放列表 (L键)");
        ui->togglePlaylistBtn->setIconSize(iconSize);
    }
    
    if (ui->prevBtn) {
        ui->prevBtn->setStyleSheet("");
        ui->prevBtn->setIcon(QIcon(":/tubiao/icon_previous.png"));
        ui->prevBtn->setToolTip("上一首 (左箭头)");
        ui->prevBtn->setIconSize(iconSize);
    }
    
    if (ui->nextBtn) {
        ui->nextBtn->setStyleSheet("");
        ui->nextBtn->setIcon(QIcon(":/tubiao/icon_next.png"));
        ui->nextBtn->setToolTip("下一首 (右箭头)");
        ui->nextBtn->setIconSize(iconSize);
    }
    
    if (ui->volumeBtn) {
        ui->volumeBtn->setStyleSheet("");
        ui->volumeBtn->setIcon(QIcon(":/tubiao/player_volume_increase.png"));
        ui->volumeBtn->setToolTip("音量控制 (上/下箭头, M键静音)");
        ui->volumeBtn->setIconSize(iconSize);
    }
    
    if (ui->openFileBtn) {
        ui->openFileBtn->setStyleSheet("");
        ui->openFileBtn->setIcon(QIcon(":/tubiao/File1.png"));
        ui->openFileBtn->setIconSize(iconSize);
    }
    
    if (ui->modelBtn) {
        ui->modelBtn->setStyleSheet("");
        if (musicPlayer && musicPlayer->getLoop()) {
            ui->modelBtn->setIcon(QIcon(":/tubiao/xunhuanbof2.png"));
        } else {
            ui->modelBtn->setIcon(QIcon(":/tubiao/ShunxuBof3.png"));
        }
        ui->modelBtn->setIconSize(iconSize);
    }

    // 禁用列表项的文本选择和焦点框
    if (ui->listWidget) {
        // 禁用文本选择
        ui->listWidget->setSelectionMode(QAbstractItemView::SingleSelection);
        // 禁用焦点边框
        ui->listWidget->setFocusPolicy(Qt::NoFocus);
        // 禁用文本交互
        ui->listWidget->setTextElideMode(Qt::ElideNone);
    }

    if (ui->playlistWidget && !ui->playlistWidget->isVisible()) {
        adjustSize();
    }
}

void PlayWidget::setupTrayMenu()
{
    if (!menu || !SysIcon) return;
    
    // 1. 清空旧菜单
    menu->clear();
    
    // 2. 创建菜单标题
    QAction* titleAction = new QAction("音乐播放器", this);
    titleAction->setIcon(QIcon(":/tubiao/listen1.ico"));
    QFont titleFont = titleAction->font();
    titleFont.setBold(true);
    titleAction->setFont(titleFont);
    titleAction->setEnabled(false);
    
    // 3. 创建播放控制子菜单
    playbackMenu = new QMenu("播放控制", this);
    playbackMenu->setIcon(QIcon(":/tubiao/player01.png"));
    
    // 播放/暂停动作
    playPauseAction = new QAction(this);
    if (musicPlayer && musicPlayer->isPlaying()) {
        playPauseAction->setText("暂停");
        playPauseAction->setIcon(pauseIcon);
    } else {
        playPauseAction->setText("播放");
        playPauseAction->setIcon(playIcon);
    }
    
    // 其他播放控制动作
    stopAction = new QAction("停止", this);
    stopAction->setIcon(QIcon(":/tubiao/player02.png"));
    
    prevAction = new QAction("上一首", this);
    prevAction->setIcon(QIcon(":/tubiao/icon_previous.png"));
    
    nextAction = new QAction("下一首", this);
    nextAction->setIcon(QIcon(":/tubiao/icon_next.png"));
    
    // 循环播放设置
    loopAction = new QAction("循环播放", this);
    loopAction->setCheckable(true);
    loopAction->setIcon(QIcon(":/tubiao/xunhuanbof2.png"));
    if (musicPlayer) {
        loopAction->setChecked(musicPlayer->getLoop());
    }
    
    // 添加到播放控制子菜单
    playbackMenu->addAction(playPauseAction);
    playbackMenu->addAction(stopAction);
    playbackMenu->addSeparator();
    playbackMenu->addAction(prevAction);
    playbackMenu->addAction(nextAction);
    playbackMenu->addSeparator();
    playbackMenu->addAction(loopAction);
    
    // 4. 创建音量控制子菜单
    volumeMenu = new QMenu("音量控制", this);
    volumeMenu->setIcon(QIcon(":/tubiao/player_volume_increase.png"));
    
    muteAction = new QAction("静音", this);
    muteAction->setCheckable(true);
    muteAction->setIcon(QIcon(":/tubiao/player_volume_increase.png"));
    if (musicPlayer && musicPlayer->isMuted()) {
        muteAction->setChecked(true);
        muteAction->setText("取消静音");
    }
    
    volumeUpAction = new QAction("增加音量", this);
    volumeUpAction->setIcon(QIcon(":/tubiao/yin-liang-jia.png"));
    volumeDownAction = new QAction("减小音量", this);
    volumeDownAction->setIcon(QIcon(":/tubiao/yin-liang-jian.png"));
    
    // 添加到音量子菜单
    volumeMenu->addAction(muteAction);
    volumeMenu->addSeparator();
    volumeMenu->addAction(volumeUpAction);
    volumeMenu->addAction(volumeDownAction);
    
    // 5. 创建最近文件子菜单
    recentFilesMenu = new QMenu("最近文件", this);
    recentFilesMenu->setIcon(QIcon(":/tubiao/File1.png"));
    
    // 添加最近文件
    if (ui->listWidget && ui->listWidget->count() > 0) {
        for (int i = 0; i < ui->listWidget->count() && i < 5; i++) {
            QAction* fileAction = new QAction(ui->listWidget->item(i)->text(), this);
            int index = i; // 捕获索引
            connect(fileAction, &QAction::triggered, this, [this, index]() {
                if (musicPlayer) musicPlayer->play(index);
            });
            recentFilesMenu->addAction(fileAction);
        }
    } else {
        QAction* noFilesAction = new QAction("没有最近播放的文件", this);
        noFilesAction->setEnabled(false);
        recentFilesMenu->addAction(noFilesAction);
    }
    
    // 7. 创建其他动作
    min = new QAction("最小化窗口", this);
    min->setIcon(QIcon(":/tubiao/zuixiaohua.png"));
    
    restor = new QAction("显示主窗口", this);
    restor->setIcon(QIcon(":/tubiao/show.png"));
    
    showPlaylistAction = new QAction("显示播放列表", this);
    showPlaylistAction->setCheckable(true);
    if (ui->playlistWidget && ui->playlistWidget->isVisible()) {
        showPlaylistAction->setChecked(true);
        showPlaylistAction->setText("隐藏播放列表");
        showPlaylistAction->setIcon(playlistVisibleIcon);
    } else {
        showPlaylistAction->setChecked(false);
        showPlaylistAction->setText("显示播放列表");
        showPlaylistAction->setIcon(playlistHiddenIcon);
    }
    
    settingsAction = new QAction("设置", this);
    
    quit = new QAction("退出", this);
    quit->setIcon(QIcon(":/tubiao/close.png"));  // 如果有关闭图标的话
    
    // 8. 连接信号槽
    connect(playPauseAction, &QAction::triggered, this, &PlayWidget::onTrayPlayPauseAction);
    connect(stopAction, &QAction::triggered, this, &PlayWidget::onTrayStopAction);
    connect(nextAction, &QAction::triggered, this, &PlayWidget::onTrayNextAction);
    connect(prevAction, &QAction::triggered, this, &PlayWidget::onTrayPrevAction);
    connect(volumeUpAction, &QAction::triggered, this, &PlayWidget::onTrayVolumeUpAction);
    connect(volumeDownAction, &QAction::triggered, this, &PlayWidget::onTrayVolumeDownAction);
    connect(muteAction, &QAction::triggered, this, &PlayWidget::onTrayMuteAction);
    connect(loopAction, &QAction::triggered, this, &PlayWidget::onTrayLoopAction);
    connect(showPlaylistAction, &QAction::triggered, this, &PlayWidget::onTogglePlaylistBtnClicked);
    connect(min, &QAction::triggered, this, &PlayWidget::hide);
    connect(restor, &QAction::triggered, this, &PlayWidget::showNormal);
    connect(quit, &QAction::triggered, qApp, &QApplication::quit);
    
    // 9. 构建最终菜单
    menu->addAction(titleAction);
    menu->addSeparator();
    menu->addMenu(playbackMenu);
    menu->addMenu(volumeMenu);
    menu->addMenu(recentFilesMenu);
    menu->addSeparator();
    
    // 创建均衡器动作
    equalizerAction = new QAction("均衡器 (E键)", this);
    if (QFile::exists(":/tubiao/equalizer.png")) {
        equalizerAction->setIcon(QIcon(":/tubiao/equalizer.png"));
    }
    connect(equalizerAction, &QAction::triggered, this, &PlayWidget::onEqualizerAction);
    
    // 添加均衡器动作到菜单
    menu->addAction(equalizerAction);
    
    menu->addAction(showPlaylistAction);
    menu->addAction(min);
    menu->addAction(restor);
    menu->addSeparator();
    menu->addAction(quit);
    
    // 应用菜单到托盘图标
    SysIcon->setContextMenu(menu);
}

void PlayWidget::updateTrayIcon()
{
    if (!SysIcon) return;
    
    // 根据播放状态更新托盘图标
    if (musicPlayer && musicPlayer->isPlaying()) {
        SysIcon->setIcon(QIcon(":/tubiao/listen1.ico"));
    } else {
        SysIcon->setIcon(QIcon(":/tubiao/listen1.ico")); 
        // 可以考虑使用不同图标表示暂停状态
    }
}

void PlayWidget::updateTrayTooltip()
{
    if (!SysIcon) return;
    
    QString tooltip = "音乐播放器";
    
    // 添加当前播放信息
    if (musicPlayer) {
        if (musicPlayer->isPlaying()) {
            QString songName = musicPlayer->currentSong();
            if (!songName.isEmpty()) {
                tooltip = "正在播放: " + songName;
            }
        } else if (musicPlayer->isPaused()) {
            tooltip = "已暂停播放";
        }
    }
    
    SysIcon->setToolTip(tooltip);
}

void PlayWidget::onTrayPlayPauseAction()
{
    if (!musicPlayer) return;
    
    if (musicPlayer->isPlaying()) {
        musicPlayer->pause();
    } else {
        musicPlayer->play();
    }
    
    // 更新动作文本和图标
    if (playPauseAction) {
        if (musicPlayer->isPlaying()) {
            playPauseAction->setText("暂停");
            playPauseAction->setIcon(pauseIcon);
        } else {
            playPauseAction->setText("播放");
            playPauseAction->setIcon(playIcon);
        }
    }
    
    updateTrayTooltip();
}

void PlayWidget::onTrayStopAction()
{
    if (musicPlayer) musicPlayer->stop();
    updateTrayTooltip();
}

void PlayWidget::onTrayNextAction()
{
    if (musicPlayer) musicPlayer->next();
    updateTrayTooltip();
}

void PlayWidget::onTrayPrevAction()
{
    if (musicPlayer) musicPlayer->previous();
    updateTrayTooltip();
}

void PlayWidget::onTrayVolumeUpAction()
{
    if (!musicPlayer) return;
    
    int currentVolume = musicPlayer->volume();
    int newVolume = qMin(100, currentVolume + 10);
    musicPlayer->setVolume(newVolume);
    
    if (volumePopup) {
        volumePopup->setVolume(newVolume);
    }
}

void PlayWidget::onTrayVolumeDownAction()
{
    if (!musicPlayer) return;
    
    int currentVolume = musicPlayer->volume();
    int newVolume = qMax(0, currentVolume - 10);
    musicPlayer->setVolume(newVolume);
    
    if (volumePopup) {
        volumePopup->setVolume(newVolume);
    }
}

void PlayWidget::onTrayMuteAction(bool muted)
{
    if (!musicPlayer) return;
    
    musicPlayer->mute(muted);
    
    if (muteAction) {
        if (muted) {
            muteAction->setText("取消静音");
        } else {
            muteAction->setText("静音");
        }
    }
}

void PlayWidget::onTrayLoopAction(bool loop)
{
    if (musicPlayer) {
        musicPlayer->setLoop(loop);
        
        // 同步UI按钮状态
        if (ui->modelBtn) {
            ui->modelBtn->setStyleSheet("");
            if (loop) {
                ui->modelBtn->setIcon(QIcon(":/tubiao/xunhuanbof2.png"));
                ui->modelBtn->setToolTip("Loop Play");
            } else {
                ui->modelBtn->setIcon(QIcon(":/tubiao/ShunxuBof3.png"));
                ui->modelBtn->setToolTip("Sequential Play");
            }
        }
    }
}

void PlayWidget::onEqualizerAction()
{
    // 创建均衡器对话框（如果尚未创建）
    if (!equalizerDialog) {
        equalizerDialog = new EqualizerDialog(musicPlayer, this);
    }
    
    // 显示对话框
    equalizerDialog->show();
    equalizerDialog->raise();
    equalizerDialog->activateWindow();
}

void PlayWidget::showNotification(const QString &message, int durationMs)
{
    if (!notificationLabel || message.isEmpty()) return;
    
    // 设置通知文本
    notificationLabel->setText(message);
    
    // 调整大小和位置 - 居中显示在播放器底部
    notificationLabel->adjustSize();
    int labelWidth = qMax(notificationLabel->width(), 200); // 最小宽度
    int labelHeight = notificationLabel->height();
    
    // 使用整个窗口的宽度来居中通知
    int x = (width() - labelWidth) / 2;
    int y = height() - labelHeight - 20; // 在底部上方20像素
    
    notificationLabel->setGeometry(x, y, labelWidth, labelHeight);
    
    // 显示通知
    notificationLabel->raise();
    notificationLabel->show();
    
    // 设置自动隐藏定时
    notificationTimer->start(durationMs);
}

void PlayWidget::hideNotification()
{
    if (notificationLabel) {
        notificationLabel->hide();
    }
}

// setupBufferingIndicator 函数已移除

// showBufferingIndicator 函数已移除

void PlayWidget::onMediaStatusChanged(QMediaPlayer::MediaStatus status)
{
    switch (status) {
        case QMediaPlayer::LoadingMedia:
        case QMediaPlayer::BufferingMedia:
            // 缓冲指示器已移除，不再显示加载动画
            break;
        case QMediaPlayer::LoadedMedia:
        case QMediaPlayer::BufferedMedia:
            // 媒体加载完成时，确保进度条状态正确
            if (ui->playCourseSlider && !isSliderDragging && musicPlayer && musicPlayer->player) {
                ui->playCourseSlider->setValue(musicPlayer->player->position());
            }
            break;
            
        case QMediaPlayer::InvalidMedia:
            if (ui->currentSongLabel) {
                ui->currentSongLabel->setText("无效的媒体文件");
            }
            break;
            
        default:
            break;
    }
}

void PlayWidget::setupShortcuts()
{
    // 播放/暂停 - 空格键
    playPauseShortcut = new QShortcut(QKeySequence(Qt::Key_Space), this);
    connect(playPauseShortcut, &QShortcut::activated, this, [this]() {
        onplayBtn();
        showNotification(musicPlayer && musicPlayer->isPlaying() ? "播放" : "暂停");
    });
    
    // 下一首 - 右箭头
    nextShortcut = new QShortcut(QKeySequence(Qt::Key_Right), this);
    connect(nextShortcut, &QShortcut::activated, this, [this]() {
        onnextBtn();
        showNotification("下一首");
    });
    
    // 上一首 - 左箭头
    prevShortcut = new QShortcut(QKeySequence(Qt::Key_Left), this);
    connect(prevShortcut, &QShortcut::activated, this, [this]() {
        onprevBtn();
        showNotification("上一首");
    });
    
    // 增加音量 - 上箭头
    volumeUpShortcut = new QShortcut(QKeySequence(Qt::Key_Up), this);
    connect(volumeUpShortcut, &QShortcut::activated, this, [this]() {
        if (musicPlayer) {
            int newVolume = qMin(musicPlayer->volume() + 5, 100);
            musicPlayer->setVolume(newVolume);
            if (volumePopup) {
                volumePopup->setVolume(newVolume);
            }
            showNotification(QString("音量: %1%").arg(newVolume));
        }
    });
    
    // 减少音量 - 下箭头
    volumeDownShortcut = new QShortcut(QKeySequence(Qt::Key_Down), this);
    connect(volumeDownShortcut, &QShortcut::activated, this, [this]() {
        if (musicPlayer) {
            int newVolume = qMax(musicPlayer->volume() - 5, 0);
            musicPlayer->setVolume(newVolume);
            if (volumePopup) {
                volumePopup->setVolume(newVolume);
            }
            showNotification(QString("音量: %1%").arg(newVolume));
        }
    });
    
    // 静音 - M键
    muteShortcut = new QShortcut(QKeySequence(Qt::Key_M), this);
    connect(muteShortcut, &QShortcut::activated, this, [this]() {
        if (musicPlayer && musicPlayer->player && musicPlayer->player->audioOutput()) {
            bool muted = !musicPlayer->player->audioOutput()->isMuted();
            musicPlayer->player->audioOutput()->setMuted(muted);
            showNotification(muted ? "静音" : "取消静音");
        }
    });
    
    // 切换播放列表显示 - L键
    togglePlaylistShortcut = new QShortcut(QKeySequence(Qt::Key_L), this);
    connect(togglePlaylistShortcut, &QShortcut::activated, this, [this]() {
        onTogglePlaylistBtnClicked();
        bool visible = ui->playlistWidget && ui->playlistWidget->isVisible();
        showNotification(visible ? "显示播放列表" : "隐藏播放列表");
    });

    // 均衡器 - E键
    equalizerShortcut = new QShortcut(QKeySequence(Qt::Key_E), this);
    connect(equalizerShortcut, &QShortcut::activated, this, [this]() {
        onEqualizerAction();
        showNotification("打开均衡器");
    });
}

// 均衡器对话框实现
EqualizerDialog::EqualizerDialog(MusicPlayer *player, QWidget *parent)
    : QDialog(parent)
    , musicPlayer(player)
    , presetComboBox(nullptr)
    , bassSlider(nullptr)
    , midSlider(nullptr)
    , trebleSlider(nullptr)
    , bassLabel(nullptr)
    , midLabel(nullptr)
    , trebleLabel(nullptr)
{
    setWindowTitle("音频均衡器");
    setMinimumSize(300, 250);
    
    setupUI();
    connectSignals();
    updateSliders();
}

void EqualizerDialog::setupUI()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    
    // 预设选择
    QHBoxLayout *presetLayout = new QHBoxLayout();
    QLabel *presetLabel = new QLabel("预设:", this);
    presetComboBox = new QComboBox(this);
    presetComboBox->addItem("平衡");
    presetComboBox->addItem("低音增强");
    presetComboBox->addItem("高音增强");
    presetComboBox->addItem("人声增强");
    presetComboBox->addItem("摇滚");
    presetComboBox->addItem("流行");
    presetComboBox->addItem("古典");
    presetComboBox->addItem("爵士");
    presetComboBox->addItem("自定义");
    
    presetLayout->addWidget(presetLabel);
    presetLayout->addWidget(presetComboBox, 1);
    
    // 频段调整组
    QGroupBox *bandsGroup = new QGroupBox("频段调整", this);
    QVBoxLayout *bandsLayout = new QVBoxLayout(bandsGroup);
    
    // 低音控制
    QHBoxLayout *bassLayout = new QHBoxLayout();
    QLabel *bassTitle = new QLabel("低音:", this);
    bassSlider = new QSlider(Qt::Horizontal, this);
    bassSlider->setRange(0, 100);
    bassSlider->setValue(50);
    bassLabel = new QLabel("50", this);
    bassLabel->setMinimumWidth(30);
    bassLayout->addWidget(bassTitle);
    bassLayout->addWidget(bassSlider, 1);
    bassLayout->addWidget(bassLabel);
    
    // 中音控制
    QHBoxLayout *midLayout = new QHBoxLayout();
    QLabel *midTitle = new QLabel("中音:", this);
    midSlider = new QSlider(Qt::Horizontal, this);
    midSlider->setRange(0, 100);
    midSlider->setValue(50);
    midLabel = new QLabel("50", this);
    midLabel->setMinimumWidth(30);
    midLayout->addWidget(midTitle);
    midLayout->addWidget(midSlider, 1);
    midLayout->addWidget(midLabel);
    
    // 高音控制
    QHBoxLayout *trebleLayout = new QHBoxLayout();
    QLabel *trebleTitle = new QLabel("高音:", this);
    trebleSlider = new QSlider(Qt::Horizontal, this);
    trebleSlider->setRange(0, 100);
    trebleSlider->setValue(50);
    trebleLabel = new QLabel("50", this);
    trebleLabel->setMinimumWidth(30);
    trebleLayout->addWidget(trebleTitle);
    trebleLayout->addWidget(trebleSlider, 1);
    trebleLayout->addWidget(trebleLabel);
    
    bandsLayout->addLayout(bassLayout);
    bandsLayout->addLayout(midLayout);
    bandsLayout->addLayout(trebleLayout);
    
    // 添加所有控件到主布局
    mainLayout->addLayout(presetLayout);
    mainLayout->addWidget(bandsGroup);
    mainLayout->addStretch(1);
    
    // 按钮区域
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    QPushButton *resetButton = new QPushButton("重置", this);
    QPushButton *closeButton = new QPushButton("关闭", this);
    
    buttonLayout->addStretch(1);
    buttonLayout->addWidget(resetButton);
    buttonLayout->addWidget(closeButton);
    
    mainLayout->addLayout(buttonLayout);
    
    // 连接按钮信号
    connect(resetButton, &QPushButton::clicked, this, [this]() {
        if (musicPlayer) {
            musicPlayer->setEqualizerPreset(Flat); // 重置为平衡
            presetComboBox->setCurrentIndex(0);
            updateSliders();
        }
    });
    
    connect(closeButton, &QPushButton::clicked, this, &QDialog::accept);
}

void EqualizerDialog::connectSignals()
{
    connect(presetComboBox, QOverload<int>::of(&QComboBox::currentIndexChanged), 
            this, &EqualizerDialog::onPresetChanged);
    
    connect(bassSlider, &QSlider::valueChanged, this, &EqualizerDialog::onBassChanged);
    connect(midSlider, &QSlider::valueChanged, this, &EqualizerDialog::onMidChanged);
    connect(trebleSlider, &QSlider::valueChanged, this, &EqualizerDialog::onTrebleChanged);
    
    if (musicPlayer) {
        connect(musicPlayer, &MusicPlayer::equalizerPresetChanged, this, [this](EqualizerPreset preset) {
            // 同步预设选择框
            presetComboBox->setCurrentIndex(static_cast<int>(preset));
            updateSliders();
        });
    }
}

void EqualizerDialog::updateSliders()
{
    // 禁用信号，避免循环更新
    bassSlider->blockSignals(true);
    midSlider->blockSignals(true);
    trebleSlider->blockSignals(true);
    
    // 设置滑块值
    if (musicPlayer) {
        bassSlider->setValue(musicPlayer->getBassLevel());
        midSlider->setValue(musicPlayer->getMidLevel());
        trebleSlider->setValue(musicPlayer->getTrebleLevel());
        
        // 更新标签
        bassLabel->setText(QString::number(musicPlayer->getBassLevel()));
        midLabel->setText(QString::number(musicPlayer->getMidLevel()));
        trebleLabel->setText(QString::number(musicPlayer->getTrebleLevel()));
    }
    
    // 重新启用信号
    bassSlider->blockSignals(false);
    midSlider->blockSignals(false);
    trebleSlider->blockSignals(false);
}

void EqualizerDialog::onPresetChanged(int index)
{
    if (musicPlayer) {
        EqualizerPreset preset = static_cast<EqualizerPreset>(index);
        musicPlayer->setEqualizerPreset(preset);
        
        // 显示通知 (需要将通知传递给主窗口)
        if (PlayWidget *mainWidget = qobject_cast<PlayWidget*>(parentWidget())) {
            QString presetName = presetComboBox->itemText(index);
            mainWidget->showNotification(QString("均衡器: %1").arg(presetName));
        }
    }
}

void EqualizerDialog::onBassChanged(int value)
{
    if (musicPlayer) {
        bassLabel->setText(QString::number(value));
        musicPlayer->setCustomEqualizer(value, midSlider->value(), trebleSlider->value());
        // 确保显示自定义预设
        presetComboBox->setCurrentIndex(static_cast<int>(Custom));
    }
}

void EqualizerDialog::onMidChanged(int value)
{
    if (musicPlayer) {
        midLabel->setText(QString::number(value));
        musicPlayer->setCustomEqualizer(bassSlider->value(), value, trebleSlider->value());
        // 确保显示自定义预设
        presetComboBox->setCurrentIndex(static_cast<int>(Custom));
    }
}

void EqualizerDialog::onTrebleChanged(int value)
{
    if (musicPlayer) {
        trebleLabel->setText(QString::number(value));
        musicPlayer->setCustomEqualizer(bassSlider->value(), midSlider->value(), value);
        // 确保显示自定义预设
        presetComboBox->setCurrentIndex(static_cast<int>(Custom));
    }
}
