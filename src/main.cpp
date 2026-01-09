#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QLocalSocket>
#include <QLocalServer>
#include <QIcon>
#include <QDebug>
#include <QQuickWindow>

#include "app/PlayerController.h"
#include "app/PlaylistModel.h"
#include "app/TrayIconManager.h"

// Single instance server name
#define SERVER_NAME "MusicPlayerQMLSingleInstance"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    // Set application info
    QGuiApplication::setApplicationName("MusicPlayer");
    QGuiApplication::setOrganizationName("MusicPlayerCMake");
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/qt/qml/MusicPlayer/resources/icons/listen1.ico")));
    
    // Check for existing instance
    QLocalSocket socket;
    socket.connectToServer(SERVER_NAME);
    
    if (socket.waitForConnected(500)) {
        // Instance already running, send activation message
        QByteArray message = "ACTIVATE";
        socket.write(message);
        socket.waitForBytesWritten();
        socket.close();
        
        qDebug() << "Application already running. Sent activation message.";
        return 0;
    }
    
    // No instance running, create server
    QLocalServer *server = new QLocalServer(&app);
    QLocalServer::removeServer(SERVER_NAME);
    
    if (!server->listen(SERVER_NAME)) {
        qWarning() << "Cannot start local server:" << server->errorString();
    }
    
    // Set up QML engine
    QQuickStyle::setStyle("Basic");
    
    // Create controller singleton
    PlayerController *controller = new PlayerController(&app);
    
    QQmlApplicationEngine engine;
    
    // Register the playerController as a context property (lowercase for QML)
    engine.rootContext()->setContextProperty("playerController", controller);
    
    // Connect to engine warnings for debugging
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError> &warnings) {
        for (const QQmlError &error : warnings) {
            qWarning() << "QML Warning:" << error.toString();
        }
    });
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        qCritical() << "QML object creation failed!";
        QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    // Load QML using Qt 6 module loading
    qDebug() << "Loading QML from module MusicPlayer...";
    engine.loadFromModule("MusicPlayer", "Main");
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML - no root objects created";
        return -1;
    }
    
    qDebug() << "QML loaded successfully";
    
    // Get main window for tray icon and single-instance handling
    QQuickWindow *mainWindow = qobject_cast<QQuickWindow*>(engine.rootObjects().first());
    
    if (!mainWindow) {
        qCritical() << "Failed to get main window";
        return -1;
    }
    
    // Set up tray icon manager
    TrayIconManager *trayManager = new TrayIconManager(controller, &app);
    
    // Connect tray signals to window
    QObject::connect(trayManager, &TrayIconManager::showWindowRequested, mainWindow, [mainWindow]() {
        mainWindow->show();
        mainWindow->raise();
        mainWindow->requestActivate();
    });
    
    QObject::connect(trayManager, &TrayIconManager::quitRequested, &app, &QGuiApplication::quit);
    
    trayManager->show();
    
    // Handle single instance activation
    QObject::connect(server, &QLocalServer::newConnection, [server, mainWindow]() {
        QLocalSocket *clientSocket = server->nextPendingConnection();
        if (clientSocket->waitForReadyRead(1000)) {
            QByteArray message = clientSocket->readAll();
            if (message == "ACTIVATE" && mainWindow) {
                mainWindow->show();
                mainWindow->raise();
                mainWindow->requestActivate();
            }
        }
        clientSocket->close();
        clientSocket->deleteLater();
    });
    
    // Load saved playlist
    controller->loadSavedPlaylist();
    
    qDebug() << "Application started successfully";
    
    return app.exec();
}
