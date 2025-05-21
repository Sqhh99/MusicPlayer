#include "playwidget.h"
#include "stylemanager.h"

#include <QApplication>
#include <QDebug>
#include <QDir>
#include <QStyleFactory>
#include <QLocalSocket>
#include <QLocalServer>
#include <QMessageBox>

// 单例应用程序服务器名称
#define SERVER_NAME "MusicPlayerCMakeSingleInstance"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    
    // 设置应用程序名称和组织名
    QApplication::setApplicationName("MusicPlayer");
    QApplication::setOrganizationName("MusicPlayerCMake");
    
    // 检查是否有实例已在运行
    QLocalSocket socket;
    socket.connectToServer(SERVER_NAME);
    
    if (socket.waitForConnected(500)) {
        // 已有实例在运行，发送激活消息
        QByteArray message = "ACTIVATE";
        socket.write(message);
        socket.waitForBytesWritten();
        socket.close();
        
        qDebug() << "Application already running. Sent activation message.";
        return 0; // 退出当前实例
    }
    
    // 没有实例运行，创建服务器
    QLocalServer* server = new QLocalServer(&a);
    
    // 确保没有残留的服务器实例
    QLocalServer::removeServer(SERVER_NAME);
    
    // 启动服务器
    if (!server->listen(SERVER_NAME)) {
        qWarning() << "Cannot start local server:" << server->errorString();
        QMessageBox::critical(nullptr, "错误", "无法启动应用程序: " + server->errorString());
        return 1;
    }
    
    // 连接新连接信号
    QObject::connect(server, &QLocalServer::newConnection, [&]() {
        QLocalSocket *clientSocket = server->nextPendingConnection();
        if (clientSocket->waitForReadyRead(1000)) {
            QByteArray message = clientSocket->readAll();
            if (message == "ACTIVATE") {
                // 获取主窗口并激活
                for (QWidget *widget : QApplication::topLevelWidgets()) {
                    if (PlayWidget *mainWindow = qobject_cast<PlayWidget*>(widget)) {
                        mainWindow->setWindowState(mainWindow->windowState() & ~Qt::WindowMinimized | Qt::WindowActive);
                        mainWindow->show();
                        mainWindow->activateWindow();
                        mainWindow->raise();
                        break;
                    }
                }
            }
            clientSocket->close();
        }
        clientSocket->deleteLater();
    });
    
    qDebug() << "Available styles:" << QStyleFactory::keys();
    qDebug() << "Current directory:" << QDir::currentPath();
    qDebug() << "Style directory exists:" << QDir("styles").exists();
    QStringList styleFiles = QDir("styles").entryList(QStringList() << "*.qss", QDir::Files);
    qDebug() << "Found style files:" << styleFiles;
    
    // 加载样式表目录中的所有样式
    if (!StyleManager::loadStyleSheetsFromDirectory("styles")) {
        qWarning() << "Failed to load style sheets from directory!";
        qWarning() << "Current directory:" << QDir::currentPath();
    }
    
    PlayWidget w;
    w.show();
    return a.exec();
}
