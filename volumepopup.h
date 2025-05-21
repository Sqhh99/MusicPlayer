#ifndef VOLUMEPOPUP_H
#define VOLUMEPOPUP_H

#include <QWidget>
#include <QSlider>
#include <QLabel>
#include <QVBoxLayout>

class VolumePopup : public QWidget
{
    Q_OBJECT

public:
    explicit VolumePopup(QWidget *parent = nullptr);
    ~VolumePopup();

    void setVolume(int volume);
    int volume() const;
    void showPopup(const QPoint &buttonPos);

signals:
    void volumeChanged(int volume);

private:
    QVBoxLayout *layout;
    QSlider *volumeSlider;
    QLabel *percentLabel;

    void setupUi();
    void setupConnections();
    void loadVolumeStyle();
};

#endif // VOLUMEPOPUP_H 