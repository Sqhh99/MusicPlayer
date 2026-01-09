#ifndef PLAYLISTMODEL_H
#define PLAYLISTMODEL_H

#include <QAbstractListModel>
#include <QStringList>
#include <QFileInfo>

class PlaylistModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        FileNameRole = Qt::UserRole + 1,
        FilePathRole,
        IndexRole
    };

    explicit PlaylistModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    // Proper count getter for Q_PROPERTY
    int count() const { return m_filePaths.count(); }

    Q_INVOKABLE void setPlaylist(const QStringList &files);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QString getFileName(int index) const;
    Q_INVOKABLE QString getFilePath(int index) const;

signals:
    void countChanged();

private:
    QStringList m_filePaths;
    QStringList m_fileNames;
};

#endif // PLAYLISTMODEL_H
