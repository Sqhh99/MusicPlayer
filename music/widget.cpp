#include "widget.h"
#include "ui_widget.h"
#include <QDebug>
#include <QFileDialog>
#include <QDir>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
Widget::Widget(QWidget *parent)
    : QWidget(parent)
    , ui(new Ui::Widget)
{
    ui->setupUi(this);
    //   固定窗口大小
    setFixedSize(width(),height());

    //  设置窗口图标
    this->setWindowIcon(QIcon(":/tubiao/listen.png"));

    //  先new一个output对象
    audioOutput = new QAudioOutput(this);

    //  在来一个媒体播放对象
    mediaPlayer = new QMediaPlayer(this);
    mediaPlayer->setAudioOutput(audioOutput);

    //  读取文件
    readPathsFromFile();

    //  获取当前媒体的时长 通过信号关联获取
    connect(mediaPlayer,&QMediaPlayer::durationChanged,this,[=](qint64 duration){
        ui->totalLibel->setText(QString("%1:%2").arg(duration/1000/60,2,10,QChar('0')).arg(duration/1000%60));
        ui->playCourseSlider->setRange(0,duration);
    });

    //  获取当前播放时长
    connect(mediaPlayer,&QMediaPlayer::positionChanged,this,[=](qint64 pos){
        ui->curLabel->setText(QString("%1:%2").arg(pos/1000/60,2,10,QChar('0')).arg(pos/1000%60,2,10,QChar('0')));
        ui->playCourseSlider->setValue(pos);
    });

    //  拖动滑块，让音乐播放器的进度改变
    connect(ui->playCourseSlider,&QSlider::sliderMoved,mediaPlayer,&QMediaPlayer::setPosition);

    //  自动播放下一首
    connect(mediaPlayer, &QMediaPlayer::mediaStatusChanged, this, [&](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::EndOfMedia) {
            if (pand == true)
            {
                curPlayIndex++;
                if (curPlayIndex >= playList.size()) {
                    curPlayIndex = 0;
                }
                ui->listWidget->setCurrentRow(curPlayIndex);
                mediaPlayer->setSource(playList[curPlayIndex]);
                mediaPlayer->play();
            }
            else
            {
                mediaPlayer->setPosition(0);  // 重置播放位置到开头
                mediaPlayer->play();          // 继续播放当前歌曲
            }
        }
    });

    //  监视状态
    connect(mediaPlayer, &QMediaPlayer::playbackStateChanged, this, &Widget::onPlaybackStateChanged);

    //  设置音量
    audioOutput->setVolume(0.5);//[0,1]
}
Widget::~Widget()
{
    delete ui;
}

void Widget::readPathsFromFile()
{
    QFile file(filePathsFileName);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QTextStream in(&file);
        while (!in.atEnd())
        {
            QString filePath = in.readLine();

            // 检查文件是否存在
            if (QFile::exists(filePath))
            {
                QFileInfo fileInfo(filePath);

                // 检查文件后缀
                if (fileInfo.suffix().toLower() == "mp3" || fileInfo.suffix().toLower() == "flac" || fileInfo.suffix().toLower() == "m4a")
                {
                    QString fileName = fileInfo.fileName();
                    ui->listWidget->addItem(fileName);
                    playList.append(QUrl::fromLocalFile(filePath));
                }
            }
        }

        file.close();
    }

    // 默认选中第一个音乐
    ui->listWidget->setCurrentRow(0);
}



