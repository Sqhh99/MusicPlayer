#ifndef PLAYWIDGET_H
#define PLAYWIDGET_H

#include <QWidget>
#include "musicsettings.h"
#include "musicplayer.h"
#include "volumepopup.h"
#include <QSystemTrayIcon>
#include <QSlider>
#include <QLabel>
#include <QIcon>
#include <QScrollBar>
#include <QFile>
#include <QPushButton>
#include <QHBoxLayout>
#include <QMessageBox>
#include <QStyledItemDelegate>
#include <QPainter>
#include <QColor>
#include <QAction>
#include <QActionGroup>
#include <QMovie> // For animated buffering indicator
#include <QShortcut> // For keyboard shortcuts
#include <QKeySequence>
#include <QDialog>
#include <QVBoxLayout>
#include <QComboBox>
#include <QGroupBox>
#include <QTimer> // For notification timer

// 自定义列表项代理，用于控制绘制方式
class PlaylistItemDelegate : public QStyledItemDelegate
{
public:
    explicit PlaylistItemDelegate(QObject *parent = nullptr) : QStyledItemDelegate(parent) {}
    
    void paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const override
    {
        // 创建自定义风格选项，移除焦点框
        QStyleOptionViewItem customOption = option;
        customOption.state &= ~QStyle::State_HasFocus;  // 移除焦点状态
        customOption.state &= ~QStyle::State_Selected;  // 移除选中状态
        
        // 绘制背景（带圆角）
        painter->save();
        painter->setRenderHint(QPainter::Antialiasing, true); // 启用抗锯齿
        painter->setPen(Qt::NoPen);
        
        const int cornerRadius = 6; // 圆角半径
        
        if (option.state & QStyle::State_Selected) {
            // 浅绿色背景 - 选中状态
            painter->setBrush(QColor(200, 240, 220)); // 浅绿色
            QRect roundedRect = option.rect.adjusted(2, 1, -2, -1); // 稍微缩小一点，增加间距
            painter->drawRoundedRect(roundedRect, cornerRadius, cornerRadius);
            
            // 添加左侧更深的绿色边框作为视觉指示
            painter->setPen(Qt::NoPen);
            painter->setBrush(QColor(29, 185, 84)); // 原始绿色作为指示条
            QRect leftIndicator(option.rect.left() + 2, option.rect.top() + 3, 3, option.rect.height() - 6);
            painter->drawRoundedRect(leftIndicator, 1, 1);
        } 
        else if (option.state & QStyle::State_MouseOver) {
            // 灰色背景 - 悬停状态
            painter->setBrush(QColor(240, 240, 240));
            QRect roundedRect = option.rect.adjusted(2, 1, -2, -1);
            painter->drawRoundedRect(roundedRect, cornerRadius, cornerRadius);
        }
        painter->restore();
        
        // 绘制文本
        painter->save();
        if (option.state & QStyle::State_Selected) {
            painter->setPen(QColor(50, 120, 80)); // 深绿色文本，搭配浅绿色背景
        } else {
            painter->setPen(QColor("#333333")); // 默认文本颜色
        }
        
        QRect textRect = option.rect;
        textRect.setLeft(textRect.left() + 12); // 文本左侧留出空间
        painter->drawText(textRect, Qt::AlignVCenter, index.data().toString());
        painter->restore();
    }
};

QT_BEGIN_NAMESPACE
namespace Ui {
class PlayWidget;
}
QT_END_NAMESPACE

class QWidget;

// 均衡器对话框
class EqualizerDialog : public QDialog
{
    Q_OBJECT
    
public:
    explicit EqualizerDialog(MusicPlayer *player, QWidget *parent = nullptr);
    
private slots:
    void onPresetChanged(int index);
    void onBassChanged(int value);
    void onMidChanged(int value);
    void onTrebleChanged(int value);
    
private:
    MusicPlayer *musicPlayer;
    QComboBox *presetComboBox;
    QSlider *bassSlider;
    QSlider *midSlider;
    QSlider *trebleSlider;
    QLabel *bassLabel;
    QLabel *midLabel;
    QLabel *trebleLabel;
    
    void setupUI();
    void connectSignals();
    void updateSliders();
};

class PlayWidget : public QWidget
{
    Q_OBJECT

public:
    explicit PlayWidget(QWidget *parent = nullptr);
    ~PlayWidget() override;
    
    // 通知相关
    void showNotification(const QString &message, int durationMs = 3000); // 显示临时通知

private slots:
    void extracted(QStringList &filePaths);
    void onprevBtn();
    void onnextBtn();
    void onplayBtn();
    void onmodelBtn();
    void onVolumeBtn();
    void onPlaybackStateChanged(QMediaPlayer::PlaybackState state);
    void onActivatedSysTrayIcon(QSystemTrayIcon::ActivationReason reason);
    void onVolumeChanged(int value);
    void onOpenFileBtnClicked();
    void onTogglePlaylistBtnClicked();
    void onMinimizeButtonClicked();
    void onCloseButtonClicked();
    void onAlwaysOnTopButtonClicked();
    
