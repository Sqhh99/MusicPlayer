#include "TrayIconManager.h"
#include "PlayerController.h"
#include "../backend/musicplayer.h"

TrayIconManager::TrayIconManager(PlayerController *controller, QObject *parent)
    : QObject(parent)
    , m_controller(controller)
    , m_trayIcon(new QSystemTrayIcon(this))
    , m_menu(new QMenu(nullptr)) // Menu needs no parent, managed by context menu
{
    // Load icons - qt_add_qml_module puts resources at qrc:/qt/qml/MusicPlayer/...
    m_playIcon.addFile(QStringLiteral(":/qt/qml/MusicPlayer/resources/icons/pause01.png"));
    m_pauseIcon.addFile(QStringLiteral(":/qt/qml/MusicPlayer/resources/icons/player01.png"));

    setupMenu();
    setupTrayIcon();

    // Connect to controller signals
    connect(m_controller, &PlayerController::playingChanged,
            this, &TrayIconManager::onPlaybackStateChanged);
    connect(m_controller, &PlayerController::currentSongChanged,
            this, &TrayIconManager::updateTooltip);
}

TrayIconManager::~TrayIconManager()
{
    delete m_menu;
}

void TrayIconManager::setupTrayIcon()
{
    m_trayIcon->setIcon(QIcon(QStringLiteral(":/qt/qml/MusicPlayer/resources/icons/listen1.ico")));
    m_trayIcon->setContextMenu(m_menu);
    m_trayIcon->setToolTip(QStringLiteral("Music Player"));

    connect(m_trayIcon, &QSystemTrayIcon::activated,
            this, &TrayIconManager::onTrayActivated);
}

void TrayIconManager::setupMenu()
{
    // Show/Hide window action
    m_showAction = m_menu->addAction(tr("显示窗口"));
    connect(m_showAction, &QAction::triggered, this, &TrayIconManager::showWindowRequested);

    m_menu->addSeparator();

    // Playback controls
    m_playPauseAction = m_menu->addAction(m_playIcon, tr("播放"));
    connect(m_playPauseAction, &QAction::triggered, m_controller, &PlayerController::togglePlayPause);

    m_stopAction = m_menu->addAction(tr("停止"));
    connect(m_stopAction, &QAction::triggered, m_controller, &PlayerController::stop);

    m_menu->addSeparator();

    m_prevAction = m_menu->addAction(tr("上一首"));
    connect(m_prevAction, &QAction::triggered, m_controller, &PlayerController::previous);

    m_nextAction = m_menu->addAction(tr("下一首"));
    connect(m_nextAction, &QAction::triggered, m_controller, &PlayerController::next);

    m_menu->addSeparator();

    // Volume submenu
    QMenu *volumeMenu = m_menu->addMenu(tr("音量"));
    QAction *volumeUpAction = volumeMenu->addAction(tr("增加音量"));
    connect(volumeUpAction, &QAction::triggered, this, [this]() {
        int newVol = qMin(100, m_controller->volume() + 5);
        m_controller->setVolume(newVol);
    });

    QAction *volumeDownAction = volumeMenu->addAction(tr("减小音量"));
    connect(volumeDownAction, &QAction::triggered, this, [this]() {
        int newVol = qMax(0, m_controller->volume() - 5);
        m_controller->setVolume(newVol);
    });

    volumeMenu->addSeparator();

    m_muteAction = volumeMenu->addAction(tr("静音"));
    m_muteAction->setCheckable(true);
    connect(m_muteAction, &QAction::toggled, m_controller, &PlayerController::setMuted);
    connect(m_controller, &PlayerController::mutedChanged, this, [this]() {
        m_muteAction->setChecked(m_controller->isMuted());
    });

    m_menu->addSeparator();

    // Loop action
    m_loopAction = m_menu->addAction(tr("循环播放"));
    m_loopAction->setCheckable(true);
    m_loopAction->setChecked(m_controller->isLooping());
    connect(m_loopAction, &QAction::toggled, m_controller, &PlayerController::setLooping);
    connect(m_controller, &PlayerController::loopingChanged, this, [this]() {
        m_loopAction->setChecked(m_controller->isLooping());
    });

    m_menu->addSeparator();

    // Quit action
    m_quitAction = m_menu->addAction(tr("退出"));
    connect(m_quitAction, &QAction::triggered, this, &TrayIconManager::quitRequested);
}

void TrayIconManager::show()
{
    m_trayIcon->show();
}

void TrayIconManager::hide()
{
    m_trayIcon->hide();
}

void TrayIconManager::onTrayActivated(QSystemTrayIcon::ActivationReason reason)
{
    switch (reason) {
    case QSystemTrayIcon::Trigger:
    case QSystemTrayIcon::DoubleClick:
        emit showWindowRequested();
        break;
    case QSystemTrayIcon::MiddleClick:
        m_controller->togglePlayPause();
        break;
    default:
        break;
    }
}

void TrayIconManager::onPlaybackStateChanged()
{
    updatePlayPauseAction();
    updateTooltip();
}

void TrayIconManager::updatePlayPauseAction()
{
    if (m_controller->isPlaying()) {
        m_playPauseAction->setText(tr("暂停"));
        m_playPauseAction->setIcon(m_pauseIcon);
    } else {
        m_playPauseAction->setText(tr("播放"));
        m_playPauseAction->setIcon(m_playIcon);
    }
}

void TrayIconManager::updateTooltip()
{
    QString tooltip = QStringLiteral("Music Player");
    QString currentSong = m_controller->currentSong();
    if (!currentSong.isEmpty()) {
        tooltip = currentSong;
        if (m_controller->isPlaying()) {
            tooltip += QStringLiteral(" - 播放中");
        } else if (m_controller->isPaused()) {
            tooltip += QStringLiteral(" - 已暂停");
        }
    }
    m_trayIcon->setToolTip(tooltip);
}
