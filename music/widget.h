#ifndef WIDGET_H
#define WIDGET_H
#include <QWidget>
#include <QUrl>
#include <QMediaPlayer>
class QMediaPlayer;
class QAudioOutput;
QT_BEGIN_NAMESPACE
namespace Ui { class Widget; }
QT_END_NAMESPACE

class Widget : public QWidget
{
    Q_OBJECT

public:
    Widget(QWidget *parent = nullptr);
    ~Widget();

private slots:
    void on_pushButton_clicked();

    void on_pushButton_4_clicked();

    void on_pushButton_3_clicked();

    void on_pushButton_5_clicked();

    void on_listWidget_doubleClicked(const QModelIndex &index);

    void on_XunHuanOrShunXu_clicked();

    void onPlaybackStateChanged(QMediaPlayer::PlaybackState newState);

private:
    QString filePathsFileName = "filePaths.mypaths";  // 使用自定义的文件后缀
    Ui::Widget *ui;
    QList<QUrl> playList; //  播放列表
    QAudioOutput* audioOutput;//  音频
    QMediaPlayer* mediaPlayer;//  媒体播放器
    int curPlayIndex = 0;
    bool pand = true;
    void readPathsFromFile();
};
#endif // WIDGET_H
