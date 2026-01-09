#ifndef TRAYICONMANAGER_H
#define TRAYICONMANAGER_H

#include <QObject>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>

class PlayerController;

class TrayIconManager : public QObject
{
    Q_OBJECT

public:
    explicit TrayIconManager(PlayerController *controller, QObject *parent = nullptr);
    ~TrayIconManager() override;

    void show();
    void hide();

signals:
    void showWindowRequested();
    void hideWindowRequested();
    void quitRequested();

private slots:
    void onTrayActivated(QSystemTrayIcon::ActivationReason reason);
    void onPlaybackStateChanged();
    void updateTooltip();

private:
    void setupTrayIcon();
    void setupMenu();
    void updatePlayPauseAction();

    PlayerController *m_controller;
    QSystemTrayIcon *m_trayIcon;
    QMenu *m_menu;

    // Actions
    QAction *m_showAction;
    QAction *m_playPauseAction;
    QAction *m_stopAction;
    QAction *m_nextAction;
    QAction *m_prevAction;
    QAction *m_muteAction;
    QAction *m_loopAction;
    QAction *m_quitAction;

    // Icons
    QIcon m_playIcon;
    QIcon m_pauseIcon;
};

#endif // TRAYICONMANAGER_H