    // 新增系统托盘相关槽函数
    void setupTrayMenu();                    // 设置系统托盘菜单
    void updateTrayIcon();                   // 更新托盘图标状态
    void updateTrayTooltip();                // 更新托盘提示信息
    void onTrayPlayPauseAction();            // 托盘播放/暂停
    void onTrayNextAction();                 // 托盘下一首
    void onTrayPrevAction();                 // 托盘上一首
    void onTrayStopAction();                 // 托盘停止播放
    void onTrayVolumeUpAction();             // 托盘增加音量
    void onTrayVolumeDownAction();           // 托盘减少音量
    void onTrayMuteAction(bool muted);       // 托盘静音
    void onTrayLoopAction(bool loop);        // 托盘循环播放
    
    void onMediaStatusChanged(QMediaPlayer::MediaStatus status); // 新增: 处理缓冲状态变化
    
    void onEqualizerAction(); // 新增: 显示均衡器对话框
    
    // 通知相关
    void hideNotification(); // 隐藏通知
    
private:
    Ui::PlayWidget *ui;
    MusicSettings* msettings;
    MusicPlayer* musicPlayer;
    QAction* min;
    QAction* restor; //恢复
    QAction* quit;
    QSystemTrayIcon *SysIcon;
    QMenu *menu;
    
    // 系统托盘相关动作
    QAction* playPauseAction;       // 播放/暂停
    QAction* stopAction;            // 停止
    QAction* nextAction;            // 下一首
    QAction* prevAction;            // 上一首
    QAction* muteAction;            // 静音
    QAction* loopAction;            // 循环
    QAction* volumeUpAction;        // 增加音量
    QAction* volumeDownAction;      // 减少音量
    QAction* showPlaylistAction;    // 显示播放列表
    QAction* settingsAction;        // 设置
    QMenu* volumeMenu;              // 音量子菜单
    QMenu* playbackMenu;            // 播放控制子菜单
    QMenu* recentFilesMenu;         // 最近文件子菜单

    VolumePopup *volumePopup;
    PlaylistItemDelegate *playlistDelegate; // 列表项代理

    // Custom title bar buttons
    QPushButton *minimizeButton;
    QPushButton *closeButton;
    QPushButton *alwaysOnTopButton;
    QHBoxLayout *titleBarLayout;
    
    // Window state tracking
    bool isAlwaysOnTop;
    
    // Mouse tracking for window movement
    bool isDragging;
    QPoint dragStartPosition;

    // Icons for play/pause state
    QIcon playIcon;
    QIcon pauseIcon;
    QIcon playlistVisibleIcon;
    QIcon playlistHiddenIcon;
    QIcon pinOnIcon;
    QIcon pinOffIcon;

    // 初始化和设置方法
    void initConn();                // 初始化信号槽连接
    void loadIcons();               // 加载图标
    void setupTitleBar();           // 设置自定义标题栏
    void loadStyles();              // 加载样式表
    void loadPlaylist();            // 加载播放列表
    void setupInitialUI();          // 设置初始UI状态
    
    // 辅助功能
    bool loadStyleFile(const QString &path, QWidget *target = nullptr); // 加载样式表辅助函数
    void showError(const QString &title, const QString &message);       // 显示错误对话框

    // 事件处理
    void closeEvent(QCloseEvent *event) override;
    bool eventFilter(QObject *watched, QEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void paintEvent(QPaintEvent *event) override;

    QLabel *bufferingIndicator;    // 缓冲指示器
    QMovie *bufferingAnimation;    // 缓冲动画
    
    void setupBufferingIndicator(); // 设置缓冲指示器
    void showBufferingIndicator(bool show); // 显示或隐藏缓冲指示器

    // 设置键盘快捷键
    void setupShortcuts();

    QAction *equalizerAction; // 均衡器动作
    EqualizerDialog *equalizerDialog; // 均衡器对话框

    // 通知相关
    QLabel *notificationLabel;  // 通知标签
    QTimer *notificationTimer;  // 通知计时器

    // 键盘快捷键
    QShortcut *playPauseShortcut;
    QShortcut *nextShortcut;
    QShortcut *prevShortcut;
    QShortcut *volumeUpShortcut;
    QShortcut *volumeDownShortcut;
    QShortcut *muteShortcut;
    QShortcut *togglePlaylistShortcut;
    QShortcut *equalizerShortcut; // 均衡器快捷键
};

#endif // PLAYWIDGET_H
