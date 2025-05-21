#include "volumepopup.h"
#include <QApplication>
#include <QScreen>
#include <QFile>
#include <QDebug>
#include <QDir>
#include <QCoreApplication>

VolumePopup::VolumePopup(QWidget *parent)
    : QWidget(parent)
    , layout(new QVBoxLayout(this))
    , volumeSlider(new QSlider(Qt::Vertical, this))
    , percentLabel(new QLabel("80%", this))
{
    setWindowFlags(Qt::Popup | Qt::FramelessWindowHint | Qt::NoDropShadowWindowHint);
    setAttribute(Qt::WA_TranslucentBackground);
    
    setupUi();
    setupConnections();
    loadVolumeStyle();
}

VolumePopup::~VolumePopup()
{
}

void VolumePopup::setupUi()
{
    // Set size
    resize(50, 120);
    
    // Configure the layout
    layout->setSpacing(5);
    layout->setContentsMargins(5, 5, 5, 5);
    layout->setAlignment(Qt::AlignHCenter);
    
    // Configure the slider
    volumeSlider->setObjectName("volumeSlider");
    volumeSlider->setMaximum(100);
    volumeSlider->setValue(80);
    volumeSlider->setInvertedAppearance(false);
    volumeSlider->setMinimumHeight(80);
    
    // Configure the label
    percentLabel->setObjectName("percentLabel");
    percentLabel->setAlignment(Qt::AlignCenter);
    percentLabel->setMinimumWidth(40);
    
    // Add widgets to layout
    layout->addWidget(volumeSlider, 1, Qt::AlignHCenter);
    layout->addWidget(percentLabel, 0, Qt::AlignHCenter);
}

void VolumePopup::setupConnections()
{
    connect(volumeSlider, &QSlider::valueChanged, this, [this](int value) {
        percentLabel->setText(QString::number(value) + "%");
        emit volumeChanged(value);
    });
}

void VolumePopup::setVolume(int volume)
{
    volumeSlider->setValue(volume);
}

int VolumePopup::volume() const
{
    return volumeSlider->value();
}

void VolumePopup::showPopup(const QPoint &buttonPos)
{
    if (isVisible()) {
        hide();
        return;
    }
    
    // Calculate position to show popup above the button
    int xPos = buttonPos.x() - width() / 2;
    int yPos = buttonPos.y() - height() - 5; // 5px gap
    
    // Ensure the popup stays within screen bounds
    QRect screenGeometry = QApplication::primaryScreen()->geometry();
    if (xPos < screenGeometry.x()) 
        xPos = screenGeometry.x();
        
    if (yPos < screenGeometry.y()) 
        yPos = screenGeometry.y();
        
    if (xPos + width() > screenGeometry.width())
        xPos = screenGeometry.width() - width();
    
    // Move and show
    move(xPos, yPos);
    show();
    raise();
}

void VolumePopup::loadVolumeStyle()
{
    QStringList stylePaths = {
        // Try application directory first
        QCoreApplication::applicationDirPath() + "/styles/volume.qss",
        // Try relative paths
        "styles/volume.qss",
        // Try absolute path
        QDir::currentPath() + "/styles/volume.qss"
    };
    
    bool styleLoaded = false;
    QString styleSheet;
    
    for (const QString &path : stylePaths) {
        QFile styleFile(path);
        if (styleFile.open(QFile::ReadOnly)) {
            styleSheet = QLatin1String(styleFile.readAll());
            styleFile.close();
            styleLoaded = true;
            qDebug() << "Successfully loaded volume style from:" << path;
            break;
        }
    }
    
    if (!styleLoaded) {
        qWarning() << "Could not load volume style from any path. Applying inline style.";
        // Apply a minimal inline style if file loading fails
        styleSheet = "QSlider#volumeSlider::groove:vertical { background: #f0f0f0; width: 4px; border-radius: 2px; }"
                     "QSlider#volumeSlider::handle:vertical { background: #1DB954; width: 10px; height: 10px; margin: 0 -3px; border-radius: 5px; }"
                     "QSlider#volumeSlider::add-page:vertical { background: #1DB954; border-radius: 2px; }"
                     "QSlider#volumeSlider::sub-page:vertical { background: #e6e6e6; border-radius: 2px; }"
                     "QLabel#percentLabel { font-size: 10pt; font-weight: bold; color: #202020; }"
                     "VolumePopup { background-color: white; border: 1px solid #e0e0e0; border-radius: 10px; padding: 5px; }";
    }
    
    // Apply style to this widget and all its children
    this->setStyleSheet(styleSheet);
    
    qDebug() << "Volume popup dimensions:" << width() << "x" << height();
    qDebug() << "Volume slider dimensions:" << volumeSlider->width() << "x" << volumeSlider->height();
} 
