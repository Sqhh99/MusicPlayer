#include "PlaylistModel.h"

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent)
{
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
    return roles;
}

void PlaylistModel::setPlaylist(const QStringList &files)
{
    beginResetModel();
    m_filePaths = files;
    m_fileNames.clear();
    for (const QString &path : files) {
        m_fileNames.append(QFileInfo(path).fileName());
    }
    endResetModel();
    emit countChanged();
}

void PlaylistModel::clear()
{
    beginResetModel();
    m_filePaths.clear();
    m_fileNames.clear();
    endResetModel();
    emit countChanged();
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
