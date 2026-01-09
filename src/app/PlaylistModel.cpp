#include "PlaylistModel.h"

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QTimer>
#include <QUrl>

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_probePlayer = new QMediaPlayer(this);
    m_probeAudio = new QAudioOutput(this);
    m_probePlayer->setAudioOutput(m_probeAudio);

    connect(m_probePlayer, &QMediaPlayer::durationChanged, this, [this](qint64 duration) {
        if (m_probeIndex < 0 || m_probeIndex >= m_filePaths.size()) {
            return;
        }
        if (duration <= 0 || m_durationReady.value(m_probeIndex)) {
            return;
        }
        setDuration(m_probeIndex, duration);
        m_durationReady[m_probeIndex] = true;
        m_probeIndex++;
        QTimer::singleShot(0, this, &PlaylistModel::probeNext);
    });

    connect(m_probePlayer, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        if (m_probeIndex < 0 || m_probeIndex >= m_filePaths.size()) {
            return;
        }
        if (status == QMediaPlayer::InvalidMedia || status == QMediaPlayer::NoMedia) {
            if (!m_durationReady.value(m_probeIndex)) {
                setDuration(m_probeIndex, 0);
                m_durationReady[m_probeIndex] = true;
            }
            m_probeIndex++;
            QTimer::singleShot(0, this, &PlaylistModel::probeNext);
        }
    });
}

int PlaylistModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_filePaths.count();
}

QVariant PlaylistModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_filePaths.count())
        return QVariant();

    switch (role) {
    case Qt::DisplayRole:
    case FileNameRole:
        return m_fileNames.at(index.row());
    case FilePathRole:
        return m_filePaths.at(index.row());
    case IndexRole:
        return index.row();
    case DurationTextRole:
        return m_durationTexts.value(index.row(), "--:--");
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PlaylistModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[FileNameRole] = "fileName";
    roles[FilePathRole] = "filePath";
    roles[IndexRole] = "itemIndex";
    roles[DurationTextRole] = "durationText";
    return roles;
}

void PlaylistModel::setPlaylist(const QStringList &files)
{
    beginResetModel();
    m_filePaths = files;
    m_fileNames.clear();
    m_durationTexts.clear();
    for (const QString &path : files) {
        m_fileNames.append(QFileInfo(path).fileName());
        m_durationTexts.append("--:--");
    }
    endResetModel();
    emit countChanged();

    m_durationReady = QVector<bool>(m_filePaths.size(), false);
    m_probeToken++;
    startDurationProbe();
}

void PlaylistModel::clear()
{
    beginResetModel();
    m_filePaths.clear();
    m_fileNames.clear();
    m_durationTexts.clear();
    endResetModel();
    emit countChanged();

    m_durationReady.clear();
    m_probeIndex = -1;
    m_probeToken++;
}

QString PlaylistModel::getFileName(int index) const
{
    if (index >= 0 && index < m_fileNames.count()) {
        return m_fileNames.at(index);
    }
    return QString();
}

QString PlaylistModel::getFilePath(int index) const
{
    if (index >= 0 && index < m_filePaths.count()) {
        return m_filePaths.at(index);
    }
    return QString();
}

QString PlaylistModel::getDurationText(int index) const
{
    if (index >= 0 && index < m_durationTexts.count()) {
        return m_durationTexts.at(index);
    }
    return QString("--:--");
}

void PlaylistModel::startDurationProbe()
{
    if (!m_probePlayer || m_filePaths.isEmpty()) {
        return;
    }
    m_probeIndex = 0;
    probeNext();
}

void PlaylistModel::probeNext()
{
    if (m_probeIndex < 0 || m_probeIndex >= m_filePaths.size()) {
        m_probeIndex = -1;
        return;
    }

    const int token = ++m_probeToken;
    const QUrl url = QUrl::fromLocalFile(m_filePaths.at(m_probeIndex));
    m_probePlayer->setSource(url);

    QTimer::singleShot(1500, this, [this, token]() {
        if (token != m_probeToken) {
            return;
        }
        if (m_probeIndex < 0 || m_probeIndex >= m_filePaths.size()) {
            return;
        }
        if (!m_durationReady.value(m_probeIndex)) {
            setDuration(m_probeIndex, 0);
            m_durationReady[m_probeIndex] = true;
            m_probeIndex++;
            QTimer::singleShot(0, this, &PlaylistModel::probeNext);
        }
    });
}

void PlaylistModel::setDuration(int index, qint64 durationMs)
{
    if (index < 0 || index >= m_durationTexts.size()) {
        return;
    }
    m_durationTexts[index] = formatTime(durationMs);
    emit dataChanged(this->index(index), this->index(index), {DurationTextRole});
}

QString PlaylistModel::formatTime(qint64 ms) const
{
    const qint64 totalSeconds = ms / 1000;
    const qint64 minutes = totalSeconds / 60;
    const qint64 seconds = totalSeconds % 60;
    return QStringLiteral("%1:%2")
        .arg(minutes)
        .arg(seconds, 2, 10, QLatin1Char('0'));
}