void Widget::on_pushButton_clicked()
{
    // 获取用户选择的文件
    QStringList fileNames = QFileDialog::getOpenFileNames(this,"请选择音乐文件","D:","音乐文件 (*.mp3 *.flac *.m4a)");

    // 清空列表
    if (!fileNames.empty())
    {
        int counter = ui->listWidget->count();
        for (int index = 0; index < counter; ++index)
        {
            QListWidgetItem *item = ui->listWidget->takeItem(0);
            delete item;
        }
        playList.clear();

        QFile file(filePathsFileName);
        if (file.open(QIODevice::WriteOnly | QIODevice::Text))
        {
            QTextStream out(&file);

            // 把音乐文件名添加到listWidget展示，并追加路径到文件
            for (const auto &filePath : fileNames)
            {
                QFileInfo fileInfo(filePath);
                QString fileName = fileInfo.fileName();
                ui->listWidget->addItem(fileName);
                playList.append(QUrl::fromLocalFile(filePath));
                out << filePath << "\n";  // 追加路径到文件
            }

            file.close();
        }

        // 默认选中第一个音乐
        ui->listWidget->setCurrentRow(0);
    }
}

//  使用信号和槽的机制
void Widget::onPlaybackStateChanged(QMediaPlayer::PlaybackState newState)
{
    switch (newState) {
    case QMediaPlayer::PlayingState:
        ui->pushButton_4->setStyleSheet("QPushButton{border:none;image: url(:/tubiao/player01.png);}");
        break;
    case QMediaPlayer::PausedState:
        ui->pushButton_4->setStyleSheet("QPushButton{border:none;image: url(:/tubiao/pause01.png);}");
        break;
    case QMediaPlayer::StoppedState:
        // 可以根据需要处理停止状态的逻辑
        ui->pushButton_4->setStyleSheet("QPushButton{border:none;image: url(:/tubiao/pause01.png);}");
        break;
    // 可以处理其他状态...
    default:
        // 处理其他状态
        break;
    }
}

void Widget::on_pushButton_4_clicked()
{
    if (playList.empty())
    {
        return;
    }
    switch (mediaPlayer->playbackState())
    {
    case QMediaPlayer::PlaybackState::StoppedState://  停止状态
    {
        // 播放当前选中的音乐
        //1.获取选中的行号
        curPlayIndex = ui->listWidget->currentRow();

        //2.播放对应下标的音乐
        mediaPlayer->setSource(playList[curPlayIndex]);
        mediaPlayer->play();
        break;
    }
    case QMediaPlayer::PlaybackState::PlayingState://  播放状态
    {
        //  如果现在正在播放，暂停
        mediaPlayer->pause();
        break;
    }
    case QMediaPlayer::PlaybackState::PausedState://  停止状态
    {
        //  如果暂停，播放
        mediaPlayer->play();
        break;
    }
    }
}

//  上一曲
void Widget::on_pushButton_3_clicked()
{
    if (playList.empty())
    {
        return;
    }
    //让listWidget选中下一行
    curPlayIndex--; //  会下标越界吗
    if (curPlayIndex < 0)
    {
        curPlayIndex = playList.size()-1;
    }
    ui->listWidget->setCurrentRow(curPlayIndex);
    mediaPlayer->setSource(playList[curPlayIndex]);
    mediaPlayer->play();
}

//  下一曲
void Widget::on_pushButton_5_clicked()
{
    if (playList.empty())
    {
        return;
    }
    curPlayIndex = (curPlayIndex+1)%playList.size();
    ui->listWidget->setCurrentRow(curPlayIndex);
    mediaPlayer->setSource(playList[curPlayIndex]);
    mediaPlayer->play();
}

void Widget::on_listWidget_doubleClicked(const QModelIndex &index)
{
    curPlayIndex = index.row();
    mediaPlayer->setSource(playList[curPlayIndex]);
    mediaPlayer->play();
}


void Widget::on_XunHuanOrShunXu_clicked()
{
    if (pand == true)
    {
        ui->XunHuanOrShunXu->setStyleSheet("QPushButton{border:none;image: url(:/tubiao/xunhuanbof2.png);}");
        pand = false;
    }
    else
    {
        ui->XunHuanOrShunXu->setStyleSheet("QPushButton{border:none;image: url(:/tubiao/ShunxuBof3.png);}");
        pand = true;
    }
}

