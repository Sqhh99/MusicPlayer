#ifndef WINDOWEFFECTSCONTROLLER_H
#define WINDOWEFFECTSCONTROLLER_H

#include <QObject>
#include <QPointer>

class QEvent;
class QQuickWindow;

class WindowEffectsController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool acrylicEnabled READ acrylicEnabled NOTIFY acrylicEnabledChanged)
    Q_PROPERTY(int cornerRadius READ cornerRadius WRITE setCornerRadius NOTIFY cornerRadiusChanged)

public:
    explicit WindowEffectsController(QObject *parent = nullptr);

    void attachTo(QQuickWindow *window);
    bool acrylicEnabled() const;
    int cornerRadius() const;
    void setCornerRadius(int radius);

signals:
    void acrylicEnabledChanged();
    void cornerRadiusChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    void scheduleApply();
    void applyEffects();
    void setAcrylicEnabled(bool enabled);

    QPointer<QQuickWindow> m_window;
    bool m_acrylicEnabled = false;
    bool m_applyScheduled = false;
    int m_cornerRadius = 32;
};

#endif // WINDOWEFFECTSCONTROLLER_H
